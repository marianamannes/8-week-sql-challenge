# Fixing NULL, NAN and "" values in customer_orders

UPDATE customer_orders
SET exclusions = ""
WHERE exclusions = "null" OR exclusions IS NULL;

UPDATE customer_orders
SET extras = ""
WHERE extras = "null" OR extras IS NULL;

SELECT * from customer_orders;

# Fixing NULL, NAN and "" values in runner_orders

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

# Fixing measurement units padronization in runner_orders

UPDATE runner_orders
SET distance = REGEXP_REPLACE(distance, "[a-zA-Z]", "");

UPDATE runner_orders
SET duration = REGEXP_REPLACE(duration, "[a-zA-Z]", "");

SELECT * FROM runner_orders;