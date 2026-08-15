-- Λύσεις — Μάθημα 3

-- 1.
SELECT title, price FROM books ORDER BY price ASC LIMIT 5;

-- 2.
SELECT title, published_year FROM books ORDER BY published_year ASC LIMIT 3;

-- 3.
SELECT category_id, title, price
FROM books
ORDER BY category_id ASC, price DESC;

-- 4.
SELECT DISTINCT city FROM customers WHERE city IS NOT NULL ORDER BY city;

-- 5. Το "country IS NULL" δίνει 0/1 και ταξινομεί πρώτα τα μη κενά
SELECT DISTINCT country FROM authors ORDER BY country IS NULL, country;

-- 6.
SELECT title, price FROM books ORDER BY price DESC LIMIT 5 OFFSET 5;

-- 7.
SELECT title, stock, price, ROUND(stock * price, 2) AS αξία_αποθέματος
FROM books
ORDER BY αξία_αποθέματος DESC
LIMIT 3;

-- 8.
SELECT
    title,
    published_year,
    CASE
        WHEN published_year < 1900 THEN 'κλασικό'
        WHEN published_year < 1980 THEN '20ός αιώνας'
        ELSE 'σύγχρονο'
    END AS εποχή
FROM books
ORDER BY published_year;

-- 9.
SELECT id, order_date, status
FROM orders
ORDER BY
    CASE status
        WHEN 'pending'   THEN 1
        WHEN 'paid'      THEN 2
        WHEN 'cancelled' THEN 3
    END,
    order_date DESC;

-- 10.
SELECT
    title,
    LENGTH(title) AS μήκος,
    UPPER(title)  AS κεφαλαία
FROM books
ORDER BY μήκος DESC
LIMIT 5;

-- 11.
SELECT
    id,
    order_date,
    STRFTIME('%Y', order_date) AS έτος,
    STRFTIME('%m', order_date) AS μήνας
FROM orders
ORDER BY order_date;
