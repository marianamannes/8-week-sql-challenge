# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #4 - Data Bank

## Problem Statement
Danny has created a digital bank that also has the world’s most secure distributed data storage platform. This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments.

There are three key datasets, which are represented by the relationshop diagram below.

<p align="center">
<img src="https://8weeksqlchallenge.com/images/case-study-4-erd.png" width=60% height=60%>

***

## Case Study Questions

### A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?

```sql
SELECT COUNT(DISTINCT(node_id)) AS "Unique nodes" 
FROM customer_nodes;
```

|Unique nodes|
|-----|
|5|

***

### 2. What is the number of nodes per region?

```sql
SELECT r.region_name               AS "Region",
       COUNT(DISTINCT (c.node_id)) AS "Nodes"
FROM customer_nodes c
INNER JOIN regions r ON c.region_id = r.region_id
GROUP BY region_name;
```

|Region|Nodes|
|-----|-----|
|Europe|5|
|Australia|5|
|Asia|5|
|America|5|
|Africa|5|

***

### 3. How many customers are allocated to each region?

```sql
SELECT r.region_name                   AS "Region",
       COUNT(DISTINCT (c.customer_id)) AS "Customers"
FROM customer_nodes c
INNER JOIN regions r ON c.region_id = r.region_id
GROUP BY region_name
ORDER BY COUNT(DISTINCT (c.customer_id)) DESC;
```

|Region|Customers|
|-----|-----|
|Australia|110|
|America|105|
|Africa|102|
|Asia|95|
|Europ|88|


***

### B. Customer Transactions 

###  1. What is the unique count and total amount for each transaction type?

```sql
SELECT txn_type                      AS "Transaction type",
       COUNT(txn_type)               AS "Count",
       CONCAT("$ ", SUM(txn_amount)) AS "Amount"
FROM customer_transactions
GROUP BY txn_type;
```


|Transaction type|Count	Amount|
|-----|-----|
|deposit|2671|$ 1359168|
|withdrawal|1580|$ 793003|
|purchase|1617|$ 806537|

***

### 2. What is the average total historical deposit counts and amounts for all customers?

```sql
WITH cte_table AS (SELECT customer_id,
                          COUNT(txn_type) AS count_txn,
                          SUM(txn_amount) AS sum_txn
                   FROM customer_transactions
                   WHERE txn_type = "deposit"
                   GROUP BY customer_id)

SELECT AVG(count_txn)                                  AS "Avg Count",
       CONCAT("$ ", SUM(sum_txn) / COUNT(customer_id)) AS "Avg Amount"
FROM cte_table;
```

|Avg Count|Avg Amount|
|-----|-----|
|5.3420|$ 2718.3360|

***

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql
WITH cte_table AS (SELECT MONTH(txn_date)                                                                            AS txn_month,
                          customer_id,
                          SUM(CASE WHEN (txn_type = "deposit") = TRUE THEN 1 ELSE 0 END)                             AS deposits,
                          SUM(CASE
                                  WHEN (txn_type = "purchase" OR txn_type = "withdrawal") = TRUE THEN 1
                                  ELSE 0 END)                                                                        AS purchase_or_withdrawal
                   FROM customer_transactions
                   GROUP BY MONTH(txn_date), customer_id)

SELECT txn_month          AS "Month",
       COUNT(customer_id) AS "Customers"
FROM cte_table
WHERE deposits > 1
  AND purchase_or_withdrawal >= 1
GROUP BY txn_month
ORDER BY txn_month;
```

|Month|Customers|
|-----|-----|
|1|168|
|2|181|
|3|192|
|4|70|

***

### 4. What is the closing balance for each customer at the end of the month?

```sql
WITH cte_table AS (SELECT customer_id,
                          MONTH(txn_date)                                                                         AS txn_month,
                          SUM(CASE
                                  WHEN (txn_type = "deposit") = TRUE THEN txn_amount
                                  ELSE txn_amount * (-1) END)                                                     AS transactions
                   FROM customer_transactions
                   GROUP BY MONTH(txn_date), customer_id
                   ORDER BY customer_id, MONTH(txn_date))

SELECT customer_id                                                                                                                    AS "Customer",
       txn_month                                                                                                                      AS "Month",
       CONCAT("$ ", SUM(transactions)
                    OVER (PARTITION BY customer_id ORDER BY customer_id, txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS "Balance"
FROM cte_table
GROUP BY customer_id, txn_month;
```

|Customer|Month|Balance|
|-----|-----|-----|
|1|1|$ 312|
|1|3|$ -640|
|2|1|$ 549|
|2|3|$ 610|
|3|1|$ 144|
|3|2|$ -821|
|3|3|$ -1222|
|3|4|$ -729|
|4|1|$ 848|
|4|3|$ 655|
|5|1|$ 954|
|5|3|$ -1923|
|5|4|$ -2413|
...

***
