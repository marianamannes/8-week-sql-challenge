# What is the total amount each customer spent at the restaurant?
SELECT s.customer_id AS "Customer ID", CONCAT("$ ", SUM(m.price)) "Total Amount"
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id;

# How many days has each customer visited the restaurant?
SELECT customer_id AS "Customer ID", COUNT(DISTINCT order_date) AS "Number of visits"
FROM sales
GROUP BY customer_id;

# What was the first item from the menu purchased by each customer?
WITH cte_table AS(
SELECT s.customer_id AS CustomerID, 
		m.product_name AS Item, 
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS ItemNumber
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_ID
ORDER BY order_date)
SELECT CustomerID AS "CustomerID", Item as "Item Name", ItemNumber as "Item Number"
FROM cte_table
WHERE ItemNumber = 1;

# What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name AS "Product Name", COUNT(s.product_id) AS "Times Purchased"
FROM sales s 
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;

# Which item was the most popular for each customer?
WITH cte_table AS(
	SELECT s.customer_id as CustomerID, 
    m.product_name AS ProductName, 
    COUNT(s.product_ID) AS TimesPurchased,
    RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_ID) DESC) AS PopularityRank
	FROM sales s
	INNER JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name)
SELECT CustomerID AS "Customer ID", ProductName AS "Product Most Popular", TimesPurchased AS "Times Purchased", PopularityRank AS "Popularity Rank"
FROM cte_table
GROUP BY CustomerID, ProductName
HAVING PopularityRank = 1;

# Which item was purchased first by the customer after they became a member?
DROP TABLE IF EXISTS temp_membership;

CREATE TEMPORARY TABLE temp_membership AS
SELECT s.customer_id AS CustomerID, s.order_date AS OrderDate, s.product_id AS ProductID, mm.join_date AS JoinDate,
		CASE WHEN(s.order_date >= mm.join_date)=TRUE THEN "Member"
        ELSE "Not Member" END AS Membership
FROM sales s
LEFT JOIN members mm
ON s.customer_id = mm.customer_id;

WITH cte_table AS(
SELECT t.CustomerID AS CustomerID, m.product_name as ProductName, t.OrderDate AS OrderDate,
		RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate) AS OrderRank
FROM temp_membership t
INNER JOIN menu m
ON m.product_id = t.ProductID
WHERE Membership = "Member")
SELECT CustomerID AS "Customer ID", ProductName as "Product Name", OrderDate AS "Order Date", OrderRank AS "Order Rank"
FROM cte_table
WHERE OrderRank = 1;

# Which item was purchased just before the customer became a member?
WITH cte_table AS(
SELECT t.CustomerID AS CustomerID, m.product_name as ProductName, t.OrderDate AS OrderDate, t.JoinDate as JoinDate,
		RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate DESC) AS OrderRank
FROM temp_membership t
INNER JOIN menu m
ON m.product_id = t.ProductID
WHERE Membership = "Not Member" AND JoinDate IS NOT NULL)
SELECT CustomerID AS "Customer ID", ProductName as "Product Name", OrderDate AS "Order Date", OrderRank AS "Order Rank"
FROM cte_table
WHERE OrderRank = 1;

# What is the total items and amount spent for each member before they became a member?
WITH cte_table AS(
SELECT t.CustomerID AS CustomerID, m.price as AmountSpent, t.OrderDate AS OrderDate, t.JoinDate as JoinDate,
		RANK() OVER (PARTITION BY t.CustomerID ORDER BY t.OrderDate DESC) AS OrderRank
FROM temp_membership t
INNER JOIN menu m
ON m.product_id = t.ProductID
WHERE Membership = "Not Member" AND JoinDate IS NOT NULL)
SELECT CustomerID AS "Customer ID", CONCAT("$ ", SUM(AmountSpent)) as "Total Amount Spent"
FROM cte_table
GROUP BY CustomerID;

# If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT t.CustomerID AS "Customer ID", 
					SUM(CASE WHEN(m.product_name = "Sushi")=TRUE THEN m.price*10*2
                    ELSE m.price*10 END) AS "Points"
FROM temp_membership t
INNER JOIN menu m
ON t.ProductID = m.product_id
WHERE t.Membership = "Member"
GROUP BY t.CustomerID;
 
# In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT t.CustomerID AS "Customer ID", 
					SUM(CASE WHEN(m.product_name = "Sushi" OR t.OrderDate < DATE_ADD(t.JoinDate,INTERVAL 7 DAY))=TRUE THEN m.price*10*2
                    ELSE m.price*10 END) AS "Points"
FROM temp_membership t
INNER JOIN menu m
ON t.ProductID = m.product_id
WHERE t.Membership = "Member" and t.OrderDate <= "2021-01-31"
GROUP BY t.CustomerID;