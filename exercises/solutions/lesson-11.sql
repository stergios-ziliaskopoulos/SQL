-- Λύσεις — Μάθημα 11
-- Προετοιμασία:
--   python3 tools/build_db.py
--   python3 sql.py -f bi/star_schema.sql
--   python3 sql.py -f exercises/solutions/lesson-11.sql

-- 1. Οι έλεγχοι συμφωνίας (μετά από σκόπιμη διαγραφή μιας γραμμής
--    "κοκκινίζουν" οι έλεγχοι 1 και 2· ο 3ος μένει ΟΚ, γιατί δεν
--    δημιουργείται ορφανό κλειδί — μια γραμμή απλώς λείπει.)
SELECT
    (SELECT COUNT(*) FROM order_items) AS πηγή_γραμμές,
    (SELECT COUNT(*) FROM fact_sales)  AS fact_γραμμές,
    CASE WHEN (SELECT COUNT(*) FROM order_items) = (SELECT COUNT(*) FROM fact_sales)
         THEN 'OK' ELSE 'ΔΙΑΦΟΡΑ' END AS έλεγχος_πλήθους;

-- 2α. ΜΕ dim_date: 12 γραμμές, όσοι και οι μήνες του έτους
SELECT
    d.month_key                               AS μήνας,
    ROUND(COALESCE(SUM(f.line_amount), 0), 2) AS τζίρος
FROM dim_date d
LEFT JOIN fact_sales f ON f.date_key = d.date_key AND f.status = 'paid'
WHERE d.year = 2024
GROUP BY d.month_key
ORDER BY d.month_key;

-- 2β. ΧΩΡΙΣ dim_date: λιγότερες γραμμές — οι μήνες χωρίς πωλήσεις χάνονται
SELECT
    STRFTIME('%Y-%m', date_key) AS μήνας,
    ROUND(SUM(line_amount), 2)  AS τζίρος
FROM fact_sales
WHERE status = 'paid' AND date_key >= '2024-01-01' AND date_key < '2025-01-01'
GROUP BY μήνας
ORDER BY μήνας;

-- 3. Pivot: έτη ως στήλες
SELECT
    b.category_name AS κατηγορία,
    ROUND(SUM(CASE WHEN d.year = 2023 THEN f.line_amount ELSE 0 END), 2) AS "2023",
    ROUND(SUM(CASE WHEN d.year = 2024 THEN f.line_amount ELSE 0 END), 2) AS "2024",
    ROUND(SUM(CASE WHEN d.year = 2025 THEN f.line_amount ELSE 0 END), 2) AS "2025",
    ROUND(SUM(f.line_amount), 2)                                         AS σύνολο
FROM fact_sales f
JOIN dim_book b ON b.book_key = f.book_key
JOIN dim_date d ON d.date_key = f.date_key
WHERE f.status = 'paid'
GROUP BY b.category_name
ORDER BY σύνολο DESC;

-- 4. Pareto πελατών
WITH ανά_πελάτη AS (
    SELECT c.full_name, SUM(f.line_amount) AS ποσό
    FROM fact_sales f
    JOIN dim_customer c ON c.customer_key = f.customer_key
    WHERE f.status = 'paid'
    GROUP BY c.customer_key, c.full_name
)
SELECT
    full_name                                                   AS πελάτης,
    ROUND(ποσό, 2)                                              AS τζίρος,
    ROUND(ποσό * 100.0 / SUM(ποσό) OVER (), 1)                  AS μερίδιο_pct,
    ROUND(SUM(ποσό) OVER (ORDER BY ποσό DESC) * 100.0
          / SUM(ποσό) OVER (), 1)                               AS αθροιστικά_pct
FROM ανά_πελάτη
ORDER BY ποσό DESC
LIMIT 5;

-- 5. Fan trap: κάθε πώληση ζευγαρώνει με ΚΑΘΕ κριτική του βιβλίου.
--    Λύση: χωριστή συγκέντρωση σε κάθε επίπεδο και μετά ένωση.
WITH πωλήσεις AS (
    SELECT book_key, SUM(line_amount) AS τζίρος
    FROM fact_sales
    WHERE status = 'paid'
    GROUP BY book_key
),
κριτικές AS (
    SELECT book_id AS book_key, AVG(rating) AS βαθμολογία, COUNT(*) AS πλήθος
    FROM reviews
    GROUP BY book_id
)
SELECT
    b.title,
    ROUND(COALESCE(p.τζίρος, 0), 2) AS τζίρος,
    ROUND(k.βαθμολογία, 2)          AS βαθμολογία,
    COALESCE(k.πλήθος, 0)           AS κριτικές
FROM dim_book b
LEFT JOIN πωλήσεις p ON p.book_key = b.book_key
LEFT JOIN κριτικές k ON k.book_key = b.book_key
ORDER BY τζίρος DESC;

-- Απόδειξη ότι το σύνολο βγαίνει σωστό (996.70)
SELECT ROUND(SUM(line_amount), 2) AS σωστός_τζίρος FROM fact_sales WHERE status = 'paid';

-- 6. Τα τεμάχια είναι additive (ροή), το απόθεμα semi-additive (στιγμιότυπο).
--    Το απόθεμα του Ιανουαρίου + του Φεβρουαρίου δεν σημαίνει τίποτα: θέλεις
--    την τελευταία τιμή της περιόδου, όχι το άθροισμα.
SELECT
    b.title,
    COALESCE(SUM(f.quantity), 0) AS πωληθέντα_τεμάχια,
    bk.stock                     AS τρέχον_απόθεμα
