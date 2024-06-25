# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #6 - Clique Bait

## Problem Statement

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry. In this case study it was required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

There are five key datasets, which are represented by the relationshop diagram below.

<p align="center">
<img src="https://user-images.githubusercontent.com/81607668/134619326-f560a7b0-23b2-42ba-964b-95b3c8d55c76.png" width=60% height=60%>

***

## Case Study Questions

### Digital Analysis

### 1. How many users are there?

```sql
SELECT COUNT(DISTINCT(user_id)) AS "Users"
FROM users;
```

|Users|
|-----|
|500|

***

### 2. How many cookies does each user have on average?

```sql
WITH cte_table AS (SELECT user_id,
                          COUNT(cookie_id) AS count_cookie
                   FROM users
                   GROUP BY user_id)

SELECT ROUND(AVG(count_cookie), 1) AS "Avg cookies"
FROM cte_table;
```

|Avg cookies|
|-----|
|3.6|

***

### 3. What is the unique number of visits by all users per month?

```sql
SELECT MONTH(event_time)          AS "Month",
       COUNT(DISTINCT (visit_id)) AS "Visits"
FROM events
GROUP BY MONTH(event_time);
```

|Month|Visits|
|-----|-----|
|1|876|
|2|1488|
|3|916|
|4|248|
|5|36|

***

### 4. What is the number of events for each event type?

```sql
SELECT ei.event_name       AS "Event name",
       COUNT(e.event_type) AS "Events"
FROM event_identifier ei
INNER JOIN events e ON e.event_type = ei.event_type
GROUP BY ei.event_name;
```
|Event name|Events|
|-----|-----|
|Page View|20928|
|Add to Cart|8451|
|Purchase|1777|
|Ad Impression|876|
|Ad Click|702|

***

### 5. What is the percentage of visits which have a purchase event?

```sql
WITH cte_table AS (SELECT DISTINCT(e.visit_id)                                             AS visits,
                                  CASE WHEN (ei.event_name = "Purchase") = TRUE THEN 1 END as purchases
                   FROM events e
                            INNER JOIN event_identifier ei
                                       ON e.event_type = ei.event_type)

SELECT CONCAT(ROUND((COUNT(purchases) / COUNT(DISTINCT (visits))) * 100, 2), "%") AS "Percentage"
FROM cte_table;
```

|Percentage|
|-----|
|49.86%|

***

### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
WITH cte_table AS (SELECT e.visit_id                                                                                  AS visits,
                          SUM(CASE
                                  WHEN (ei.event_name = "Page View" AND p.page_name = "Checkout") = TRUE
                                      THEN 1 END)                                                                     AS checkout,
                          SUM(CASE WHEN (ei.event_name = "Purchase") = TRUE THEN 1 END)                               AS purchases
                   FROM events e
                   INNER JOIN event_identifier ei ON e.event_type = ei.event_type
                   INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                   GROUP BY e.visit_id)

SELECT CONCAT(ROUND((SUM(CASE WHEN (checkout >= 1 AND purchases IS NULL) = TRUE THEN 1 END) /
                     COUNT(DISTINCT (visits))) * 100, 2), "%")                         AS "Percentage (All pages)",
       CONCAT(ROUND((SUM(CASE WHEN (checkout >= 1 AND purchases IS NULL) = TRUE THEN 1 END) /
                     SUM(CASE WHEN (checkout >= 1) = TRUE THEN 1 END)) * 100, 2), "%") AS "Percentage (Checkout)"
FROM cte_table;
```

|Percentage (All pages)|Percentage (Checkout)|
|-----|-----|
|9.15%|15.50%|

***

### 7. What are the top 3 pages by number of views?

```sql
SELECT p.page_name                  AS "Page",
       COUNT(DISTINCT (e.visit_id)) AS "Visits"
FROM page_hierarchy p
INNER JOIN events e ON p.page_id = e.page_id
GROUP BY p.page_name
ORDER BY COUNT(DISTINCT (e.visit_id)) DESC
LIMIT 3;
```

|Page|Visits|
|-----|-----|
|All Products|3174|
|Checkout|2103|
|Home Page|1782|

***

### 8. What is the number of views and cart adds for each product category?

```sql
SELECT p.product_category                                               AS "Product Category",
       SUM(CASE WHEN (ei.event_name = "Page View") = TRUE THEN 1 END)   AS "Views",
       SUM(CASE WHEN (ei.event_name = "Add to Cart") = TRUE THEN 1 END) AS "Adds to cart"
