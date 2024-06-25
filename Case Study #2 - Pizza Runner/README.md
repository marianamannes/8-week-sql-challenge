# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #2 - Pizza Runner

## Problem Statement
Danny has launched a pizza delivery app where customers can place orders and runners can deliver them. He needs help analyzing his business data.

There are six key datasets, which are represented by the relationshop diagram below.


<p align="center">
<img src="https://i.ibb.co/xM5LBS8/Capturar.png" width=60% height=60%>

***

## Database

Before starting with the case study questions, some changes in the database needed to de done.

There were some mixed null formats in table customer_orders and runner_orders, as can be seen below:

<p align="center">
<img src="https://i.ibb.co/rxrbYJr/Capturar.png" width=60% height=60%>

<p align="center">
<img src="https://i.ibb.co/MRKDyB2/Capturar.png" width=60% height=60%>

```sql
UPDATE customer_orders
SET exclusions = ""
WHERE exclusions = "null" OR exclusions IS NULL;

UPDATE customer_orders
SET extras = ""
WHERE extras = "null" OR extras IS NULL;

SELECT * from customer_orders;
```

|order_id|customer_id|pizza_id|exclusions|extras|order_time|
|-----|-----|-----|-----|-----|-----|
|1|101|1| | |2020-01-01 18:05:02|
|2|101|1| | |2020-01-01 19:00:52|
|3|102|1| | |2020-01-02 23:51:23|
|3|102|2| | |2020-01-02 23:51:23|
|4|103|1|4| |2020-01-04 13:23:46|
|4|103|1|4| |2020-01-04 13:23:46|
|4|103|2|4| |2020-01-04 13:23:46|
|5|104|1| |1|2020-01-08 21:00:29|
|6|101|2| | |2020-01-08 21:03:13|
|7|105|2| |1|2020-01-08 21:20:29|
|8|102|1| | |2020-01-09 23:54:33|
|9|103|1|4|1,5|2020-01-10 11:22:59|
|10|104|1| | |2020-01-11 18:34:49|
|10|104|1|2,6|1,4|2020-01-11 18:34:49|

```sql
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = "null" OR pickup_time = "";

UPDATE runner_orders
SET distance = NULL
WHERE distance = "null" OR distance = "";

UPDATE runner_orders
SET duration = NULL
WHERE duration = "null" OR duration = "";

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = "null" OR cancellation = "";

SELECT * FROM runner_orders;
```

|order_id|runner_id|pickup_time|distance|duration|cancellation|
|-----|-----|-----|-----|-----|-----|
|1|1|2020-01-01|18:15:34|20km|32 minutes|	|	
|2|1|2020-01-01|19:10:54|20km|27 minutes|	|	
|3|1|2020-01-03|00:12:37|13.4km|20 mins|	| 	
|4|2|2020-01-04|13:53:03|23.4|40|	|	
|5|3|2020-01-08|21:10:57|10|15|	|	
|6|3|	|	|	|Restaurant Cancellation|
|7|2|2020-01-08|21:30:45|25km|25mins|	|	
|8|2|2020-01-10|00:15:02|23.4 km |15 minutes|	| 	
|9|2|	|	|	|Customer Cancellation|
|10|1|2020-01-11 18:50:20|10km|10minutes|	|	


Also, some columns in table runner_orders were not padronizated.

```sql
UPDATE runner_orders
SET distance = REGEXP_REPLACE(distance, "[a-zA-Z]", "");

UPDATE runner_orders
SET duration = REGEXP_REPLACE(duration, "[a-zA-Z]", "");

SELECT * FROM runner_orders;
```

|order_id|runner_id|pickup_time|distance|duration|cancellation|
|-----|-----|-----|-----|-----|-----|
|1|1|2020-01-01|18:15:34|20|32|	|	
|2|1|2020-01-01|19:10:54|20|27|	|	
|3|1|2020-01-03|00:12:37|13.4|20|	| 	
|4|2|2020-01-04|13:53:03|23.4|40|	|	
|5|3|2020-01-08|21:10:57|10|15|	|	
|6|3|	|	|	|Restaurant Cancellation|
|7|2|2020-01-08|21:30:45|25|25|	|	
|8|2|2020-01-10|00:15:02|23.4|15|	| 	
|9|2|	|	|	|Customer Cancellation|
|10|1|2020-01-11 18:50:20|10|10|	|	

Finally, the tables pizza_recipes and customer_orders needed to be normalized. For that, I chose to build a script in Python connecting with the database to create new normalized tables for the columns unnormalized in customer_orders and for the table pizza_recipes.

