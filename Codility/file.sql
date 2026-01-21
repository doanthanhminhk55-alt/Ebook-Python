CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount DECIMAL(10, 2)
)
INSERT INTO orders
VALUES (1, 101, '2024-01-05', 100),
    (2, 101, '2024-01-20', 200),
    (3, 101, '2024-01-25', 200),
    (4, 102, '2024-02-10', 300),
    (5, 102, '2024-02-15', 150);
-- CÂU 1 – Đơn hàng lớn nhất mỗi tháng / customer
WITH ranked_orders AS (
    SELECT customer_id,
        DATE_TRUNC('month', order_date) AS year_month,
        order_id,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id,
            DATE_TRUNC("month", order_date)
            ORDER BY amount DESC,
                order_date ASC
        ) AS rn
    FROM orders
)
SELECT customer_id,
    year_month,
    order_id,
    amount
FROM ranked_orders
WHERE rn = 1;
--CÂU 2 – Top 3 lương mỗi phòng ban
WITH ranked_salary AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) as rnk
    FROM employee_salary
)
SELECT *
FROM ranked_salary
WHERE rnk <= 3;
--CÂU 3 – User không order 6 tháng gần nhất
-- | order_id | user_id | order_date |
-- | -------- | ------- | ---------- |
-- | 101      | 1       | 2025-12-01 |
-- | 102      | 2       | 2024-12-01 |
-- | 103      | 3       | 2023-10-01 |
-- | user | Có order 6 tháng gần đây? | Kết quả |
-- | ---- | ------------------------- | ------- |
-- | 1    | ✅ Có (12/2025)            | ❌       |
-- | 2    | ❌ (> 6 tháng)             | ✅       |
-- | 3    | ❌ (> 6 tháng)             | ✅       |
-- | 4    | ❌ Chưa từng order         | ✅       |
SELECT u.user_id
FROM users u
WHERE NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.user_id = u.user_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    );
--CÂU 4 – Gap & Island (login liên tiếp)
-- login_logs
-- +---------+------------+
-- | user_id | login_date |
-- +---------+------------+
-- | 1       | 2024-01-01 |
-- | 1       | 2024-01-02 |
-- | 1       | 2024-01-03 |
-- | 1       | 2024-01-05 |
-- | 1       | 2024-01-06 |
-- +---------+------------+
WITH ranked AS (
    SELECT user_id,
        login_date,
        -- login_date	row_number
        -- 2024-01-01	1
        -- 2024-01-02	2
        -- 2024-01-03	3
        -- 2024-01-05	4
        -- 2024-01-06	5
        login_date - ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY login_date
        ) as grp -- | login_date | rn | login_date - rn |
        -- | ---------- | -- | --------------- |
        -- | 2024-01-01 | 1  | 2023-12-31      |
        -- | 2024-01-02 | 2  | 2023-12-31      |
        -- | 2024-01-03 | 3  | 2023-12-31      |
        -- | 2024-01-05 | 4  | 2024-01-01      |
        -- | 2024-01-06 | 5  | 2024-01-01      |
    FROM login_logs
)
SELECT user_id,
    MIN(login_date) AS start_date,
    MAX(login_date) AS end_date,
    COUNT(*) AS total_days
FROM ranked
GROUP BY user_id,
    grp;
-- CÂU 5 – SỐ DƯ CUỐI MỖI NGÀY (RUNNING BALANCE)
-- | user_id | trans_date | type     | amount |
-- | ------- | ---------- | -------- | ------ |
-- | 1       | 2024-01-01 | DEPOSIT  | 100    |
-- | 1       | 2024-01-02 | WITHDRAW | 30     |
-- | 1       | 2024-01-03 | DEPOSIT  | 50     |
-- | date | biến động | balance |
-- | ---- | --------- | ------- |
-- | 01   | +100      | 100     |
-- | 02   | -30       | 70      |
-- | 03   | +50       | 120     |
SELECT user_id,
    trans_date,
    SUM(
        CASE
            WHEN type = 'DEPOSIT' THEN amount
            ELSE - amount
        END
    ) OVER (
        PARTITION BY user_id
        ORDER BY trans_date
    ) AS balance
FROM transactions;
--CÂU 6 – XÓA RECORD TRÙNG (AN TOÀN)
-- | event_id | user_id | event_time | created_at |
-- | -------- | ------- | ---------- | ---------- |
-- | 1        | 1       | 10:00      | 10:01      |
-- | 2        | 1       | 10:00      | 10:02      |
WITH dup AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id,
            event_time
            ORDER BY created_at
        ) AS rn
    FROM events
)
DELETE FROM events
WHERE event_id in (
        SELECT event_id
        FROM dup
        WHERE rn > 1
    );
