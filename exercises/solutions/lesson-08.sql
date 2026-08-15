-- Λύσεις — Μάθημα 8
-- ΠΡΟΣΟΧΗ: αυτό το αρχείο αλλάζει τα δεδομένα.
-- Επαναφορά:  python3 tools/build_db.py

-- 1.
INSERT INTO categories (name) VALUES ('Ιστορία');

-- 2.
INSERT INTO authors (name, country, birth_year) VALUES
 ('Ερνέστ Χέμινγουεϊ', 'ΗΠΑ',              1899),
 ('Βιρτζίνια Γουλφ',   'Ηνωμένο Βασίλειο', 1882);

-- 3. Παίρνουμε τα id με υποερωτήματα αντί να τα μαντέψουμε
INSERT INTO books (title, author_id, category_id, price, stock, published_year)
VALUES (
    'Ο Γέρος και η Θάλασσα',
    (SELECT id FROM authors    WHERE name = 'Ερνέστ Χέμινγουεϊ'),
    (SELECT id FROM categories WHERE name = 'Ιστορία'),
    11.50, 10, 1952
);

-- 4. Πρώτα κοιτάμε...
SELECT id, title, price FROM books
WHERE category_id = (SELECT id FROM categories WHERE name = 'Πληροφορική');

-- ...και μετά αλλάζουμε
UPDATE books
SET price = ROUND(price * 1.10, 2)
WHERE category_id = (SELECT id FROM categories WHERE name = 'Πληροφορική');

-- 5.
UPDATE books SET stock = 0 WHERE published_year < 1900;

-- 6.
UPDATE customers SET city = 'Αθήνα' WHERE id = 9;

-- 7.
INSERT INTO reviews (book_id, customer_id, rating, comment, review_date)
VALUES (
    (SELECT id FROM books WHERE title = 'Μαθαίνω SQL'),
    12, 5, 'Επιτέλους κατάλαβα τα JOIN.', '2025-08-15'
);

-- 8.
UPDATE orders
SET status = 'cancelled'
WHERE status = 'pending'
  AND order_date >= '2023-01-01' AND order_date < '2024-01-01';

-- 9.
DELETE FROM reviews WHERE comment IS NULL;

-- 10. Αποτυγχάνει: FOREIGN KEY constraint failed.
--     Ο πελάτης 1 έχει παραγγελίες που τον αναφέρουν· η βάση δεν επιτρέπει να
--     μείνουν "ορφανές". Θα έπρεπε πρώτα να σβήσεις τις παραγγελίες του (και τις
--     γραμμές τους), ή να είχε οριστεί ON DELETE CASCADE.
DELETE FROM customers WHERE id = 1;

-- 11. Συναλλαγή που ολοκληρώνεται
BEGIN;
INSERT INTO orders (customer_id, order_date, status)
VALUES (13, '2025-08-15', 'paid');

INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (last_insert_rowid(), 17, 2, (SELECT price FROM books WHERE id = 17));

UPDATE books SET stock = stock - 2 WHERE id = 17;
COMMIT;

SELECT id, customer_id, order_date FROM orders WHERE customer_id = 13;

-- 12. Ίδια συναλλαγή, αλλά ακυρωμένη
BEGIN;
INSERT INTO orders (customer_id, order_date, status)
VALUES (13, '2025-08-16', 'paid');
UPDATE books SET stock = stock - 99 WHERE id = 17;
ROLLBACK;

-- Επιβεβαίωση: η παραγγελία της 16ης δεν υπάρχει και το απόθεμα δεν άλλαξε
SELECT COUNT(*) AS παραγγελίες_16ης FROM orders WHERE order_date = '2025-08-16';
SELECT id, title, stock FROM books WHERE id = 17;

-- 13.
UPDATE books SET price = ROUND(price, 2);
