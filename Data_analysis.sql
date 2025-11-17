--- Request 1: Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region--
SELECT 
    market
FROM 
    dim_customer
WHERE 
    customer = 'Atliq Exclusive'
    AND region = 'APAC'
ORDER BY 
    market;

 --- Request 2: What is the percentage of unique product increase in 2021 vs. 2020? 
 --- The final output contains these fields
 --- unique_products_2020
  --- unique_products_2021
  --- percentage_chg 
  WITH cte1 AS (
    SELECT 
        (SELECT COUNT(DISTINCT product_code) 
         FROM fact_sales_monthly 
         WHERE fiscal_year = 2020) AS unique_products_2020,
          (SELECT COUNT(DISTINCT product_code) 
         FROM fact_sales_monthly 
         WHERE fiscal_year = 2021) AS unique_products_2021
    FROM 
        fact_sales_monthly)
SELECT  
    unique_products_2020,
    unique_products_2021,
    ROUND(
        (unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 2 ) AS pct_chg
FROM cte1
LIMIT 1;

--- Request 3: Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
--- The final output contains 2 fields
--- segment
--- product_count
SELECT segment,
COUNT(distinct product_code) AS product_count
 FROM dim_product 
GROUP BY segment 
ORDER BY product_count  DESC;

 --- Request 4: Which segment had the most increase in unique products in 2021 vs 2020? 
 --- The final output contains these fields
 --- segment 
 --- product_count_2020
 --- product_count_2021
 --- difference 
 WITH cte1 AS (
    SELECT
        dp.segment,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN fsm.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN fsm.product_code END) AS product_count_2021
    FROM
        fact_sales_monthly fsm
    JOIN
        dim_product dp ON dp.product_code = fsm.product_code
    GROUP BY dp.segment)

SELECT
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM
    cte1;

--- Request 5: Get the products that have the highest and lowest manufacturing costs.
 --- The final output should contain these fields
 --- product_code
 --- product
 --- manufacturing_cost 
 SELECT
    fmc.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
JOIN
    dim_product dp ON dp.product_code = fmc.product_code
WHERE
    fmc.manufacturing_cost = (
        SELECT MAX(manufacturing_cost)
        FROM fact_manufacturing_cost
    )
    OR fmc.manufacturing_cost = (
        SELECT MIN(manufacturing_cost)
        FROM fact_manufacturing_cost);

 --- Request 6:  Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
 --- The final output contains these fields
 --- customer_code 
 --- customer 
 ---- average_discount_percentage

SELECT
    pre.customer_code,
    dc.customer,
    ROUND(AVG(pre.pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions pre
JOIN
    dim_customer dc ON dc.customer_code=pre.customer_code
WHERE
    pre.fiscal_year = 2021
    AND dc.market = 'India'
GROUP BY
    pre.customer_code,
    dc.customer
ORDER BY
    average_discount_percentage DESC
LIMIT 5;

--- Request 7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
 --- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
 --- The final report contains these columns
 --- Month 
 ---- Year 
 --- Gross sales Amount 
 SELECT
    MONTH(fsm.date) AS sale_month,
    YEAR(fsm.date) AS sale_year,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / 1000000, 2) AS gross_sales_amount_mn
FROM 
    gdb023.fact_sales_monthly fsm
JOIN 
    fact_gross_price fgp 
    ON fgp.product_code = fsm.product_code
    AND fgp.fiscal_year = fsm.fiscal_year
JOIN 
    dim_customer dc 
    ON dc.customer_code = fsm.customer_code
WHERE 
    dc.customer = 'Atliq Exclusive'
GROUP BY 
    YEAR(fsm.date), 
    MONTH(fsm.date)
ORDER BY YEAR(fsm.date),MONTH(fsm.date);

--- Request 8: In which quarter of 2020, got the maximum total_sold_quantity? 
--- The final output contains these fields sorted by the total_sold_quantity 
---- Quarter
 ---- total_sold_quantity
 
 SELECT 
    get_quarter(date) AS Quarter,
    SUM(sold_quantity) / 1000000 AS total_sold_quantity
FROM 
    fact_sales_monthly
WHERE 
    fiscal_year = 2020
GROUP BY 
    get_quarter(date)
ORDER BY 
    total_sold_quantity DESC;

--- Request 9:Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
---- The final output contains these fields, 
--- channel 
---- gross_sales_mln 
----- percentage
SELECT
    dc.channel,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / 1000000, 2) AS gross_sales_amount_Mn,
    ROUND(
        SUM(fsm.sold_quantity * fgp.gross_price) * 100.0 /
        SUM(SUM(fsm.sold_quantity * fgp.gross_price)) OVER (), 
        2
    ) AS percentage
FROM 
    gdb023.fact_sales_monthly fsm
JOIN 
    fact_gross_price fgp 
        ON fgp.product_code = fsm.product_code
        AND fgp.fiscal_year = fsm.fiscal_year
JOIN 
    dim_customer dc 
        ON dc.customer_code = fsm.customer_code
WHERE 
    fsm.fiscal_year = 2021
GROUP BY  
    dc.channel
ORDER BY 
    gross_sales_amount_Mn DESC;

--- Request 10:Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
--- The final output contains these fields, 
---- division 
---- product_code 
---- product total_sold_quantity
---- rank_order
WITH cte1 AS (
    SELECT 
        dp.division,
        fsm.product_code,
        dp.product,
        SUM(sold_quantity) / 1000000 AS total_sold_quantity,
        DENSE_RANK() OVER (
            PARTITION BY dp.division 
            ORDER BY SUM(sold_quantity) / 1000000 DESC) AS rank_order
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_product dp 
            ON dp.product_code = fsm.product_code
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dp.division, 
        fsm.product_code, 
        dp.product)
SELECT *
FROM  cte1
WHERE rank_order <= 3;







