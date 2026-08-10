/*==========================================================
Retail Analytics Project
==========================================================*/

-- =========================================
-- SECTION 1: One-Time Setup (Run Only Once)
-- =========================================

CREATE DATABASE retail_analytics;
USE retail_analytics;

-- Import CSVs manually

ALTER TABLE orders
ADD COLUMN order_date DATE;

UPDATE orders
SET order_date = STR_TO_DATE(OrderDate,'%d-%m-%Y');

--  Run this section only once.

/*==========================================================
Step 1: Validate Record Count
==========================================================*/

SELECT COUNT(*) AS Total_Customers
FROM customers;

SELECT COUNT(*) AS Total_Products
FROM products;

SELECT COUNT(*) AS Total_Orders
FROM orders;

SELECT COUNT(*) AS Total_Returns
FROM returns;

/*==========================================================
Step 2: Check Duplicate Primary Keys
==========================================================*/

SELECT CustomerID, COUNT(*)
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SELECT ProductID, COUNT(*)
FROM products
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT OrderID, COUNT(*)
FROM orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

SELECT ReturnID, COUNT(*)
FROM returns
GROUP BY ReturnID
HAVING COUNT(*) > 1;

/*==========================================================
Step 3: Check Missing Values
==========================================================*/

SELECT *
FROM orders
WHERE OrderDate IS NULL
OR CustomerID IS NULL
OR ProductID IS NULL
OR Profit IS NULL;       -- If no rows are returned, there are no missing values in these columns.

SELECT OrderDate,order_date
FROM orders
LIMIT 10;

describe orders;

/*==========================================================
Business Question 1
Is Revenue & Profit really declining over time while
order volume remains relatively stable?
==========================================================*/

-- Business Requirement:
-- Analyze monthly Revenue, Profit and Order Volume trends
-- to validate whether declining profitability is caused by
-- lower demand or other business factors.

SELECT
    YEAR(order_date) AS Year,
    MONTHNAME(order_date) AS Month,
    SUM(NetRevenue) AS Revenue,
    SUM(Profit) AS Profit,
    COUNT(OrderID) AS Order_Volume
FROM orders
GROUP BY
    YEAR(order_date),
    MONTH(order_date),
    MONTHNAME(order_date)
ORDER BY
    YEAR(order_date),
    MONTH(order_date);

/*----------------------------------------------------------
Observation:
1. Revenue fluctuated throughout the two-year period and showed a slight decline during Q3–Q4 2025.
2. Profit declined much more sharply than revenue and became negative from July 2025 onwards.
3. Monthly order volume remained relatively stable (around 600–700 orders), indicating stable customer demand.

Business Insight:
The decline in profitability is not driven by lower order volume. Since customer demand remained 
relatively stable while profit dropped significantly, the likely causes are higher discounts,
returns, shipping costs, product mix, or sales channel performance. These factors will be
investigated in the following analysis.
----------------------------------------------------------*/

/*==========================================================
Business Question 2
Which product categories are contributing the most
to profitability decline?
==========================================================*/

-- Business Requirement:
-- Analyze Revenue, Profit and Profit Margin by Category to identify categories that are underperforming.

select p.category,
sum(o.netrevenue) as Revenue,
sum(o.profit) as Profit,
Round((sum(o.profit)/sum(o.netrevenue))*100,2) AS profit_margin_pct
from orders o
join products p
on o.productid=p.productid
group by p.category
order by profit asc;

/*----------------------------------------------------------
Observation:
1. Electronics generated the highest revenue among all product categories.
2. Despite generating the highest revenue, Electronics recorded the lowest profit margin (13.12%), indicating lower profitability.
3. Beauty & Personal Care generated the lowest overall profit, while Sports & Outdoors achieved the highest profit margin (28.61%).

Business Insight:
Electronics should be prioritized for further investigation because it contributes the largest share of company revenue but
operates at a significantly lower profit margin. Even a small improvement in Electronics profitability could substantially
increase overall business profit.
----------------------------------------------------------*/

/*==========================================================
Business Question 3
Which product categories should we stop discounting?
==========================================================*/

-- Business Requirement:
-- Analyze average discount, revenue and profit by category to identify categories where high discounts may be reducing profitability.

SELECT
    p.Category,
    ROUND(AVG(o.DiscountPct)*100,2) AS Avg_Discount_Pct,
    SUM(o.NetRevenue) AS Revenue,
    SUM(o.Profit) AS Profit
FROM orders o
JOIN products p
ON o.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY Avg_Discount_Pct DESC;

