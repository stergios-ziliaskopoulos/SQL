-- ============================================================
--  Star schema — το αναλυτικό μοντέλο πάνω από τη λειτουργική βάση
--
--  Τρέξε το με:  python3 sql.py -f bi/star_schema.sql
--  Μετά δοκίμασε: python3 sql.py -f bi/reports.sql
--
--  Αυτό ακριβώς κάνεις πριν στήσεις ένα Qlik Sense app ή ένα
--  BusinessObjects universe: μετατρέπεις το κανονικοποιημένο
--  σχήμα των συναλλαγών σε σχήμα κατάλληλο για ανάλυση.
-- ============================================================

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_book;
DROP TABLE IF EXISTS dim_customer;

-- ------------------------------------------------------------
-- ΔΙΑΣΤΑΣΗ: Ημερολόγιο
-- Παράγεται προγραμματιστικά, μία γραμμή ανά ημέρα — ΠΟΤΕ δεν
-- βασιζόμαστε στις ημερομηνίες που τυχαίνει να υπάρχουν στα δεδομένα,
-- γιατί τότε οι μήνες χωρίς πωλήσεις εξαφανίζονται από τα γραφήματα.
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_key   TEXT PRIMARY KEY,   -- 'YYYY-MM-DD'
    year       INTEGER,
    quarter    TEXT,
    month_key  TEXT,               -- 'YYYY-MM' — για ταξινόμηση
    month_no   INTEGER,
    month_name TEXT,
    day_of_week TEXT,
    is_weekend INTEGER
);

INSERT INTO dim_date
WITH RECURSIVE ημέρες(d) AS (
    SELECT DATE((SELECT MIN(order_date) FROM orders), 'start of year')
    UNION ALL
    SELECT DATE(d, '+1 day')
    FROM ημέρες
    WHERE d < DATE((SELECT MAX(order_date) FROM orders), 'start of year', '+1 year', '-1 day')
)
SELECT
    d,
    CAST(STRFTIME('%Y', d) AS INTEGER),
    'Q' || ((CAST(STRFTIME('%m', d) AS INTEGER) + 2) / 3),
    STRFTIME('%Y-%m', d),
    CAST(STRFTIME('%m', d) AS INTEGER),
    CASE STRFTIME('%m', d)
        WHEN '01' THEN 'Ιανουάριος'  WHEN '02' THEN 'Φεβρουάριος' WHEN '03' THEN 'Μάρτιος'
        WHEN '04' THEN 'Απρίλιος'    WHEN '05' THEN 'Μάιος'       WHEN '06' THEN 'Ιούνιος'
        WHEN '07' THEN 'Ιούλιος'     WHEN '08' THEN 'Αύγουστος'   WHEN '09' THEN 'Σεπτέμβριος'
        WHEN '10' THEN 'Οκτώβριος'   WHEN '11' THEN 'Νοέμβριος'   ELSE 'Δεκέμβριος'
    END,
    CASE STRFTIME('%w', d)
        WHEN '0' THEN 'Κυριακή'   WHEN '1' THEN 'Δευτέρα' WHEN '2' THEN 'Τρίτη'
        WHEN '3' THEN 'Τετάρτη'   WHEN '4' THEN 'Πέμπτη'  WHEN '5' THEN 'Παρασκευή'
        ELSE 'Σάββατο'
    END,
    CASE WHEN STRFTIME('%w', d) IN ('0', '6') THEN 1 ELSE 0 END
FROM ημέρες;

-- ------------------------------------------------------------
-- ΔΙΑΣΤΑΣΗ: Βιβλίο
-- Οι πίνακες books + authors + categories "ισοπεδώνονται" σε έναν.
-- Στο μοντέλο αναλύσεων η επανάληψη του ονόματος συγγραφέα ΔΕΝ είναι
-- σφάλμα: μειώνει τα joins και επιταχύνει τα ερωτήματα.
-- ------------------------------------------------------------
CREATE TABLE dim_book (
    book_key    INTEGER PRIMARY KEY,
    title       TEXT,
    author_name TEXT,
    author_country TEXT,
    category_name  TEXT,
    price_band  TEXT,
    published_year INTEGER,
    decade      INTEGER
);

INSERT INTO dim_book
SELECT
    b.id,
    b.title,
    COALESCE(a.name, '(άγνωστος)'),
    COALESCE(a.country, '(άγνωστη)'),
    COALESCE(c.name, '(χωρίς κατηγορία)'),
    CASE
        WHEN b.price < 12 THEN '1. έως 12€'
        WHEN b.price < 18 THEN '2. 12-18€'
        ELSE                   '3. άνω των 18€'
    END,
    b.published_year,
    b.published_year / 10 * 10
FROM books b
LEFT JOIN authors    a ON a.id = b.author_id
LEFT JOIN categories c ON c.id = b.category_id;

