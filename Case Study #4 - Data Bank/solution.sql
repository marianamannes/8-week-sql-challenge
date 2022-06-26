# A. Customer Nodes Exploration
# How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT (node_id)) AS "Unique nodes"
FROM customer_nodes;

# What is the number of nodes per region?
SELECT r.region_name               AS "Region",
       COUNT(DISTINCT (c.node_id)) AS "Nodes"
FROM customer_nodes c
INNER JOIN regions r ON c.region_id = r.region_id
GROUP BY region_name;

# How many customers are allocated to each region?
SELECT r.region_name                   AS "Region",
       COUNT(DISTINCT (c.customer_id)) AS "Customers"
FROM customer_nodes c
INNER JOIN regions r ON c.region_id = r.region_id
GROUP BY region_name
ORDER BY COUNT(DISTINCT (c.customer_id)) DESC;

# B. Customer Transactions
# What is the unique count and total amount for each transaction type?
SELECT txn_type                      AS "Transaction type",
       COUNT(txn_type)               AS "Count",
       CONCAT("$ ", SUM(txn_amount)) AS "Amount"
FROM customer_transactions
GROUP BY txn_type;

# What is the average total historical deposit counts and amounts for all customers?
WITH cte_table AS (SELECT customer_id,
                          COUNT(txn_type) AS count_txn,
                          SUM(txn_amount) AS sum_txn
                   FROM customer_transactions
                   WHERE txn_type = "deposit"
                   GROUP BY customer_id)

SELECT AVG(count_txn)                                  AS "Avg Count",
       CONCAT("$ ", SUM(sum_txn) / COUNT(customer_id)) AS "Avg Amount"
FROM cte_table;

# For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
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

# What is the closing balance for each customer at the end of the month?
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
