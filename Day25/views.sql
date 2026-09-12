-- View 1: `v_customer_360`
-- A complete customer profile view showing for each active customer:
-- customer_id, customer_name, city, state, age, signup_date, total_orders, total_spent, avg_order_value, last_order_date, days_since_last_order, top_category, value_segment (High/Mid/Low), churn_risk (High if > 60 days inactive, Low otherwise)

CREATE VIEW v_customer_360 AS
WITH customer_stats AS (
    SELECT
        c.customer_id,c.customer_name,c.city,
        c.state,c.age,c.signup_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(
            oi.unit_price
            * oi.quantity
            * (1 - oi.discount_pct / 100.0)
        ) AS total_spent,
        MAX(o.order_date) AS last_order_date
    FROM dim_customers c
    JOIN fact_orders o ON c.customer_id = o.customer_id
    JOIN fact_order_items oi ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,c.customer_name,c.city,c.state,
        c.age,c.signup_date
),
customer_stat_final AS(
	SELECT 
		*,
		ROUND(
			total_spent / NULLIF(total_orders,0),2) AS avg_order_value,
		(
			SELECT MAX(order_date) FROM fact_orders
		) - last_order_date AS days_since_last_order
		FROM customer_stats
),
category_spending AS(
	SELECT 
		o.customer_id , p.category,
		SUM(unit_price * quantity * (1-discount_pct / 100.0)) AS category_spent
	FROM fact_orders o 
	JOIN fact_order_items oi ON o.order_id = oi.order_id 
	JOIN dim_products p ON oi.product_id = p.product_id
	GROUP BY o.customer_id, p.category
),
ranked_categories AS(
	SELECT 
		customer_id , category,
		ROW_NUMBER() OVER(
			PARTITION BY customer_id 
			ORDER BY category_spent DESC
		) AS category_rank
	FROM category_spending
),
top_categories AS(
	SELECT 
		customer_id , category AS top_category
	FROM ranked_categories
	WHERE category_rank = 1
)
SELECT 
	csf.customer_id , csf.customer_name,
  csf.city,csf.state, csf.age,
  csf.signup_date, csf.total_orders, csf.total_spent,
  csf.avg_order_value,

  csf.last_order_date,
  csf.days_since_last_order,
	tc.top_category,
	
	CASE 
		WHEN csf.total_spent >= 100000 THEN 'High'
		WHEN csf.total_spent >= 50000 THEN 'Mid'
		ELSE 'Low'
	END AS value_segment,
	
	CASE 
		WHEN csf.days_since_last_order > 60 THEN 'High'
		ELSE 'Low'
	END AS churn_risk
FROM customer_stat_final csf

LEFT JOIN top_categories tc
    ON csf.customer_id = tc.customer_id;


-- View 2:** `v_product_performance`
-- Product performance showing: product_id, product_name, category, total_units_sold, total_revenue, total_profit, profit_margin_pct, revenue_rank_in_category

CREATE VIEW  v_product_performance1 AS
WITH product_stats AS(
	SELECT 
		dp.product_id, product_name,
		category,
		COUNT(quantity) AS total_units_sold,
		SUM(unit_price * quantity * (1-discount_pct / 100.0)) AS total_revenue,
		SUM(
    (unit_price * quantity * (1 - discount_pct / 100.0))
    - (cost * quantity)) AS total_profit
   FROM fact_order_items fi 
   JOIN dim_products dp ON fi.product_id = dp.product_id 
   GROUP BY dp.product_id, product_name,category
 )
 SELECT 
	 *,
	 ROUND(total_profit * 100.0 / NULLIF(total_revenue,0),
	 2) AS profit_margin_pct,
	 RANK() OVER(
		 PARTITION BY category
		 ORDER BY total_revenue DESC
	) AS revenue_rank_in_category
FROM product_stats;


-- View 3: `v_monthly_business_kpis`
-- Monthly KPIs showing: month, monthly_revenue, new_customers, returning_customers, monthly_orders, avg_order_value, mom_revenue_growth_pct

CREATE VIEW v_monthly_business_kpis AS
WITH monthly_stats AS(
	SELECT
		DATE_TRUNC('month',order_date) AS month,
		ROUND(SUM(unit_price * quantity * (1-discount_pct / 100.0)),
		2) AS monthly_revenue,
		COUNT(DISTINCT fo.order_id) AS  monthly_orders
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY DATE_TRUNC('month',order_date)
),
first_order AS(
	SELECT
		customer_id,
		DATE_TRUNC('month',MIN(order_date)) AS first_order_month
	FROM fact_orders
	GROUP BY customer_id
),
customer_month AS(
	SELECT DISTINCT 
		customer_id,
		DATE_TRUNC('month',order_date) AS month
	FROM fact_orders
),
customer_types AS(
	SELECT 
		cm.month,
		cm.customer_id,
		CASE 
			WHEN cm.month = fo.first_order_month
				THEN 'new'
			ELSE 'returning'
		END AS customer_type
	FROM customer_month cm
	JOIN first_order fo ON cm.customer_id = fo.customer_id 
),
customer_kpis AS(
	SELECT 
		month,
		COUNT(*) FILTER(
			WHERE customer_type = 'new'
		) AS new_customers,
		COUNT(*) FILTER(
			WHERE customer_type = 'returning'
		) AS returning_customers
	FROM customer_types
	GROUP BY month
),
combined AS(
	SELECT 
		ms.month, ms.monthly_revenue,
		ck.new_customers, ck.returning_customers,
		ms.monthly_orders,

		ROUND(
			ms.monthly_revenue / NULLIF(ms.monthly_orders,0),2
		) AS avg_order_value
	FROM monthly_stats ms
	LEFT JOIN customer_kpis ck ON ms.month = ck.month
),
with_previous AS (
    SELECT
        *,
        LAG(monthly_revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM combined
)
SELECT
    month,
    monthly_revenue,
    new_customers,
    returning_customers,
    monthly_orders,
    avg_order_value,

    ROUND(
        (
            (monthly_revenue - previous_month_revenue)
            / NULLIF(previous_month_revenue, 0)
        ) * 100,
        2
    ) AS mom_revenue_growth_pct
FROM with_previous
ORDER BY month; 

------------------------------------------------------------------------------------------------------------------------------
-- Stored Procedure:** `sp_refresh_customer_segments()`
-- Updates the value_segment for all customers based on their latest total spend. Uses a transaction with ROLLBACK on error.

CREATE OR REPLACE PROCEDURE sp_refresh_customer_segments()
LANGUAGE plpgsql
AS $$
BEGIN 
	UPDATE dim_customers c
    SET value_segment =
        CASE
            WHEN s.total_spent >= 100000 THEN 'High'
            WHEN s.total_spent >= 50000 THEN 'Mid'
            ELSE 'Low'
        END
    FROM (
        SELECT
            fo.customer_id,
            SUM(oi.unit_price * oi.quantity * (1 - oi.discount_pct / 100.0)
            ) AS total_spent
        FROM fact_orders fo
        JOIN fact_order_items oi ON fo.order_id = oi.order_id
        GROUP BY fo.customer_id
    ) s
    
WHERE c.customer_id = s.customer_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

CALL sp_refresh_customer_segments();
