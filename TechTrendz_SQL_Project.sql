create database Sales;
use Sales;

CREATE TABLE sales_data (
    InvoiceNo INT,
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country VARCHAR(100),
    Discount DECIMAL(5, 2),
    PaymentMethod VARCHAR(50),
    ShippingCost DECIMAL(10, 2),
    Category VARCHAR(100),
    SalesChannel VARCHAR(50),
    ReturnStatus VARCHAR(50),
    ShipmentProvider VARCHAR(100),
    WarehouseLocation VARCHAR(100),
    OrderPriority VARCHAR(50)
);

-- importing dataset

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/csvfiles/Sales_Dataset.csv"
INTO TABLE sales_data
FIELDS TERMINATED BY ','       -- Fields are separated by commas
ENCLOSED BY '"'                -- Fields are enclosed in double quotes (if necessary)
LINES TERMINATED BY '\r\n'     -- Each row ends with a new line
IGNORE 1 LINES;               -- Skip the header row

select * from Sales_Data;

-- ---- EDA ---- --

-- Understanding the Dataset
Select * from Sales_data Limit 10;
		
-- 	These columns will allow us to analyze trends, customer behavior, product performance, and more.

-- 1. Sales Trends with seasonal breakdown and year over year comparison
SELECT YEAR(InvoiceDate) AS Year,
       MONTH(InvoiceDate) AS Month,
       SUM(Quantity * UnitPrice - Discount) AS TotalSales
FROM sales_data
GROUP BY Year, Month
ORDER BY Year DESC, Month DESC;

-- The monthly sales data from 2020 to 2025 reveals fluctuating trends with noticeable seasonal patterns, indicating potential peaks during holiday months and overall growth in total sales over the years.

-- 2. Customer Lifetime Value (CLTV)
select CustomerID,
       Sum(Quantity * UnitPrice - Discount) As TotalSpent,
       count(distinct InvoiceNo) As TotalTransactions,
       Min(InvoiceDate) As FirstPurchaseDate,
       Max(InvoiceDate) As LastPurchaseDate
       from sales_data
       group by customerID
       having TotalTransactions>1
       order by TotalTransactions desc;

--  3. Identifying Repeat Purchases
Select CustomerID,
       Count(Distinct InvoiceNo) As TotalPurchases,
       Max(InvoiceDate) As LastPurchaseDate
from Sales_data
group by CustomerID
having TotalPurchases>1
order by TotalPurchases Desc, LastPurchaseDate Desc;

-- 4. Sales by Product Category/Profitability
select Category,
       Sum(Quantity*UnitPrice-(1-Discount)) As TotalRevenue
from Sales_data
group by Category
order by TotalRevenue Desc;

-- Furniture leads total revenue at $11,440,522.50, followed closely by Accessories and Electronics, indicating strong overall performance across all categories.

-- 5.Impact of Discounts on Customer Retention and Repeat Purchases
select CustomerID,
	   count(distinct invoiceNo) as TotalPurchases,
       sum(Discount) As TotalDiscountRecieved,
       sum(Quantity * UnitPrice - Discount) As TotalSpent
from Sales_Data
group by CustomerID
having sum(discount)>0
order by TotalDiscountRecieved Desc, TotalSpent Desc;

-- 6. Discounted vs. Non-Discounted Sales
select 
    CASE 
        WHEN Discount > 0 THEN 'Discounted Sales' 
        ELSE 'Non-Discounted Sales' 
    END AS SaleType,
    sum(Quantity) AS TotalQuantitySold,
    sum(Quantity * UnitPrice) AS TotalSales,
    sum(Quantity * UnitPrice * Discount) AS TotalDiscount
from sales_data
group by SaleType;

-- 7. Sales Trends by Country
select Country,
	   sum(quantity * UnitPrice - (1 - Discount)) As TotalSales,
       count(distinct invoiceNo) As TotalTransactions
from sales_data
group by Country;

-- 8.Relationship Between Product Pricing and Return Rates
select StockCode, Description, 
    avg(UnitPrice) As AveragePrice, 
    sum(CASE WHEN ReturnStatus = 'Returned' THEN Quantity ELSE 0 END) As TotalReturns, 
    sum(Quantity) As TotalSales,
    (sum(CASE WHEN ReturnStatus = 'Returned' THEN Quantity ELSE 0 END) * 1.0 / NULLIF(SUM(Quantity), 0)) As ReturnRate
from Sales_data 
group by StockCode, Description
order by AveragePrice desc;

-- 9.Top 10 Products by Total Revenue
select StockCode, description,
       SUM(Quantity * UnitPrice) AS TotalRevenue
from sales_data
group by StockCode, Description
order by TotalRevenue desc
limit 10;

-- 10. Discounted vs. Non-Discounted Sales
select 
    CASE 
        WHEN Discount > 0 THEN 'Discounted Sales' 
        ELSE 'Non-Discounted Sales' 
    END AS SaleType,
    sum(Quantity) AS TotalQuantitySold,
    sum(Quantity * UnitPrice) AS TotalSales,
    sum(Quantity * UnitPrice * Discount) AS TotalDiscount
from sales_data
group by SaleType;

-- 11. Sales by Payment method
SELECT PaymentMethod,
    sum(Quantity) AS TotalQuantitySold,
    sum(Quantity * UnitPrice) AS TotalSales
from sales_data
group by PaymentMethod
order by TotalSales desc;

       