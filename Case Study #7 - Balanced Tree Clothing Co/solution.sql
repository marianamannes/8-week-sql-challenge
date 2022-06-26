# High Level Sales Analysis
# What was the total quantity sold for all products?
SELECT SUM(qty) AS "Total quantity"
FROM sales;

# What is the total generated revenue for all products before discounts?
SELECT CONCAT('$', FORMAT(SUM(qty * price), 2)) AS "Revenue before discounts"
FROM sales;

# What was the total discount amount for all products?
SELECT CONCAT('$', FORMAT(SUM(discount), 2)) AS "Total discount amount"
FROM sales;

# Transaction Analysis
# How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS "Unique transactions"
FROM sales;

# What is the average unique products purchased in each transaction?
WITH cte_table AS (SELECT txn_id,
                          COUNT(DISTINCT prod_id) AS unique_products
                   FROM sales
                   GROUP BY txn_id)

SELECT ROUND(AVG(unique_products)) AS "Avg unique products"
FROM cte_table;

# What is the average discount value per transaction?
WITH cte_table AS (SELECT txn_id,
                          SUM(price * qty * discount / 100) AS discount
                   FROM sales
                   GROUP BY txn_id)

SELECT CONCAT('$', FORMAT(AVG(discount), 2)) AS "Avg discount"
FROM cte_table;

# What is the percentage split of all transactions for members vs non-members?
WITH cte_table AS (SELECT member        AS member,
                          COUNT(txn_id) AS transactions
                   FROM sales
                   GROUP BY member)

SELECT CASE WHEN (member = 0) = TRUE THEN "no" ELSE "yes" END                AS "Member",
       CONCAT(ROUND(transactions / SUM(transactions) OVER () * 100, 2), "%") AS "Transactions Percentage"
FROM cte_table;

# What is the average revenue for member transactions and non-member transactions?
SELECT CASE WHEN (member = 0) = TRUE THEN "no" ELSE "yes" END            AS "Member",
       CONCAT('$', FORMAT(SUM(price * qty) / COUNT(DISTINCT txn_id), 2)) AS "Avg revenue"
FROM sales
GROUP BY member;

# Product Analysis
# What are the top 3 products by total revenue before discount?
SELECT p.product_name                               AS "Product",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2)) AS "Revenue"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY SUM(s.price * s.qty) DESC
LIMIT 3;

# What is the total quantity, revenue and discount for each segment?
SELECT p.segment_name                                                  AS "Segment",
       SUM(s.qty)                                                      AS "Quantity",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2))                    AS "Revenue",
       CONCAT('$', FORMAT(SUM(s.price * s.qty * s.discount / 100), 2)) AS "Discount"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name
ORDER BY SUM(s.price * s.qty) DESC;

# What is the top selling product for each segment?
SELECT p.segment_name                                                           AS "Segment",
       p.product_name                                                           AS "Product",
       SUM(s.qty)                                                               AS "Quantity",
       ROW_NUMBER() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS "Position"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name, p.segment_name
ORDER BY 4
LIMIT 4;

# What is the total quantity, revenue and discount for each category?
SELECT p.category_name                                                 AS "Category",
       SUM(s.qty)                                                      AS "Quantity",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2))                    AS "Revenue",
       CONCAT('$', FORMAT(SUM(s.price * s.qty * s.discount / 100), 2)) AS "Discount"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name
ORDER BY SUM(s.price * s.qty) DESC;

# What is the top selling product for each category?
SELECT p.category_name                                                           AS "Category",
       p.product_name                                                            AS "Product",
       SUM(s.qty)                                                                AS "Quantity",
       ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS "Position"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name, p.category_name
ORDER BY 4
LIMIT 2;

# What is the percentage split of revenue by product for each segment?
WITH cte_table AS (SELECT p.segment_name       AS segment,
                          p.product_name       AS product,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                            INNER JOIN sales s
                                       ON s.prod_id = p.product_id
                   GROUP BY p.product_name, p.segment_name)

SELECT segment                                                                           AS "Segment",
       product                                                                           AS "Product",
       revenue                                                                           AS "Revenue",
       CONCAT(ROUND(revenue / SUM(revenue) OVER (PARTITION BY (segment)) * 100, 2), "%") AS "Revenue percentage"
FROM cte_table;

# What is the percentage split of revenue by segment for each category?
WITH cte_table AS (SELECT p.category_name      AS category,
                          p.segment_name       AS segment,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                            INNER JOIN sales s
                                       ON s.prod_id = p.product_id
                   GROUP BY p.segment_name, p.category_name)

SELECT category,
       segment,
       revenue,
       CONCAT(ROUND(revenue / SUM(revenue) OVER (PARTITION BY (category)) * 100, 2), "%") AS "Category's percentage"
FROM cte_table;

# What is the percentage split of total revenue by category?
WITH cte_table AS (SELECT p.category_name      AS category,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                   INNER JOIN sales s ON s.prod_id = p.product_id
                   GROUP BY p.category_name)

SELECT category                                                    AS "Category",
       revenue                                                     AS "Revenue",
       CONCAT(ROUND(revenue / SUM(revenue) OVER () * 100, 2), "%") AS "Category's percentage"
FROM cte_table;

# What is the total transaction “penetration” for each product?
#(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT p.product_name                                                                                          AS "Product",
       CONCAT(ROUND(COUNT(DISTINCT (s.txn_id)) / (SELECT(COUNT(DISTINCT (txn_id))) FROM sales) * 100, 2),
              "%")                                                                                             AS "Transaction penetration"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;
