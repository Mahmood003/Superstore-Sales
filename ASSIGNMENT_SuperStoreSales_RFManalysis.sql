-- 1. CREATE A DATABASE IN MYSQL
CREATE DATABASE SUPERSTORE;
USE SUPERSTORE;
-- CREATE TABLE SALES_DATA;

/*  2. CREATE A TABLE UNDER THAT DATABASE
	3.INSERT THE ATTACH DATA THERE (PREFERABLY BULK INSERTION) */
select * from superstore_sales;
select 
	count(*)
from superstore_sales; -- 9033 entries

-- 4. EXPLORE THE DATA AND CHECK IF ALL THE DATA IS IN THE PROPER FORMAT
select
	`Customer Name`,
    count(*) as Customer_Numbers
from superstore_sales
group by `Customer Name`;

select
	`Customer Segment`,
    count(*) as CustomerSEGMENTS
from superstore_sales
group by `Customer Segment`;

select
	`Order Date`,
    str_to_date(`Order Date`, '%d/%m/%Y') as Formatted_Date
from superstore_sales;

Select
	`Order Date`,
    `Ship Date`,
	DATE_ADD('1899-12-30', INTERVAL `Order Date` DAY) AS Order_Date,
    DATE_ADD('1899-12-30', Interval `Ship Date` DAY) As Ship_Date
from superstore_sales;

-- 5. DO THE NECESSARY CLEANING AND UPDATE THE TABLE SCHEMA IF REQUIRED
SET SQL_SAFE_UPDATES = 0;

ALTER TABLE superstore_sales ADD COLUMN ORDER_DATE DATE;
UPDATE superstore_sales
SET ORDER_DATE = DATE_ADD('1899-12-30', INTERVAL `Order Date` DAY);

ALTER TABLE superstore_sales ADD COLUMN SHIP_DATE DATE;
UPDATE superstore_sales
SET SHIP_DATE = DATE_ADD('1899-12-30', INTERVAL `Ship Date` DAY);

-- 6. PERFORM EXPLORATORY DATA ANALYSIS
Select
	ORDER_DATE,
    SHIP_DATE
from superstore_sales;

Select
	max(Order_date) as Last_Order_Date, -- 2013-12-31
    min(Order_date) as First_Order_Date -- 2010-01-02
from superstore_sales;

-- CTE : RFM_SCORE
CREATE OR REPLACE VIEW RFM_SCORE AS
With ALL_CUSTOMERS as (
Select
	`Customer Name`,
    datediff((select max(Order_date) from superstore_sales), max(Order_date)) as Recency,
    count(distinct `Order ID`) as Frequency,
    Round(sum(Sales),0) as Monetary
from superstore_sales
Group By `Customer Name`
order by 2 ASC
),

RFM_SCORE AS (
Select
	ALL_CUSTOMERS.*,
	NTILE(4) OVER (ORDER BY Recency DESC) as R_SCORE,
    NTILE(4) OVER (ORDER BY Frequency ASC) as F_SCORE,
    NTILE(4) OVER (ORDER BY Monetary ASC) as M_SCORE
from ALL_CUSTOMERS
)

Select
	RFM_SCORE.*,
    R_SCORE + F_SCORE + M_SCORE as TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION
from RFM_SCORE
Order by TOTAL_RFM_SCORE DESC;

-- 7. SEGMENT THE CUSTOMER USING RFM SEGMENTATION
-- CTE : CUSTOMER_SEGMENTATION
CREATE OR REPLACE VIEW CUSTOMER_SEGMENTATION AS
select 
	rfm_score.*,
    CASE
        WHEN RFM_SCORE_COMBINATION IN (111, 112, 121, 132, 211, 211, 212, 114, 141) THEN 'CHURNED CUSTOMER'
        WHEN RFM_SCORE_COMBINATION IN (133, 134, 143, 224, 334, 343, 344, 144) THEN 'SLIPPING AWAY, CANNOT LOSE'
        WHEN RFM_SCORE_COMBINATION IN (311, 411, 331) THEN 'NEW CUSTOMERS'
        WHEN RFM_SCORE_COMBINATION IN (222, 231, 221,  223, 233, 322) THEN 'POTENTIAL CHURNERS'
        WHEN RFM_SCORE_COMBINATION IN (323, 333,321, 341, 422, 332, 432) THEN 'ACTIVE'
        WHEN RFM_SCORE_COMBINATION IN (433, 434, 443, 444) THEN 'LOYAL'
    ELSE 'Other'
    END AS CUSTOMER_SEGMENT
from rfm_score;

Select
	CUSTOMER_SEGMENT,
    Count(*) AS `Number Of Customers as per segmentation`
from CUSTOMER_SEGMENTATION
group by CUSTOMER_SEGMENT;

Select
	CUSTOMER_SEGMENT,
    SUM(Monetary) AS `TOTAL sales as per segmentation`,
    round(avg(Monetary),0) AS `AVG sales as per segmentation`
from CUSTOMER_SEGMENTATION
group by CUSTOMER_SEGMENT;


