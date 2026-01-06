CREATE SCHEMA stage;
CREATE SCHEMA core;
CREATE SCHEMA mart;

create TABLE IF NOT EXISTS  stage.superstore_raw (
    row_id int primary key,
    order_id VARCHAR(30),
    order_date DATE,
    ship_date date,
    ship_mode VARCHAR(50),
    customer_id  VARCHAR(50),
    customer_name VARCHAR(50),
    segment VARCHAR(30),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(30),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name TEXT,
    sales DECIMAL(10, 4),
    quantity int,
    discount DECIMAL(6, 4),
    profit DECIMAL(10, 4)
);

--importing data
SET DateStyle = 'ISO, MDY';
COPY stage.superstore_raw FROM 'D:/WORK/datasets/Sample - Superstore.csv' 
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'LATIN1');

--for incremental loads i guess
CREATE table stage.superstore_incremental as table stage.superstore_raw with no data;