-- Λύσεις — Μάθημα 6

-- 1.
SELECT title, price
FROM books
WHERE price > (SELECT AVG(price) FROM books)
ORDER BY price DESC;

-- 2.
SELECT title, price
FROM books
WHERE price = (SELECT MAX(price) FROM books);

-- 3. συσχετισμένο υποερώτημα: για κάθε βιβλίο, ο μέσος όρος ΤΗΣ ΚΑΤΗΓΟΡΙΑΣ ΤΟΥ
SELECT b.title, b.category_id, b.price
FROM books b
WHERE b.price < (
    SELECT AVG(b2.price) FROM books b2 WHERE b2.category_id = b.category_id
)
ORDER BY b.category_id, b.price;

-- 4.
SELECT c.first_name || ' ' || c.last_name AS πελάτης
FROM customers c
WHERE EXISTS (SELECT 1 FROM reviews r WHERE r.customer_id = c.id);

-- 5.
SELECT b.title AS χωρίς_κριτικές
FROM books b
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.book_id = b.id);

-- 6. Τρεις ισοδύναμοι τρόποι. Εδώ δίνουν το ίδιο αποτέλεσμα, επειδή το
--    reviews.book_id είναι NOT NULL. Αν επέτρεπε NULL, το NOT IN θα επέστρεφε
--    ΚΕΝΟ αποτέλεσμα — γι' αυτό προτιμάμε NOT EXISTS.
SELECT title FROM books b WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.book_id = b.id);

SELECT title FROM books WHERE id NOT IN (SELECT book_id FROM reviews);

SELECT b.title
FROM books b
LEFT JOIN reviews r ON r.book_id = b.id
WHERE r.id IS NULL;

-- 7.
WITH σύνολα AS (
    SELECT o.id, SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id
)
SELECT ROUND(AVG(σύνολο), 2) AS μέση_αξία_παραγγελίας FROM σύνολα;

-- 8.
WITH δαπάνες AS (
    SELECT o.customer_id, SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id
)
SELECT
    c.first_name || ' ' || c.last_name AS πελάτης,
    ROUND(d.σύνολο, 2)                 AS ξόδεψε
FROM δαπάνες d
JOIN customers c ON c.id = d.customer_id
WHERE d.σύνολο > 100
ORDER BY d.σύνολο DESC;

-- 9.
WITH πωλήσεις AS (
    SELECT i.book_id, SUM(i.quantity) AS τεμάχια
    FROM order_items i
    JOIN orders o ON o.id = i.order_id
    WHERE o.status = 'paid'
    GROUP BY i.book_id
),
βαθμολογίες AS (
    SELECT book_id, ROUND(AVG(rating), 2) AS μέση, COUNT(*) AS πλήθος
    FROM reviews
    GROUP BY book_id
)
SELECT
    b.title,
    COALESCE(p.τεμάχια, 0)  AS πωλήσεις,
    v.μέση                  AS μέση_βαθμολογία,
    COALESCE(v.πλήθος, 0)   AS κριτικές
FROM books b
LEFT JOIN πωλήσεις    p ON p.book_id = b.id
LEFT JOIN βαθμολογίες v ON v.book_id = b.id
ORDER BY πωλήσεις DESC, μέση_βαθμολογία DESC;

-- 10.
WITH δαπάνες AS (
    SELECT o.customer_id, SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id
)
SELECT
    c.first_name || ' ' || c.last_name AS καλύτερος_πελάτης,
    ROUND(d.σύνολο, 2)                 AS ξόδεψε
FROM δαπάνες d
JOIN customers c ON c.id = d.customer_id
ORDER BY d.σύνολο DESC
LIMIT 1;

-- 11.
WITH πωλήσεις AS (
    SELECT book_id, SUM(quantity) AS τεμάχια
    FROM order_items
    GROUP BY book_id
)
SELECT b.title, p.τεμάχια
FROM πωλήσεις p
JOIN books b ON b.id = p.book_id
WHERE p.τεμάχια > (SELECT AVG(τεμάχια) FROM πωλήσεις)
ORDER BY p.τεμάχια DESC;

-- 12.
SELECT 'πελάτης'   AS τύπος, first_name || ' ' || last_name AS όνομα FROM customers
UNION ALL
SELECT 'υπάλληλος' AS τύπος, name                            AS όνομα FROM employees
ORDER BY τύπος, όνομα;

-- 13.
WITH RECURSIVE ιεραρχία AS (
    SELECT id, name, manager_id, 0 AS επίπεδο
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, ι.επίπεδο + 1
    FROM employees e
    JOIN ιεραρχία ι ON ι.id = e.manager_id
)
SELECT SUBSTR('                    ', 1, επίπεδο * 3) || name AS οργανόγραμμα, επίπεδο
FROM ιεραρχία
ORDER BY επίπεδο, name;
