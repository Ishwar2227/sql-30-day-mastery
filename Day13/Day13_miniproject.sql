-- Day 13 Mini Project: EDA Report for ML Pipeline
-- Statistical summary, distribution, outlier detection, ML segmentation
-- Completed: 19-7-2026

-- ## Mini Project — "EDA Report for ML Pipeline"
-- Your data science manager says:
-- "Before we build a customer churn prediction model, I need a full exploratory data analysis report on our orders data. Give me the statistical summary, distribution analysis, outlier identification, and customer segments. Format it so a data scientist can act on it directly."*

-- Build four sections:

-- Section 1 — Statistical Summary:**
-- Full descriptive stats for total_amount: count, mean, median, stddev, min, max, Q1, Q3, IQR.

-- Section 2 — Distribution:**
-- Amount buckets (0-200, 200-500, 500-800, 800+) with count and percentage.

-- Section 3 — Outlier Report:**
-- Customers whose total spend is a Tukey outlier (beyond Q3 + 1.5×IQR). Show customer_name, total_spent.

-- Section 4 — ML Segmentation:**
-- NTILE(4) spend segments with labels (Champions/Loyal/Potential/At Risk). Show customer_name, total_spent, segment.
-- 3-line comment per section. All in pgAdmin, all running.


--SECTION 1 - full descriptive summary of dataset 
--Give total counts of rows , and shows avg spending customers 
--Shows Highest spending(VIP) customers and low spending customers 
WITH statistical_summary AS ( 
SELECT
		COUNT(total_amount) AS total_counts,
		AVG(total_amount) AS mean,
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY total_amount) AS median,
		STDDEV(total_amount) AS std_dev,
		MIN(total_amount) AS minimum,
		MAX(total_amount) AS maximum,
		PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total_amount) AS Q1,
		PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY total_amount) AS Q3,
		PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY total_amount) - 
		PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total_amount) AS IQR
FROM orders 
)
SELECT * FROM statistical_summary;

--SECTION 2 - Distribution 
--Distribute customers according to their spendings 
--shows low spending customer first 
-- goes to highest spending customers and percentage of total spendings in each bucket
WITH distribution AS(
	SELECT 
		CASE 
			WHEN total_amount < 200 THEN '0-200'
			WHEN total_amount < 500 THEN '200-500'
			WHEN total_amount < 800 THEN '500-800'
			ELSE '800+'
		END AS buckets,
		COUNT(*) AS order_count,
		ROUND(
			COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS pct_of_total
		FROM orders
		GROUP BY buckets 
)
SELECT * FROM distribution;

--SECTION 3 
--Shows customers who have abnormal spendings compare to other customers 
WITH outlier_report AS (
    SELECT
        o.order_id,
        c.customer_name,
        o.total_amount,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_amount) OVER () AS q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_amount) OVER () AS median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_amount) OVER () AS q3
    FROM orders o
    JOIN customers c
    ON c.customer_id = o.customer_id
)
SELECT
    order_id,
    customer_name,
    total_amount,
    q1,
    median,
    q3,
    (q3-q1) AS iqr
FROM outlier_report
WHERE total_amount < q1 - 1.5*(q3-q1)
   OR total_amount > q3 + 1.5*(q3-q1);
		
--SECTION 4 - ML segmentation 
--Displays the highest spending customer as champions 
--Displays the lowest spending customer as at risk 
WITH ML_seg AS (
		SELECT customer_name , SUM(total_amount) AS total_spent,
		NTILE(4) OVER (ORDER BY SUM(total_amount)) AS quartiles
		FROM customers c
		JOIN orders o ON c.customer_id = o.customer_id 
		GROUP BY customer_name
)
SELECT 
	customer_name, total_spent,quartiles ,
		CASE 
			WHEN quartile = 4 THEN 'Champions'
			WHEN quartile = 3 THEN 'Loyal'
			WHEN quartile = 2 THEN 'Potential'
			WHEN quartile = 1 THEN 'At Risk'
END AS segment 
FROM ML_seg;
