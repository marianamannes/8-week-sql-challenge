# 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS "Number of customers"
FROM subscriptions;

# 2. What is the monthly distribution of trial plan start_date values for our dataset? - use the start of the month as the group by value
SELECT MONTHNAME(s.start_date) AS "Month",
	COUNT(p.plan_name) AS "Number of plans"
FROM subscriptions s
INNER JOIN plans p
ON s.plan_id = p.plan_id
WHERE p.plan_name = "trial"
GROUP BY MONTHNAME(s.start_date)
ORDER BY MONTH(s.start_date);

# 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name AS "planname",
	COUNT(p.plan_name) AS "plans"
FROM subscriptions s
INNER JOIN plans p
ON s.plan_id = p.plan_id
WHERE s.start_date >= "2021-01-01"
GROUP BY p.plan_name;

# 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT SUM(CASE WHEN plan_id = "4" THEN 1 ELSE 0 END) AS "Number of churns",
	CONCAT(ROUND(((SUM(CASE WHEN plan_id = "4" THEN 1 ELSE 0 END))/(COUNT(DISTINCT customer_id)))*100,1), "%") AS "Percentage of churns"
	FROM subscriptions;

# 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte_table AS(
SELECT customer_id AS "customerid",
	plan_id AS "planid",
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS "plannumber",
	start_date AS "startdate"
FROM subscriptions)
SELECT COUNT(customerid) AS "Churned Customers",
	CONCAT(ROUND(COUNT(customerid)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100,0), "%") AS "Churn percentage"
FROM cte_table
WHERE plannumber = "2" AND planid = "4";

# 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte_table AS(
SELECT customer_id AS "customerid",
	plan_id AS "planid",
	LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS "nextplan"
FROM subscriptions)
SELECT p.plan_name AS "Plan name",
	COUNT(c.customerid) AS "Number of customers",
	CONCAT(ROUND(COUNT(c.customerid)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100,2), "%") AS "Percentage of customers"
FROM cte_table c
INNER JOIN plans p
ON c.nextplan = p.plan_id
WHERE c.planid = 0
GROUP BY p.plan_name;

# 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte_table AS(
SELECT customer_id AS "customerid",
	plan_id AS "planid",
	start_date AS "startdate",
	LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS "enddate"
FROM subscriptions)
SELECT p.plan_name AS "Plan name",
	COUNT(c.customerid) AS "Number of customers",
	CONCAT(ROUND(COUNT(c.customerid)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100,2), "%") AS "Percentage of customers"
FROM cte_table c
INNER JOIN plans p
ON c.planid = p.plan_id
WHERE enddate > "2020-12-31" OR (startdate <= "2020-12-31" AND enddate IS NULL)
GROUP BY p.plan_name;

# 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS "Number of customers"
FROM subscriptions
WHERE (start_date >= "2020-01-01" AND start_date <= "2020-12-31") AND plan_id = "3";

# 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH cte_table1 AS(
	WITH cte_table2 AS(
		SELECT customer_id,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS "plannumber",
		start_date
		FROM subscriptions)
	SELECT customer_id,
		plannumber,
		start_date
	FROM cte_table2
	WHERE plannumber = "1"),
cte_table3 AS(
	SELECT customer_id,
	plan_id,
	start_date
FROM subscriptions
WHERE plan_id = 3)
SELECT ROUND(AVG(DATEDIFF(c3.start_date, c1.start_date)),2) AS "Days in average"
FROM cte_table3 c3
INNER JOIN cte_table1 c1
ON c3.customer_id = c1.customer_id;

# 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?
WITH cte_table1 AS(
	WITH cte_table2 AS(
		SELECT customer_id,
			ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS "plannumber",
			start_date
		FROM subscriptions)
	SELECT customer_id,
		plannumber,
		start_date
	FROM cte_table2
	WHERE plannumber = "1"),
cte_table3 AS(
	SELECT customer_id,
	plan_id,
	start_date
FROM subscriptions
WHERE plan_id = 3),
cte_table4 AS(
SELECT ROUND((DATEDIFF(c3.start_date, c1.start_date)),2) AS "days"
FROM cte_table3 c3
INNER JOIN cte_table1 c1
ON c3.customer_id = c1.customer_id)
SELECT "0 - 30" AS "Range",
	COUNT(days) AS "Number of customers"
FROM cte_table4
WHERE days BETWEEN 0 and 30
UNION(
SELECT "31 - 60" AS "Range",
	COUNT(days) AS "Number of customers"
FROM cte_table4
WHERE days BETWEEN 31 and 60)
UNION(
SELECT "61 - 90" AS "Range",
	COUNT(days) AS "Number of customers"
FROM cte_table4
WHERE days BETWEEN 61 and 90)
UNION(
SELECT "91 - 120" AS "Range",
	COUNT(days) AS "Number of customers"
FROM cte_table4
WHERE days BETWEEN 91 and 120)
UNION(
SELECT "120+" AS "Range",
	COUNT(days) AS "Number of customers"
FROM cte_table4
WHERE days > 120);

# 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte_table AS(
SELECT customer_id AS "customerid",
	plan_id AS "planid",
	LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS "nextplan"
FROM subscriptions)
SELECT COUNT(customerid) AS "Number of customers"
FROM cte_table
WHERE planid = 2 AND nextplan = 1;
