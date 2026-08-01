-- B1. Write a recursive CTE that walks from the CEO
-- down to every employee. Show emp_name and depth level.
-- Depth 1 = CEO, Depth 2 = direct reports, etc.


WITH RECURSIVE emp_info AS (
	SELECT emp_id , emp_name , manager_id, 1 AS depth
	FROM employees 
	WHERE manager_id IS NULL
	
	UNION ALL
	
	SELECT e.emp_id, e.emp_name , e.manager_id ,ei.depth+1
	FROM employees e
	JOIN emp_info ei ON e.manager_id = ei.emp_id
)
SELECT emp_name , depth
FROM emp_info;


-- B2. Find all employees who directly or indirectly
-- report to 'CTO Mike'. Show their names and depth.

WITH RECURSIVE emp_rel AS(
	SELECT emp_id , emp_name,manager_id , 2 AS depth
	FROM employees 
	WHERE emp_id = 1
	
	UNION ALL
	
	SELECT e.emp_id, e.emp_name,e.manager_id , er.depth+1
	FROM employees e
	JOIN emp_rel er ON e.manager_id = er.emp_id
)
SELECT emp_name , depth
FROM emp_rel;


-- B3. Show the full reporting path for every employee.
-- Format: 'CEO Sarah > CTO Mike > VP Eng Raj > Lead Dev Amit'
-- Show emp_name and full_path.
WITH RECURSIVE emp_repo AS(
	SELECT emp_id , emp_name,manager_id ,
		emp_name::TEXT AS full_path
	FROM employees 
	WHERE manager_id  IS NULL 
	
	UNION ALL
	
	SELECT e.emp_id , e.emp_name,e.manager_id, 
		er.full_path || ' > ' ||e.emp_name
	FROM employees e 
	JOIN emp_repo er ON e.manager_id = er.emp_id
)
SELECT emp_name , full_path
FROM emp_repo 
ORDER BY full_path;


-- B4. Find all employees with no direct reports
-- (leaf nodes in the org chart).
-- Do NOT use recursive CTE for this — use a subquery.
SELECT emp_name 
FROM employees 
WHERE emp_id NOT IN (
    SELECT manager_id FROM employees
    WHERE manager_id IS NOT NULL  -- ← critical
);


-- B5. Show each employee's name, their direct manager's name,
-- and their department. Use a self-join on employees table.
-- (No recursive CTE needed — just JOIN employees to itself.)
SELECT e.emp_name AS employee , m.emp_name AS manager , e.department
FROM employees e 
LEFT JOIN employees m
ON e.manager_id = m.emp_id; 


-- ## 🟡 Intermediate
-- I1. Calculate the total salary cost of each manager's
-- entire team (all direct and indirect reports).
-- Show manager_name, team_size, total_team_salary.
-- Use recursive CTE.

WITH RECURSIVE team AS (
    SELECT 
    emp_id AS manager_id,
    emp_name AS manager_name, 
    emp_id, salary
    FROM employees

    UNION ALL
		-- Find everyone reporting to that manager
    SELECT 
	    t.manager_id,
	    t.manager_name, 
	    e.emp_id, 
	    e.salary
    FROM team t
    JOIN employees e ON e.manager_id = t.emp_id
)
SELECT 
	manager_name , 
	COUNT(*) - 1 AS team_size,
	SUM(salary) - MAX(salary) AS total_team_salary
FROM team 
GROUP BY manager_name 
ORDER BY total_team_salary DESC;


-- I2. Find the maximum depth of the org chart.
-- Show a single number: max_depth.

WITH RECURSIVE emp_depth AS(
	SELECT 
		emp_id,manager_id, 1 AS depth
	FROM employees 
	WHERE manager_id IS NULL
	
	UNION ALL
	
	SELECT 
		e.emp_id , e.manager_id, ed.depth+1
	FROM employees e
	JOIN emp_depth ed ON e.manager_id = ed.emp_id
) 
SELECT MAX(depth) AS max_depth
FROM emp_depth;


-- I3. For each employee, show their level in the hierarchy
-- and how many people are in their subtree
-- (themselves + all who report to them at any depth).
-- Show emp_name, level, subtree_size.

