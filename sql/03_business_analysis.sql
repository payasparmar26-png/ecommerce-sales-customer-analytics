-- =========================================================
-- E-COMMERCE SALES & CUSTOMER ANALYTICS
-- BUSINESS ANALYSIS QUERIES
-- MySQL 8+
-- =========================================================

USE ecommerce_analytics;

-- =========================================================
-- SECTION 1: DATA QUALITY / OVERVIEW
-- =========================================================

-- 1. Row counts
SELECT 'Customers' AS table_name, COUNT(*) AS records FROM customers
UNION ALL SELECT 'Categories', COUNT(*) FROM categories
UNION ALL SELECT 'Products', COUNT(*) FROM products
UNION ALL SELECT 'Orders', COUNT(*) FROM orders
UNION ALL SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL SELECT 'Payments', COUNT(*) FROM payments
UNION ALL SELECT 'Shipping', COUNT(*) FROM shipping;


-- 2. Overall order status distribution
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY orders DESC;


-- 3. Payment status distribution
SELECT
    payment_status,
    COUNT(*) AS payments,
    ROUND(SUM(amount), 2) AS payment_value
FROM payments
GROUP BY payment_status
ORDER BY payment_value DESC;


-- =========================================================
-- SECTION 2: CORE SALES KPIs
-- =========================================================

-- 4. Total revenue from completed sales
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned');


-- 5. Total orders, customers and units sold
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(oi.quantity) AS units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned');


-- 6. Average Order Value (AOV)
WITH order_totals AS (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price - oi.item_discount)
        - o.discount_amount
        + o.shipping_cost AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY o.order_id, o.discount_amount, o.shipping_cost
)
SELECT ROUND(AVG(order_value), 2) AS average_order_value
FROM order_totals;


-- 7. Monthly revenue trend
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


-- 8. Monthly orders and revenue
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


-- =========================================================
-- SECTION 3: PRODUCT ANALYSIS
-- =========================================================

-- 9. Top 10 products by revenue
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue,
    SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY revenue DESC
LIMIT 10;


-- 10. Category performance
SELECT
    c.category_name,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC;


-- 11. Product gross margin
SELECT
    p.product_name,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - p.cost_price) - oi.item_discount),
        2
    ) AS gross_margin
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name
ORDER BY gross_margin DESC
LIMIT 15;


-- 12. Products with low stock
SELECT
    product_id,
    product_name,
    stock_quantity,
    price
FROM products
WHERE stock_quantity < 30
  AND is_active = TRUE
ORDER BY stock_quantity;


-- =========================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- =========================================================

-- 13. Top 10 customers by lifetime revenue
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    c.state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY c.customer_id, customer_name, c.city, c.state
ORDER BY lifetime_value DESC
LIMIT 10;


-- 14. Repeat customers
SELECT
    customer_id,
    COUNT(*) AS completed_orders
FROM orders
WHERE order_status NOT IN ('Cancelled', 'Returned')
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY completed_orders DESC;


-- 15. Customer segmentation by order frequency
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    WHERE order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat'
        WHEN order_count BETWEEN 5 AND 9 THEN 'Loyal'
        ELSE 'VIP'
    END AS customer_segment,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat'
        WHEN order_count BETWEEN 5 AND 9 THEN 'Loyal'
        ELSE 'VIP'
    END
ORDER BY customers DESC;


-- 16. Customer lifetime value
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY c.customer_id, customer_name
ORDER BY lifetime_value DESC;


-- =========================================================
-- SECTION 5: REGIONAL ANALYSIS
-- =========================================================

-- 17. Revenue by state
SELECT
    o.shipping_state AS state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY o.shipping_state
ORDER BY revenue DESC;


-- 18. Revenue by city
SELECT
    o.shipping_city AS city,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY o.shipping_city
ORDER BY revenue DESC
LIMIT 15;


-- =========================================================
-- SECTION 6: PAYMENT & OPERATIONS
-- =========================================================

-- 19. Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS transactions,
    ROUND(SUM(amount), 2) AS transaction_value
FROM payments
WHERE payment_status = 'Completed'
GROUP BY payment_method
ORDER BY transaction_value DESC;


-- 20. Delivery performance by courier
SELECT
    courier,
    COUNT(*) AS shipments,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    SUM(CASE WHEN shipping_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered
FROM shipping
GROUP BY courier
ORDER BY avg_delivery_days;


-- 21. Delayed shipments
SELECT
    s.order_id,
    s.courier,
    s.expected_delivery_date,
    s.actual_delivery_date,
    DATEDIFF(s.actual_delivery_date, s.expected_delivery_date) AS days_late
FROM shipping s
WHERE s.actual_delivery_date > s.expected_delivery_date
ORDER BY days_late DESC;


-- =========================================================
-- SECTION 7: ADVANCED SQL / WINDOW FUNCTIONS
-- =========================================================

-- 22. Rank products within each category
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        SUM(oi.quantity * oi.unit_price - oi.item_discount) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY p.product_id, p.product_name, p.category_id
)
SELECT
    pr.product_name,
    c.category_name,
    ROUND(pr.revenue, 2) AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY pr.category_id
        ORDER BY pr.revenue DESC
    ) AS category_rank
FROM product_revenue pr
JOIN categories c ON pr.category_id = c.category_id
ORDER BY c.category_name, category_rank;


-- 23. Monthly revenue with month-over-month growth
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price - oi.item_discount) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_percentage
FROM growth
ORDER BY month;


-- 24. Running cumulative revenue
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price - oi.item_discount) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY month),
        2
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;


-- 25. Top 3 customers in every state
WITH customer_state_sales AS (
    SELECT
        c.state,
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(oi.quantity * oi.unit_price - oi.item_discount) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.state, c.customer_id, customer_name
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY state
            ORDER BY revenue DESC
        ) AS customer_rank
    FROM customer_state_sales
)
SELECT
    state,
    customer_name,
    ROUND(revenue, 2) AS revenue,
    customer_rank
FROM ranked
WHERE customer_rank <= 3
ORDER BY state, customer_rank;


-- 26. 3-month moving average of revenue
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price - oi.item_discount) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_avg
FROM monthly_sales
ORDER BY month;


-- =========================================================
-- SECTION 8: VIEWS FOR POWER BI
-- =========================================================

-- Sales fact view
CREATE OR REPLACE VIEW vw_sales_fact AS
SELECT
    o.order_id,
    o.order_date,
    o.customer_id,
    o.order_status,
    o.shipping_city,
    o.shipping_state,
    p.product_id,
    p.product_name,
    p.brand,
    c.category_name,
    oi.quantity,
    oi.unit_price,
    oi.item_discount,
    ROUND(
        oi.quantity * oi.unit_price - oi.item_discount,
        2
    ) AS line_revenue,
    ROUND(
        oi.quantity * (oi.unit_price - p.cost_price) - oi.item_discount,
        2
    ) AS line_gross_margin
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned');


-- Customer summary view
CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.gender,
    c.city,
    c.state,
    c.registration_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(
        ROUND(SUM(oi.quantity * oi.unit_price - oi.item_discount), 2),
        0
    ) AS lifetime_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status NOT IN ('Cancelled', 'Returned')
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_id,
    customer_name,
    c.gender,
    c.city,
    c.state,
    c.registration_date;


-- Verify views
SELECT * FROM vw_sales_fact LIMIT 10;
SELECT * FROM vw_customer_summary LIMIT 10;
