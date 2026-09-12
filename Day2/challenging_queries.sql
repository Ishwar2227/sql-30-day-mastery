-- C1. Write a query that shows customer_name, email, and a third column
-- called 'contact_status':
-- - If email exists → 'Reachable'
-- - If email is NULL → 'Unreachable'
-- Without using CASE. You already know the function that can do this.

SELECT
    customer_name,
    email,
    COALESCE(REPLACE(email, email, 'Reachable'), 'Unreachable') AS contact_status
FROM customers;
