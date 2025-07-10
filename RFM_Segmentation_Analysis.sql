CREATE DATABASE RFM_Segmentation;

use RFM_Segmentation;

SELECT 
    *
FROM
    sales;

alter table sales add column formated_order_date date;

UPDATE sales 
SET 
    formated_order_date = DATE_ADD('1899-12-30',
        INTERVAL `Order date` DAY);
        
select * from (
SELECT 
    `Customer ID`, 
    count(*) over (partition by `Customer ID`) as order_count
FROM
    sales) as t;

alter table sales
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;


-- perform EDA

describe sales;

select count(*) as total_records from sales;

    
select count(*) as total_records,
	sum(case when formated_order_date is null then 1 else 0 end) as missing_order_date,
    sum(case when sales is null then 1 else 0 end) as missing_salels,
    sum(case when `Customer ID` is null then 1 else 0 end) as missing_customer_id
 from sales;


-- check duplicate rocords
-- this query is slower takes about 23 seconds to run
SELECT 
    *
FROM
    sales s1
WHERE
    EXISTS( SELECT 
            1
        FROM
            sales s2
        WHERE
            s1.`Customer ID` = s2.`Customer ID`
                AND s1.`Product Name` = s2.`Product Name`
                AND S1.`ORDER ID` = S2.`ORDER ID`
        GROUP BY s2.`Customer ID`
        HAVING COUNT(*) > 1);


-- check duplicate rocords using join method
-- this query is faster takes about 0.048 seconds to run

SELECT s1.*
FROM sales s1
JOIN (
    SELECT `Customer ID`, `Product Name`, `ORDER ID`
    FROM sales
    GROUP BY `Customer ID`, `Product Name`, `ORDER ID`
    HAVING COUNT(*) > 1
) dup
ON s1.`Customer ID` = dup.`Customer ID`
   AND s1.`Product Name` = dup.`Product Name`
   AND s1.`ORDER ID` = dup.`ORDER ID`;


-- check duplicate rocords using cte method
-- this query is fast enough takes about 0.053 seconds to run

WITH duplicate_orders AS (
    SELECT `Customer ID`, `Product Name`, `ORDER ID`
    FROM sales
    GROUP BY `Customer ID`, `Product Name`, `ORDER ID`
    HAVING COUNT(*) > 1
)

SELECT s.*
FROM sales s
JOIN duplicate_orders d
ON s.`Customer ID` = d.`Customer ID`
   AND s.`Product Name` = d.`Product Name`
   AND s.`ORDER ID` = d.`ORDER ID`;


select count(distinct `Customer ID`) as unique_customer from sales;

SELECT 
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales)) AS Avg_Sales,
    ROUND(SUM(Sales)) AS Total_Sales
FROM sales;

SELECT -- History of Each Customer.
	`Customer ID`,
    `Customer Name`,
    COUNT(*) AS Total_Order,
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales),0) AS Avg_Sales,
    ROUND(SUM(Sales),0) AS Total_Sales
FROM sales
GROUP BY `Customer ID`, `Customer Name`
ORDER BY Total_Order DESC, Avg_Sales DESC;


SELECT COUNT(*) FROM 
(SELECT -- History of Each Customer.
	`Customer ID`,
    `Customer Name`,
    COUNT(*) AS Total_Item,
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales),0) AS Avg_Sales,
    ROUND(SUM(Sales),0) AS Total_Sales
FROM sales
GROUP BY `Customer ID`, `Customer Name`
ORDER BY Total_Item DESC, Avg_Sales DESC) p;


/*
	Expand EDA section
*/

 -- Identifying Top & Bottom Customers
-- 🏆 Top Spending Customer
SELECT `Customer ID`,`Customer Name`, ROUND(SUM(Sales), 2) AS Total_Spent
FROM sales
GROUP BY `Customer ID`,`Customer Name`
ORDER BY Total_Spent DESC
LIMIT 1;

-- 🏅 Lowest Spending Customer
SELECT `Customer ID`,`Customer Name`, ROUND(SUM(Sales), 2) AS Total_Spent
FROM sales
GROUP BY `Customer ID`,`Customer Name`
ORDER BY Total_Spent ASC
LIMIT 1;


-- 5️⃣ Most & Least Sold Products
-- 📈 Best-Selling Product
SELECT `Product Name`, COUNT(*) AS Total_Sales
FROM sales
GROUP BY `Product Name`
ORDER BY Total_Sales DESC
LIMIT 1;

-- 📉 Least Sold Product
SELECT `Product Name`, COUNT(*) AS Total_Sales
FROM sales
GROUP BY `Product Name`
ORDER BY Total_Sales ASC
LIMIT 1;

