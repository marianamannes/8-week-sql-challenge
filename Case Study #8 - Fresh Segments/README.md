# [8 Week SQL Challenge](https://github.com/marianamannes/8-week-sql-challenge) 

# Case Study #8 - Fresh Segments

## Problem Statement

Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base. Danny has asked assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

***

## Case Study Questions

### Data Exploration and Cleansing

### 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

```sql
ALTER TABLE interest_metrics MODIFY month_year VARCHAR (10);

UPDATE interest_metrics
SET month_year = CASE
                     WHEN (_month > 9) = TRUE THEN STR_TO_DATE((CONCAT(_year, "-", _month, "-01")), "%Y-%m-%d")
                     ELSE STR_TO_DATE((CONCAT(_year, "-0", _month, "-01")), "%Y-%m-%d") END;
```

|_month|_year|month_year|interest_id|composition|index_value|ranking|percentile_ranking|
|-----|-----|-----|-----|-----|-----|-----|-----|
|7|2018|2018-07-01|32486|11.89|6.19|1|99.86|
|7|2018|2018-07-01|6106|9.93|5.31|2|99.73|
|7|2018|2018-07-01|18923|10.85|5.29|3|99.59|
|7|2018|2018-07-01|6344|10.32|5.1|4|99.45|
|7|2018|2018-07-01|100|10.77|5.04|5|99.31|
|7|2018|2018-07-01|69|10.82|5.03|6|99.18|
|7|2018|2018-07-01|79|11.21|4.97|7|99.04|
...

***

### 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

```sql
SELECT month_year AS "Date",
       COUNT(*)   AS "Records"
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
```

|Date|Records|
|-----|-----|
|NULL|1194|
|2018-07-01|729|
|2018-08-01|767|
|2018-09-01|780|
|2018-10-01|857|
|2018-11-01|928|
|2018-12-01|995|
|2019-01-01|973|
|2019-02-01|1121|
|2019-03-01|1136|
|2019-04-01|1099|
|2019-05-01|857|
|2019-06-01|824|
|2019-07-01|864|
|2019-08-01|1149|

***

### 3. What do you think we should do with these null values in the fresh_segments.interest_metrics?

```sql
DELETE FROM interest_metrics
WHERE interest_id IS NULL;
```

***

### 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

```sql
SELECT COUNT(DISTINCT(me.interest_id)) AS "Interests"
FROM interest_metrics me
LEFT JOIN interest_map ma ON me.interest_id = ma.id
WHERE ma.id IS NULL;
```

|Interests|
|-----|
|0|

```sql
SELECT COUNT(DISTINCT(ma.id)) AS "Interests" 
FROM interest_metrics me
RIGHT JOIN interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id IS NULL;
```

|Interests|
|-----|
|7|

***

### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

```sql
SELECT COUNT(id) AS "IDs"
FROM interest_map;
```

|IDs|
|-----|
|1209|

***

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

```sql
SELECT ma.id,
       ma.interest_name,
       ma.interest_summary,
       ma.created_at,
       ma.last_modified,
       me._month,
       me._year,
       me.month_year,
       me.interest_id,
       me.composition,
       me.index_value,
       me.ranking,
       me.percentile_ranking
FROM interest_map ma
LEFT JOIN interest_metrics me ON ma.id = me.interest_id
WHERE ma.id = "21246";
```

|id|interest_name|interest_summary|created_at|last_modified|_month|_year|month_year|interest_id|composition|index_value|ranking|percentile_ranking|
|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|11|2018|2018-11-01|21246|2.25|0.78|908|2.16|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|10|2018|2018-10-01|21246|1.74|0.58|855|0.23|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|9|2018|2018-09-01|21246|2.06|0.61|774|0.77|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|8|2018|2018-08-01|21246|2.13|0.59|765|0.26|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|7|2018|2018-07-01|21246|2.26|0.65|722|0.96|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|4|2019|2019-04-01|21246|1.58|0.63|1092|0.64|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|3|2019|2019-03-01|21246|1.75|0.67|1123|1.14|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|2|2019|2019-02-01|21246|1.84|0.68|1109|1.07|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|1|2019|2019-01-01|21246|2.05|0.76|954|1.95|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|12|2018|2018-12-01|21246|1.97|0.7|983|1.21|
|21246|Readers of El Salvadoran Content|People reading news from El Salvadoran media sources.|2018-06-11 17:50:04|2018-06-11 17:50:04|	|	|21246|1.61|0.68|1191|0.25|

***

### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? 

```sql
SELECT COUNT(ma.id) AS "Records"
FROM interest_map ma
LEFT JOIN interest_metrics me ON ma.id = me.interest_id
WHERE month_year < created_at;
```

|Records|
|-----|
|188|

***

### Interest Analysis

### 1.  Which interests have been present in all month_year dates in our dataset?

```sql
WITH cte_table AS (SELECT DISTINCT(ma.interest_name)              AS interest,
                                  COUNT(DISTINCT (me.month_year)) AS presence
                   FROM interest_map ma
                   LEFT JOIN interest_metrics me ON me.interest_id = ma.id
                   GROUP BY ma.interest_name)
SELECT interest,
       presence
FROM cte_table
WHERE presence = (SELECT COUNT(DISTINCT (month_year)) FROM interest_metrics);
```

|interest|presence|
|-----|------|
|Accounting & CPA Continuing Education Researchers|14|
|Affordable Hotel Bookers|14|
|Aftermarket Accessories Shoppers|14|
|Alabama Trip Planners|14|
|Alaskan Cruise Planners|14|
...

***

### 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

```sql
WITH cte_table AS (SELECT DISTINCT(interest_id),
                                  COUNT(DISTINCT (month_year)) AS total_months
                   FROM interest_metrics
                   WHERE interest_id IS NOT NULL
                   GROUP BY interest_id)

SELECT total_months                                                 AS "Total Months",
       COUNT(DISTINCT (interest_id))                                AS "Qty of interests",
       ROUND(SUM(COUNT(DISTINCT (interest_id))) OVER (ORDER BY total_months DESC) /
             (SUM(COUNT(DISTINCT (interest_id))) OVER ()) * 100, 2) AS "Cumulative Percentage"
FROM cte_table
GROUP BY total_months;
```

|Total Months|Qty of interests|Cumulative Percentage|
|-----|-----|-----|
|14|480|39.93|
|13|82|46.76|
|12|65|52.16|
|11|94|59.98|
|10|86|67.14|
|9|95|75.04|
|8|67|80.62|
|7|90|88.10|
|6|33|90.85|
|5|38|94.01|
|4|32|96.67|
|3|15|97.92|
|2|12|98.92|
|1|13|100.00|

***

### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

```sql
WITH cte_table AS (SELECT DISTINCT(interest_id),
                                  COUNT(DISTINCT (month_year)) AS total_months
                   FROM interest_metrics
                   WHERE interest_id IS NOT NULL
                   GROUP BY interest_id),
    
     cte_table2 AS (SELECT total_months,
                           COUNT(DISTINCT (interest_id))                                AS qty,
                           ROUND(SUM(COUNT(DISTINCT (interest_id))) OVER (ORDER BY total_months DESC) /
                                 (SUM(COUNT(DISTINCT (interest_id))) OVER ()) * 100, 2) AS cumulative
                    FROM cte_table
                    GROUP BY total_months)

SELECT SUM(qty) as "Quantity"
FROM cte_table2
WHERE cumulative > 90;
```

|Quantity|
|-----|
|143|

***
