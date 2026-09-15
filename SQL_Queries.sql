
-- The total number of orders by shipping month, sorted from most recent to oldest

SELECT COUNT(DISTINCT order_id) as total_order, date_trunc(ship_ts, month) as shipping_month
FROM core.order_status
GROUP BY shipping_month 
ORDER BY shipping_month desc;


-- Create a helper column `is_refund` in the `order_status` table that returns 1 if there is a refund, 0 if not. Return the first 20 records.

SELECT *, 
  CASE
  WHEN refund_ts is null then 0
  ELSE 1 
  END as is_refund
FROM `core.order_status`
LIMIT 20;

--The order count, sales and aov for Macbooks sold in North America for each quarter across all years

SELECT date_trunc(purchase_ts,quarter) as quarter, 
COUNT(orders.id) as order_count, 
round(sum(orders.usd_price),2) as sales, 
round(avg(orders.usd_price),2) as aov 
FROM core.orders 
LEFT JOIN core.customers_orig
  on orders.customer_id = customers_orig.id 
LEFT JOIN core.geo_lookup 
  on geo_lookup.country_code = customers_orig.country_code
WHERE lower(orders.product_name) like 'macbook%' and geo_lookup.region = 'NA'
GROUP BY quarter
ORDER BY 1 desc;

--The average quarterly order count and total sales for Macbooks sold in North America 

WITH Quarterly_order AS (
SELECT date_trunc(purchase_ts, quarter) as quarter, 
COUNT(*) as order_count, 
round(sum(usd_price),2) as total_sales
FROM core.orders co
LEFT JOIN core.customers cc
  on co.customer_id = cc.id
LEFT JOIN core.geo_lookup cg
  on cc.country_code = cg.country_code
WHERE lower(co.product_name) like '%macbook%' and region='NA'
GROUP BY 1
ORDER BY 1
)

SELECT avg(order_count) as avg_quarterly_order_count,
avg(total_sales) as avg_total_sales
FROM Quarterly_order;


-- The region with the average highest time to deliver for products purchased in 2022 on the website or products purchased on mobile in any year.

SELECT  region, round(avg(date_diff(os.delivery_ts,os.purchase_ts,day)),2) as avg_delivery_time
FROM core.order_status os
LEFT JOIN core.orders co
  on os.order_id = co.id
LEFT JOIN `core.customers` cc
  on co.customer_id = cc.id
LEFT JOIN core.geo_lookup gl
  on cc.country_code = gl.country_code
WHERE (extract(year from os.purchase_ts)  = 2022 and purchase_platform = 'website') or
purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 desc;


-- Website purchases made in 2022 or Samsung purchases made in 2021, with time to deliver in weeks.

SELECT  region, round(avg(date_diff(os.delivery_ts,os.purchase_ts,week)),2) as avg_delivery_time
FROM core.order_status os
LEFT JOIN core.orders co
  on os.order_id = co.id
LEFT JOIN `core.customers` cc
  on co.customer_id = cc.id
LEFT JOIN core.geo_lookup gl
  on cc.country_code = gl.country_code
WHERE (extract(year FROM os.purchase_ts)  = 2022 AND purchase_platform = 'website') OR
(product_name LIKE '%Samsung%' AND extract(year FROM os.purchase_ts)  = 2021)
GROUP BY 1
ORDER BY 2 DESC;


-- The refund rate and refund count for each product overall 

SELECT CASE 
        WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name 
      END as product_clean,
        sum(CASE WHEN refund_ts is not null THEN 1 ELSE 0 END) as refunds,
    avg(CASE WHEN refund_ts is not null THEN 1 ELSE 0 END) as refund_rate
FROM core.orders 
LEFT JOIN core.order_status 
    on orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 desc;


-- The refund rate and refund count for each product per year.

SELECT extract(year FROM orders.purchase_ts) as purchase_year,
      CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
      SUM(CASE WHEN refund_ts is not null THEN 1 ELSE 0 END) AS refunds,
      AVG(CASE WHEN refund_ts is not null THEN 1 ELSE 0 END) AS refund_rate
  FROM core.orders 
  LEFT JOIN core.order_status 
      on orders.id = order_status.order_id
  GROUP BY 1,2
  ORDER BY 3 desc;


--  The most popular product Within each region. 

WITH popular_product AS (SELECT region, CASE WHEN product_name =  '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name 
  END as product_name, COUNT(DISTINCT co.id) as order_count
FROM core.geo_lookup gl
LEFT JOIN core.customers cc
  ON gl.country_code = cc.country_code
LEFT JOIN core.orders co
  ON cc.id = co.customer_id
  GROUP BY 1, 2)

SELECT *, 
row_number() over(partition BY region ORDER BY order_count DESC ) AS popularity
FROM popular_product
qualify row_number() over(partition BY region ORDER BY order_count DESC )  =1;
--qualify is the WHERE for window functions


-- Time to make a purchase difference between loyalty customers vs. non-loyalty customers.

SELECT customers.loyalty_program, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, DAY)),1) AS days_to_purchase,
  round(avg(date_diff(orders.purchase_ts, customers.created_on, MONTH)),1) AS months_to_purchase
FROM core.customers
LEFT JOIN core.orders
  ON customers.id = orders.customer_id
GROUP BY 1;



