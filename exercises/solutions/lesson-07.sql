-- Λύσεις — Μάθημα 7

-- 1.
SELECT
    title,
    category_id,
    price,
    ROUND(AVG(price) OVER (PARTITION BY category_id), 2) AS μέση_κατηγορίας
FROM books
ORDER BY category_id, price DESC;

-- 2.
WITH σύγκριση AS (
    SELECT
        title,
        category_id,
        price,
        ROUND(price - AVG(price) OVER (PARTITION BY category_id), 2) AS διαφορά
    FROM books
)
SELECT * FROM σύγκριση
WHERE διαφορά > 0
ORDER BY διαφορά DESC;

-- 3.
SELECT
    title,
    price,
    RANK() OVER (ORDER BY price DESC) AS κατάταξη
FROM books
ORDER BY κατάταξη;

-- 4.
WITH κατάταξη AS (
    SELECT
        b.title,
        c.name AS κατηγορία,
        b.price,
        ROW_NUMBER() OVER (PARTITION BY b.category_id ORDER BY b.price DESC) AS σειρά
    FROM books b
    JOIN categories c ON c.id = b.category_id
)
SELECT κατηγορία, title, price
FROM κατάταξη
WHERE σειρά = 1
ORDER BY price DESC;

-- 5.
WITH πρόσφατες AS (
    SELECT
        o.id,
        o.customer_id,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS σειρά
    FROM orders o
)
SELECT
    c.first_name || ' ' || c.last_name AS πελάτης,
    p.order_date,
    p.σειρά
FROM πρόσφατες p
JOIN customers c ON c.id = p.customer_id
WHERE p.σειρά <= 3
ORDER BY πελάτης, p.order_date DESC;

-- 6.
WITH έσοδα AS (
    SELECT
        b.title,
        SUM(i.quantity * i.unit_price) AS ποσό
    FROM order_items i
    JOIN orders o ON o.id = i.order_id
    JOIN books  b ON b.id = i.book_id
    WHERE o.status = 'paid'
    GROUP BY b.id, b.title
)
SELECT
    title,
    ROUND(ποσό, 2)                                  AS έσοδα,
    ROUND(ποσό * 100.0 / SUM(ποσό) OVER (), 2)      AS ποσοστό,
    ROUND(SUM(ποσό) OVER (ORDER BY ποσό DESC) * 100.0
          / SUM(ποσό) OVER (), 2)                   AS αθροιστικό_ποσοστό
FROM έσοδα
ORDER BY ποσό DESC;

-- 7.
WITH ανά_μήνα AS (
    SELECT
        STRFTIME('%Y-%m', o.order_date) AS μήνας,
        SUM(i.quantity * i.unit_price)  AS τζίρος
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY μήνας
)
SELECT
    μήνας,
    ROUND(τζίρος, 2)                                     AS τζίρος,
    ROUND(LAG(τζίρος) OVER (ORDER BY μήνας), 2)          AS προηγούμενος,
    ROUND(τζίρος - LAG(τζίρος) OVER (ORDER BY μήνας), 2) AS μεταβολή
FROM ανά_μήνα
ORDER BY μήνας;

-- 8.
WITH ανά_μήνα AS (
    SELECT
        STRFTIME('%Y-%m', o.order_date) AS μήνας,
        SUM(i.quantity * i.unit_price)  AS τζίρος
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY μήνας
)
SELECT
    μήνας,
    ROUND(τζίρος, 2)                            AS τζίρος,
    ROUND(SUM(τζίρος) OVER (ORDER BY μήνας), 2) AS αθροιστικά
FROM ανά_μήνα
ORDER BY μήνας;

-- 9.
SELECT
    c.first_name || ' ' || c.last_name AS πελάτης,
    o.order_date,
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS αγορά_νο,
    CAST(JULIANDAY(o.order_date)
         - JULIANDAY(LAG(o.order_date) OVER (PARTITION BY o.customer_id
                                             ORDER BY o.order_date)) AS INTEGER) AS μέρες_από_προηγούμενη
FROM orders o
JOIN customers c ON c.id = o.customer_id
ORDER BY πελάτης, o.order_date;

-- 10.
SELECT
    title,
    price,
    NTILE(4) OVER (ORDER BY price DESC) AS τεταρτημόριο
FROM books
ORDER BY price DESC;

-- 11. Οι window functions υπολογίζονται ΜΕΤΑ το WHERE, άρα το "σειρά" δεν υπάρχει
--     ακόμα εκεί. Η λύση είναι CTE (ή υποερώτημα) και φιλτράρισμα ένα επίπεδο έξω:
WITH κατάταξη AS (
    SELECT title, price, ROW_NUMBER() OVER (ORDER BY price DESC) AS σειρά
    FROM books
)
SELECT * FROM κατάταξη WHERE σειρά <= 3;