```python
import mysql.connector as c
import pandas as pd

con = c.connect(host="localhost", 
                database="pizza_runner", 
                user="root", 
                password="")

# Creating new table exclusions_norm

exclusions = pd.read_sql("SELECT order_id, pizza_id, exclusions FROM customer_orders", con)

exclusions["exclusions"] = exclusions["exclusions"].replace(",","", regex=True)

for i in range(0, len(exclusions)):
    exclusions["exclusions"][i] = exclusions["exclusions"][i].split()
    
exclusions = exclusions.explode("exclusions").reset_index(drop=True)

cursor = con.cursor()

cursor.execute("CREATE TABLE exclusions_norm (order_id INTEGER, pizza_id INTEGER, exclusions INTEGER)")

for i in range(0, len(exclusions)):
    if pd.isna(exclusions["exclusions"][i]) is False:
        x = int(exclusions["order_id"][i])
        y = int(exclusions["pizza_id"][i])
        z = int(exclusions["exclusions"][i])
        cursor.execute("INSERT INTO exclusions_norm (order_id, pizza_id, exclusions) VALUES (%s, %s, %s)", (x, y, z))

# Creating new table extras_norm

extras = pd.read_sql("SELECT order_id, pizza_id, extras FROM customer_orders", con)

extras["extras"] = extras["extras"].replace(",","", regex=True)

for i in range(0, len(extras)):
    extras["extras"][i] = extras["extras"][i].split()
    
extras = extras.explode("extras").reset_index(drop=True)

cursor.execute("CREATE TABLE extras_norm (order_id INTEGER, pizza_id INTEGER, extras INTEGER)")

for i in range(0, len(extras)):
    if pd.isna(extras["extras"][i]) is False:
        x = int(extras["order_id"][i])
        y = int(extras["pizza_id"][i])
        z = int(extras["extras"][i])
        cursor.execute("INSERT INTO extras_norm (order_id, pizza_id, extras) VALUES (%s, %s, %s)", (x, y, z))
        
# Creating new table pizza_recipes_norm

pizza_recipes = pd.read_sql("SELECT pizza_id, toppings FROM pizza_recipes", con)

pizza_recipes["toppings"] = pizza_recipes["toppings"].replace(",","", regex=True)

for i in range(0, len(pizza_recipes)):
    pizza_recipes["toppings"][i] = pizza_recipes["toppings"][i].split()
    
pizza_recipes = pizza_recipes.explode("toppings").reset_index(drop=True)
              
cursor.execute("CREATE TABLE pizza_recipes_norm (pizza_id INTEGER, toppings INTEGER)")

for i in range(0, len(pizza_recipes)):
    if pd.isna(pizza_recipes["toppings"][i]) is False:
        x = int(pizza_recipes["pizza_id"][i])
        y = int(pizza_recipes["toppings"][i])
        cursor.execute("INSERT INTO pizza_recipes_norm (pizza_id, toppings) VALUES (%s, %s)", (x, y))
        
con.commit()

con.close()
```

New tables:

```sql
SELECT *
FROM exclusions_norm;
```

|order_id|pizza_id|exclusions|
|-----|-----|-----|
|4|1|4|
|4|1|4|
|4|2|4|
|9|1|4|
|10|1|2|
|10|1|6|

```sql
SELECT *
FROM extras_norm
```

|order_id|pizza_id|extras|
|-----|-----|-----|
|5|1|1|
|7|2|1|
|9|1|1|
|9|1|5|
|10|1|1|
|10|1|4|

```sql
SELECT *
FROM pizza_recipes_norm;
```

|pizza_id|toppings|
|-----|-----|
|1|1|
|1|2|
|1|3|
|1|4|
|1|5|
|1|6|
|1|8|
|1|10|
|2|4|
|2|6|
|2|7|
|2|9|
|2|11|
|2|12|

After cleaning and transformating the data, we can start with the case study questions.

***

## Case Study Questions

### Pizza Metrics
### 1. How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) AS "Pizzas Ordered"
FROM customer_orders;
```

|Pizzas Ordered|
|-----|
|14|

***

### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) AS "Unique Customer Orders"
FROM customer_orders;
```

|Unique Customer Orders|
|-----|
|10|

***

### 3. How many successful orders were delivered by each runner?

```sql
SELECT runner_id                                             AS "Runner ID",
       SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS "Successful orders"
FROM runner_orders
GROUP BY runner_id;
```

|Runner ID|Successful orders|
|-----|-----|
|1|4|
|2|3|
|3|1|

***

### 4. How many of each type of pizza was delivered?

