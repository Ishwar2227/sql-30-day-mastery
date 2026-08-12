-- The technique: aggregate to the right grain first, then apply window functions in a separate step.

-- **The three mistakes people make:**

-- 1. Including raw columns in GROUP BY → too-granular groups
-- 2. Using SUM instead of AVG for rolling average
-- 3. Missing ROWS BETWEEN → wrong window frame

-- **Template:**


-- Step 1: aggregate to correct grain
WITH grain AS (
    SELECT entity, period, SUM(metric) AS period_metric
    FROM table
    GROUP BY entity, period  -- ONLY these two, nothing else
),
-- Step 2: apply window function
rolling AS (
    SELECT entity, period, period_metric,
        AVG(period_metric) OVER (
            PARTITION BY entity
            ORDER BY period
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  -- 3-period rolling
        ) AS rolling_avg
    FROM grain
)
SELECT * FROM rolling;


-- **Practice Problem 5:**
-- For each customer, show their monthly revenue and 2-month rolling average. Include all months they ordered.

WITH grain AS(
	SELECT 
		dc.customer_name , 
		DATE_TRUNC('month',fo.order_date) AS month ,
		ROUND(SUM(foi.unit_price * foi.quantity * 
		(1 - foi.discount_pct/100.0)), 2) AS monthly_revenue
	FROM dim_customers dc
	JOIN fact_orders fo ON dc.customer_id = fo.customer_id 
	JOIN fact_order_items foi ON fo.order_id = foi.order_id
	GROUP BY dc.customer_name , DATE_TRUNC('month',fo.order_date)
),
rolling AS(
	SELECT customer_name , month, monthly_revenue,
		AVG(monthly_revenue) OVER(
			PARTITION BY customer_name 
			ORDER BY month
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS rolling_avg
	FROM grain
)
SELECT * FROM rolling;	


-- **Practice Problem 6:**
-- For each product category, show monthly revenue and 3-month rolling average. Show which months the rolling average exceeds the overall average for that category.

WITH monthly_revenue AS (
    SELECT
        dp.category,
        DATE_TRUNC('month', fo.order_date) AS month,

        SUM(
            foi.unit_price *
            foi.quantity *
            (1 - foi.discount_pct / 100.0)
        ) AS monthly_revenue

    FROM dim_products dp
    JOIN fact_order_items foi
        ON dp.product_id = foi.product_id
    JOIN fact_orders fo
        ON foi.order_id = fo.order_id

    GROUP BY
        dp.category,
        DATE_TRUNC('month', fo.order_date)
),

rolling AS (
    SELECT
        category,
        month,
        monthly_revenue,
        AVG(monthly_revenue) OVER (
            PARTITION BY category
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_month_avg,

        AVG(monthly_revenue) OVER (
            PARTITION BY category
        ) AS overall_avg

    FROM monthly_revenue
)

SELECT
    category,
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(rolling_3_month_avg, 2) AS rolling_3_month_avg,
    ROUND(overall_avg, 2) AS overall_avg

FROM rolling
WHERE rolling_3_month_avg > overall_avg
ORDER BY category,month;
