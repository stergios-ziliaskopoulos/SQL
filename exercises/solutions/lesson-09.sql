-- Λύσεις — Μάθημα 9
-- Επαναφορά της βάσης μετά:  python3 tools/build_db.py

-- 1.
CREATE TABLE publishers (
    id      INTEGER PRIMARY KEY,
    name    TEXT    NOT NULL UNIQUE,
    city    TEXT,
    founded INTEGER CHECK (founded > 1400)
);

-- 2.
ALTER TABLE books ADD COLUMN publisher_id INTEGER REFERENCES publishers(id);

-- 3.
INSERT INTO publishers (name, city, founded) VALUES
 ('Εκδόσεις Καστανιώτη', 'Αθήνα',       1971),
 ('Πατάκης',             'Αθήνα',       1974),
 ('Ίκαρος',              'Θεσσαλονίκη', 1943);

UPDATE books
SET publisher_id = (SELECT id FROM publishers WHERE name = 'Ίκαρος')
WHERE category_id = 2;                       -- τα ποιητικά

UPDATE books
SET publisher_id = (SELECT id FROM publishers WHERE name = 'Πατάκης')
WHERE category_id = 6;                       -- τα παιδικά

-- 4. Και οι τέσσερις εισαγωγές ΠΡΕΠΕΙ να αποτύχουν — αυτό είναι το ζητούμενο.
INSERT INTO books (title, price) VALUES ('Αρνητικό', -5);
--> CHECK constraint failed: price >= 0

INSERT INTO orders (customer_id, order_date, status) VALUES (1, '2025-01-01', 'άκυρο');
--> CHECK constraint failed: το status δέχεται μόνο paid/pending/cancelled

INSERT INTO orders (customer_id, order_date, status) VALUES (999, '2025-01-01', 'paid');
--> FOREIGN KEY constraint failed: δεν υπάρχει πελάτης 999

INSERT INTO publishers (name) VALUES ('Πατάκης');
--> UNIQUE constraint failed: publishers.name

-- 5. Πριν: "SCAN orders" (διαβάζει όλες τις γραμμές).
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 5;

CREATE INDEX idx_orders_customer ON orders(customer_id);

-- Μετά: "SEARCH orders USING INDEX idx_orders_customer (customer_id=?)"
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 5;

-- 6.
CREATE UNIQUE INDEX idx_reviews_unique ON reviews(book_id, customer_id);

-- Ο πελάτης 1 έχει ήδη κριτική για το βιβλίο 16 -> αποτυγχάνει
INSERT INTO reviews (book_id, customer_id, rating, comment, review_date)
VALUES (16, 1, 3, 'Δεύτερη γνώμη', '2025-08-15');
--> UNIQUE constraint failed: reviews.book_id, reviews.customer_id

-- 7.
CREATE VIEW v_πωλήσεις_βιβλίων AS
SELECT
    b.id,
    b.title,
    COALESCE(SUM(i.quantity), 0)                          AS τεμάχια,
    ROUND(COALESCE(SUM(i.quantity * i.unit_price), 0), 2) AS έσοδα
FROM books b
LEFT JOIN order_items i ON i.book_id = b.id
LEFT JOIN orders      o ON o.id = i.order_id AND o.status = 'paid'
GROUP BY b.id, b.title;

SELECT * FROM v_πωλήσεις_βιβλίων ORDER BY έσοδα DESC LIMIT 5;

-- 8. Σχέση πολλά-προς-πολλά -> ενδιάμεσος πίνακας.
--    Το σύνθετο πρωτεύον κλειδί εμποδίζει διπλοεγγραφή του ίδιου βιβλίου.
CREATE TABLE wishlists (
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    book_id     INTEGER NOT NULL REFERENCES books(id),
    added_at    TEXT    NOT NULL DEFAULT (DATE('now')),
    PRIMARY KEY (customer_id, book_id)
);

INSERT INTO wishlists (customer_id, book_id) VALUES (12, 23), (12, 16), (13, 23);

SELECT c.first_name, b.title
FROM wishlists w
JOIN customers c ON c.id = w.customer_id
JOIN books     b ON b.id = w.book_id;

-- 9. Τι πάει στραβά:
--    α) Η στήλη "βιβλία" κρατά λίστα σε ένα κελί. Δεν μπορείς να μετρήσεις πωλήσεις
--       ανά τίτλο, ούτε να συνδεθείς με τον books. Κάθε ερώτημα καταλήγει σε LIKE.
--    β) Το όνομα, το email και η πόλη του πελάτη επαναλαμβάνονται σε κάθε παραγγελία.
--       Αλλαγή email = ενημέρωση σε Ν γραμμές, με κίνδυνο να μείνουν ασυνεπείς.
--    γ) Δεν υπάρχει ποσότητα ούτε τιμή ανά βιβλίο — μόνο ένα συνολικό ποσό που δεν
--       επαληθεύεται από πουθενά.
--    δ) Δεν υπάρχει κανένα foreign key: τίποτα δεν εγγυάται ότι ο πελάτης υπάρχει.
--    Η σωστή μορφή είναι ακριβώς αυτή που έχει το μάθημα:
--       customers (1) --- (Ν) orders (1) --- (Ν) order_items (Ν) --- (1) books

-- 10. Δεν είναι περιττή. Η books.price είναι η ΤΡΕΧΟΥΣΑ τιμή καταλόγου· η
--     order_items.unit_price είναι η τιμή ΤΗΣ ΣΤΙΓΜΗΣ ΤΗΣ ΠΩΛΗΣΗΣ — ιστορικό γεγονός.
--     Αν δεν την κρατούσαμε, μια αύξηση τιμών θα άλλαζε αναδρομικά τον τζίρο του 2023.
--     Κανόνας: τα γεγονότα καταγράφονται όπως συνέβησαν, δεν υπολογίζονται εκ των υστέρων.
