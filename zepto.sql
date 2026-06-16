drop table if exists zepto;

create table zepto (
sku_id SERIAL PRIMARY KEY,
category VARCHAR(120),
name VARCHAR(150) NOT NULL,
mrp NUMERIC(8,2),
discountPercent NUMERIC(5,2),
availableQuantity INTEGER,
discountedSellingPrice NUMERIC(8,2),
weightInGms INTEGER,
outOfStock BOOLEAN,	
quantity INTEGER
);

--data exploration

--count of rows
select count(*) from zepto;

--sample data
SELECT * FROM zepto
LIMIT 10;

--null values
SELECT * FROM zepto
WHERE name IS NULL
OR
category IS NULL
OR
mrp IS NULL
OR
discountPercent IS NULL
OR
discountedSellingPrice IS NULL
OR
weightInGms IS NULL
OR
availableQuantity IS NULL
OR
outOfStock IS NULL
OR
quantity IS NULL;

--different product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

--products in stock vs out of stock
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

--product names present multiple times
SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

--data cleaning

--products with price = 0
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

--convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;

--data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

--Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

--Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;

--Top 5 Products Contributing 80% Revenue (Pareto Analysis)
WITH product_revenue AS (
    SELECT
        name,
        SUM(discountedSellingPrice * availableQuantity) AS revenue
    FROM zepto
    GROUP BY name
),
revenue_ranked AS (
    SELECT *,
           SUM(revenue) OVER(ORDER BY revenue DESC) AS running_revenue,
           SUM(revenue) OVER() AS total_revenue
    FROM product_revenue
)
SELECT *
FROM revenue_ranked
WHERE running_revenue <= total_revenue * 0.8
ORDER BY revenue DESC;
--Revenue Rank Within Each Category
SELECT *
FROM (
    SELECT
        category,
        name,
        discountedSellingPrice * availableQuantity AS revenue,
        DENSE_RANK() OVER(
            PARTITION BY category
            ORDER BY discountedSellingPrice * availableQuantity DESC
        ) AS revenue_rank
    FROM zepto
) t
WHERE revenue_rank <= 5;
--Identify Premium Products
SELECT
    category,
    name,
    mrp
FROM zepto
WHERE mrp >
(
    SELECT AVG(mrp) + STDDEV(mrp)
    FROM zepto z2
    WHERE z2.category = zepto.category
);

--Inventory Concentration Analysis
SELECT
    category,
    ROUND(
        100.0 * SUM(weightInGms * availableQuantity)
        /
        SUM(SUM(weightInGms * availableQuantity)) OVER(),
        2
    ) AS inventory_percentage
FROM zepto
GROUP BY category
ORDER BY inventory_percentage DESC;

--Find Products With Extremely High Discounts
SELECT *
FROM zepto
WHERE discountPercent >
(
    SELECT AVG(discountPercent)
           + 2 * STDDEV(discountPercent)
    FROM zepto
);
--Find Categories With Above Average Revenue

WITH category_revenue AS (
    SELECT
        category,
        SUM(discountedSellingPrice * availableQuantity) AS revenue
    FROM zepto
    GROUP BY category
)
SELECT *
FROM category_revenue
WHERE revenue >
(
    SELECT AVG(revenue)
    FROM category_revenue
);
--Business Recommendations
--Allocate more inventory and warehouse space to top-performing categories to maximize revenue generation.
--Prioritize replenishment of high-value out-of-stock products to minimize revenue loss and improve customer satisfaction.
--Reduce inventory investment in underperforming categories and reallocate resources to high-demand products.
--Reassess discount policies for low-performing products to improve profit margins without affecting sales volume.