/*----------------------------------------------------------
Observation:
1. Electronics received the highest average discount among all product categories.
2. Electronics also recorded the lowest profit margin despite generating the highest revenue.
3. The results indicate a possible relationship between higher discounting and lower profitability.

Business Insight:
Higher discounts may be one of the factors contributing to declining profitability, particularly in the Electronics category.
However, additional analysis of shipping costs, returns, and marketplace commissions is required before concluding that
discounts are the primary reason for profit decline.
----------------------------------------------------------*/

/*==========================================================
Business Question 4
Which sales channel generates the highest profit margin?
==========================================================*/

-- Business Requirement:
-- Compare Revenue, Profit and Profit Margin across different sales channels.

SELECT SalesChannel,
SUM(NetRevenue) AS Revenue,
SUM(Profit) AS Profit,
ROUND((SUM(Profit)/SUM(NetRevenue))*100,2) AS Profit_Margin_Pct
FROM orders
GROUP BY SalesChannel
ORDER BY Profit_Margin_Pct DESC;

/*----------------------------------------------------------
Observation:
1. Online channel generated the highest profit margin (24.75%).
2. Marketplace generated the lowest profit margin (4.06%), despite contributing significant revenue.
3. In-Store and Online channels performed similarly, while Marketplace was considerably less profitable.

Business Insight:
The company should focus on expanding the Online channel due to its high profitability. Marketplace sales
require further investigation, as low margins may be driven by marketplace commissions, higher discounts,
or other operational costs.
----------------------------------------------------------*/

/*==========================================================
Business Question 5
Which regions need logistics optimization?
==========================================================*/

-- Business Requirement: Compare shipping cost and profit across regions.

select region,
round(avg(shippingcost),2) AS Avg_Shipping_Cost,
Sum(profit) as profit
from orders
group by region
order by Avg_Shipping_Cost desc;

/*----------------------------------------------------------
Observation:
1. West region recorded the highest average shipping cost.
2. Central region generated the lowest overall profit despite having the lowest average shipping cost.
3. The relationship between shipping cost and profitability is not consistent across all regions.

Business Insight:
Shipping cost alone is unlikely to be the primary reason for declining profitability. Other factors such as
discounts, returns, product mix and sales channel performance should also be investigated.
----------------------------------------------------------*/

/*==========================================================
Business Question 6
What changed in Q3–Q4 2025 that caused profitability to decline?
==========================================================*/

-- Business Requirement:
-- Compare key business metrics across quarters to identify what changed before the profit decline.

SELECT YEAR(order_date) AS Year,
QUARTER(order_date) AS Quarter,
ROUND(AVG(DiscountPct)*100,2) AS Avg_Discount_Pct,
ROUND(AVG(ShippingCost),2) AS Avg_Shipping_Cost,
SUM(NetRevenue) AS Revenue,
SUM(Profit) AS Profit
FROM orders
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY YEAR(order_date), QUARTER(order_date);

/*==========================================================
Business Question 7
Which are the Top 5 products hurting profitability?
==========================================================*/

-- Business Requirement: Identify products generating the lowest profit.

SELECT p.ProductName,
p.Category,
SUM(o.Profit) AS Total_Profit
FROM orders o
JOIN products p
ON o.ProductID = p.ProductID
GROUP BY p.ProductName, p.Category
ORDER BY Total_Profit
LIMIT 5;

/*----------------------------------------------------------
Observation:
1. All five least profitable products belong to the Electronics category.
2. "Cameras Compact 944" recorded the highest loss among all products.
3. The results indicate that losses are concentrated within specific Electronics products rather than being 
evenly distributed across categories.

Business Insight:
The company should review pricing, discount strategy, supplier quality and return patterns for these products.
Improving or discontinuing consistently loss-making products could significantly improve overall profitability.
----------------------------------------------------------*/

/*==========================================================
Business Question 8
Root Cause Analysis & Business Recommendations
==========================================================*/
/*----------------------------------------------------------
-- Observation:
-- Revenue remained relatively stable throughout the period.
-- However, average discount increased sharply from around 6% to nearly 39% in Q3-Q4 2025.
-- Profit turned negative during the same period.
-- Shipping cost also increased in Q4 2025.
----------------------------------------------------------*/

-- =========================================
-- Final Business Recommendations
-- =========================================

-- 1. Reduce excessive discounting, especially in Electronics during Q3-Q4, as high discounts are the primary reason behind negative profitability.

-- 2. Review pricing strategy for loss-making products and discontinue or renegotiate products generating continuous losses.

-- 3. Optimize Marketplace operations by reducing commission costs and improving pricing, since it generates high revenue but very low profit margin.

-- 4. Investigate increasing shipping costs, especially in West region and Q4 2025, to improve operational efficiency.

-- 5. Increase focus on profitable sales channels such as Online and In-Store while improving Marketplace profitability.

-- 6. Monitor quarterly business KPIs (Revenue, Profit, Discount, Shipping Cost) using dashboards to identify issues before profitability declines.
