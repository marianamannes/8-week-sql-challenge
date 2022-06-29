# Pizza Metrics
# How many pizzas were ordered?
SELECT COUNT(pizza_id) AS "Pizzas Ordered"
FROM customer_orders;

# How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS "Unique Customer Orders"
FROM customer_orders;

# How many successful orders were delivered by each runner?
SELECT runner_id AS "Runner ID", SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS "Successful orders"
FROM runner_orders
GROUP BY runner_id;

# How many of each type of pizza was delivered?
WITH cte_table AS(
SELECT c.pizza_id, c.order_id
FROM customer_orders c 
INNER JOIN runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL)
SELECT p.pizza_name AS "Pizza Name", COUNT(cte.order_id) AS "Delivered"
FROM cte_table cte
INNER JOIN pizza_names p
ON cte.pizza_id = p.pizza_id
GROUP BY p.pizza_name;

# How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id AS "Customer ID", 
		SUM(CASE WHEN p.pizza_name = "Meatlovers" THEN 1 ELSE 0 END) AS "Meatlovers",
        SUM(CASE WHEN p.pizza_name = "Vegetarian" THEN 1 ELSE 0 END) AS "Vegetarian"
FROM customer_orders c
INNER JOIN pizza_names p
ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

# What was the maximum number of pizzas delivered in a single order?
WITH cte_table AS(
SELECT c.order_id AS "order_id", c.pizza_id AS "pizza_id"
FROM customer_orders c 
INNER JOIN runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL)
SELECT cte.order_id "Order ID", COUNT(p.pizza_id) AS "Number of pizzas delivered"
FROM cte_table cte
INNER JOIN pizza_names p
ON cte.pizza_id = p.pizza_id
GROUP BY cte.order_id
ORDER BY COUNT(p.pizza_id) DESC
LIMIT 1;

# For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH cte_table AS(
SELECT c.order_id AS "order_id", c.customer_id AS "customer_id", c.exclusions AS "exclusions", c.extras AS "extras"
FROM customer_orders c 
INNER JOIN runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL)
SELECT cte.customer_id, 
		SUM(CASE WHEN ((cte.exclusions = "") AND (cte.extras = "")) THEN 1 ELSE 0 END) AS "No Changes",
		SUM(CASE WHEN ((cte.exclusions <> "") OR (cte.extras <> "")) THEN 1 ELSE 0 END) AS "At Least 1 Change"
FROM cte_table cte
GROUP BY cte.customer_id
ORDER BY cte.customer_id;

# How many pizzas were delivered that had both exclusions and extras?
WITH cte_table AS(
SELECT c.order_id AS "order_id", c.customer_id AS "customer_id", c.exclusions AS "exclusions", c.extras AS "extras"
FROM customer_orders c 
INNER JOIN runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL)
SELECT SUM(CASE WHEN ((exclusions <> "") AND (extras <> "")) THEN 1 ELSE 0 END) AS "Both Exclusions and extras"
FROM cte_table;

# What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time) AS "Order Time", COUNT(pizza_id) AS "Volume of pizzas"
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);

# What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS "Day of Week", COUNT(pizza_id) AS "Volume of pizzas"
FROM customer_orders
GROUP BY DAYNAME(order_time)
ORDER BY DAYOFWEEK(order_time);

