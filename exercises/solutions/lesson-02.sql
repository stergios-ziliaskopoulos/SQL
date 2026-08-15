-- Λύσεις — Μάθημα 2

-- 1.
SELECT title, price FROM books WHERE price < 12;

-- 2.
SELECT title, published_year, price
FROM books
WHERE published_year < 1950 AND price > 12;

-- 3.
SELECT title, category_id FROM books WHERE category_id IN (2, 3, 6);

-- 4.
SELECT title, published_year
FROM books
WHERE published_year BETWEEN 1960 AND 1990
ORDER BY published_year;

-- 5.
SELECT first_name, last_name, city
FROM customers
WHERE city IN ('Αθήνα', 'Θεσσαλονίκη')
ORDER BY last_name;

-- 6.
SELECT title FROM books WHERE title LIKE '%Κόσμου%';

-- 7.
SELECT title, stock FROM books WHERE stock = 0;

-- 8.
SELECT first_name, last_name FROM customers WHERE city IS NULL;

-- 9.
SELECT COUNT(*) AS χωρίς_συγγραφέα FROM books WHERE author_id IS NULL;   -- 2

-- 10.
SELECT id, order_date, status
FROM orders
WHERE order_date >= '2024-01-01'
  AND order_date <  '2025-01-01'
  AND status <> 'cancelled'
ORDER BY order_date;

-- 11.
SELECT
    first_name || ' ' || last_name  AS πελάτης,
    COALESCE(city, 'άγνωστη')       AS πόλη
FROM customers;

-- 12. Το πρώτο δίνει 20, το δεύτερο 22 (σε σύνολο 25 βιβλίων).
--     Το author_id <> 4 απορρίπτει τα βιβλία με author_id = NULL, γιατί η σύγκριση
--     NULL <> 4 δεν είναι "αληθής" αλλά "άγνωστη" — και το WHERE κρατά μόνο τις
--     αληθείς συνθήκες. Αν θέλεις και τα κενά, πρέπει να το ζητήσεις ρητά.
SELECT COUNT(*) FROM books WHERE author_id <> 4;
SELECT COUNT(*) FROM books WHERE author_id <> 4 OR author_id IS NULL;