-- ------------------------------------------------------------
-- ΔΙΑΣΤΑΣΗ: Πελάτης
-- ------------------------------------------------------------
CREATE TABLE dim_customer (
    customer_key INTEGER PRIMARY KEY,
    full_name    TEXT,
    city         TEXT,
    signup_date  TEXT,
    signup_year  INTEGER,
    cohort       TEXT          -- το έτος εγγραφής, η κλασική διάσταση cohort analysis
);

INSERT INTO dim_customer
SELECT
    id,
    first_name || ' ' || last_name,
    COALESCE(city, '(άγνωστη)'),
    signup_date,
    CAST(STRFTIME('%Y', signup_date) AS INTEGER),
    STRFTIME('%Y', signup_date)
FROM customers;

-- ------------------------------------------------------------
-- ΓΕΓΟΝΟΣ: Πωλήσεις
--
-- ΚΟΚΚΟΣ (grain): μία γραμμή ανά (παραγγελία, βιβλίο).
-- Το grain είναι η πρώτη ερώτηση σε κάθε σχεδιασμό fact table και η
-- πρώτη ερώτηση που θα σου κάνει ένας έμπειρος συνάδελφος. Αν δεν
-- μπορείς να το διατυπώσεις σε μία πρόταση, το μοντέλο δεν είναι έτοιμο.
--
-- Κρατάμε ΟΛΕΣ τις παραγγελίες μαζί με το status: το φιλτράρισμα είναι
-- απόφαση της αναφοράς, όχι του μοντέλου. Αν πετάξεις τις ακυρωμένες
-- εδώ, δεν μπορείς ποτέ να υπολογίσεις ποσοστό ακυρώσεων.
-- ------------------------------------------------------------
CREATE TABLE fact_sales (
    order_id     INTEGER NOT NULL,
    book_key     INTEGER NOT NULL REFERENCES dim_book(book_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    date_key     TEXT    NOT NULL REFERENCES dim_date(date_key),
    status       TEXT    NOT NULL,
    quantity     INTEGER NOT NULL,
    unit_price   REAL    NOT NULL,
    line_amount  REAL    NOT NULL,   -- προϋπολογισμένο: quantity * unit_price
    PRIMARY KEY (order_id, book_key)
);

INSERT INTO fact_sales
SELECT
    o.id,
    i.book_id,
    o.customer_id,
    o.order_date,
    o.status,
    i.quantity,
    i.unit_price,
    ROUND(i.quantity * i.unit_price, 2)
FROM orders o
JOIN order_items i ON i.order_id = o.id;

-- Ευρετήρια στα κλειδιά της fact — σε πραγματικό όγκο δεδομένων
-- είναι η διαφορά ανάμεσα σε 2 δευτερόλεπτα και 2 λεπτά.
CREATE INDEX idx_fact_date     ON fact_sales(date_key);
CREATE INDEX idx_fact_book     ON fact_sales(book_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);

-- ------------------------------------------------------------
-- ΕΛΕΓΧΟΙ ΣΥΜΦΩΝΙΑΣ (reconciliation)
--
-- Ποτέ μην παραδώσεις μοντέλο χωρίς αυτούς. Είναι η απάντηση στην
-- ερώτηση "και πώς ξέρουμε ότι τα νούμερα του dashboard είναι σωστά;"
-- Και τα τρία πρέπει να δείχνουν ΟΚ.
-- ------------------------------------------------------------

-- 1. Ίδιο πλήθος γραμμών με την πηγή;
SELECT
    (SELECT COUNT(*) FROM order_items) AS πηγή_γραμμές,
    (SELECT COUNT(*) FROM fact_sales)  AS fact_γραμμές,
    CASE WHEN (SELECT COUNT(*) FROM order_items) = (SELECT COUNT(*) FROM fact_sales)
         THEN 'OK' ELSE 'ΔΙΑΦΟΡΑ' END AS έλεγχος;

-- 2. Ίδιο σύνολο αξίας;
SELECT
    ROUND((SELECT SUM(quantity * unit_price) FROM order_items), 2) AS πηγή_αξία,
    ROUND((SELECT SUM(line_amount)           FROM fact_sales), 2)  AS fact_αξία,
    CASE WHEN ABS((SELECT SUM(quantity * unit_price) FROM order_items)
                - (SELECT SUM(line_amount) FROM fact_sales)) < 0.01
         THEN 'OK' ELSE 'ΔΙΑΦΟΡΑ' END AS έλεγχος;

-- 3. Ορφανά κλειδιά — κάθε γραμμή της fact βρίσκει τη διάστασή της;
SELECT
    SUM(CASE WHEN d.date_key     IS NULL THEN 1 ELSE 0 END) AS ορφανές_ημερομηνίες,
    SUM(CASE WHEN b.book_key     IS NULL THEN 1 ELSE 0 END) AS ορφανά_βιβλία,
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS ορφανοί_πελάτες
FROM fact_sales f
LEFT JOIN dim_date     d ON d.date_key     = f.date_key
LEFT JOIN dim_book     b ON b.book_key     = f.book_key
LEFT JOIN dim_customer c ON c.customer_key = f.customer_key;
