# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #5 - Data Mart

## Problem Statement

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer. Danny needs help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

There is only one key dataset, which is represented by the table below.

<p align="center">
<img src="https://8weeksqlchallenge.com/images/case-study-5-erd.png" width=40% height=40%>

***

## Case Study Questions

### Data Cleansing Steps

```sql
TEMPORARY TABLE clean_weekly_sales AS
    (SELECT STR_TO_DATE(week_date, "%d/%m/%Y")        AS "week_date",
            WEEK(STR_TO_DATE(week_date, "%d/%m/%Y")
                )                                     AS "week_number",
            MONTH(STR_TO_DATE(week_date, "%d/%m/%Y")) AS "month_number",
            YEAR(STR_TO_DATE(week_date, "%d/%m/%Y"))  AS "calendar_year",
            region,
            platform,
            CASE
                WHEN (segment LIKE "%1%") = TRUE THEN "Young Adults"
                WHEN (segment LIKE "%2%") = TRUE THEN "Middle Aged"
                WHEN (segment LIKE "%3%" OR segment LIKE "%4%") = TRUE THEN "Retirees"
                ELSE "unknown" END                    AS "age_band",
            CASE
                WHEN (segment LIKE "%C%") = TRUE THEN "Couples"
                WHEN (segment LIKE "%F%") = TRUE THEN "Families"
                ELSE "unknown" END                    AS "demographic",
            customer_type,
            transactions,
            ROUND(sales / transactions, 2)            AS "avg_transaction",
            sales
     FROM weekly_sales);
```

***

### Data Exploration

### 1. What day of the week is used for each week_date value?

```sql
SELECT DISTINCT(DAYNAME(week_date)) AS "Day of the week"
FROM clean_weekly_sales;
```

|Day of the week|
|-----|
|Monday|

***

### 2. What range of week numbers are missing from the dataset?

```sql
WITH RECURSIVE cte_table(Number) AS (SELECT 1
                                     UNION ALL
                                     SELECT Number + 1
                                     FROM cte_table
                                     WHERE Number < 52)
SELECT DISTINCT(cte.Number)
FROM cte_table cte
LEFT OUTER JOIN clean_weekly_sales c ON cte.Number = c.week_number
WHERE c.week_number IS NULL;
```

|Number|
|-----|
|1|
|2|
|3|
|4|
|5|
|6|
|7|
|8|
|9|
|10|
|11|
|36|
|37|
|38|
|39|
|40|
|41|
|42|
|43|
|44|
|45|
|46|
|47|
|48|
|49|
|50|
|51|
|52|

***

### 3. How many total transactions were there for each year in the dataset?


```sql
SELECT calendar_year     AS "Year",
       SUM(transactions) AS "Transactions"
FROM clean_weekly_sales
GROUP BY calendar_year;
```

|Year|Transactions|
|-----|-----|
|2020|375813651|
|2019|365639285|
|2018|346406460|

***

### 4. What is the total sales for each region for each month?

```sql
SELECT region       AS "Region",
       month_number AS "Month",
       SUM(sales)   AS "Sales"
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```

|Region|Month|Sales|
|-----|-----|-----|
|AFRICA|3|567767480|
|AFRICA|4|1911783504|
|AFRICA|5|1647244738|
|AFRICA|6|1767559760|
|AFRICA|7|1960219710|
|AFRICA|8|1809596890|
|AFRICA|9|276320987|
|ASIA|3|529770793|
|ASIA|4|1804628707|
|ASIA|5|1526285399|
|ASIA|6|1619482889|
|ASIA|7|1768844756|
|ASIA|8|1663320609|
|ASIA|9|252836807|
|CANADA|3|144634329|
|CANADA|4|484552594|
|CANADA|5|412378365|
|CANADA|6|443846698|
|CANADA|7|477134947|
|CANADA|8|447073019|
|CANADA|9|69067959|
...

***

### 5. What is the total count of transactions for each platform

