-- Λύσεις — Μάθημα 1
-- Τρέξε τες όλες μαζί:  python3 sql.py -f exercises/solutions/lesson-01.sql

-- 1. Όλες οι κατηγορίες
SELECT * FROM categories;

-- 2. Τίτλος και έτος έκδοσης
SELECT title, published_year FROM books;

-- 3. Πλήρες όνομα σε μία στήλη
SELECT first_name || ' ' || last_name AS πελάτης
FROM customers;

-- 4. Τιμή με έκπτωση 20%
SELECT
    title,
    price,
    ROUND(price * 0.8, 2) AS τιμή_προσφοράς
FROM books;

-- 5. Αξία αποθέματος
SELECT
    title,
    stock,
    ROUND(stock * price, 2) AS αξία_αποθέματος
FROM books;

-- 6. Ψευδώνυμο με κενά -> διπλά εισαγωγικά
SELECT email AS "Ηλεκτρονικό ταχυδρομείο"
FROM customers;

-- 7. Το σχήμα του orders (η .schema δουλεύει μόνο διαδραστικά,
--    εδώ το ίδιο αποτέλεσμα με ερώτημα στον κατάλογο της SQLite)
SELECT sql FROM sqlite_master WHERE name = 'orders';
-- 4 στήλες: id, customer_id, order_date, status.
-- Το status δέχεται μόνο 'paid', 'pending' ή 'cancelled' (CHECK constraint).

-- 8. Το ψευδώνυμο "διπλάσια" δεν υπάρχει ακόμα όταν εκτελείται το WHERE
--    (σειρά: FROM -> WHERE -> SELECT). Επανάλαβε τον υπολογισμό:
SELECT price * 2 AS διπλάσια
FROM books
WHERE price * 2 > 30;
