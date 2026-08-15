-- Λύσεις — Μάθημα 10

-- 1. Μηνιαία αναφορά
WITH σύνολα AS (
    SELECT
        o.id,
        STRFTIME('%Y-%m', o.order_date) AS μήνας,
        SUM(i.quantity)                 AS τεμάχια,
        SUM(i.quantity * i.unit_price)  AS ποσό
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, μήνας
)
SELECT
    μήνας,
    COUNT(*)             AS παραγγελίες,
    SUM(τεμάχια)         AS τεμάχια,
    ROUND(SUM(ποσό), 2)  AS τζίρος,
    ROUND(AVG(ποσό), 2)  AS μέση_παραγγελία
FROM σύνολα
GROUP BY μήνας
ORDER BY μήνας;

-- 2. Κατάταξη πελατών
WITH σύνολα AS (
    SELECT
        o.id,
        o.customer_id,
        o.order_date,
        SUM(i.quantity * i.unit_price) AS ποσό
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, o.customer_id, o.order_date
),
ανά_πελάτη AS (
    SELECT
        customer_id,
        COUNT(*)        AS παραγγελίες,
        SUM(ποσό)       AS τζίρος,
        AVG(ποσό)       AS μέση,
        MIN(order_date) AS πρώτη,
        MAX(order_date) AS τελευταία
    FROM σύνολα
    GROUP BY customer_id
)
SELECT
    c.first_name || ' ' || c.last_name        AS πελάτης,
    COALESCE(a.παραγγελίες, 0)                AS παραγγελίες,
    ROUND(COALESCE(a.τζίρος, 0), 2)           AS τζίρος,
    ROUND(a.μέση, 2)                          AS μέση_παραγγελία,
    a.πρώτη,
    a.τελευταία,
    CAST(JULIANDAY('2025-08-15') - JULIANDAY(a.τελευταία) AS INTEGER) AS μέρες_αδράνειας
FROM customers c
LEFT JOIN ανά_πελάτη a ON a.customer_id = c.id
ORDER BY τζίρος DESC;

-- 3. Ανάλυση καταλόγου
WITH πωλήσεις AS (
    SELECT
        b.category_id,
        SUM(i.quantity)                AS τεμάχια,
        SUM(i.quantity * i.unit_price) AS τζίρος
    FROM order_items i
    JOIN orders o ON o.id = i.order_id AND o.status = 'paid'
    JOIN books  b ON b.id = i.book_id
    GROUP BY b.category_id
),
κατάλογος AS (
    SELECT category_id, COUNT(*) AS τίτλοι, AVG(price) AS μέση_τιμή
    FROM books
    GROUP BY category_id
)
SELECT
    c.name                              AS κατηγορία,
    COALESCE(k.τίτλοι, 0)               AS τίτλοι,
    ROUND(k.μέση_τιμή, 2)               AS μέση_τιμή,
    COALESCE(p.τεμάχια, 0)              AS τεμάχια,
    ROUND(COALESCE(p.τζίρος, 0), 2)     AS τζίρος,
    ROUND(COALESCE(p.τζίρος, 0) * 100.0
          / (SELECT SUM(τζίρος) FROM πωλήσεις), 1) AS ποσοστό_τζίρου
FROM categories c
LEFT JOIN κατάλογος k ON k.category_id = c.id
LEFT JOIN πωλήσεις  p ON p.category_id = c.id
ORDER BY τζίρος DESC;

