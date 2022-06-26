# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #3 - Foodie-Fi

## Problem Statement
Danny has created a new straming device that only has food related content. It's a subscription based business, and the goal of this case study is to answer some questions about the customers' data.

There are two key datasets, which are represented by the relationshop diagram below.

<p align="center">
<img src="https://8weeksqlchallenge.com/images/case-study-3-erd.png" width=60% height=60%>

***

## Case Study Questions

### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT customer_id) AS "Number of customers"
FROM subscriptions;
```

|Number of customers|
|-----|
|1000|

***

### 2. What is the monthly distribution of trial plan start_date values for our dataset?

```sql
SELECT MONTHNAME(s.start_date) AS "Month",
       COUNT(p.plan_name)      AS "Number of plans"
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = "trial"
GROUP BY MONTHNAME(s.start_date)
ORDER BY MONTH(s.start_date);
```

|Month|Number of plans|
|-----|-----|
|January|88|
|February|68|
|March|94|
|April|81|
|May|88|
|June|79|
|July|89|
|August|88|
|September|87|
|October|79|
|November|75|
|December|84|

***

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

```sql
SELECT p.plan_name        AS "planname",
       COUNT(p.plan_name) AS "plans"
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE s.start_date >= "2021-01-01"
GROUP BY p.plan_name;
```

|planname|plans|
|-----|-----|
|churn|71|
|pro monthly|60|
|pro annual|63|
|basic monthly|8|

***

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
SELECT SUM(CASE WHEN plan_id = "4" THEN 1 ELSE 0 END) AS "Number of churns",
       CONCAT(ROUND(((SUM(CASE WHEN plan_id = "4" THEN 1 ELSE 0 END)) / (COUNT(DISTINCT customer_id))) * 100, 1),
              "%")                                    AS "Percentage of churns"
FROM subscriptions;
```

|Number of churns|Percentage of churns|
|-----|-----|
|307|30.7%|

***

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
WITH cte_table AS (SELECT customer_id                                                   AS "customerid",
                          plan_id                                                       AS "planid",
                          ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY plan_id) AS "plannumber",
                          start_date                                                    AS "startdate"
                   FROM subscriptions)

SELECT COUNT(customerid)                                                                                        AS "Churned Customers",
       CONCAT(ROUND(COUNT(customerid) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 0),
              "%")                                                                                              AS "Churn percentage"
FROM cte_table
WHERE plannumber = "2"
  AND planid = "4";
```

|Churned Customers|Churn percentage|
|-----|-----|
|92|9%|

***

### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
WITH cte_table AS (SELECT customer_id                                                       AS "customerid",
                          plan_id                                                           AS "planid",
                          LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS "nextplan"
                   FROM subscriptions)
SELECT p.plan_name                                                                                                AS "Plan name",
       COUNT(c.customerid)                                                                                        AS "Number of customers",
       CONCAT(ROUND(COUNT(c.customerid) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 2),
              "%")                                                                                                AS "Percentage of customers"
FROM cte_table c
INNER JOIN plans p ON c.nextplan = p.plan_id
WHERE c.planid = 0
GROUP BY p.plan_name;
```

|Plan name|Number of customers|Percentage of customers|
|-----|-----|-----|
|basic monthly|546|54.60%|
|pro monthly|325|32.50%|
|pro annual|37|3.70%|
|churn|92|9.20%|

***

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql
WITH cte_table AS (SELECT customer_id                                                             AS "customerid",
                          plan_id                                                                 AS "planid",
                          start_date                                                              AS "startdate",
                          LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS "enddate"
                   FROM subscriptions)
SELECT p.plan_name                                                                                                AS "Plan name",
       COUNT(c.customerid)                                                                                        AS "Number of customers",
       CONCAT(ROUND(COUNT(c.customerid) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 2),
              "%")                                                                                                AS "Percentage of customers"
FROM cte_table c
INNER JOIN plans p ON c.planid = p.plan_id
WHERE enddate > "2020-12-31"
   OR (startdate <= "2020-12-31" AND enddate IS NULL)
GROUP BY p.plan_name;
```

|Plan name|Number of customers|Percentage of customers|
|-----|-----|-----|
|trial|19|1.90%|
|basic monthly|227|22.70%|
|pro monthly|337|33.70%|
|pro annual|195|19.50%|
|churn|236|23.60%|

***

### 8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT COUNT(DISTINCT customer_id) AS "Number of customers"
FROM subscriptions
WHERE (start_date >= "2020-01-01" AND start_date <= "2020-12-31")
  AND plan_id = "3";
```

|Number of customers|
|-----|
|195|

***

### 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?
```sql
WITH annual_plan AS (SELECT customer_id, 
                          start_date AS annual_date
                   FROM subscriptions
                   WHERE plan_id = 3),
    
     trial_date AS (SELECT customer_id, 
                         start_date AS trial_date
                  FROM subscriptions
                  WHERE plan_id = 0)

SELECT ROUND(AVG(DATEDIFF(annual_date, trial_date)), 0) AS "Days in average"
FROM annual_plan
INNER JOIN trial_date ON annual_plan.customer_id = trial_date.customer_id;
```

|Days in average|
|-----|
|105|

***

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?

```sql
WITH annual_plan AS (SELECT customer_id,
                            start_date AS annual_date
                     FROM subscriptions
                     WHERE plan_id = 3),

     trial_date AS (SELECT customer_id,
                           start_date AS trial_date
                    FROM subscriptions
                    WHERE plan_id = 0),

     day_period AS (SELECT FLOOR(DATEDIFF(annual_date, trial_date) / 30) AS diff
                    FROM trial_date
                    LEFT JOIN annual_plan ON trial_date.customer_id = annual_plan.customer_id
                    WHERE annual_plan.customer_id IS NOT NULL)

SELECT CONCAT((diff * 30) + 1, ' - ', (diff + 1) * 30) AS "Range",
       COUNT(diff)                                     AS "Number of customers"
FROM day_period
GROUP BY CONCAT((diff * 30) + 1, ' - ', (diff + 1) * 30), diff
ORDER BY diff;
```

| Range     | Number of customers |
|-----------|---------------------|
| 1 - 30    | 48                  |
| 31 - 60   | 25                  |
| 61 - 90   | 33                  |
| 91 - 120  | 35                  |
| 121 - 150 | 43                  |
| 151 - 180 | 35                  |
| 181 - 210 | 27                  |
| 211 - 240 | 4                   |
| 241 - 270 | 5                   |
| 271 - 300 | 1                   |
| 301 - 330 | 1                   |
| 331 - 360 | 1                   |

***

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
WITH cte_table AS (SELECT customer_id                                                       AS "customerid",
                          plan_id                                                           AS "planid",
                          LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS "nextplan"
                   FROM subscriptions)

SELECT COUNT(customerid) AS "Number of customers"
FROM cte_table
WHERE planid = 2
  AND nextplan = 1;
```

|Number of customers|
|-----|
|0|

***