```sql
SELECT platform          AS "Platform",
       SUM(transactions) AS "Transactions"
FROM clean_weekly_sales
GROUP BY platform;
```

|Platform|Transactions|
|-----|-----|
|Retail|1081934227|
|Shopify|5925169|

***

### 6. What is the percentage of sales for Retail vs Shopify for each month?

```sql
WITH cte_table AS (SELECT month_number,
                          SUM(CASE WHEN (platform = "Retail") = TRUE THEN sales END)  AS retail,
                          SUM(CASE WHEN (platform = "Shopify") = TRUE THEN sales END) AS shopify,
                          SUM(sales)                                                  AS total_sales
                   FROM clean_weekly_sales
                   GROUP BY month_number)

SELECT month_number                                       AS "Month",
       CONCAT(ROUND(retail / total_sales * 100, 2), "%")  AS "Retail percentage",
       CONCAT(ROUND(shopify / total_sales * 100, 2), "%") AS "Shopify percentage"
FROM cte_table
GROUP BY month_number
ORDER BY month_number;
```

|Month|Retail percentage|Shopify percentage|
|-----|-----|-----|
|3|97.54%|2.46%|
|4|97.59%|2.41%|
|5|97.30%|2.70%|
|6|97.27%|2.73%|
|7|97.29%|2.71%|
|8|97.08%|2.92%|
|9|97.38%|2.62%|

***

### 7. What is the percentage of sales by demographic for each year in the dataset?

```sql
WITH cte_table AS (SELECT calendar_year,
                          SUM(CASE WHEN (demographic = "Couples") = TRUE THEN sales END)  AS couples,
                          SUM(CASE WHEN (demographic = "Families") = TRUE THEN sales END) AS families,
                          SUM(CASE WHEN (demographic = "unknown") = TRUE THEN sales END)  AS dg_unknown,
                          SUM(sales)                                                      AS total_sales
                   FROM clean_weekly_sales
                   GROUP BY calendar_year)

SELECT calendar_year                                         AS "Year",
       CONCAT(ROUND(couples / total_sales * 100, 2), "%")    AS "Couples percentage",
       CONCAT(ROUND(families / total_sales * 100, 2), "%")   AS "Families percentage",
       CONCAT(ROUND(dg_unknown / total_sales * 100, 2), "%") AS "Unknown percentage"
FROM cte_table
GROUP BY calendar_year
ORDER BY calendar_year;
```

|Year|Couples percentage|Families percentage|Unknown percentage|
|-----|-----|-----|-----|
|2018|26.38%|31.99%|41.63%|
|2019|27.28%|32.47%|40.25%|
|2020|28.72%|32.73%|38.55%|

***

### 8. Which age_band and demographic values contribute the most to Retail sales?

```sql
SELECT age_band    AS "Age Band",
       demographic AS "Demographic",
       SUM(sales)  as "Sales"
FROM clean_weekly_sales
WHERE platform = "Retail"
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC
LIMIT 1;
```

|Age Band|Demographic|Sales|
|-----|-----|-----|
|unknown|unknown|16067285533|

***

### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

```sql
SELECT calendar_year                            AS "Year",
       platform                                 AS "Platform",
       ROUND(SUM(sales) / SUM(transactions), 2) AS "Avg Transactions"
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
```

|Year|Platform|Avg Transactions|
|-----|-----|-----|
|2018|Retail|36.56|
|2018|Shopify|192.48|
|2019|Retail|36.83|
|2019|Shopify|183.36|
|2020|Retail|36.56|
|2020|Shopify|179.03|

***

### Before & After Analysis

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

