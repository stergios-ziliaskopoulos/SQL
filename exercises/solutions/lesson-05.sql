-- Λύσεις — Μάθημα 5

-- 1.
SELECT b.title, a.name AS συγγραφέας
FROM books b
JOIN authors a ON a.id = b.author_id
ORDER BY a.name, b.title;

-- 2.
SELECT b.title, COALESCE(a.name, '(άγνωστος)') AS συγγραφέας
FROM books b
LEFT JOIN authors a ON a.id = b.author_id
ORDER BY b.title;

-- 3.
SELECT c.name AS κατηγορία, b.title AS βιβλίο
FROM books b
JOIN categories c ON c.id = b.category_id
ORDER BY c.name, b.title;

-- 4. anti-join: κατηγορίες χωρίς βιβλία
SELECT c.name AS κατηγορία_χωρίς_βιβλία
FROM categories c
LEFT JOIN books b ON b.category_id = c.id
WHERE b.id IS NULL;

-- 5.
SELECT
    o.id,
    o.order_date,
    c.first_name || ' ' || c.last_name AS πελάτης,
    o.status
FROM orders o
JOIN customers c ON c.id = o.customer_id
ORDER BY o.order_date;

-- 6.
SELECT
    b.title,
    i.quantity,
    i.unit_price,
    ROUND(i.quantity * i.unit_price, 2) AS σύνολο_γραμμής
FROM order_items i
JOIN books b ON b.id = i.book_id
WHERE i.order_id = 24;

-- 7.
SELECT c.first_name || ' ' || c.last_name AS πελάτης_χωρίς_παραγγελίες
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- 8.
SELECT b.title AS αδιάθετο_βιβλίο
FROM books b
LEFT JOIN order_items i ON i.book_id = b.id
WHERE i.book_id IS NULL;

-- 9.
SELECT
    b.title,
    COALESCE(a.name, '(άγνωστος)')           AS συγγραφέας,
    SUM(i.quantity)                          AS τεμάχια,
    ROUND(SUM(i.quantity * i.unit_price), 2) AS έσοδα
FROM books b
JOIN order_items i ON i.book_id = b.id
JOIN orders      o ON o.id = i.order_id
LEFT JOIN authors a ON a.id = b.author_id
WHERE o.status = 'paid'
GROUP BY b.id, b.title, συγγραφέας
ORDER BY τεμάχια DESC, έσοδα DESC
LIMIT 10;

-- 10.
SELECT
    c.name                                   AS κατηγορία,
    ROUND(SUM(i.quantity * i.unit_price), 2) AS τζίρος
FROM categories c
JOIN books       b ON b.category_id = c.id
JOIN order_items i ON i.book_id = b.id
JOIN orders      o ON o.id = i.order_id
WHERE o.status = 'paid'
GROUP BY c.id, c.name
ORDER BY τζίρος DESC;

-- 11. Προσοχή: η συνθήκη status μπαίνει στο ON, ώστε να μη χαθούν
--     οι πελάτες χωρίς παραγγελίες.
SELECT
    cu.first_name || ' ' || cu.last_name                  AS πελάτης,
    COUNT(DISTINCT o.id)                                  AS παραγγελίες,
    ROUND(COALESCE(SUM(i.quantity * i.unit_price), 0), 2) AS σύνολο
FROM customers cu
LEFT JOIN orders      o ON o.customer_id = cu.id AND o.status = 'paid'
LEFT JOIN order_items i ON i.order_id = o.id
GROUP BY cu.id
ORDER BY σύνολο DESC;

-- 12. self join
SELECT
    e.name                AS υπάλληλος,
    e.role                AS θέση,
    COALESCE(m.name, '—') AS προϊστάμενος
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY προϊστάμενος, e.name;

-- 13.
SELECT
    a.name                AS συγγραφέας,
    COUNT(r.id)           AS κριτικές,
    ROUND(AVG(r.rating), 2) AS μέση_βαθμολογία
FROM authors a
JOIN books   b ON b.author_id = a.id
JOIN reviews r ON r.book_id = b.id
GROUP BY a.id, a.name
HAVING AVG(r.rating) > 4
ORDER BY μέση_βαθμολογία DESC;

-- 14. Το πρώτο μετρά βιβλία (25). Το δεύτερο μετρά ΓΡΑΜΜΕΣ ΠΑΡΑΓΓΕΛΙΑΣ (59):
--     κάθε βιβλίο εμφανίζεται τόσες φορές όσες φορές πουλήθηκε, και τα βιβλία
--     που δεν πουλήθηκαν ποτέ εξαφανίζονται εντελώς. Το JOIN προς την πλευρά
--     "πολλά" πολλαπλασιάζει τις γραμμές.
SELECT COUNT(*) AS βιβλία FROM books;
SELECT COUNT(*) AS γραμμές_μετά_το_join FROM books b JOIN order_items i ON i.book_id = b.id;
