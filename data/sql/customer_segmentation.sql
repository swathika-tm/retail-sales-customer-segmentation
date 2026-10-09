-- ====================================================================
-- Project: Retail Sales Performance & Customer Segmentation
-- Description: Comprehensive, production-grade SQL script covering data 
--              validation, anomaly detection, RFM customer segmentation, 
--              advanced window functions, and strategic business metrics.
-- ====================================================================

-- ====================================================================
-- SECTION 1: DATA CLEANING & VALIDATION
-- Objective: Ensure data integrity by checking for nulls and anomalies.
-- ====================================================================

-- 1.1 Check for missing or null values in critical operational fields
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN TransactionID IS NULL THEN 1 ELSE 0 END) AS MissingTransactions,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomers,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS MissingDates,
    SUM(CASE WHEN TotalSales IS NULL THEN 1 ELSE 0 END) AS MissingSales
FROM retail_sales_dataset;

-- 1.2 Check for duplicate transaction IDs (Primary Key integrity check)
SELECT 
    TransactionID, 
    COUNT(*) AS DuplicateCount
FROM retail_sales_dataset 
GROUP BY TransactionID 
HAVING COUNT(*) > 1;

-- 1.3 Data sanity check: Ensure no negative or zero quantities/prices exist
SELECT * 
FROM retail_sales_dataset 
WHERE Quantity <= 0 OR UnitPrice <= 0 OR TotalSales <= 0;


-- ====================================================================
-- SECTION 2: CUSTOMER SEGMENTATION (RFM-STYLE AGGREGATIONS)
-- Objective: Group customers into behavioral tiers based on spend & frequency.
-- ====================================================================

WITH CustomerMetrics AS (
    SELECT 
        CustomerID,
        CustomerName,
        COUNT(DISTINCT TransactionID) AS TotalOrders,
        SUM(TotalSales) AS MonetaryValue,
        MAX(OrderDate) AS LastOrderDate
    FROM retail_sales_dataset
    GROUP BY CustomerID, CustomerName
)
SELECT 
    CustomerID,
    CustomerName,
    TotalOrders,
    MonetaryValue,
    LastOrderDate,
    CASE 
        WHEN MonetaryValue >= 200.00 AND TotalOrders >= 3 THEN 'High-Value Repeat'
        WHEN TotalOrders >= 2 THEN 'Regular Repeat'
        ELSE 'Single Purchase / Inactive'
    END AS CustomerSegment
FROM CustomerMetrics
ORDER BY MonetaryValue DESC;


-- ====================================================================
-- SECTION 3: ADVANCED WINDOW FUNCTIONS
-- Objective: Calculate running totals and purchase rankings per customer.
-- ====================================================================

SELECT 
    TransactionID,
    CustomerID,
    CustomerName,
    OrderDate,
    TotalSales,
    SUM(TotalSales) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS RunningTotalSpend,
    ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate DESC) AS PurchaseRecencyRank
FROM retail_sales_dataset;


-- ====================================================================
-- SECTION 4: STRATEGIC BUSINESS ANALYSIS (Category Revenue Share)
-- Objective: Calculate revenue contribution percentage by product category.
-- ====================================================================

SELECT 
    Category,
    COUNT(DISTINCT TransactionID) AS TotalOrders,
    SUM(TotalSales) AS CategoryRevenue,
    ROUND(
        (SUM(TotalSales) / (SELECT SUM(TotalSales) FROM retail_sales_dataset)) * 100, 
        2
    ) AS RevenuePercentage
FROM retail_sales_dataset
GROUP BY Category
ORDER BY CategoryRevenue DESC;


-- ====================================================================
-- SECTION 5: TIME-SERIES ANALYSIS (Monthly Sales Trend)
-- Objective: Track revenue performance over time to spot seasonal trends.
-- ====================================================================

SELECT 
    DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth,
    COUNT(DISTINCT CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT TransactionID) AS MonthlyOrders,
    SUM(TotalSales) AS MonthlyRevenue
FROM retail_sales_dataset
GROUP BY SalesMonth
ORDER BY SalesMonth ASC;
