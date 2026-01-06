--inserting customer data
INSERT INTO core.customer_dim (
    customer_id,
    customer_name,
    segment,
    city,
    state,
    postal_code,
    region, country,
    valid_from,
    is_current)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment,
    city,
    state,
    postal_code,
    region,
    country,
    '2014-01-01'::date,
    TRUE
FROM stage.superstore_raw

--inserting product data
INSERT INTO core.product_dim (product_id, product_name, category, sub_category)
SELECT 
    product_id,
    MAX(product_name),
    MAX(category),
    MAX(sub_category)
FROM stage.superstore_raw
GROUP BY product_id;


--inserting sales data
INSERT INTO core.sales_fact(
    order_id,
    order_date_key,
    customer_key,
    product_key,
    ship_mode,
    quantity,
    sales,
    discount,
    profit
)
SELECT
    r.order_id,
    TO_CHAR(r.order_date, 'YYYYMMDD')::INT,
    c.customer_key,
    p.product_key,
    r.ship_mode,
    r.quantity,
    r.sales,
    r.discount,
    r.profit
FROM stage.superstore_raw as r
JOIN core.customer_dim as c 
on c.customer_id = r.customer_id and c.is_current
JOIN core.product_dim as p
ON p.product_id = r.product_id