--CÂU 7 – RECURSIVE CTE (CÂY CHA–CON)
-- | id | parent_id | name        |
-- | -- | --------- | ----------- |
-- | 1  | NULL      | Electronics |
-- | 2  | 1         | Phone       |
-- | 3  | 2         | iPhone      |
WITH RECURSIVE cte AS(
    SELECT id,
        parent_id,
        name,
        name as path
    FROM categories
    WHERE parent_id IS NULL -- | id | parent_id | name        |
        -- | -- | --------- | ----------- |
        -- | 1  | NULL      | Electronics |
        -- | id | parent_id | name        | path        |
        -- | -- | --------- | ----------- | ----------- |
        -- | 1  | NULL      | Electronics | Electronics |
    SELECT c.id,
        c.parent_id,
        c.name,
        cte.path || '>' || c.name
    FROM categories c
        JOIN cte ON c.parent_id = ctd.id
)
SELECT *
FROM cte;
-- | c.id | c.parent_id | c.name | cte.id | cte.path    |
-- | ---- | ----------- | ------ | ------ | ----------- |
-- | 2    | 1           | Phone  | 1      | Electronics |
--     | id | parent_id | name  | path                |
-- | -- | --------- | ----- | ------------------- |
-- | 2  | 1         | Phone | Electronics > Phone |
--     | id | path                |
-- | -- | ------------------- |
-- | 1  | Electronics         |
-- | 2  | Electronics > Phone |
-- | c.id | c.parent_id | c.name | cte.id | cte.path            |
-- | ---- | ----------- | ------ | ------ | ------------------- |
-- | 3    | 2           | iPhone | 2      | Electronics > Phone |
--     | id | parent_id | name   | path                         |
-- | -- | --------- | ------ | ---------------------------- |
-- | 3  | 2         | iPhone | Electronics > Phone > iPhone |
--     | id | path                         |
-- | -- | ---------------------------- |
-- | 1  | Electronics                  |
-- | 2  | Electronics > Phone          |
-- | 3  | Electronics > Phone > iPhone |
--     | id | parent_id | name        | path                         |
-- | -- | --------- | ----------- | ---------------------------- |
-- | 1  | NULL      | Electronics | Electronics                  |
-- | 2  | 1         | Phone       | Electronics > Phone          |
-- | 3  | 2         | iPhone      | Electronics > Phone > iPhone |
--CÂU 8 – QUERY CHẬM & TỐI ƯU (SARGABLE)
-- | order_id | customer_id | order_date | amount |
-- | -------- | ----------- | ---------- | ------ |
-- | 1        | 123         | 2024-01-05 | 100    |
-- | 2        | 123         | 2024-06-10 | 200    |
-- | 3        | 456         | 2024-03-01 | 150    |
-- | 4        | 123         | 2023-12-31 | 90     |
SELECT *
FROM orders
WHERE order_date >= '2024-01-01'
    AND order_date < '2025-01-01'
    AND customer_id = 123;
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
-- | order_id | customer_id | order_date |
-- | -------- | ----------- | ---------- |
-- | 1        | 123         | 2024-01-05 |
-- | 2        | 123         | 2024-06-10 |
-- | 4        | 123         | 2023-12-31 |
-- CÂU 9 – TRANSACTION + ISOLATION (BANKING / FINANCE)
-- | user_id | balance |
-- | ------- | ------- |
-- | A       | 1000    |
-- | B       | 500     |
-- | Thuộc tính  | Ý nghĩa               |
-- | ----------- | --------------------- |
-- | Atomicity   | Làm hết hoặc rollback |
-- | Consistency | Không phá rule        |
-- | Isolation   | Không bị đụng         |
-- | Durability  | Commit là tồn tại     |
BEGIN;
SELECT *
FROM account
WHERE user_id = 'A' FOR
UPDATE;
UPDATE account
SET balance = balance - 100
WHERE user_id = 'A';
UPDATE account
SET balance = balance + 100
WHERE user_id = 'B';
COMMIT;
--CÂU 10 – ORDERS 100 TRIỆU ROWS (SYSTEM DESIGN)
CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    amount NUMERIC
) PARTITION BY RANGE (order_date);
CREATE TABLE orders_2024_01 PARTITION OF orders FOR
VALUES
FROM ('2024-01-01') TO ('2024-02-01');
SELECT *
FROM orders
WHERE order_date >= '2024-01-01'
    AND order_date < '2024-02-01';
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
monthly_revenue(month DATE, total_amount NUMERIC)
INSERT INTO monthly_revenue
SELECT DATE_TRUNC('month', order_date),
    SUM(amount)
FROM orders GROUP_BY 1;
CREATE MATERIALIZED VIEW monthly_revenue_mv AS
SELECT DATE_TRUNC('month', order_date) AS month,
    SUM(amount) AS total
FROM orders
GROUP BY 1;
REFRESH MATERIALIZED VIEW monthly_revenue_mv;
SELECT *
FROM monthly_revenue_mv;