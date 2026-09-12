-- Your manager asks:
-- "I need a full customer segmentation report for the executive team. For every customer show their region, age group, value segment based on total spend, whether they're reachable, and their signup era. Only include active customers. Sort by value segment — High Value first, then Mid, then Low."*


-- Requirements:
-- - Columns: `customer_name`, `city`, `region`, `age_group`, `total_spent`, `value_segment`, `contact_status`, `signup_era`
-- - `total_spent` — use LEFT JOIN + COALESCE so customers with no orders show 0
-- - Custom ORDER BY: High Value → Mid Value → Low Value (not alphabetical)
-- - Active customers only
-- - 3-line comment
-- - No `SELECT *`

-- -- Executive customer segmentation report
-- -- Includes spend, demographics, contactability, and signup era
-- -- Only active customers, sorted by business-defined value priority

SELECT 
    c.customer_name,
    c.city,

    -- Region mapping
    CASE 
        WHEN c.city IN ('Mumbai', 'Pune') THEN 'West'
        WHEN c.city = 'Delhi' THEN 'North'
        WHEN c.city = 'Bangalore' THEN 'South'
        ELSE 'Other'
    END AS region,

    -- Age grouping
    CASE 
        WHEN c.age < 25 THEN 'Young'
        WHEN c.age BETWEEN 25 AND 35 THEN 'Mid'
        ELSE 'Senior'
    END AS age_group,

    -- Total spend (NULL → 0)
    COALESCE(SUM(o.total_amount), 0) AS total_spent,

    -- Value segmentation
    CASE 
        WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 'High Value'
        WHEN COALESCE(SUM(o.total_amount), 0) >= 500 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS value_segment,

    -- Contact status
    CASE 
        WHEN c.email IS NOT NULL THEN 'Reachable'
        ELSE 'Unreachable'
    END AS contact_status,

    -- Signup era
    CASE 
        WHEN c.signup_date < '2024-01-01' THEN 'Early Adopter'
        ELSE 'Recent'
    END AS signup_era

FROM customers c
LEFT JOIN orders o 
    ON c.customer_id = o.customer_id

WHERE c.is_active = TRUE

GROUP BY 
    c.customer_id,
    c.customer_name,
    c.city,
    c.age,
    c.email,
    c.signup_date

ORDER BY 
    CASE 
        WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 1
        WHEN COALESCE(SUM(o.total_amount), 0) >= 500 THEN 2
        ELSE 3
    END,
    total_spent DESC;
