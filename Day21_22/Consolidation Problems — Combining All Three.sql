-- CP1. Find customers who were consistently "returning" for
-- at least 2 consecutive months (not new, not churned).
-- Combine Pattern 1 and Pattern 2.

WITH user_period AS (
    SELECT
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date) AS month
    FROM dim_customers dc
    JOIN fact_orders fo
        ON dc.customer_id = fo.customer_id
    GROUP BY
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date)
),

first_seen AS (
    SELECT
        customer_id,
        MIN(month) AS first_order
    FROM user_period
    GROUP BY customer_id
),

all_periods AS (
    SELECT DISTINCT month
    FROM user_period
),

classification AS (
    SELECT
        ap.month,
        fs.customer_id,

        CASE
            WHEN fs.first_order = ap.month
                THEN 'new'

            WHEN up.customer_id IS NOT NULL
                THEN 'returning'

            ELSE 'churned'
        END AS type

    FROM all_periods ap

    CROSS JOIN first_seen fs

    LEFT JOIN user_period up
        ON fs.customer_id = up.customer_id
        AND up.month = ap.month

    WHERE fs.first_order <= ap.month
),

flagged AS (
    SELECT
        customer_id,
        month,

        CASE
            WHEN type = 'returning' THEN 1
            ELSE 0
        END AS returning_flag

    FROM classification
),

with_previous AS (
    SELECT
        customer_id,
        month,
        returning_flag,

        LAG(month) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_month,

        LAG(returning_flag) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_returning_flag

    FROM flagged
),

consecutive AS (
    SELECT
        customer_id,
        month,

        CASE
            WHEN returning_flag = 1
                 AND previous_returning_flag = 1
                 AND month - previous_month = INTERVAL '1 month'
            THEN 1
            ELSE 0
        END AS consecutive_returning

    FROM with_previous
)

SELECT
    dc.customer_name,
    COUNT(*) AS consecutive_returning_months
FROM consecutive c
JOIN dim_customers dc
    ON c.customer_id = dc.customer_id
WHERE c.consecutive_returning = 1
GROUP BY
    dc.customer_id,
    dc.customer_name
HAVING COUNT(*) >= 1
ORDER BY
    consecutive_returning_months DESC;


-- CP2. For customers with a 3-month rolling average above 50000,
-- identify if they had consecutive months of growth.
-- Combine Pattern 2 and Pattern 3.


WITH monthly_revenue AS (
    SELECT
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date) AS month,

        SUM(
            foi.unit_price
            * foi.quantity
            * (1 - foi.discount_pct / 100.0)
        ) AS monthly_revenue

    FROM dim_customers dc

    JOIN fact_orders fo ON dc.customer_id = fo.customer_id
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date)
),

rolling AS (
    SELECT
        customer_id,
        customer_name,
        month,
        monthly_revenue,

        AVG(monthly_revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_month_avg,

        LAG(monthly_revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_revenue

    FROM monthly_revenue
),

growth AS (
    SELECT
        customer_id,
        customer_name,
        month,
        monthly_revenue,
        rolling_3_month_avg,

        CASE
            WHEN monthly_revenue > previous_revenue
            THEN 1
            ELSE 0
        END AS growth_flag

    FROM rolling
),

consecutive_growth AS (
    SELECT
        *,
        SUM(growth_flag) OVER (
            PARTITION BY customer_id
            ORDER BY month
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS consecutive_growth_months

    FROM growth
)

SELECT
    customer_name,
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(rolling_3_month_avg, 2) AS rolling_3_month_avg,
    consecutive_growth_months

FROM consecutive_growth

WHERE rolling_3_month_avg > 50000
  AND consecutive_growth_months >= 2

ORDER BY
    customer_name,
    month;


-- CP3. Build a complete customer health dashboard showing:
-- - customer_name
-- - months_active (total distinct months with orders)
-- - is_consecutive_3_months (TRUE/FALSE)
-- - avg_monthly_revenue
-- - 3m_rolling_avg (latest month's rolling average)
-- - current_status (new/returning/churned based on last month)
-- This combines all three patterns in one query.

WITH monthly_revenue AS (
    SELECT
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date) AS month,

        SUM(
            foi.unit_price
            * foi.quantity
            * (1 - foi.discount_pct / 100.0)
        ) AS monthly_revenue

    FROM dim_customers dc
    JOIN fact_orders fo
        ON dc.customer_id = fo.customer_id
    JOIN fact_order_items foi
        ON fo.order_id = foi.order_id

    GROUP BY
        dc.customer_id,
        dc.customer_name,
        DATE_TRUNC('month', fo.order_date)
),

rolling AS (
    SELECT
        customer_id,
        customer_name,
        month,
        monthly_revenue,

        AVG(monthly_revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_avg,

        LAG(month) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_month

    FROM monthly_revenue
),

consecutive AS (
    SELECT
        *,
        CASE
            WHEN month - previous_month = INTERVAL '1 month'
            THEN 1
            ELSE 0
        END AS consecutive_flag
    FROM rolling
),

customer_summary AS (
    SELECT
        customer_id,
        customer_name,

        COUNT(DISTINCT month) AS months_active,

        MAX(rolling_3_avg) AS latest_rolling_avg,

        SUM(consecutive_flag) AS consecutive_month_pairs

    FROM consecutive

    GROUP BY
        customer_id,
        customer_name
),

last_activity AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month DESC
        ) AS rn
    FROM monthly_revenue
)

SELECT
    cs.customer_name,

    cs.months_active,

    CASE
        WHEN cs.consecutive_month_pairs >= 2
        THEN TRUE
        ELSE FALSE
    END AS is_consecutive_3_months,

    ROUND(
        (
            SELECT AVG(mr.monthly_revenue)
            FROM monthly_revenue mr
            WHERE mr.customer_id = cs.customer_id
        ),
        2
    ) AS avg_monthly_revenue,

    ROUND(cs.latest_rolling_avg, 2) AS "3m_rolling_avg",

    CASE
        WHEN la.month = (
            SELECT MIN(month)
            FROM monthly_revenue
            WHERE customer_id = cs.customer_id
        )
        THEN 'new'

        WHEN la.month = DATE_TRUNC('month', CURRENT_DATE)
        THEN 'returning'

        ELSE 'churned'
    END AS current_status

FROM customer_summary cs

JOIN last_activity la
    ON cs.customer_id = la.customer_id
    AND la.rn = 1

ORDER BY
    cs.customer_name;
