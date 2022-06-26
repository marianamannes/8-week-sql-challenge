# Pizza Metrics
# How many pizzas were ordered?
SELECT COUNT(pizza_id) AS "Pizzas Ordered"
FROM customer_orders;

# How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS "Unique Customer Orders"
FROM customer_orders;

# How many successful orders were delivered by each runner?
SELECT runner_id                                             AS "Runner ID",
       SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS "Successful orders"
FROM runner_orders
GROUP BY runner_id;

# How many of each type of pizza was delivered?
WITH cte_table AS (SELECT c.pizza_id,
                          c.order_id
                   FROM customer_orders c
                            INNER JOIN runner_orders r
                                       ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)
SELECT p.pizza_name        AS "Pizza Name",
       COUNT(cte.order_id) AS "Delivered"
FROM cte_table cte
         INNER JOIN pizza_names p
                    ON cte.pizza_id = p.pizza_id
GROUP BY p.pizza_name;

# How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id                                                AS "Customer ID",
       SUM(CASE WHEN p.pizza_name = "Meatlovers" THEN 1 ELSE 0 END) AS "Meatlovers",
       SUM(CASE WHEN p.pizza_name = "Vegetarian" THEN 1 ELSE 0 END) AS "Vegetarian"
FROM customer_orders c
         INNER JOIN pizza_names p
                    ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

# What was the maximum number of pizzas delivered in a single order?
WITH cte_table AS (SELECT c.order_id AS "order_id",
                          c.pizza_id AS "pizza_id"
                   FROM customer_orders c
                            INNER JOIN runner_orders r
                                       ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)
SELECT cte.order_id         "Order ID",
       COUNT(p.pizza_id) AS "Number of pizzas delivered"
FROM cte_table cte
         INNER JOIN pizza_names p
                    ON cte.pizza_id = p.pizza_id
GROUP BY cte.order_id
ORDER BY COUNT(p.pizza_id) DESC
LIMIT 1;

# For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH cte_table AS (SELECT c.order_id    AS "order_id",
                          c.customer_id AS "customer_id",
                          c.exclusions  AS "exclusions",
                          c.extras      AS "extras"
                   FROM customer_orders c
                            INNER JOIN runner_orders r
                                       ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)
SELECT cte.customer_id,
       SUM(CASE WHEN ((cte.exclusions = "") AND (cte.extras = "")) THEN 1 ELSE 0 END)  AS "No Changes",
       SUM(CASE WHEN ((cte.exclusions <> "") OR (cte.extras <> "")) THEN 1 ELSE 0 END) AS "At Least 1 Change"
FROM cte_table cte
GROUP BY cte.customer_id
ORDER BY cte.customer_id;

# How many pizzas were delivered that had both exclusions and extras?
WITH cte_table AS (SELECT c.order_id    AS "order_id",
                          c.customer_id AS "customer_id",
                          c.exclusions  AS "exclusions",
                          c.extras      AS "extras"
                   FROM customer_orders c
                            INNER JOIN runner_orders r
                                       ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)
SELECT SUM(CASE WHEN ((exclusions <> "") AND (extras <> "")) THEN 1 ELSE 0 END) AS "Both Exclusions and extras"
FROM cte_table;

# What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time) AS "Order Time",
       COUNT(pizza_id)  AS "Volume of pizzas"
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);

# What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS "Day of Week",
       COUNT(pizza_id)     AS "Volume of pizzas"
FROM customer_orders
GROUP BY DAYNAME(order_time)
ORDER BY DAYOFWEEK(order_time);

# Runner and Customer Experience
# How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT (WEEK(registration_date) - WEEK("2021-01-01")) + 1 AS "Week",
       COUNT(runner_id)                                   AS "Runners"
FROM runners
GROUP BY (WEEK(registration_date) - WEEK("2021-01-01")) + 1;

# What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT r.runner_id                                                       AS "Runner",
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)), 2) AS "Average minutes to arrive"
FROM runner_orders r
         LEFT JOIN customer_orders c
                   ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id;

# Is there any relationship between the number of pizzas and how long the order takes to
prepare ?
WITH cte_table AS (SELECT c.order_id                                              AS "order_id",
                          COUNT(c.pizza_id)                                       AS "pizzas",
                          AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)) AS "avgminutes"
                   FROM runner_orders r
                            LEFT JOIN customer_orders c
                                      ON r.order_id = c.order_id
                   WHERE r.pickup_time IS NOT NULL
                   GROUP BY c.order_id)
SELECT pizzas                    AS "Number of pizzas",
       ROUND(AVG(avgminutes), 2) AS "Average minutes to prepare"
FROM cte_table
GROUP BY pizzas;

# What was the average distance travelled for each customer?
WITH cte_table AS (SELECT c.customer_id AS "customer_id",
                          r.distance    AS "distance"
                   FROM customer_orders c
                            INNER JOIN runner_orders r
                                       ON c.order_id = r.order_id
                   WHERE distance IS NOT NULL)
SELECT customer_id             AS "Customer ID",
       ROUND(AVG(distance), 2) AS "Average Distance"
FROM cte_table
GROUP BY customer_id;

# What was the difference between the longest and shortest delivery times for all orders?
SELECT (MAX(duration) - MIN(duration)) AS "Delivery time difference"
FROM runner_orders
WHERE duration IS NOT NULL;

# What was the average speed for each runner for each delivery and
do you notice any trend for these values ?
SELECT r.runner_id                              AS "Runner",
       c.order_id                               AS "Order ID",
       ROUND(r.duration / 60, 2)                AS "Duration (h)",
       r.distance                               AS "Distance (Km)",
       ROUND(r.distance / (r.duration / 60), 2) AS "Average Speed (Km/h)"
FROM runner_orders r
         LEFT JOIN customer_orders c
                   ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id, c.order_id
ORDER BY r.runner_id, c.order_id;

# What is the successful delivery percentage for each runner?
SELECT runner_id   AS "Runner ID",
       CONCAT(ROUND((SUM(CASE WHEN cancellation IS NULL = TRUE THEN 1 ELSE 0 END)) / (COUNT(order_id)) * 100, 2),
              "%") AS "Successful delivery percentage"
FROM runner_orders
GROUP BY runner_id;


# Ingredient Optimisation
# What are the standard ingredients for each pizza?
SELECT n.pizza_name                                AS "Pizza Name",
       GROUP_CONCAT(t.topping_name SEPARATOR ", ") AS "Standard Ingredients"
FROM pizza_recipes_norm r
INNER JOIN pizza_names n ON r.pizza_id = n.pizza_id
INNER JOIN pizza_toppings t ON r.toppings = t.topping_id
GROUP BY n.pizza_name;

# What was the most commonly added extra?
SELECT t.topping_name     "Most commonly added extra",
       COUNT(e.extras) AS "Times Added"
FROM extras_norm e
INNER JOIN pizza_toppings t ON e.extras = t.topping_id
GROUP BY t.topping_name
ORDER BY COUNT(e.extras) DESC
LIMIT 1;

# What was the most common exclusion?
SELECT t.topping_name         "Most common exclusion",
       COUNT(e.exclusions) AS "Times Excluded"
FROM exclusions_norm e
INNER JOIN pizza_toppings t ON e.exclusions = t.topping_id
GROUP BY t.topping_name
ORDER BY COUNT(e.exclusions) DESC
LIMIT 1;
