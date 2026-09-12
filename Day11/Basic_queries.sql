-- B1. Find all customers where customer_name has leading or
-- trailing spaces. Use LENGTH and TRIM to detect them:
-- WHERE LENGTH(customer_name) != LENGTH(TRIM(customer_name))
SELECT customer_name 
FROM customers
WHERE LENGTH(customer_name) != LENGTH(TRIM(customer_name));


-- B2. Show all customer emails in lowercase.
-- Show customer_name and lowercase_email.
SELECT customer_name , LOWER(email)
FROM customers;


-- B3. Find all customers whose city is not in standard
-- title case (i.e., city != INITCAP(city)).
-- These are the dirty city records.
SELECT customer_name, city
FROM customers
WHERE city != INITCAP(city);


-- B4. Count how many customers are missing an email.
-- Count how many have an email.
-- Show both in one row: missing_email, has_email.
SELECT COUNT(customer_name) ,
SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS missing_email,
SUM(CASE WHEN email IS NOT NULL AND email != '' THEN 1 ELSE 0 END) AS has_email 
FROM customers;


-- B5. Show customer_name, email, and the domain part
-- of their email (everything after '@').
-- Call it email_domain. Use SPLIT_PART.
-- Handle NULLs — show 'No email' for NULL emails.
SELECT customer_name ,
CASE
    WHEN email IS NULL THEN 'No email'
    ELSE SPLIT_PART(email, '@', 2)
END AS email_domain
FROM customers;








