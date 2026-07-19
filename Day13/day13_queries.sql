-- Day 13: Statistical Functions + Sampling + Distribution Analysis
-- Topics: PERCENTILE_CONT, NTILE, CORR, STDDEV, IQR, Outlier Detection
-- Completed: 19-7-2026

-- ## Basic

-- B1. Write a complete descriptive statistics query for total_amount
-- in the orders table.
-- Show: count, mean, min, max, range, stddev.


SELECT 
	COUNT(total_amount) AS total_rows,
	AVG(total_amount) AS mean_value,
	MIN(total_amount) AS minimum_value,
	MAX(total_amount) AS maximum_value,
	MAX(total_amount) - MIN(total_amount) AS range,
	STDDEV(total_amount) AS std_deviation
FROM orders;


-- B2. Find the median order amount using PERCENTILE_CONT.
-- Show just the median value.


SELECT 
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median
FROM orders;


-- B3. Divide orders into 4 quartiles by total_amount.
-- Show order_id, total_amount, and quartile.


SELECT order_id ,
		total_amount,
		NTILE(4) OVER (ORDER BY total_amount) AS quartile 
FROM orders;


-- B4. Get a random sample of 3 customers.
-- Show customer_name and city.


SELECT customer_name,
		city
FROM customers 
ORDER BY RANDOM() 
LIMIT 3;


-- B5. Find the mean and median age of customers.
-- Show both in one row as mean_age and median_age.
-- Do you expect them to be the same? Write your expectation
-- as a SQL comment.


SELECT 
		AVG(age) AS mean_age,
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY age) AS median_age
FROM customers;
--NO i don't expect them to be same cause , one of the customers 
--can be more older than others like thier age can be around 45-50 , and avg age can be 30-35


-- ## 🟡 Intermediate

-- I1. Build a full distribution analysis of order amounts.
-- Buckets: 0-200, 200-500, 500-800, 800+
-- Show bucket, order_count, pct_of_total.
-- Order by bucket logically (not alphabetically).


SELECT 
	CASE 
			WHEN total_amount < 200 THEN '0-200'
			WHEN total_amount < 500 THEN '200-500'
			WHEN total_amount < 800 THEN '500 - 800'
			ELSE '800+'
	END AS buckets ,
	COUNT(*) AS order_count,
	ROUND(
			COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS pct_of_total
FROM orders 
GROUP BY buckets
ORDER BY MIN(total_amount);


-- I2. Find Q1, median, Q3, and IQR for total_amount.
-- Show all four in one row.
-- Then identify which orders fall outside
-- Q1 - 1.5 *IQR or Q3 + 1.5* IQR (Tukey's outlier method).


WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_amount) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_amount) AS Q3,
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY total_amount) AS median
    FROM orders
),
iqr_calc AS (
    SELECT Q1, Q3, median, Q3 - Q1 AS IQR FROM stats
)

SELECT Q1, Q3, median, IQR FROM iqr_calc;

SELECT o.order_id, o.total_amount
FROM orders o, iqr_calc i
WHERE o.total_amount < i.Q1 - 1.5 * i.IQR
   OR o.total_amount > i.Q3 + 1.5 * i.IQR;


-- I3. Check if there's a correlation between customer age
-- and their total spending. Show the correlation coefficient
-- and interpret it in a SQL comment.


SELECT CORR(c.age,o.total_amount) AS age_spend_correlation
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
--0.751 that indicates Strong Positive Correlation exist between customer age and thier spending 


-- I4. Divide customers into spending deciles (10 buckets)
-- based on their total spend. Show customer_name,
-- total_spent, and decile. Use a CTE for totals.


WITH totals AS (
    SELECT c.customer_id, c.customer_name,
           SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name, total_spent,
    NTILE(10) OVER (ORDER BY total_spent) AS decile
FROM totals;


-- I5. Compare mean vs median total_amount per city.
-- Show city, mean_amount, median_amount, and a column
-- called 'distribution_skew':
-- If mean > median → 'Right Skewed'
-- If mean < median → 'Left Skewed'
-- If equal → 'Symmetric'


WITH compare AS (
		SELECT city,
		AVG(total_amount) AS mean_amount,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median_amount
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id 
		GROUP BY city
)
SELECT city,mean_amount,median_amount,
CASE 
		WHEN mean_amount > median_amount THEN 'Right Skewed'
		WHEN mean_amount < median_amount THEN 'Left Skewed'
		WHEN mean_amount = median_amount THEN 'Symmetric'
END AS distribution_skew
FROM compare;		


-- 🔴 Challenging

/*C1. Build a complete statistical profile of the orders table
in one query. Show:
count, mean, median, stddev, variance, min, max,
range, Q1, Q3, IQR, and outlier_count
(orders beyond Q1 - 1.5*IQR or Q3 + 1.5*IQR).
This is a real EDA (Exploratory Data Analysis) query.*/


WITH profile AS (
SELECT 
		COUNT(*) AS total_counts,
		AVG(total_amount) AS mean,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY total_amount) AS median,
		STDDEV(total_amount) AS std_dev,
		VARIANCE(total_amount) AS variance,
		MIN(total_amount) AS min,
		MAX(total_amount) AS max,
		MAX(total_amount) - MIN(total_amount) AS range,
		PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total_amount) AS Q1,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_amount) AS Q3
FROM orders
)
SELECT total_counts,mean,median,std_dev,variance,min,max,range,Q1,Q3,
Q3 - Q1 AS IQR,
( 
	SELECT COUNT(*) 
	FROM orders 
	WHERE total_amount < Q1 - 1.5*IQR 
	OR total_amount > Q3 + 1.5*IQR
) AS outlier_count
FROM profile;
		


/*C2. Build a customer segmentation using NTILE:
Divide customers by total spend into 4 quartiles.
Label them:
Quartile 4 → 'Champions'
Quartile 3 → 'Loyal'
Quartile 2 → 'Potential'
Quartile 1 → 'At Risk'
Show customer_name, total_spent, quartile, segment.*/


WITH customer_det AS (
SELECT 
	customer_name, SUM(total_amount) AS total_spent,
	NTILE(4) OVER (ORDER BY SUM(total_amount)) AS quartile
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id
	GROUP BY customer_name
)
SELECT customer_name,total_spent,quartile,
CASE 
	WHEN quartile = 4 THEN 'Champions'
	WHEN quartile = 3 THEN 'Loyal'
	WHEN quartile = 2 THEN 'Potential'
	WHEN quartile = 1 THEN 'At Risk'
END AS segment 
FROM customer_det;


/*C3. Create a sampling query that splits customers into
a 70/30 train-test split based on customer_id.
Show customer_name, city, and split ('Train' or 'Test').
Use NTILE(10) — customers in deciles 1-7 are Train,
8-10 are Test.
This is how ML engineers create dataset splits in SQL.*/


WITH customer_split AS(
	SELECT customer_name , city,
	NTILE(10) OVER (ORDER BY customer_id) AS decile
FROM customers 
) 
SELECT 
	customer_name , city, 
	CASE
		WHEN decile <= 7 THEN 'Train'
		ELSE 'Test'
	END AS split
FROM customer_split;


