# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #7 - Balanced Tree Clothing Co.

## Problem Statement

Danny, the CEO of this trendy fashion company, has asked help to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

***

## Case Study Questions

### High Level Sales Analysis

### 1. What was the total quantity sold for all products?

```sql
SELECT SUM(qty) AS "Total quantity"
FROM sales;
```

|Total quantity|
|-----|
|45216|

***

### 2. What is the total generated revenue for all products before discounts?

```sql
SELECT CONCAT('$', FORMAT(SUM(qty * price),2)) AS "Revenue before discounts"
FROM sales;
```

|Revenue before discounts|
|-----|
|$1,289,453.00|

***

### 3. What was the total discount amount for all products?

```sql
SELECT CONCAT('$', FORMAT(SUM(discount),2)) AS "Total discount amount"
FROM sales;
```

|Total discount amount|
|-----|
|$182,700.00|

***

### Transaction Analysis

### 1. How many unique transactions were there?

```sql
SELECT COUNT(DISTINCT txn_id) AS "Unique transactions"
FROM sales;
```
|Unique transactions|
|-----|
|2500|

***

### 2. What is the average unique products purchased in each transaction?

```sql
WITH cte_table AS (SELECT txn_id,
                          COUNT(DISTINCT prod_id) AS unique_products
                   FROM sales
                   GROUP BY txn_id)

SELECT ROUND(AVG(unique_products)) AS "Avg unique products"
FROM cte_table;
```

|Avg unique products|
|-----|
|6|

***

### 3. What is the average discount value per transaction?

```sql
WITH cte_table AS (SELECT txn_id,
                          SUM(price * qty * discount / 100) AS discount
                   FROM sales
                   GROUP BY txn_id)

SELECT CONCAT('$', FORMAT(AVG(discount), 2)) AS "Avg discount"
FROM cte_table;
```

|Avg discount|
|-----|
|$62.49|

***

### 4. What is the percentage split of all transactions for members vs non-members?

```sql
WITH cte_table AS (SELECT member        AS member,
                          COUNT(txn_id) AS transactions
                   FROM sales
                   GROUP BY member)

SELECT CASE WHEN (member = 0) = TRUE THEN "no" ELSE "yes" END                AS "Member",
       CONCAT(ROUND(transactions / SUM(transactions) OVER () * 100, 2), "%") AS "Transactions Percentage"
FROM cte_table;
```

|Member|Transactions Percentage|
|-----|-----|
|yes|60.03%|
|no|39.97%|

***

### Product Analysis

### 1. What are the top 3 products by total revenue before discount?

```sql
SELECT p.product_name                               AS "Product",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2)) AS "Revenue"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY SUM(s.price * s.qty) DESC
LIMIT 3;
```

|Product|Revenue|
|-----|-----|
|Blue Polo Shirt - Mens|$217,683.00|
|Grey Fashion Jacket - Womens|$209,304.00|
|White Tee Shirt - Mens|$152,000.00|

***

### 2. What is the total quantity, revenue and discount for each segment?

```sql
SELECT p.segment_name                                                  AS "Segment",
       SUM(s.qty)                                                      AS "Quantity",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2))                    AS "Revenue",
       CONCAT('$', FORMAT(SUM(s.price * s.qty * s.discount / 100), 2)) AS "Discount"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name
ORDER BY SUM(s.price * s.qty) DESC;
```

|Segment|Quantity|Revenue|Discount|
|-----|-----|-----|-----|
|Shirt|11265|$406,143.00|$49,594.27|
|Jacket|11385|$366,983.00|$44,277.46|
|Socks|11217|$307,977.00|$37,013.44|
|Jeans|11349|$208,350.00|$25,343.97|

***

### 3. What is the top selling product for each segment?

```sql
SELECT p.segment_name                                                           AS "Segment",
       p.product_name                                                           AS "Product",
       SUM(s.qty)                                                               AS "Quantity",
       ROW_NUMBER() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS "Position"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name, p.segment_name
ORDER BY 4
LIMIT 4;
```

|Segment|Product|Quantity|Position|
|-----|-----|-----|-----|
|Jacket|Grey Fashion Jacket - Womens|3876|1|
|Jeans|Navy Oversized Jeans - Womens|3856|1|
|Shirt|Blue Polo Shirt - Mens|3819|1|
|Socks|Navy Solid Socks - Mens|3792|1|

***

### 4. What is the total quantity, revenue and discount for each category?

```sql
SELECT p.category_name                                                 AS "Category",
       SUM(s.qty)                                                      AS "Quantity",
       CONCAT('$', FORMAT(SUM(s.price * s.qty), 2))                    AS "Revenue",
       CONCAT('$', FORMAT(SUM(s.price * s.qty * s.discount / 100), 2)) AS "Discount"
FROM sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name
ORDER BY SUM(s.price * s.qty) DESC;
```

