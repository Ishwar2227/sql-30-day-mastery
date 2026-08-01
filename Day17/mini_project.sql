-- ## Mini Project — "HR Analytics Report"
-- Your HR manager says:

-- > "I need a complete organizational analytics report. Show me the full org chart with reporting lines, identify the highest-cost teams, flag any salary anomalies where employees earn more than their manager, and give me a department summary."*
-- > 

-- Section 1 — Full Org Chart:
-- emp_name, level/depth, manager_name, department, full_path. ORDER BY full_path.

-- Section 2 — Team Cost Analysis:
-- For each manager: manager_name, direct_report_count, total_team_salary (all levels), avg_team_salary. Only show managers (employees who have at least one report).

-- Section 3 — Salary Anomalies:
-- Employees earning more than their direct manager. Show emp_name, emp_salary, manager_name, manager_salary, salary_difference.

-- Section 4 — Department Summary:
-- department, headcount, total_salary, avg_salary, highest_paid_employee.
-- 3-line comment per section. All four required.


--SECTION 1
--Shows employees and their corresponding managers
--Shows entire organization path from top manager to employee
--Displays level of each employee/manager/CEO of the company  
WITH RECURSIVE org_chart AS(
	SELECT 
		emp_id ,emp_name , 1 AS level , emp_name AS manager_name, department,
		emp_name::TEXT AS full_path
	FROM employees 
	WHERE manager_id IS NULL

	UNION ALL 
	SELECT e.emp_id ,e.emp_name , oc.level+1, oc.manager_name , e.department,
		oc.full_path ||' -> ' || e.emp_name 
	FROM employees e 
	JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT 
	emp_name , level , manager_name , department , full_path 
FROM org_chart 
ORDER BY full_path;

--SECTION 2
WITH RECURSIVE team AS(
	SELECT 
		emp_id AS manager_id,
		emp_name AS manager_name,
		emp_id, salary
	FROM employees 
	
	UNION ALL 
	
	SELECT 
		t.manager_id, t.manager_name , e.emp_id , e.salary
	FROM team t 
	JOIN employees e on e.manager_id = t.emp_id
)
SELECT 
	t.manager_name,
	(
		SELECT COUNT(*) FROM employees e 
		WHERE e.manager_id = t.manager_id 
	) AS direct_report_count,
	
	SUM(t.salary) - m.salary AS total_team_salary,
	
	ROUND(
		(SUM(t.salary) - m.salary) *1.0 / NULLIF(COUNT(*) -1,0),2) AS avg_team_salary
FROM team t 
JOIN employees m ON t.manager_id = m.emp_id 
GROUP BY t.manager_id , t.manager_name, m.salary
HAVING COUNT(*) > 1
ORDER BY total_team_salary DESC; 

--SECTION 3
--shows employees who has more salary than their managers
--shows employee name their salary and manager name and their salary 
-- shows the difference between employee salary and manager salary 
SELECT 
	e.emp_name ,
	e.salary AS emp_salary,
	m.emp_name AS manager_name,
	m.salary AS manager_salary,
	m.salary - e.salary AS salary_difference
FROM employees e 
JOIN employees m
	ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;

--SECTION 4
--shows total salary of each department 
-- Displays highest paid employee name 
-- shows average salary of department 
WITH dept_summary AS(
	SELECT 
		department, emp_name , salary,
		COUNT(*) OVER(PARTITION BY department) AS headcount,
		SUM(salary) OVER(PARTITION BY department) AS total_salary,
		ROUND(
			AVG(salary) OVER(PARTITION BY department),2) AS avg_salary,
		ROW_NUMBER() OVER( 
			PARTITION BY department
			ORDER BY salary DESC
		) AS rn 
	FROM employees 
)
SELECT 
	department,headcount,total_salary,avg_salary,
	emp_name AS highest_paid_employee
FROM dept_summary
WHERE rn = 1
ORDER BY department;