FROM dim_book b
JOIN books bk ON bk.id = b.book_key
LEFT JOIN fact_sales f ON f.book_key = b.book_key AND f.status = 'paid'
GROUP BY b.book_key, b.title, bk.stock
ORDER BY πωληθέντα_τεμάχια DESC;

-- 7. Τα δύο ποσοστά διαφέρουν: ο μέσος όρος μηνιαίων ποσοστών δίνει σε έναν
--    μήνα με 1 παραγγελία το ίδιο βάρος με έναν μήνα με 20. Σωστό είναι το (β).
WITH ανά_μήνα AS (
    SELECT
        d.year,
        d.month_key,
        COUNT(DISTINCT f.order_id) AS παραγγελίες,
        COUNT(DISTINCT CASE WHEN f.status = 'cancelled' THEN f.order_id END) AS ακυρωμένες
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY d.year, d.month_key
)
SELECT
    year                                                            AS έτος,
    ROUND(AVG(100.0 * ακυρωμένες / παραγγελίες), 1)                 AS λάθος_μέσος_ποσοστών,
    ROUND(100.0 * SUM(ακυρωμένες) / SUM(παραγγελίες), 1)            AS σωστό_σταθμισμένο
FROM ανά_μήνα
GROUP BY year
ORDER BY year;

-- 8. Σαββατοκύριακο vs καθημερινές
SELECT
    CASE d.is_weekend WHEN 1 THEN 'Σαββατοκύριακο' ELSE 'Καθημερινή' END AS περίοδος,
    COUNT(DISTINCT f.order_id)                                           AS παραγγελίες,
    ROUND(SUM(f.line_amount), 2)                                         AS τζίρος,
    ROUND(SUM(f.line_amount) * 100.0
          / (SELECT SUM(line_amount) FROM fact_sales WHERE status = 'paid'), 1) AS ποσοστό
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
WHERE f.status = 'paid'
GROUP BY d.is_weekend
ORDER BY τζίρος DESC;

-- 9. Έλεγχος ποιότητας: παραγγελία πριν την εγγραφή (πρέπει να επιστρέψει 0 γραμμές)
SELECT
    f.order_id,
    c.full_name,
    c.signup_date,
    f.date_key AS ημερομηνία_παραγγελίας
FROM fact_sales f
JOIN dim_customer c ON c.customer_key = f.customer_key
WHERE f.date_key < c.signup_date;

-- 10. Πίνακας συγκεντρώσεων: 31 γραμμές αντί για 59 —
--     σε πραγματικό όγκο η αναλογία είναι εκατομμύρια προς χιλιάδες.
DROP TABLE IF EXISTS agg_monthly_category;

CREATE TABLE agg_monthly_category AS
SELECT
    d.month_key     AS μήνας,
    d.year          AS έτος,
    b.category_name AS κατηγορία,
    SUM(f.quantity)    AS τεμάχια,
    SUM(f.line_amount) AS τζίρος
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
JOIN dim_book b ON b.book_key = f.book_key
WHERE f.status = 'paid'
GROUP BY d.month_key, d.year, b.category_name;

SELECT κατηγορία, ROUND(SUM(τζίρος), 2) AS τζίρος_2025
FROM agg_monthly_category
WHERE έτος = 2025
GROUP BY κατηγορία
ORDER BY τζίρος_2025 DESC;

SELECT
    (SELECT COUNT(*) FROM fact_sales)           AS γραμμές_fact,
    (SELECT COUNT(*) FROM agg_monthly_category) AS γραμμές_aggregate;

-- 11. Το πρώτο κάνει SCAN (η συνάρτηση "τυφλώνει" το ευρετήριο),
--     το δεύτερο SEARCH USING INDEX idx_fact_date.
EXPLAIN QUERY PLAN
SELECT SUM(line_amount) FROM fact_sales WHERE STRFTIME('%Y', date_key) = '2025';

EXPLAIN QUERY PLAN
SELECT SUM(line_amount) FROM fact_sales
WHERE date_key >= '2025-01-01' AND date_key < '2026-01-01';

-- 12. Χρειάζεται ΝΕΟ fact table. Το grain των κριτικών είναι
--     "μία γραμμή ανά (βιβλίο, πελάτης, κριτική)" — διαφορετικό από το
--     "μία γραμμή ανά (παραγγελία, βιβλίο)" των πωλήσεων. Δύο γεγονότα με
--     διαφορετικό κόκκο δεν μπαίνουν ΠΟΤΕ στον ίδιο πίνακα: αυτό ακριβώς
--     παράγει το fan trap της άσκησης 5.
--     Μοιράζονται όμως τις ίδιες διαστάσεις (dim_date, dim_book, dim_customer)
--     — αυτό λέγεται "conformed dimensions" και είναι το ζητούμενο.
DROP TABLE IF EXISTS fact_reviews;

CREATE TABLE fact_reviews AS
SELECT
    r.id           AS review_key,
    r.book_id      AS book_key,
    r.customer_id  AS customer_key,
    r.review_date  AS date_key,
    r.rating,
    CASE WHEN r.comment IS NULL THEN 0 ELSE 1 END AS έχει_σχόλιο
FROM reviews r;

-- Τώρα η ανάλυση γίνεται σωστά, στο δικό της επίπεδο
SELECT
    d.month_key           AS μήνας,
    b.category_name       AS κατηγορία,
    COUNT(*)              AS κριτικές,
    ROUND(AVG(fr.rating), 2) AS μέση_βαθμολογία
FROM fact_reviews fr
JOIN dim_date d ON d.date_key = fr.date_key
JOIN dim_book b ON b.book_key = fr.book_key
GROUP BY d.month_key, b.category_name
ORDER BY μήνας, κατηγορία;
