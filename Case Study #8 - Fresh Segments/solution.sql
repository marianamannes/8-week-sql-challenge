# Data Exploration and Cleansing
# Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE interest_metrics MODIFY month_year VARCHAR (10);

UPDATE interest_metrics
SET month_year = CASE
                     WHEN (_month > 9) = TRUE THEN STR_TO_DATE((CONCAT(_year, "-", _month, "-01")), "%Y-%m-%d")
                     ELSE STR_TO_DATE((CONCAT(_year, "-0", _month, "-01")), "%Y-%m-%d") END;

# What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year AS "Date",
       COUNT(*)   AS "Records"
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;

# What do you think we should do with these null values in the fresh_segments.interest_metrics? 
DELETE FROM interest_metrics
WHERE interest_id IS NULL;

# How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT COUNT(DISTINCT(me.interest_id)) AS "Interests"
FROM interest_metrics me
LEFT JOIN interest_map ma ON me.interest_id = ma.id
WHERE ma.id IS NULL;

SELECT COUNT(DISTINCT(ma.id)) AS "Interests" 
FROM interest_metrics me
RIGHT JOIN interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id IS NULL;

# Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT COUNT(id) AS "IDs"
FROM interest_map;

# What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
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

# Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT COUNT(ma.id) AS "Records"
FROM interest_map ma
LEFT JOIN interest_metrics me ON ma.id = me.interest_id
WHERE month_year < created_at;

# Interest Analysis
#  Which interests have been present in all month_year dates in our dataset?
WITH cte_table AS (SELECT DISTINCT(ma.interest_name)              AS interest,
                                  COUNT(DISTINCT (me.month_year)) AS presence
                   FROM interest_map ma
                   LEFT JOIN interest_metrics me ON me.interest_id = ma.id
                   GROUP BY ma.interest_name)
SELECT interest,
       presence
FROM cte_table
WHERE presence = (SELECT COUNT(DISTINCT (month_year)) FROM interest_metrics);

# Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
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

# If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
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