|Category|Quantity|Revenue|Discount|
|-----|-----|-----|-----|
|Mens|22482|$714,120.00|$86,607.71|
|Womens|22734|$575,333.00|$69,621.43|

***

### 5. What is the top selling product for each category?

```sql
SELECT p.category_name                                                           AS "Category",
       p.product_name                                                            AS "Product",
       SUM(s.qty)                                                                AS "Quantity",
       ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS "Position"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name, p.category_name
ORDER BY 4
LIMIT 2;
```

|Category|Product|Quantity|Position|
|-----|-----|-----|-----|
|Mens|Blue Polo Shirt - Mens|3819|1|
|Womens|Grey Fashion Jacket - Womens|3876|1|

***

### 6. What is the percentage split of revenue by product for each segment?

```sql
WITH cte_table AS (SELECT p.segment_name       AS segment,
                          p.product_name       AS product,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                   INNER JOIN sales s ON s.prod_id = p.product_id
                   GROUP BY p.product_name, p.segment_name)

SELECT segment                                                                           AS "Segment",
       product                                                                           AS "Product",
       revenue                                                                           AS "Revenue",
       CONCAT(ROUND(revenue / SUM(revenue) OVER (PARTITION BY (segment)) * 100, 2), "%") AS "Revenue percentage"
FROM cte_table;
```

|Segment|Product|Revenue|Revenue percentage|
|-----|-----|-----|-----|
|Jacket|Indigo Rain Jacket - Womens|71383|19.45%|
|Jacket|Khaki Suit Jacket - Womens|86296|23.51%|
|Jacket|Grey Fashion Jacket - Womens|209304|57.03%|
|Jeans|Navy Oversized Jeans - Womens|50128|24.06%|
|Jeans|Cream Relaxed Jeans - Womens|37070|17.79%|
|Jeans|Black Straight Jeans - Womens|121152|58.15%|
|Shirt|White Tee Shirt - Mens|152000|37.43%|
|Shirt|Blue Polo Shirt - Mens|217683|53.60%|
|Shirt|Teal Button Up Shirt - Mens|36460|8.98%|
|Socks|White Striped Socks - Mens|62135|20.18%|
|Socks|Pink Fluro Polkadot Socks - Mens|109330|35.50%|
|Socks|Navy Solid Socks - Mens|136512|44.33%|

***

### 7. What is the percentage split of revenue by segment for each category?

```sql
WITH cte_table AS (SELECT p.category_name      AS category,
                          p.segment_name       AS segment,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                   INNER JOIN sales s ON s.prod_id = p.product_id
                   GROUP BY p.segment_name, p.category_name)
SELECT category,
       segment,
       revenue,
       CONCAT(ROUND(revenue / SUM(revenue) OVER (PARTITION BY (category)) * 100, 2), "%") AS "Category's percentage"
FROM cte_table;
```

|category|revenue|Category's percentage|
|-----|-----|-----|
|Mens|Shirt|56.87%|
|Mens|Socks|43.13%|
|Womens|Jeans|36.21%|
|Womens|Jacket|63.79%|

***

### 8. What is the percentage split of total revenue by category?

```sql
WITH cte_table AS (SELECT p.category_name      AS category,
                          SUM(s.qty * s.price) AS revenue
                   FROM product_details p
                   INNER JOIN sales s ON s.prod_id = p.product_id
                   GROUP BY p.category_name)
SELECT category                                                    AS "Category",
       revenue                                                     AS "Revenue",
       CONCAT(ROUND(revenue / SUM(revenue) OVER () * 100, 2), "%") AS "Category's percentage"
FROM cte_table;
```

|Category|Revenue|Category's percentage|
|-----|-----|-----|
|Womens|575333|44.62%|
|Mens|714120|55.38%|

***

### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

```sql
SELECT p.product_name AS "Product",
       CONCAT(ROUND(COUNT(DISTINCT (s.txn_id)) / (SELECT(COUNT(DISTINCT (txn_id))) FROM sales) * 100, 2),
              "%")    AS "Transaction penetration"
FROM product_details p
INNER JOIN sales s ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;
```

|Product|Transaction penetration|
|-----|-----|
|Navy Solid Socks - Mens|51.24%|
|Grey Fashion Jacket - Womens|51.00%|
|Navy Oversized Jeans - Womens|50.96%|
|Blue Polo Shirt - Mens|50.72%|
|White Tee Shirt - Mens|50.72%|
|Pink Fluro Polkadot Socks - Mens|50.32%|
|Indigo Rain Jacket - Womens|50.00%|
|Khaki Suit Jacket - Womens|49.88%|
|Black Straight Jeans - Womens|49.84%|
|Cream Relaxed Jeans - Womens|49.72%|
|White Striped Socks - Mens|49.72%|
|Teal Button Up Shirt - Mens|49.68%|

***