```sql
WITH cte_table AS (SELECT c.pizza_id,
                          c.order_id
                   FROM customer_orders c
                   INNER JOIN runner_orders r ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)

SELECT p.pizza_name        AS "Pizza Name",
       COUNT(cte.order_id) AS "Delivered"
FROM cte_table cte
INNER JOIN pizza_names p ON cte.pizza_id = p.pizza_id
GROUP BY p.pizza_name;
```

|Pizza Name|Delivered|
|-----|-----|
|Meatlovers|9|
|Vegetarian|3|

***

### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT c.customer_id                                                AS "Customer ID",
       SUM(CASE WHEN p.pizza_name = "Meatlovers" THEN 1 ELSE 0 END) AS "Meatlovers",
       SUM(CASE WHEN p.pizza_name = "Vegetarian" THEN 1 ELSE 0 END) AS "Vegetarian"
FROM customer_orders c
INNER JOIN pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;
```

|Customer ID|Meatlovers|Vegetarian|
|-----|-----|-----|
|101|2|1|
|102|2|1|
|103|3|1|
|104|3|0|
|105|0|1|

***

### 6. What was the maximum number of pizzas delivered in a single order?

```sql
WITH cte_table AS (SELECT c.order_id AS "order_id",
                          c.pizza_id AS "pizza_id"
                   FROM customer_orders c
                   INNER JOIN runner_orders r ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)

SELECT cte.order_id         "Order ID",
       COUNT(p.pizza_id) AS "Number of pizzas delivered"
FROM cte_table cte
INNER JOIN pizza_names p ON cte.pizza_id = p.pizza_id
GROUP BY cte.order_id
ORDER BY COUNT(p.pizza_id) DESC
LIMIT 1;
```

|Order ID|Number of pizzas delivered|
|-----|-----|
|4|3|

***

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
WITH cte_table AS (SELECT c.order_id    AS "order_id",
                          c.customer_id AS "customer_id",
                          c.exclusions  AS "exclusions",
                          c.extras      AS "extras"
                   FROM customer_orders c
                   INNER JOIN runner_orders r ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)

SELECT cte.customer_id,
       SUM(CASE WHEN ((cte.exclusions = "") AND (cte.extras = "")) THEN 1 ELSE 0 END)  AS "No Changes",
       SUM(CASE WHEN ((cte.exclusions <> "") OR (cte.extras <> "")) THEN 1 ELSE 0 END) AS "At Least 1 Change"
FROM cte_table cte
GROUP BY cte.customer_id
ORDER BY cte.customer_id;
```

|customer_id|No Changes|At Least 1 Change|
|-----|-----|-----|
|101|2|0|
|102|3|0|
|103|0|3|
|104|1|2|
|105|0|1|


***

### 8. How many pizzas were delivered that had both exclusions and extras?

```sql
WITH cte_table AS (SELECT c.order_id    AS "order_id",
                          c.customer_id AS "customer_id",
                          c.exclusions  AS "exclusions",
                          c.extras      AS "extras"
                   FROM customer_orders c
                   INNER JOIN runner_orders r ON c.order_id = r.order_id
                   WHERE r.cancellation IS NULL)

SELECT SUM(CASE WHEN ((exclusions <> "") AND (extras <> "")) THEN 1 ELSE 0 END) AS "Both Exclusions and extras"
FROM cte_table;
```

|Both Exclusions and extras|
|-----|
|1|


***

### 9. What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT HOUR(order_time) AS "Order Time",
       COUNT(pizza_id)  AS "Volume of pizzas"
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);
```

|Order Time|Volume of pizzas|
|-----|-----|
|11|1|
|13|3|
|18|3|
|19|1|
|21|3|
|23|3|

***

### 10. What was the volume of orders for each day of the week?

```sql
SELECT DAYNAME(order_time) AS "Day of Week",
       COUNT(pizza_id)     AS "Volume of pizzas"
FROM customer_orders
GROUP BY DAYNAME(order_time)
ORDER BY DAYOFWEEK(order_time);
```

|Day of Week|Volume of pizzas|
|-----|-----|
|Wednesday|5|
|Thursday|3|
|Friday|1|
|Saturday|5|

***

### Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SELECT (WEEK(registration_date) - WEEK("2021-01-01")) + 1 AS "Week",
       COUNT(runner_id)                                   AS "Runners"
FROM runners
GROUP BY (WEEK(registration_date) - WEEK("2021-01-01")) + 1;
```

|Week|Runners|
|-----|-----|
|1|1|
|2|2|
|3|1|

