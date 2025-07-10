# 🛍️ RFM Segmentation Analysis in MySQL

## 📖 Project Overview

This repository contains a **comprehensive customer segmentation analysis** using the **RFM (Recency, Frequency, Monetary)** model, implemented entirely in **MySQL**. The project analyzes a **superstore's sales dataset** to group customers into distinct segments based on their purchasing behavior.

🎯 **Primary Goal**  
Identify different customer archetypes—such as **"Champion Customers," "Loyal Customers,"** and **"At Risk" customers**—to enable:

- 🎯 Targeted marketing strategies  
- 📈 Improved customer retention  
- 💰 Maximized profitability

This analysis demonstrates a complete workflow within MySQL, from initial **data cleaning and preparation** to **in-depth exploratory data analysis (EDA)** and the final **RFM segmentation**.

---

## 💾 Dataset Source

- **File**: `sales.csv`
- **Description**: Transactional sales data from a superstore.

**Key Columns Used:**
- `Order date`: The date of the customer's order (Excel serial format).
- `Customer ID`: A unique identifier for each customer.
- `Customer Name`: The name of the customer.
- `Sales`: The total monetary value of the transaction.
- `Order ID`: A unique identifier for each order.

---

## 🚀 Getting Started

### 1️⃣ Create the Database

```sql
CREATE DATABASE RFM_Segmentation;
USE RFM_Segmentation;
```

### 2️⃣ Import the Data

* Create a table named `sales` in the `RFM_Segmentation` database.
* Import the contents of the `sales.csv` file into this table using a SQL client (e.g., MySQL Workbench, DBeaver, etc.) or use Table Data Import Wizard Option.

### 3️⃣ Run the Analysis Script

* Execute the full `RFM_Segmentation_Analysis.sql` script.
* The script will perform all the necessary:

  * Data cleaning
  * Exploratory analysis
  * RFM segmentation logic
  * Final segmentation views

---

## 🔬 Analysis Walkthrough

### 1. 🧹 Data Cleaning and Preparation

#### ✅ Date Formatting

The original `Order date` is in Excel serial number format. We convert it to proper SQL `DATE`:

```sql
-- Add a new column
ALTER TABLE sales ADD COLUMN formated_order_date DATE;

-- Convert Excel serial date to SQL date
UPDATE sales 
SET formated_order_date = DATE_ADD('1899-12-30', INTERVAL `Order date` DAY);
```

#### ✅ Data Type Modifications

Ensure data types are consistent and appropriate:

```sql
ALTER TABLE sales 
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;
```

---

### 2. 📊 Exploratory Data Analysis (EDA)

#### 🔍 Detecting Duplicate Records

Most efficient method using a Common Table Expression (CTE):

```sql
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
```

#### 📈 Key Insights from EDA

* Total number of unique customers
* Summary statistics: min, max, avg, total sales
* Top & bottom spending customers
* Best-selling and worst-selling products
* Sales performance by region & manager
* Yearly and monthly sales trends

---

### 3. 🧠 RFM Segmentation Analysis

The heart of this project: segmenting customers based on Recency, Frequency, and Monetary values.

#### 🔢 Step 1: Calculate Raw RFM Metrics

```sql
-- Recency: Days since last order
DATEDIFF((SELECT MAX(formated_order_date) FROM sales), MAX(formated_order_date)) AS recency_value

-- Frequency: Count of unique orders
COUNT(DISTINCT `Order ID`) AS frequency_value

-- Monetary: Total spend
ROUND(SUM(sales)) AS monetary_value
```

#### 🧮 Step 2: Assign RFM Scores (1 to 5)

```sql
-- Score Recency: More recent = higher score
NTILE(5) OVER (ORDER BY recency_value DESC) AS r_score

-- Score Frequency: More frequent = higher score
NTILE(5) OVER (ORDER BY frequency_value ASC) AS f_score

-- Score Monetary: Higher spending = higher score
NTILE(5) OVER (ORDER BY monetary_value DESC) AS m_score
```

#### 🏷️ Step 3: Segment Customers

Use RFM scores to define customer segments (via `CASE` statements). For example:

* **Champion Customers**: R=5, F=5, M=5
* **At Risk**: R≤2, F≤2, M≤2
* **Potential Loyalists**: Middle range R, F, M

Views created:

* `RFM_ANALYSIS`
* `RFM_ANALYSIS2`
* `RFM_ANALYSIS3` (alternative segmentation strategies)

#### 📊 Step 4: Analyze Final Segments

```sql
SELECT 
  CUSTOMER_SEGMENT,
  COUNT(*) AS NUMBER_OF_CUSTOMERS,
  ROUND(AVG(MONETARY_VALUE), 0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;
```

---

## 📊 How to Use the Results

Run the following queries to explore segmentation results:

```sql
SELECT * FROM RFM_ANALYSIS;
SELECT * FROM RFM_ANALYSIS2;
SELECT * FROM RFM_ANALYSIS3;
```

📤 Export these views to use in:

* 📬 Email marketing platforms
* 📊 Power BI or Tableau for dashboards
* 📈 Customer lifetime value analysis

---

## 📞 Troubleshooting and Contact

This project is built for **educational purposes**.

If you face any issues or have suggestions, feel free to **open an issue** in the GitHub repository. I’d be happy to help!

---

## 🙏 Acknowledgments

This project was developed as a **learning exercise**.
The concepts and logic of RFM segmentation were adapted from multiple tutorials and online resources, particularly from the **YouTube data community**.

---

```

Let me know if you’d like to add:

- Screenshots of the results (tables, charts, dashboards)
- `LICENSE.md` or `CONTRIBUTING.md` templates
- SQL file template for `RFM_Segmentation_Analysis.sql`
- Power BI/Tableau visualizations instructions

I'm happy to help make it a fully polished GitHub repository.
```
