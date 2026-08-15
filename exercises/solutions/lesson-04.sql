-- Λύσεις — Μάθημα 4

-- 1.
SELECT
    COUNT(*)             AS πλήθος,
    ROUND(AVG(price), 2) AS μέση_τιμή,
    MIN(price)           AS ελάχιστη,
    MAX(price)           AS μέγιστη
FROM books;

-- 2.
SELECT
    COUNT(*)             AS πελάτες,
    COUNT(DISTINCT city) AS πόλεις     -- τα NULL δεν μετρώνται
FROM customers;

-- 3.
SELECT category_id, COUNT(*) AS πλήθος
FROM books
GROUP BY category_id
ORDER BY πλήθος DESC;

-- 4.
SELECT category_id, ROUND(AVG(price), 2) AS μέση_τιμή
FROM books
GROUP BY category_id
ORDER BY μέση_τιμή DESC;

-- 5.
SELECT status, COUNT(*) AS πλήθος
FROM orders
GROUP BY status
ORDER BY πλήθος DESC;

-- 6.
SELECT author_id, COUNT(*) AS βιβλία
FROM books
WHERE author_id IS NOT NULL
GROUP BY author_id
HAVING COUNT(*) >= 2
ORDER BY βιβλία DESC;

-- 7.
SELECT
    book_id,
    COUNT(*)              AS κριτικές,
    ROUND(AVG(rating), 2) AS μέση_βαθμολογία
FROM reviews
GROUP BY book_id
HAVING COUNT(*) >= 2
ORDER BY μέση_βαθμολογία DESC;

-- 8.
SELECT customer_id, COUNT(*) AS παραγγελίες
FROM orders
GROUP BY customer_id
ORDER BY παραγγελίες DESC;

-- 9.
SELECT
    STRFTIME('%Y', o.order_date)             AS έτος,
    COUNT(DISTINCT o.id)                     AS παραγγελίες,
    ROUND(SUM(i.quantity * i.unit_price), 2) AS τζίρος
FROM orders o
JOIN order_items i ON i.order_id = o.id
WHERE o.status = 'paid'
GROUP BY έτος
ORDER BY έτος;

-- 10.
SELECT book_id, SUM(quantity) AS τεμάχια
FROM order_items
GROUP BY book_id
ORDER BY τεμάχια DESC
LIMIT 5;

-- 11.
SELECT
    STRFTIME('%Y-%m', o.order_date)          AS μήνας,
    ROUND(SUM(i.quantity * i.unit_price), 2) AS τζίρος
FROM orders o
JOIN order_items i ON i.order_id = o.id
WHERE o.status = 'paid'
GROUP BY μήνας
HAVING SUM(i.quantity * i.unit_price) > 60
ORDER BY τζίρος DESC;

-- 12. Το WHERE εκτελείται ΠΡΙΝ το GROUP BY, άρα δεν υπάρχει ακόμα COUNT(*).
--     Το φιλτράρισμα ομάδων γίνεται με HAVING:
SELECT category_id, COUNT(*) AS πλήθος
FROM books
GROUP BY category_id
HAVING COUNT(*) > 3;