-- 4. Απόδοση συγγραφέων
WITH πωλήσεις AS (
    SELECT
        b.author_id,
        COUNT(DISTINCT b.id)           AS τίτλοι,
        SUM(i.quantity)                AS τεμάχια,
        SUM(i.quantity * i.unit_price) AS τζίρος
    FROM books b
    JOIN order_items i ON i.book_id = b.id
    JOIN orders      o ON o.id = i.order_id AND o.status = 'paid'
    WHERE b.author_id IS NOT NULL
    GROUP BY b.author_id
),
βαθμοί AS (
    SELECT b.author_id, AVG(r.rating) AS μέση, COUNT(*) AS κριτικές
    FROM reviews r
    JOIN books b ON b.id = r.book_id
    WHERE b.author_id IS NOT NULL
    GROUP BY b.author_id
)
SELECT
    a.name                          AS συγγραφέας,
    COALESCE(p.τίτλοι, 0)           AS τίτλοι_με_πωλήσεις,
    COALESCE(p.τεμάχια, 0)          AS τεμάχια,
    ROUND(COALESCE(p.τζίρος, 0), 2) AS τζίρος,
    ROUND(v.μέση, 2)                AS μέση_βαθμολογία,
    COALESCE(v.κριτικές, 0)         AS κριτικές
FROM authors a
LEFT JOIN πωλήσεις p ON p.author_id = a.id
LEFT JOIN βαθμοί   v ON v.author_id = a.id
ORDER BY τζίρος DESC;

-- 5. Ακίνητο απόθεμα
SELECT
    b.title,
    b.stock,
    b.price,
    ROUND(b.stock * b.price, 2) AS δεσμευμένο_κεφάλαιο
FROM books b
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items i
    JOIN orders o ON o.id = i.order_id
    WHERE i.book_id = b.id AND o.status = 'paid'
)
ORDER BY δεσμευμένο_κεφάλαιο DESC;

-- 6. Top-2 ανά κατηγορία
WITH έσοδα AS (
    SELECT
        b.id,
        b.title,
        b.category_id,
        SUM(i.quantity * i.unit_price) AS τζίρος
    FROM books b
    JOIN order_items i ON i.book_id = b.id
    JOIN orders      o ON o.id = i.order_id AND o.status = 'paid'
    GROUP BY b.id, b.title, b.category_id
),
κατάταξη AS (
    SELECT
        e.*,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY τζίρος DESC) AS σειρά
    FROM έσοδα e
)
SELECT
    c.name           AS κατηγορία,
    k.title          AS βιβλίο,
    ROUND(k.τζίρος, 2) AS τζίρος,
    k.σειρά
FROM κατάταξη k
JOIN categories c ON c.id = k.category_id
WHERE k.σειρά <= 2
ORDER BY c.name, k.σειρά;

-- 7. Επαναλαμβανόμενοι πελάτες
WITH διαστήματα AS (
    SELECT
        o.customer_id,
        JULIANDAY(o.order_date)
        - JULIANDAY(LAG(o.order_date) OVER (PARTITION BY o.customer_id
                                            ORDER BY o.order_date)) AS μέρες
    FROM orders o
    WHERE o.status = 'paid'
)
SELECT
    c.first_name || ' ' || c.last_name AS πελάτης,
    COUNT(d.μέρες) + 1                 AS παραγγελίες,
    CAST(AVG(d.μέρες) AS INTEGER)      AS μέσο_διάστημα_ημερών
FROM διαστήματα d
JOIN customers c ON c.id = d.customer_id
WHERE d.μέρες IS NOT NULL
GROUP BY c.id
ORDER BY παραγγελίες DESC, μέσο_διάστημα_ημερών;

-- 8. Ρυθμός ακυρώσεων
SELECT
    STRFTIME('%Y', order_date) AS έτος,
    COUNT(*)                   AS παραγγελίες,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS ακυρώσεις,
    ROUND(100.0 * SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END)
          / COUNT(*), 1)       AS ποσοστό_ακύρωσης
FROM orders
GROUP BY έτος
ORDER BY έτος;

-- 9. Ζευγάρια βιβλίων στο ίδιο καλάθι.
--    Το i1.book_id < i2.book_id αποτρέπει και το ζευγάρωμα με τον εαυτό του
--    και την εμφάνιση του ίδιου ζεύγους δύο φορές (Α-Β και Β-Α).
SELECT
    b1.title AS βιβλίο_1,
    b2.title AS βιβλίο_2,
    COUNT(*) AS φορές_μαζί