WITH RECURSIVE hierarchy AS (
    -- subtree traversal
    SELECT emp_id AS root_id, emp_id, manager_id FROM employees
    UNION ALL
    SELECT h.root_id, e.emp_id, e.manager_id
    FROM hierarchy h JOIN employees e ON e.manager_id = h.emp_id
),
levels AS (
    -- depth calculation
    SELECT emp_id, emp_name, 1 AS level FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, l.level + 1
    FROM employees e JOIN levels l ON e.manager_id = l.emp_id
)
SELECT l.emp_name, l.level, COUNT(h.emp_id) AS subtree_size
FROM levels l
JOIN hierarchy h ON l.emp_id = h.root_id
GROUP BY l.emp_id, l.emp_name, l.level
ORDER BY l.level, l.emp_name;


-- I4. Find employees whose salary is higher than
-- their direct manager's salary.
-- Show emp_name, emp_salary, manager_name, manager_salary.

SELECT 
	e.emp_name ,
	e.salary AS emp_salary,
	m.emp_name AS manager_name,
	m.salary AS manager_salary
FROM employees e 
JOIN employees m
	ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;


-- I5. Show the org chart with salary budget allocation:
-- for each node, show what percentage of the
-- total company salary they personally represent.
-- Show emp_name, salary, pct_of_total_salary.

SELECT 
	emp_name, salary, 
	ROUND(
		salary * 100.0 / SUM(salary) OVER(),2) AS pct_of_total_salary
FROM employees;


-- ## 🔴 Challenging

-- C1. Build a full org chart report showing:
-- emp_name, department, level, manager_name,
-- direct_report_count, full_path.
-- Combine recursive CTE + self-join + subquery for count.


WITH RECURSIVE org_chart AS(
	SELECT 
		emp_id , emp_name , department , manager_id,
		1 AS level, emp_name::TEXT AS full_path
	FROM employees 
	WHERE manager_id IS NULL 
	
	UNION ALL
	SELECT
		e.emp_id , e.emp_name , e.department, e.manager_id,
		oc.level +1 , oc.full_path || ' -> ' || e.emp_name
	FROM employees e
	JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT 
	oc.emp_name , oc.department, oc.level,
	m.emp_name AS manager_name, 
	(
		SELECT COUNT(*) 
		FROM employees d
		WHERE d.manager_id = oc.emp_id 
	) AS direct_report_count,
	oc.full_path
FROM org_chart oc
LEFT JOIN employees m
ON oc.manager_id = m.emp_id	

ORDER BY oc.level , oc.emp_name;


-- C2. Find the shortest path between any two employees.
-- For example: from 'Analyst Rohit' to 'Lead Dev Amit'
-- the path goes up to their common ancestor then down.
-- Show the path and the number of hops.
-- Hint: find common ancestor using two ancestor CTEs.


-- Ancestors of Analyst Rohit (walk up)
WITH RECURSIVE ancestors_rohit AS (
    SELECT emp_id, emp_name, manager_id, 0 AS hops
    FROM employees WHERE emp_name = 'Analyst Rohit'
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, ar.hops + 1
    FROM employees e JOIN ancestors_rohit ar ON e.emp_id = ar.manager_id
),
-- Ancestors of Lead Dev Amit (walk up)
ancestors_amit AS (
    SELECT emp_id, emp_name, manager_id, 0 AS hops
    FROM employees WHERE emp_name = 'Lead Dev Amit'
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, aa.hops + 1
    FROM employees e JOIN ancestors_amit aa ON e.emp_id = aa.manager_id
),
-- Common ancestor = first emp_id appearing in both
common_ancestor AS (
    SELECT ar.emp_id, ar.emp_name,
           ar.hops + aa.hops AS total_hops
    FROM ancestors_rohit ar
    JOIN ancestors_amit aa ON ar.emp_id = aa.emp_id
    ORDER BY total_hops LIMIT 1
)
SELECT emp_name AS common_ancestor,
       total_hops AS shortest_path_hops
FROM common_ancestor;


-- C3. Calculate each department's total salary and
-- show what percentage each employee contributes
-- to their department's total.
-- Rank employees within department by salary.
-- Show emp_name, department, salary, dept_total,
-- pct_of_dept, dept_rank.
-- (No recursive CTE needed — window functions.)


SELECT 
	emp_name , department , salary, 
	SUM(salary) OVER(PARTITION BY department) AS dept_total ,
	ROUND(
		salary * 100.0 / SUM(salary) OVER(PARTITION BY department),2) AS pct_of_dept,
	RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS dept_rank
FROM employees;
