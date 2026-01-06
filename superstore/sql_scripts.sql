--to handle cases of data changing after secondary load
begin;
truncate stage.superstore_incremental;
--used ai to generate incremental testing sample
COPY stage.superstore_incremental FROM 'D:/WORK/datasets/Superstore_inc.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'LATIN1');

WITH incremental as (
    SELECT *,
        row_number() over (PARTITION BY order_id, product_id ORDER BY row_id) as rn
    FROM stage.superstore_incremental
),

deduplication AS(
    SELECT *
    FROM incremental
    WHERE rn = 1
),

current AS (
    SELECT c.*
    FROM core.customer_dim as c
    WHERE c.is_current
),

-- for deciding the update type
changes AS (
    SELECT 
        d.*,
        c.customer_key AS previous_key,
        CASE WHEN c.customer_key IS NOT NULL
            AND (d.customer_name <> c.customer_name or d.segment <> c.segment)
            AND d.city = c.city AND d.state = c.state AND d.region = c.region
            THEN 'SCD1'
            WHEN c.customer_key IS NOT NULL
            AND (d.city <> c.city OR d.state <> c.state OR d.region <> c.region)
            THEN 'SCD2'
            WHEN c.customer_key IS NULL THEN 'NEW'
            ELSE 'NO_CHANGE'
        END AS change_type
    FROM deduplication as d
    LEFT JOIN current c ON c.customer_id = d.customer_id
),

-- SCD Type 1
upd_scd1 AS (
    UPDATE core.customer_dim as cu
    SET customer_name = ch.customer_name,
        segment = ch.segment
    FROM changes as ch
    WHERE cu.customer_key = ch.previous_key
    AND ch.change_type = 'SCD1'
),

-- SCD Type 2, firstly changing the old records
old_scd2 AS (
    UPDATE core.customer_dim cu
    SET is_current = FALSE,
        valid_to   = ch.order_date - INTERVAL '1 day' --seems like a standart move for DWH
    FROM changes as ch
    WHERE cu.customer_key = ch.previous_key
    AND ch.change_type = 'SCD2'
),

-- SCD Type 2 new records
new_scd2 AS (
    INSERT INTO core.customer_dim (
        customer_id, customer_name, segment, country, city, state, postal_code, region,
        valid_from, valid_to, is_current
    )
    SELECT 
        customer_id, customer_name, segment, country, city, state, postal_code, region,
        order_date, '9999-12-31', TRUE
    FROM changes
    WHERE change_type = 'SCD2'
    RETURNING customer_key, customer_id
),

new_customers AS (
    INSERT INTO core.customer_dim (
        customer_id, customer_name, segment,
        country, city, state, postal_code,
        region, valid_from, is_current
    )
    SELECT 
        customer_id, customer_name, segment,
        country, city, state, postal_code,
        region, order_date, TRUE
    FROM changes
    WHERE change_type = 'NEW'
    RETURNING customer_key, customer_id
),

new_products AS (
    INSERT INTO core.product_dim (product_id, product_name, category, sub_category)
    SELECT DISTINCT product_id, product_name, category, sub_category
    FROM deduplication
    WHERE product_id NOT IN (
        SELECT product_id 
        FROM core.product_dim 
        WHERE product_id IS NOT NULL)
    ON CONFLICT (product_id) DO NOTHING
),

-- finally adding only new records
final_facts AS (
    INSERT INTO core.sales_fact (
        order_id, order_date_key,
        customer_key, product_key,
        ship_mode, quantity, sales, discount, profit
    )
    SELECT 
        d.order_id,
        TO_CHAR(d.order_date, 'YYYYMMDD')::INT,
        COALESCE(c.customer_key, nc.customer_key, ns.customer_key) AS customer_key,
        p.product_key,
        d.ship_mode, d.quantity, d.sales, d.discount, d.profit
    FROM deduplication as d
    JOIN core.product_dim as p ON p.product_id = d.product_id
    LEFT JOIN core.customer_dim as c ON c.customer_id = d.customer_id AND c.is_current
    LEFT JOIN new_customers as nc ON nc.customer_id = d.customer_id
    LEFT JOIN new_scd2 as ns ON ns.customer_id = d.customer_id
    WHERE NOT EXISTS (
        SELECT 1 FROM core.sales_fact as f
        WHERE f.order_id = d.order_id 
        AND f.product_key = p.product_key
    )
)
SELECT 'Core layer uopdated successfully' AS status;
--remaking the mart layer
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

COMMIT;