FROM order_items i1
JOIN order_items i2 ON i1.order_id = i2.order_id AND i1.book_id < i2.book_id
JOIN books b1 ON b1.id = i1.book_id
JOIN books b2 ON b2.id = i2.book_id
GROUP BY b1.id, b2.id
HAVING COUNT(*) >= 2
ORDER BY φορές_μαζί DESC;

-- 10. Καλή βαθμολογία, χαμηλές πωλήσεις
WITH πωλήσεις AS (
    SELECT i.book_id, SUM(i.quantity) AS τεμάχια
    FROM order_items i
    JOIN orders o ON o.id = i.order_id AND o.status = 'paid'
    GROUP BY i.book_id
),
βαθμοί AS (
    SELECT book_id, AVG(rating) AS μέση, COUNT(*) AS κριτικές
    FROM reviews
    GROUP BY book_id
)
SELECT
    b.title,
    ROUND(v.μέση, 2)       AS βαθμολογία,
    v.κριτικές,
    COALESCE(p.τεμάχια, 0) AS τεμάχια,
    b.stock                AS απόθεμα
FROM books b
JOIN βαθμοί v ON v.book_id = b.id
LEFT JOIN πωλήσεις p ON p.book_id = b.id
WHERE v.μέση >= 4.5 AND COALESCE(p.τεμάχια, 0) < 3
ORDER BY βαθμολογία DESC, τεμάχια;

-- 11. Γεωγραφία
WITH σύνολα AS (
    SELECT
        o.id,
        o.customer_id,
        SUM(i.quantity * i.unit_price) AS ποσό
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, o.customer_id
)
SELECT
    COALESCE(c.city, '(άγνωστη)') AS πόλη,
    COUNT(DISTINCT c.id)          AS ενεργοί_πελάτες,
    COUNT(s.id)                   AS παραγγελίες,
    ROUND(SUM(s.ποσό), 2)         AS τζίρος,
    ROUND(AVG(s.ποσό), 2)         AS μέση_παραγγελία
FROM σύνολα s
JOIN customers c ON c.id = s.customer_id
GROUP BY πόλη
ORDER BY τζίρος DESC;

-- 12. Μία εκδοχή "διοικητικού" dashboard: τα βασικά μεγέθη σε μία στήλη ανά μέγεθος.
WITH σύνολα AS (
    SELECT o.id, o.customer_id, SUM(i.quantity * i.unit_price) AS ποσό, SUM(i.quantity) AS τεμ
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, o.customer_id
)
SELECT 'Συνολικός τζίρος'            AS δείκτης, ROUND(SUM(ποσό), 2)            AS τιμή FROM σύνολα
UNION ALL
SELECT 'Παραγγελίες',                       COUNT(*)                                  FROM σύνολα
UNION ALL
SELECT 'Μέση αξία παραγγελίας',             ROUND(AVG(ποσό), 2)                       FROM σύνολα
UNION ALL
SELECT 'Τεμάχια που πουλήθηκαν',            SUM(τεμ)                                  FROM σύνολα
UNION ALL
SELECT 'Ενεργοί πελάτες',                   COUNT(DISTINCT customer_id)               FROM σύνολα
UNION ALL
SELECT 'Πελάτες χωρίς αγορά',
       (SELECT COUNT(*) FROM customers) - (SELECT COUNT(DISTINCT customer_id) FROM σύνολα)
UNION ALL
SELECT 'Τίτλοι χωρίς πώληση',
       (SELECT COUNT(*) FROM books b
        WHERE NOT EXISTS (SELECT 1 FROM order_items i
                          JOIN orders o ON o.id = i.order_id AND o.status = 'paid'
                          WHERE i.book_id = b.id))
UNION ALL
SELECT 'Αξία αποθέματος',                   (SELECT ROUND(SUM(stock * price), 2) FROM books);
