# Digital Analysis
# How many users are there?
SELECT COUNT(DISTINCT (user_id)) AS "Users"
FROM users;

# How many cookies does each user have on average?
WITH cte_table AS (SELECT user_id,
                          COUNT(cookie_id) AS count_cookie
                   FROM users
                   GROUP BY user_id)

SELECT ROUND(AVG(count_cookie), 1) AS "Avg cookies"
FROM cte_table;

# What is the unique number of visits by all users per month?
SELECT MONTH(event_time)          AS "Month",
       COUNT(DISTINCT (visit_id)) AS "Visits"
FROM events
GROUP BY MONTH(event_time);

# What is the number of events for each event type?
SELECT ei.event_name       AS "Event name",
       COUNT(e.event_type) AS "Events"
FROM event_identifier ei
INNER JOIN events e ON e.event_type = ei.event_type
GROUP BY ei.event_name;

# What is the percentage of visits which have a purchase event?
WITH cte_table AS (SELECT DISTINCT(e.visit_id)                                             AS visits,
                                  CASE WHEN (ei.event_name = "Purchase") = TRUE THEN 1 END as purchases
                   FROM events e
                            INNER JOIN event_identifier ei
                                       ON e.event_type = ei.event_type)

SELECT CONCAT(ROUND((COUNT(purchases) / COUNT(DISTINCT (visits))) * 100, 2), "%") AS "Percentage"
FROM cte_table;

# What is the percentage of visits which view the checkout page but do not have a purchase event ?
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

# What are the top 3 pages by number of views?
SELECT p.page_name                  AS "Page",
       COUNT(DISTINCT (e.visit_id)) AS "Visits"
FROM page_hierarchy p
INNER JOIN events e ON p.page_id = e.page_id
GROUP BY p.page_name
ORDER BY COUNT(DISTINCT (e.visit_id)) DESC
LIMIT 3;

# What is the number of views and cart adds for each product category?
SELECT p.product_category                                               AS "Product Category",
       SUM(CASE WHEN (ei.event_name = "Page View") = TRUE THEN 1 END)   AS "Views",
       SUM(CASE WHEN (ei.event_name = "Add to Cart") = TRUE THEN 1 END) AS "Adds to cart"
FROM event_identifier ei
INNER JOIN events e ON ei.event_type = e.event_type
INNER JOIN page_hierarchy p ON p.page_id = e.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;

# Product Funnel Analysis
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
              LEFT JOIN cte_table2 cte2
                        ON cte1.visit_id = cte2.visit_id
     WHERE cte1.page_name IS NOT NULL
     GROUP BY cte1.page_name, cte1.product_category
     ORDER BY cte1.page_name);

CREATE TEMPORARY TABLE categories AS
    (SELECT product_category,
            SUM(views)     AS views,
            SUM(add_cart)  AS add_cart,
            SUM(abandoned) AS abandoned,
            SUM(purchases) AS purchases
     FROM products
     GROUP BY product_category);

# Which product had the most views, cart adds and purchases?
SELECT product      AS "Product",
       "Most views" AS "Rank"
FROM products
ORDER BY views DESC
LIMIT 1;

SELECT product          AS "Product",
       "Most cart adds" AS "Rank"
FROM products
ORDER BY add_cart DESC
LIMIT 1;

SELECT product          AS "Product",
       "Most purchases" AS "Rank"
FROM products
ORDER BY purchases DESC
LIMIT 1;

# Which product was most likely to be abandoned?
SELECT product          AS "Product",
       "Most abandoned" AS "Rank"
FROM products
ORDER BY abandoned DESC
LIMIT 1;

# Which product had the highest view to purchase percentage?
SELECT product                    AS "Product",
       "Highest view to purchase" AS "Rank"
FROM products
ORDER BY purchases / views DESC
LIMIT 1;

# What is the average conversion rate from view to cart add?
SELECT CONCAT(ROUND(SUM(add_cart) / SUM(views) * 100, 2), "%") AS "Avg conversion rate"
FROM products;

# What is the average conversion rate from cart add to purchase?
SELECT CONCAT(ROUND(SUM(purchases) / SUM(add_cart) * 100, 2), "%") AS "Avg conversion rate"
FROM products;
