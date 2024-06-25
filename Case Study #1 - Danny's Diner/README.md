# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #1 - Danny's Diner

## Problem Statement
In the beggining of 2021, Danny opened up a restaurant and now wants to answer some questions about the preferences of the costumers, including the pattern of visitis, their purchases and favorite menu items. 

There are three key datasets, which are represented by the relationshop diagram below.


<p align="center">
<img src="https://i.ibb.co/Qf8gHWm/Captura-de-tela-2022-06-25-204656.png" width=60% height=60%>

***

## Case Study Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT s.customer_id              AS "Customer ID",
       CONCAT("$ ", SUM(m.price)) AS "Total Amount"
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id;
```

|Customer ID|Total Amount|
|-----|-----|
|A|$ 76|
|B|$ 74|
|C|$ 36|

***

### 2. How many days has each customer visited the restaurant?

```sql
SELECT customer_id                AS "Customer ID",
       COUNT(DISTINCT order_date) AS "Number of visits"
FROM sales
GROUP BY customer_id;
```

|Customer ID|Number of visits|
|-----|-----|
|A|4|
|B|6|
|C|2|

***

### 3. What was the first item from the menu purchased by each customer?

```sql
WITH cte_table AS (SELECT s.customer_id                                                      AS CustomerID,
                          m.product_name                                                     AS Item,
                          ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS ItemNumber
                   FROM sales s
                   INNER JOIN menu m ON s.product_id = m.product_ID
                   ORDER BY order_date)

SELECT CustomerID AS "CustomerID",
       Item       AS "Item Name",
       ItemNumber AS "Item Number"
FROM cte_table
WHERE ItemNumber = 1;
```

|CustomerID|Item Name|Item Number|
|-----|-----|-----|
|A|sushi|1|
|B|curry|1|
|C|ramen|1|

***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT m.product_name      AS "Product Name",
       COUNT(s.product_id) AS "Times Purchased"
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;
```

|Product Name|Times Purchased|
|-----|-----|
|ramen|8|

***

### 5. Which item was the most popular for each customer?

```sql
WITH cte_table AS (SELECT s.customer_id                                                              AS CustomerID,
                          m.product_name                                                             AS ProductName,
                          COUNT(s.product_ID)                                                        AS TimesPurchased,
                          RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_ID) DESC) AS PopularityRank
                   FROM sales s
		   INNER JOIN menu m ON s.product_id = m.product_id
                   GROUP BY s.customer_id, m.product_name)

SELECT CustomerID     AS "Customer ID",
       ProductName    AS "Product Most Popular",
       TimesPurchased AS "Times Purchased",
       PopularityRank AS "Popularity Rank"
FROM cte_table
GROUP BY CustomerID, ProductName
HAVING PopularityRank = 1;
```
|Customer ID|Product Most Popular|Times Purchased|Popularity Rank|
|-----|-----|-----|-----|
|A|ramen|3|1|
|B|curry|2|1|
|B|sushi|2|1|
|B|ramen|2|1|
|C|ramen|3|1|

***

### 6. Which item was purchased first by the customer after they became a member?

```sql
DROP TABLE IF EXISTS temp_membership;

CREATE TEMPORARY TABLE temp_membership AS
SELECT s.customer_id             AS CustomerID,
       s.order_date              AS OrderDate,
       s.product_id              AS ProductID,
       mm.join_date              AS JoinDate,
       CASE
           WHEN (s.order_date >= mm.join_date) = TRUE THEN "Member"
           ELSE "Not Member" END AS Membership
FROM sales s
LEFT JOIN members mm ON s.customer_id = mm.customer_id;

WITH cte_table AS (SELECT t.CustomerID                                                 AS CustomerID,
                          m.product_name                                               AS ProductName,
                          t.OrderDate                                                  AS OrderDate,
                          RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate) AS OrderRank
                   FROM temp_membership t
                   INNER JOIN menu m ON m.product_id = t.ProductID
                   WHERE Membership = "Member")

SELECT CustomerID  AS "Customer ID",
       ProductName AS "Product Name",
       OrderDate   AS "Order Date",
       OrderRank   AS "Order Rank"
FROM cte_table
WHERE OrderRank = 1;
```

|Customer ID|Product Name|Order Date|Order Rank|
|-----|-----|-----|-----|
|A|curry|2021-01-07|1|
|B|sushi|2021-01-11|1|

***

### 7. Which item was purchased just before the customer became a member?

```sql
WITH cte_table AS (SELECT t.CustomerID                                                      AS CustomerID,
                          m.product_name                                                    AS ProductName,
                          t.OrderDate                                                       AS OrderDate,
                          t.JoinDate                                                        AS JoinDate,
                          RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate DESC) AS OrderRank
                   FROM temp_membership t 
                   INNER JOIN menu m ON m.product_id = t.ProductID
                   WHERE Membership = "Not Member"
                     AND JoinDate IS NOT NULL)

SELECT CustomerID  AS "Customer ID",
       ProductName AS "Product Name",
       OrderDate   AS "Order Date",
       OrderRank   AS "Order Rank"
FROM cte_table
WHERE OrderRank = 1;
```

|Customer ID|Product Name|Order Date|Order Rank|
|-----|-----|-----|-----|
|A|sushi|2021-01-01|1|
|A|curry|2021-01-01|1|
|B|sushi|2021-01-04|1|

***

### 8. What is the total items and amount spent for each member before they became a member?

```sql
WITH cte_table AS (SELECT t.CustomerID                                                      AS CustomerID,
                          m.price                                                           AS AmountSpent,
                          t.OrderDate                                                       AS OrderDate,
                          t.JoinDate                                                        AS JoinDate,
                          RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate DESC) AS OrderRank
                   FROM temp_membership t
		   INNER JOIN menu m ON m.product_id = t.ProductID
                   WHERE Membership = "Not Member"
                     AND JoinDate IS NOT NULL)

SELECT CustomerID                     AS "Customer ID",
       CONCAT("$ ", SUM(AmountSpent)) AS "Total Amount Spent"
FROM cte_table
GROUP BY CustomerID;
```

|Customer ID|Total Amount Spent|
|-----|-----|
|A|$ 25|
|B|$ 40|

***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

In this question, it was not specified if the points were valid for members only or not. So, in this case, I considered the points valid only after the customer was already a member.

```sql
SELECT t.CustomerID                   AS "Customer ID",
       SUM(CASE
               WHEN (m.product_name = "Sushi") = TRUE THEN m.price * 10 * 2
               ELSE m.price * 10 END) AS "Points"
FROM temp_membership t
INNER JOIN menu m ON t.ProductID = m.product_id
WHERE t.Membership = "Member"
GROUP BY t.CustomerID;
```

|Customer ID|Points|
|-----|-----|
|B|440|
|A|510|

***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
SELECT t.CustomerID                   AS "Customer ID",
       SUM(CASE
               WHEN (m.product_name = "Sushi" OR t.OrderDate < DATE_ADD(t.JoinDate, INTERVAL 7 DAY)) = TRUE
                   THEN m.price * 10 * 2
               ELSE m.price * 10 END) AS "Points"
FROM temp_membership t
INNER JOIN menu m ON t.ProductID = m.product_id
WHERE t.Membership = "Member"
  and t.OrderDate <= "2021-01-31"
GROUP BY t.CustomerID;
```

|Customer ID|Points|
|-----|-----|
|B|320|
|A|1020|

***
