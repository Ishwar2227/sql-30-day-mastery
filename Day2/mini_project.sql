-- "Data Quality Audit Report"**
-- You're a data analyst. Before your team builds a customer segmentation model, your manager says:
-- > *"Give me a clean profile of our active customer base. I need to know who they are, where they're from, whether we can contact them, and flag any data quality issues."*
-- > 
-- Write **one query** that returns:
-- - `customer_name`
-- - `city`
-- - `age`
-- - `email` — show 'No email on file' if NULL using COALESCE
-- - `is_email_missing` — TRUE/FALSE computed column
-- - `signup_date`

-- Filtered to: active customers only
-- Ordered by: city alphabetically, then signup_date newest first
-- No LIMIT this time — return all of them

-- Show active customers only
-- Replace NULL emails with readable text
-- Sort by city (A-Z) and latest signup first

SELECT 
    customer_name,
    city,
    age,
    signup_date,
    COALESCE(email, 'No email on file') AS email,
    (email IS NULL) AS is_email_missing
FROM customers
WHERE is_active = TRUE
ORDER BY city ASC, signup_date DESC;