-- 6️⃣ Sales Distribution by Region
SELECT `Region`, COUNT(*) AS Total_Orders, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Region`
ORDER BY Total_Sales DESC;

-- 7️⃣ Sales Performance by Manager
SELECT `Manager`, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Manager`
ORDER BY Total_Sales DESC;

-- 8️⃣ Customers Who Returned Products
SELECT `Customer ID`,`Customer Name`, COUNT(*) AS Total_Returns
FROM sales
WHERE `Return Status` = 'Returned'
GROUP BY `Customer ID`,`Customer Name`
ORDER BY Total_Returns DESC;


-- 9️⃣ Regional Sales in Descending Order
SELECT `Region`, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Region`
ORDER BY Total_Sales DESC;

-- 🕐 Yearly Sales Performance
SELECT YEAR(Formated_Order_Date) AS Year, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY Year
ORDER BY Year;

-- 1️⃣1️⃣ Monthly Sales Performance
SELECT YEAR(Formated_Order_Date) AS Year,
       MONTH(Formated_Order_Date) AS Month,
       ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY Year, Month
ORDER BY Year, Month;

-- 1️⃣2️⃣ Number of Orders per Customer
SELECT `Customer ID`,`Customer Name`, COUNT(`Order ID`) AS Total_Orders
FROM sales
GROUP BY `Customer ID`,`Customer Name`
ORDER BY Total_Orders DESC;

/*
	Expand EDA section
*/


SELECT MIN(Formated_Order_Date) AS FIRST_order_date FROM sales;

SELECT MAX(Formated_Order_Date) AS LAST_order_date FROM sales;

SELECT COUNT(`ORDER ID`) FROM SALES; -- 9033
SELECT COUNT(DISTINCT `ORDER ID`) FROM SALES; -- 6274


-- RFM Segmentation: 
-- Segment the customers based opn their Recency(R), Frequency(F), Monetary(M)

SELECT 
    `Customer ID`,
    `Customer Name`,
    DATEDIFF((SELECT 
                    MAX(Formated_Order_Date)
                FROM
                    sales),
            MAX(Formated_Order_Date)) AS recency_value,
    COUNT(DISTINCT `Order ID`) AS frequency_value,
    ROUND(SUM(sales)) AS monetary_value
FROM
    sales
GROUP BY `Customer ID` , `Customer Name`;


SELECT * FROM SALES WHERE `CUSTOMER ID`=1008;

CREATE OR REPLACE VIEW RFM_SCORE_DATA AS -- VIEW
with customer_aggregated_data as (
SELECT 
    `Customer ID`,
    `Customer Name`,
    DATEDIFF((SELECT 
                    MAX(Formated_Order_Date)
                FROM
                    sales),
            MAX(Formated_Order_Date)) AS recency_value,
    COUNT(DISTINCT `Order ID`) AS frequency_value,
    ROUND(SUM(sales)) AS monetary_value
FROM
    sales
GROUP BY `Customer ID` , `Customer Name`),

rfm_score as (
	select
		cad.*,
		ntile(5) over (order by recency_value desc) as r_score,
		ntile(5) over (order by frequency_value asc) as f_score,
		ntile(5) over (order by monetary_value desc) as m_score
    from customer_aggregated_data cad
)

select 
	rs.*,
    (r_score + f_score + m_score) as total_rfm_score,
    concat_ws('', r_score, f_score, m_score) as rfm_score_combination
    from rfm_score rs;


-- Labeling
 
 CREATE OR REPLACE VIEW RFM_ANALYSIS AS
 SELECT 
 rfm_score_data.*,
 CASE 
    -- ✅ Best Customers: Highly Engaged, Spends More, Very Recent
    WHEN R_SCORE = 5 AND F_SCORE = 5 AND M_SCORE = 5 THEN 'Champion Customers'
    WHEN R_SCORE >= 4 AND F_SCORE >= 4 AND M_SCORE >= 4 THEN 'Loyal Customers'

    -- 🚀 Growing Customers: Engaged & Spending Well, But Slightly Less Recent
    WHEN R_SCORE >= 3 AND F_SCORE >= 4 AND M_SCORE >= 3 THEN 'Potential Loyalists'
    WHEN R_SCORE = 5 AND (F_SCORE BETWEEN 3 AND 4) AND (M_SCORE BETWEEN 3 AND 4) THEN 'New Champions'
    
    -- 🎯 Recent Buyers: Bought Recently, But Low Spending & Frequency
    WHEN R_SCORE >= 4 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'Recent Customers'
    WHEN R_SCORE = 5 AND F_SCORE BETWEEN 1 AND 2 AND M_SCORE BETWEEN 1 AND 2 THEN 'New Buyers'
    
    -- 📈 Medium Engagement: Good Buyers but Not Consistent
    WHEN R_SCORE >= 2 AND F_SCORE >= 3 AND M_SCORE >= 2 THEN 'Promising Customers'
    WHEN R_SCORE BETWEEN 3 AND 4 AND F_SCORE BETWEEN 2 AND 3 AND M_SCORE BETWEEN 2 AND 3 THEN 'Potential Promising Customers'
    
    -- 🔥 Engaged but Low Spending
    WHEN F_SCORE >= 4 AND M_SCORE <= 3 THEN 'Frequent But Low Spenders'
    WHEN F_SCORE >= 4 AND M_SCORE >= 4 THEN 'Big Spenders'
    
    -- ⚠️ Warning Zone: Low Engagement, Less Frequency, Low Spending
    WHEN R_SCORE <= 2 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'At Risk'
    WHEN R_SCORE BETWEEN 2 AND 3 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'About to Lose'
    
    -- ❌ Lost Customers: Very Low Interaction, No Recent Purchase
    WHEN R_SCORE = 1 AND F_SCORE = 1 AND M_SCORE = 1 THEN 'Lost Customers'
    WHEN R_SCORE = 1 AND (F_SCORE BETWEEN 1 AND 2) AND (M_SCORE BETWEEN 1 AND 2) THEN 'Inactive Customers'

    ELSE 'Other'
END AS CUSTOMER_SEGMENT
FROM rfm_score_data;


SELECT 
	CUSTOMER_SEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;
	



-- CUSTOMER SEGMENT 2
CREATE OR REPLACE VIEW RFM_ANALYSIS2 AS 
WITH CUSTOMER_AGGREGATED_DATA AS 
(
    SELECT
        `Customer ID`, 
        `Customer Name`,
        DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
        COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
        ROUND(SUM(Sales)) AS MONETARY_VALUE
    FROM SALES
    GROUP BY `Customer ID`, `Customer Name`
),

RFM_SCORE AS
(
    SELECT
        CAD.*,
        NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
        NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
        NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
    FROM CUSTOMER_AGGREGATED_DATA AS CAD
)

SELECT 
    RS.* ,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION,

    CASE 
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('555', '554', '553', '552', '551') THEN 'Champion Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('543', '542', '541', '532', '531') THEN 'Loyal Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('535', '534', '533', '525', '524', '523') THEN 'Potential Loyalists'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('515', '514', '513', '412', '411') THEN 'Recent Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('421', '422', '423', '321', '322') THEN 'Promising Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('311', '312', '313', '211', '212') THEN 'Needs Attention'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('431', '432', '433', '331', '332') THEN 'About to Sleep'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('221', '222', '223', '121', '122') THEN 'At Risk'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('113', '112', '111') THEN 'Lost Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('511', '522', '531') THEN 'Cannot Lose Them'
        ELSE 'Other'
    END AS CUSTOMER_SEGMENT2

FROM RFM_SCORE AS RS;

SELECT 
	CUSTOMER_SEGMENT2,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS2
GROUP BY CUSTOMER_SEGMENT2;


-- CUSTOMER SEGMENT 3
CREATE OR REPLACE VIEW RFM_ANALYSIS3 AS 
WITH CUSTOMER_AGGREGATED_DATA AS 
(
    SELECT
        `Customer ID`, 
        `Customer Name`,
        DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
        COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
        ROUND(SUM(Sales)) AS MONETARY_VALUE
    FROM SALES
    GROUP BY `Customer ID`, `Customer Name`
),

RFM_SCORE AS
(
    SELECT
        CAD.*,
        NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
        NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
        NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
    FROM CUSTOMER_AGGREGATED_DATA AS CAD
)

SELECT 
    RS.* ,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION,

    CASE 
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('555', '554', '553') THEN 'Champion Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('552', '551', '543', '542') THEN 'Loyal Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('541', '532', '531') THEN 'Potential Loyalists'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('535', '534', '533', '525') THEN 'Recent Customers - High Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('524', '523', '515', '514', '513') THEN 'Recent Customers - Low Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('512', '511', '421', '422') THEN 'Promising Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('423', '321', '322') THEN 'Need Attention'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('311', '312', '313', '211', '212') THEN 'About to Sleep'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('431', '432', '433', '331', '332') THEN 'At Risk'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('221', '222', '223', '121', '122') THEN 'Lost Customers - High Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('113', '112', '111') THEN 'Lost Customers - Low Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('522', '533', '511') THEN 'Cannot Lose Them'
        ELSE 'Other'
    END AS CUSTOMER_SEGMENT3

FROM RFM_SCORE AS RS;


SELECT -- 
	CUSTOMER_SEGMENT3,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS3
GROUP BY CUSTOMER_SEGMENT3;

