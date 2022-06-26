# Data Cleansing Steps
CREATE TEMPORARY TABLE clean_weekly_sales AS
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

# Data Exploration
# What day of the week is used for each week_date value?
SELECT DISTINCT(DAYNAME(week_date)) AS "Day of the week"
FROM clean_weekly_sales;

# What range of week numbers are missing from the dataset?
WITH RECURSIVE cte_table(Number) AS (SELECT 1
                                     UNION ALL
                                     SELECT Number + 1
                                     FROM cte_table
                                     WHERE Number < 52)

SELECT DISTINCT(cte.Number)
FROM cte_table cte
LEFT OUTER JOIN clean_weekly_sales c ON cte.Number = c.week_number
WHERE c.week_number IS NULL;

# How many total transactions were there for each year in the dataset?
SELECT calendar_year     AS "Year",
       SUM(transactions) AS "Transactions"
FROM clean_weekly_sales
GROUP BY calendar_year;

# What is the total sales for each region for each month?
SELECT region       AS "Region",
       month_number AS "Month",
       SUM(sales)   AS "Sales"
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

# What is the total count of transactions for each platform
SELECT platform          AS "Platform",
       SUM(transactions) AS "Transactions"
FROM clean_weekly_sales
GROUP BY platform;

# What is the percentage of sales for Retail vs Shopify for each month?
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

# What is the percentage of sales by demographic for each year in the dataset?
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

# Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band    AS "Age Band",
       demographic AS "Demographic",
       SUM(sales)  as "Sales"
FROM clean_weekly_sales
WHERE platform = "Retail"
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC
LIMIT 1;

# Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT calendar_year                            AS "Year",
       platform                                 AS "Platform",
       ROUND(SUM(sales) / SUM(transactions), 2) AS "Avg Transactions"
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

# Before & After Analysis
# What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
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

# What about the entire 12 weeks before and after?
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

# How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
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
