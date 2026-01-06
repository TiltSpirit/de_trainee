-- dimension table with customers info
drop table if EXISTS core.customer_dim cascade;
CREATE TABLE core.customer_dim (
    customer_key serial primary key,
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(50),
    region VARCHAR(50),
    valid_from DATE default current_date,
    valid_to DATE default '2121-12-21',
    is_current boolean default TRUE
);

-- dimension table with product info
DROP TABLE if EXISTS core.product_dim cascade;
CREATE TABLE core.product_dim (
    product_key serial primary key,
    product_id VARCHAR(50) unique not NULL,
    product_name TEXT,
    category VARCHAR(50),
    sub_category VARCHAR(50)
);

--dimension table with dates, seems like everyone is doing it
CREATE TABLE core.date_dim (
    date_key INT PRIMARY KEY,
    date_actual DATE,
    year SMALLINT,
    quarter SMALLINT,
    month SMALLINT,
    month_name TEXT,
    day_of_month SMALLINT,
    day_of_week SMALLINT
);

INSERT INTO core.date_dim
WITH dates AS (
    SELECT generate_series('2014-01-01'::date, '2034-12-31'::date, '1 day'::interval) AS d
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TO_CHAR(d, 'Month'),
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(DOW FROM d) + 1
FROM dates;

--fact table
DROP TABLE IF EXISTS core.sales_fact CASCADE;
CREATE TABLE core.sales_fact (
    sales_key serial PRIMARY KEY,
    order_id VARCHAR(30),
    order_date_key INT REFERENCES core.date_dim(date_key),
    customer_key INT REFERENCES core.customer_dim(customer_key),
    product_key INT REFERENCES core.product_dim(product_key),
    ship_mode VARCHAR(50),
    quantity INT,
    sales DECIMAL(10,4),
    discount DECIMAL(6,4),
    profit DECIMAL(10,4)
);


--mart layer
DROP TABLE IF EXISTS mart.superstore_sales;
CREATE TABLE mart.superstore_sales AS
SELECT
    f.order_id AS order_id,
    d.date_actual AS order_date,
    d.year AS order_year,
    d.month_name AS order_month,
    d.quarter AS order_quarter,
    EXTRACT(DAY FROM d.date_actual) AS order_day,
    c.customer_id AS customer_id,
    c.customer_name AS customer_name,
    c.segment AS customer_segment,
    c.city AS customer_city,
    c.state AS customer_state,
    c.region AS customer_region,
    p.product_id AS product_id,
    p.product_name AS product_name,
    p.category AS product_category,
    p.sub_category AS product_subcategory,
    f.ship_mode AS ship_mode,
    f.quantity AS quantity_ordered,
    f.sales AS unit_price,
    f.discount AS discount_rate,
    f.profit AS profit
FROM core.sales_fact as f
JOIN core.date_dim as d ON d.date_key = f.order_date_key
JOIN core.customer_dim as c ON c.customer_key = f.customer_key AND c.is_current
JOIN core.product_dim as p ON p.product_key  = f.product_key;