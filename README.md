# RFM-Segmentation-Analysis-in-MySQL

🛍️ RFM Segmentation Analysis in MySQL
📖 Project Overview
This repository contains a comprehensive customer segmentation analysis using the RFM (Recency, Frequency, Monetary) model, implemented entirely in MySQL. The project analyzes a superstore's sales dataset to group customers into distinct segments based on their purchasing behavior.

The primary goal is to identify different customer archetypes—such as "Champion Customers," "Loyal Customers," and "At Risk" customers—to enable targeted marketing strategies, improve customer retention, and maximize profitability.

This analysis demonstrates a complete workflow within MySQL, from initial data cleaning and preparation to in-depth exploratory data analysis (EDA) and the final RFM segmentation.

💾 Dataset
Source File: sales.csv

Description: This dataset contains transactional sales data from a superstore. Key columns used for this analysis include:

Order date: The date of the customer's order.

Customer ID: A unique identifier for each customer.

Customer Name: The name of the customer.

Sales: The total monetary value of the transaction.

Order ID: A unique identifier for each order.

🚀 Getting Started
To replicate this analysis, you will need a MySQL environment (such as MySQL Server with MySQL Workbench or any other SQL client).

Create the Database:

CREATE DATABASE RFM_Segmentation;
USE RFM_Segmentation;

Import the Data:

Create a table named sales in the RFM_Segmentation database.

Import the contents of the sales.csv file into this table. Most SQL clients have a built-in wizard for importing CSV files.

Run the Analysis Script:

Execute the entire RFM_Segmentation_Analysis.sql script. This will perform all the necessary data cleaning, EDA, and create the final RFM analysis views.

🔬 Analysis Walkthrough
The analysis is performed in several distinct stages, as detailed in the SQL script.

1. Data Cleaning and Preparation
Before analysis, the raw data was cleaned and prepared to ensure accuracy and consistency.

Date Formatting: The original Order date column was stored as a number (likely an Excel serial number). A new column, formated_order_date, was created with the DATE data type. The dates were correctly formatted using the following logic, which converts Excel's numeric date format to a standard SQL date:

-- Add a new column to store the formatted date
ALTER TABLE sales ADD COLUMN formated_order_date DATE;

-- Convert the Excel serial number date to a standard SQL date
UPDATE sales
SET formated_order_date = DATE_ADD('1899-12-30', INTERVAL `Order date` DAY);

Data Type Modification: The data types of key columns were adjusted to be more appropriate for the analysis and to enforce data integrity:

ALTER TABLE sales
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;

2. Exploratory Data Analysis (EDA)
EDA was performed to uncover initial insights and understand the structure of the dataset.

Checking for Duplicate Records: Duplicate records can skew analysis results. I used three different methods to identify duplicates, noting their performance differences:

EXISTS subquery: A straightforward but slower method.

JOIN with a subquery: A significantly faster and more efficient method.

CTE (Common Table Expression): A clean, readable, and equally fast method.

The JOIN and CTE methods proved to be the most performant for this task. The following is an example of the efficient CTE method used:

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

Key Business Insights from EDA: A series of queries were run to understand the business performance, including:

Total unique customers.

Overall sales statistics (min, max, average, total).

Top and bottom-spending customers.

Best and least-selling products.

Sales performance by region and manager.

Yearly and monthly sales trends.

3. RFM Segmentation Analysis
This is the core of the project, where customers are segmented based on their transaction history. The process was broken down into several logical steps using a VIEW named RFM_SCORE_DATA.

Step 1: Calculate Raw RFM Values
For each customer, three key metrics were calculated:

Recency (R): How recently did the customer make a purchase? This was calculated as the number of days between the customer's last purchase and the last purchase date in the entire dataset.

DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS recency_value

Frequency (F): How often does the customer make a purchase? This was calculated by counting the number of distinct orders for each customer.

COUNT(DISTINCT `Order ID`) AS frequency_value

Monetary (M): How much does the customer spend? This was calculated by summing the total sales for each customer.

ROUND(SUM(sales)) AS monetary_value

Step 2: Assign RFM Scores
The raw R, F, and M values were then converted into scores from 1 to 5 using the NTILE(5) window function. This function divides the customers into five equal-sized groups (quintiles).

r_score: A higher score means a more recent purchase (ORDER BY recency_value DESC).

f_score: A higher score means more frequent purchases (ORDER BY frequency_value ASC).

m_score: A higher score means higher spending (ORDER BY monetary_value DESC).

Step 3: Create Customer Segments
Using the R, F, and M scores, customers were categorized into descriptive segments using a CASE statement. This logic is encapsulated in a final view named RFM_ANALYSIS. For example:

Champion Customers (R=5, F=5, M=5): Your best and most loyal customers.

At Risk (R<=2, F<=2, M<=2): Customers who have not purchased in a while and have low frequency and spending.

Potential Loyalists: Customers who are engaged but could be encouraged to become "Loyal" or "Champion" customers.

The script also includes two alternative segmentation models (RFM_ANALYSIS2 and RFM_ANALYSIS3) that use different combinations of RFM scores to create segments, demonstrating the flexibility of this model.

Step 4: Analyze Final Segments
Finally, the created segments were analyzed to understand their size and average monetary value. This provides actionable insights.

SELECT
    CUSTOMER_SEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;

This final summary allows the business to see, for instance, how many customers fall into each segment and what their average value is, justifying targeted marketing campaigns for each group.

📊 How to Use the Results
You can query the final views directly to explore the customer segments:

SELECT * FROM RFM_ANALYSIS;

SELECT * FROM RFM_ANALYSIS2;

SELECT * FROM RFM_ANALYSIS3;

These views provide a customer-by-customer breakdown of their RFM scores and final segment, which can be exported for use in marketing tools or further analysis in other platforms like Power BI or Tableau.

📞 Troubleshooting and Contact
This project was built for educational purposes. If you encounter any errors while running the script or have suggestions for improvement, please feel free to open an issue in this GitHub repository. I would be happy to review it.

🙏 Acknowledgments
This project was developed as a learning exercise. The concepts and methodologies for RFM analysis were learned and adapted from various educational resources and tutorials on YouTube.
