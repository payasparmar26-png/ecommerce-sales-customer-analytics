# E-Commerce Sales & Customer Analytics

A portfolio analytics project built with **MySQL and Power BI** to analyze e-commerce sales, product performance, customer behavior, and regional performance.

## Project Overview

The project uses a relational MySQL database containing synthetic Indian e-commerce data for 2024–2025 and a Power BI dashboard for interactive analysis.

### Technology Stack
- MySQL 8+
- Power BI Desktop
- DAX
- SQL

## Database Schema

The database `ecommerce_analytics` contains:

- `customers` — customer demographics, location, registration and segment
- `categories` — product categories
- `products` — product, brand, pricing, stock and rating information
- `orders` — order dates, status, shipping location and order-level costs
- `order_items` — products, quantities, prices and discounts per order
- `payments` — payment method, status and transaction amount
- `shipping` — courier, method and delivery information

Power BI uses two analytical views:
- `vw_sales_fact`
- `vw_customer_summary`

## SQL Analysis

The SQL scripts demonstrate:

- Joins and aggregations
- GROUP BY / HAVING
- CTEs
- CASE expressions
- Subqueries
- Date-based analysis
- Window functions such as `LAG`, `DENSE_RANK` and running totals
- Data-quality and KPI queries
- Product, customer, regional, payment and shipping analysis
- Power BI-ready views

## Power BI Dashboard

### Page 1 — Executive Overview
- Total Revenue
- Total Orders
- Total Customers
- Total Units Sold
- Average Order Value
- Monthly Revenue Trend
- Revenue by Category

### Page 2 — Product & Sales Analysis
- Revenue by Category
- Units Sold by Category
- Top 10 Products by Revenue
- Revenue by Brand
- Order Status Distribution

### Page 3 — Customer Analysis
- Customers by Segment
- Revenue by Customer Segment
- Top 10 Customers by Revenue
- Revenue by State
- Orders by Customer Segment

## Data

The dataset is synthetic and intended for portfolio/demo purposes. It does not represent real customers or transactions.

## How to Run

1. Open MySQL Workbench.
2. Run `sql/01_schema.sql`.
3. Run `sql/02_seed_data.sql`.
4. Run `sql/03_business_analysis.sql` to create the analysis queries and Power BI views.
5. Open the `.pbix` file in `powerbi/` using Power BI Desktop.
6. Update the MySQL connection credentials if required.

## Portfolio Skills Demonstrated

**SQL:** relational modeling, foreign keys, joins, aggregations, CTEs, window functions, views and analytical queries.

**Power BI:** data connection, DAX measures, KPI cards, time-series analysis, category/product analysis, customer segmentation and geographic analysis.

## Author

Payas Parmar
