-- The technique: for each time period, classify every known user as new/returning/churned using CTEs and LEFT JOIN.
-- **Template:**

WITH user_periods AS (
    -- all user-period combinations where user was active
    SELECT user_id, period FROM activity
    GROUP BY user_id, period
),
first_seen AS (
    SELECT user_id, MIN(period) AS first_period
    FROM user_periods GROUP BY user_id
),
all_periods AS (
    SELECT DISTINCT period FROM user_periods
),
classification AS (
    SELECT ap.period, fs.user_id,
        CASE
            WHEN fs.first_period = ap.period THEN 'new'
            WHEN up.user_id IS NOT NULL THEN 'returning'
            ELSE 'churned'
        END AS type
    FROM all_periods ap
    CROSS JOIN first_seen fs
    LEFT JOIN user_periods up
        ON fs.user_id = up.user_id AND up.period = ap.period
    WHERE fs.first_period <= ap.period
)
SELECT period,
    COUNT(*) FILTER (WHERE type = 'new') AS new_users,
    COUNT(*) FILTER (WHERE type = 'returning') AS returning_users,
    COUNT(*) FILTER (WHERE type = 'churned') AS churned_users
FROM classification
GROUP BY period ORDER BY period;


-- **Practice Problem 3:**
-- Apply this template to your ecommerce data. Show monthly new, returning, and churned customers for all months in 2024.


WITH user_period AS (
    SELECT
        dc.customer_id,
        DATE_TRUNC('month', fo.order_date) AS month
    FROM dim_customers dc
    JOIN fact_orders fo
        ON dc.customer_id = fo.customer_id
    GROUP BY
        dc.customer_id,
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

monthly_counts AS (
    SELECT
        month,
        COUNT(*) FILTER (
            WHERE type = 'new'
        ) AS new_users,

        COUNT(*) FILTER (
            WHERE type = 'returning'
        ) AS returning_users,

        COUNT(*) FILTER (
            WHERE type = 'churned'
        ) AS churned_users
    FROM classification
    GROUP BY month
)

SELECT
    month,
    ROUND(
        returning_users * 100.0 /
        NULLIF(
            new_users + returning_users + churned_users,
            0
        ),2) AS retention_rate_pct

FROM monthly_counts
WHERE month >= '2024-01-01'
  AND month < '2025-01-01'
ORDER BY month;


-- **Practice Problem 4:**
-- Calculate retention rate per month: `returning / (new + returning + churned)`. Show month and retention_rate_pct.


WITH user_period AS(
	SELECT dc.customer_id,
		DATE_TRUNC('month',fo.order_date) AS month,
	FROM dim_customers dc 
	JOIN fact_orders fo ON dc.customer_id = fo.customer_id 
	GROUP BY dc.customer_id,
	DATE_TRUNC('month',fo.order_date)
),
first_seen AS(
	SELECT 
		customer_id , MIN(month) AS first_order 
	FROM user_period
	GROUP BY customer_id
),
all_periods AS(
	SELECT DISTINCT month 
	FROM user_period
),
classification AS(
	SELECT 
		ap.month,fs.customer_id,
		CASE
			WHEN fs.first_order = ap.month THEN 'new'
			WHEN up.customer_id IS NOT NULL THEN 'returning'
			ELSE 'churned'
		END AS type 
	FROM all_periods ap
	CROSS JOIN first_seen fs
	
	LEFT JOIN user_period up 
	ON fs.customer_id = up.customer_id
	AND up.month = ap.month
	
	WHERE fs.first_order <= ap.month
),
monthly_counts AS (
    SELECT
        month,

        COUNT(*) FILTER (WHERE type = 'new') AS new_users,
        COUNT(*) FILTER (WHERE type = 'returning') AS returning_users,
        COUNT(*) FILTER (WHERE type = 'churned') AS churned_users

    FROM classification
    GROUP BY month
)
SELECT 
	month,
	ROUND(
		returning_users * 100.0 / NULLIF(new_users + returning_users + churned_users,0)
		,2) AS retention_rate_pct
FROM monthly_counts
WHERE month >= '2024-01-01' AND month < '2025-01-01'
ORDER BY month;
			