FROM event_identifier ei
INNER JOIN events e ON ei.event_type = e.event_type
INNER JOIN page_hierarchy p ON p.page_id = e.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;
```

|Product Category|Views|Adds to cart|
|-----|-----|-----|
|Luxury|3032|1870|
|Shellfish|6204|3792|
|Fish|4633|2789|

***

### Product Funnel Analysis

```sql
CREATE TEMPORARY TABLE products AS
    (WITH cte_table1 AS (SELECT e.visit_id                                                       AS visit_id,
                                p.page_name                                                      AS page_name,
                                p.product_category                                               AS product_category,
                                SUM(CASE WHEN (ei.event_name = "Page View") = TRUE THEN 1 END)   AS views,
                                SUM(CASE WHEN (ei.event_name = "Add to Cart") = TRUE THEN 1 END) AS add_cart
                         FROM events e
                         INNER JOIN event_identifier ei ON e.event_type = ei.event_type
                         INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         WHERE product_id IS NOT NULL
                         GROUP BY p.page_name, p.product_category, e.visit_id),

          cte_table2 AS (SELECT DISTINCT (e.visit_id)                                                  AS visit_id,
                                         SUM(CASE WHEN (ei.event_name = "Purchase") = TRUE THEN 1 END) AS purchases
                         FROM events e
                         INNER JOIN event_identifier ei ON e.event_type = ei.event_type
                         INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         WHERE ei.event_name = "Purchase"
                         GROUP BY e.visit_id)

     SELECT cte1.page_name                                                                         AS product,
            cte1.product_category                                                                  AS product_category,
            SUM(cte1.views)                                                                        AS views,
            SUM(cte1.add_cart)                                                                     AS add_cart,
            SUM(CASE WHEN (cte1.add_cart = 1 AND cte2.purchases IS NULL) = TRUE THEN 1 ELSE 0 END) AS abandoned,
            SUM(CASE WHEN (cte1.add_cart = 1 AND cte2.purchases = 1) = TRUE THEN 1 ELSE 0 END)     AS purchases
     FROM cte_table1 cte1
              LEFT JOIN cte_table2 cte2 ON cte1.visit_id = cte2.visit_id
     WHERE cte1.page_name IS NOT NULL
     GROUP BY cte1.page_name, cte1.product_category
     ORDER BY cte1.page_name);
```

|product|product_category|views|add_cart|abandoned|purchases|
|-----|-----|-----|-----|-----|-----|
|Abalone|Shellfish|1525|932|233|699|
|Black Truffle|Luxury|1469|924|217|707|
|Crab|Shellfish|1564|949|230|719|
|Kingfish|Fish|1559|920|213|707|
|Lobster|Shellfish|1547|968|214|754|
|Oyster|Shellfish|1568|943|217|726|
|Russian Caviar|Luxury|1563|946|249|697|
|Salmon|Fish|1559|938|227|711|
|Tuna|Fish|1515|931|234|697|

```sql
CREATE TEMPORARY TABLE categories AS (SELECT product_category,
                                             SUM(views)     AS views,
                                             SUM(add_cart)  AS add_cart,
                                             SUM(abandoned) AS abandoned,
                                             SUM(purchases) AS purchases
                                      FROM products
                                      GROUP BY product_category);
```

|product_category|views|add_cart|abandoned|purchases|
|-----|-----|-----|-----|-----|
|Shellfish|6204|3792|894|2898|
|Luxury|3032|1870|466|1404|
|Fish|4633|2789|674|2115|

***

### 1. Which product had the most views, cart adds and purchases?

```sql
SELECT product      AS "Product",
       "Most views" AS "Rank"
FROM products
ORDER BY views DESC
LIMIT 1;
```

|Product|Rank|
|-----|-----|
|Oyster|Most views|

```sql
SELECT product          AS "Product",
       "Most cart adds" AS "Rank"
FROM products
ORDER BY add_cart DESC
LIMIT 1;
```

|Product|Rank|
|-----|-----|
|Lobster|Most cart adds|

```sql
SELECT product          AS "Product",
       "Most purchases" AS "Rank"
FROM products
ORDER BY purchases DESC
LIMIT 1;
```

|Product|Rank|
|-----|-----|
|Lobster|Most purchases|

***

### 2. Which product was most likely to be abandoned?

```sql
SELECT product          AS "Product",
       "Most abandoned" AS "Rank"
FROM products
ORDER BY abandoned DESC
LIMIT 1;
```

|Product|Rank|
|-----|-----|
|Russian Caviar|Most abandoned|

***

### 3. Which product had the highest view to purchase percentage?

```sql
SELECT product                    AS "Product",
       "Highest view to purchase" AS "Rank"
FROM products
ORDER BY purchases / views DESC
LIMIT 1;
```

|Product|Rank|
|-----|-----|
|Lobster|Highest view to purchase|

***

### 4. What is the average conversion rate from view to cart add?

```sql
SELECT CONCAT(ROUND(SUM(add_cart)/SUM(views)*100,2), "%") AS "Avg conversion rate"
FROM products;
```
|Avg conversion rate|
|-----|
|60.93%|

***

### 5. What is the average conversion rate from cart add to purchase?

```sql
SELECT CONCAT(ROUND(SUM(purchases)/SUM(add_cart)*100,2), "%") AS "Avg conversion rate"
FROM products;
```
|Avg conversion rate|
|-----|
|75.93%|

***