```sql
WITH cte_table AS (SELECT week_number,
                          CASE WHEN (week_number >= 20 AND week_number < 24) = TRUE THEN SUM(sales) END AS sales_before,
                          CASE WHEN (week_number >= 24 AND week_number < 28) = TRUE THEN SUM(sales) END AS sales_after
                   FROM clean_weekly_sales
                   WHERE calendar_year = "2020"
                   GROUP BY week_number)

SELECT SUM(sales_before)                                                                       AS "Before",
       SUM(sales_after)                                                                        AS "After",
       SUM(sales_after) - SUM(sales_before)                                                    AS "Variance",
       CONCAT(ROUND((SUM(sales_after) - SUM(sales_before)) / SUM(sales_before) * 100, 2), "%") AS "Percentage"
FROM cte_table;
```

|Before|After|Variance|Percentage|
|-----|-----|-----|-----|
|2345878357|2318994169|-26884188|-1.15%|

***

### 2. What about the entire 12 weeks before and after?

```sql
WITH cte_table AS (SELECT week_number,
                          CASE WHEN (week_number >= 12 AND week_number < 24) = TRUE THEN SUM(sales) END AS sales_before,
                          CASE WHEN (week_number >= 24 AND week_number < 36) = TRUE THEN SUM(sales) END AS sales_after
                   FROM clean_weekly_sales
                   WHERE calendar_year = "2020"
                   GROUP BY week_number)

SELECT SUM(sales_before)                                                                       AS "Before",
       SUM(sales_after)                                                                        AS "After",
       SUM(sales_after) - SUM(sales_before)                                                    AS "Variance",
       CONCAT(ROUND((SUM(sales_after) - SUM(sales_before)) / SUM(sales_before) * 100, 2), "%") AS "Percentage"
FROM cte_table;
```

|Before|After|Variance|Percentage|
|-----|-----|-----|-----|
|7126273147|6973947753|-152325394|-2.14%|

***

### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

```sql
WITH cte_table AS (SELECT calendar_year,
                          week_number,
                          CASE WHEN (week_number >= 20 AND week_number < 24) = TRUE THEN SUM(sales) END AS sales_before,
                          CASE WHEN (week_number >= 24 AND week_number < 28) = TRUE THEN SUM(sales) END AS sales_after
                   FROM clean_weekly_sales
                   GROUP BY calendar_year, week_number)

SELECT calendar_year                                                                           AS "Year",
       SUM(sales_before)                                                                       AS "Before",
       SUM(sales_after)                                                                        AS "After",
       SUM(sales_after) - SUM(sales_before)                                                    AS "Variance",
       CONCAT(ROUND((SUM(sales_after) - SUM(sales_before)) / SUM(sales_before) * 100, 2), "%") AS "Percentage"
FROM cte_table
GROUP BY calendar_year;
```

|Year|Before|After|Variance|Percentage|
|-----|-----|-----|-----|-----|
|2020|2345878357|2318994169|-26884188|-1.15%|
|2019|2249989796|2252326390|2336594|0.10%|
|2018|2125140809|2129242914|4102105|0.19%|

```sql
WITH cte_table AS (SELECT calendar_year,
                          week_number,
                          CASE WHEN (week_number >= 12 AND week_number < 24) = TRUE THEN SUM(sales) END AS sales_before,
                          CASE WHEN (week_number >= 24 AND week_number < 36) = TRUE THEN SUM(sales) END AS sales_after
                   FROM clean_weekly_sales
                   GROUP BY calendar_year, week_number)

SELECT calendar_year,
       SUM(sales_before)                                                                       AS "Before",
       SUM(sales_after)                                                                        AS "After",
       SUM(sales_after) - SUM(sales_before)                                                    AS "Variance",
       CONCAT(ROUND((SUM(sales_after) - SUM(sales_before)) / SUM(sales_before) * 100, 2), "%") AS "Percentage"
FROM cte_table
GROUP BY calendar_year;
```

|Year|Before|After|Variance|Percentage|
|-----|-----|-----|-----|-----|
|2020|7126273147|6973947753|-152325394|-2.14%|
|2019|6883386397|6862646103|-20740294|-0.30%|
|2018|6396562317|6500818510|104256193|1.63%|

***