***

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT r.runner_id                                                       AS "Runner",
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)), 2) AS "Average minutes to arrive"
FROM runner_orders r
LEFT JOIN customer_orders c ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id;
```

|Runner|Average minutes to arrive|
|-----|-----|
|1|15.33|
|2|23.40|
|3|10.00|

***

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
WITH cte_table AS (SELECT c.order_id                                              AS "order_id",
                          COUNT(c.pizza_id)                                       AS "pizzas",
                          AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)) AS "avgminutes"
                   FROM runner_orders r
                   LEFT JOIN customer_orders c ON r.order_id = c.order_id
                   WHERE r.pickup_time IS NOT NULL
                   GROUP BY c.order_id)

SELECT pizzas                    AS "Number of pizzas",
       ROUND(AVG(avgminutes), 2) AS "Average minutes to prepare"
FROM cte_table
GROUP BY pizzas;
```

|Number of pizzas|Average minutes to prepare|
|-----|-----|
|1|12.00|
|2|18.00|
|3|29.00|


***

### 4. What was the average distance travelled for each customer?

```sql
WITH cte_table AS (SELECT c.customer_id AS "customer_id",
                          r.distance    AS "distance"
                   FROM customer_orders c
                   INNER JOIN runner_orders r ON c.order_id = r.order_id
                   WHERE distance IS NOT NULL)


SELECT customer_id             AS "Customer ID",
       ROUND(AVG(distance), 2) AS "Average Distance"
FROM cte_table
GROUP BY customer_id;
```

|Customer ID|Average Distance|
|-----|-----|
|101|20|
|102|16.73|
|103|23.4|
|104|10|
|105|25|

***

### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT (MAX(duration) - MIN(duration)) AS "Delivery time difference"
FROM runner_orders
WHERE duration IS NOT NULL;
```

|Delivery time difference|
|-----|
|30|

***

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT r.runner_id                              AS "Runner",
       c.order_id                               AS "Order ID",
       ROUND(r.duration / 60, 2)                AS "Duration (h)",
       r.distance                               AS "Distance (Km)",
       ROUND(r.distance / (r.duration / 60), 2) AS "Average Speed (Km/h)"
FROM runner_orders r
LEFT JOIN customer_orders c ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id, c.order_id
ORDER BY r.runner_id, c.order_id;
```

| Runner|Order ID|Duration (h)|Distance (Km)|Average Speed (Km/h)|
|-----|-----|-----|-----|-----|
|1|1|0.53|20|37.5|
|1|2|0.45|20|44.44|
|1|3|0.33|13.4|40.2|
|1|10|0.17|10|60|
|2|4|0.67|23.4|35.1|
|2|7|0.42|25|60|
|2|8|0.25|23.4|93.6|
|3|5|0.25|10|40|

***

### 7. What is the successful delivery percentage for each runner?

```sql
SELECT runner_id   AS "Runner ID",
       CONCAT(ROUND((SUM(CASE WHEN cancellation IS NULL = TRUE THEN 1 ELSE 0 END)) / (COUNT(order_id)) * 100, 2),
              "%") AS "Successful delivery percentage"
FROM runner_orders
GROUP BY runner_id;
```

|Runner ID|Successful delivery percentage|
|-----|-----|
|1|100.00%|
|2|75.00%|
|3|50.00%|

***

### Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?

```sql
SELECT n.pizza_name                                AS "Pizza Name",
       GROUP_CONCAT(t.topping_name SEPARATOR ", ") AS "Standard Ingredients"
FROM pizza_recipes_norm r
INNER JOIN pizza_names n ON r.pizza_id = n.pizza_id
INNER JOIN pizza_toppings t ON r.toppings = t.topping_id
GROUP BY n.pizza_name;
```

|Pizza Name|Standard Ingredients|
|-----|-----|
|Meatlovers|Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
|Vegetarian|Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce|

***

### 2. What was the most commonly added extra?

```sql
SELECT t.topping_name     "Most commonly added extra",
       COUNT(e.extras) AS "Times Added"
FROM extras_norm e
INNER JOIN pizza_toppings t ON e.extras = t.topping_id
GROUP BY t.topping_name
ORDER BY COUNT(e.extras) DESC
LIMIT 1;
```

|Most commonly added extra|Times Added|
|-----|-----|
|Bacon|4|

***

### 3. What was the most common exclusion?

```sql
SELECT t.topping_name         "Most common exclusion",
       COUNT(e.exclusions) AS "Times Excluded"
FROM exclusions_norm e
INNER JOIN pizza_toppings t ON e.exclusions = t.topping_id
GROUP BY t.topping_name
ORDER BY COUNT(e.exclusions) DESC
LIMIT 1;
```

|Most common exclusion|Times Excluded|
|-----|-----|
|Cheese|4|

***
