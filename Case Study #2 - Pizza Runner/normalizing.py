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

