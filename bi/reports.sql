-- ============================================================
--  Οι αναφορές πάνω στο star schema
--  Προϋπόθεση:  python3 sql.py -f bi/star_schema.sql
--  Εκτέλεση:    python3 sql.py -f bi/reports.sql
--
--  Αυτά είναι τα μοτίβα που ζητούνται ξανά και ξανά σε κάθε
--  BI εργαλείο. Αν τα ξέρεις σε SQL, τα στήνεις παντού.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Μηνιαίος τζίρος — ΜΕ τους κενούς μήνες
--
-- Το LEFT JOIN ΑΠΟ την dim_date είναι όλη η ουσία: ένα σκέτο
-- GROUP BY πάνω στη fact κρύβει τους μήνες χωρίς πωλήσεις, και
-- το γράφημα δείχνει ομαλή γραμμή εκεί που στην πραγματικότητα
-- υπάρχει τρύπα. Είναι το #1 λάθος σε dashboards.
-- ------------------------------------------------------------
SELECT
    d.month_key                              AS μήνας,
    COUNT(DISTINCT f.order_id)               AS παραγγελίες,
    COALESCE(SUM(f.quantity), 0)             AS τεμάχια,
    ROUND(COALESCE(SUM(f.line_amount), 0), 2) AS τζίρος
FROM dim_date d
LEFT JOIN fact_sales f
       ON f.date_key = d.date_key
      AND f.status = 'paid'          -- το φίλτρο ΠΡΕΠΕΙ να είναι στο ON
WHERE d.date_key <= '2025-07-31'
GROUP BY d.month_key
ORDER BY d.month_key;

-- ------------------------------------------------------------
-- 2. Σύγκριση με πέρσι (YoY) — το πιο ζητούμενο KPI
--
-- Το κόλπο: ενώνουμε τον μήνα με τον ίδιο μήνα του προηγούμενου
-- έτους μέσω του month_no, όχι με LAG(12) — γιατί το LAG σπάει
-- μόλις λείψει ένας μήνας από τα δεδομένα.
-- ------------------------------------------------------------
WITH ανά_μήνα AS (
    SELECT
        d.year,
        d.month_no,
        d.month_name,
        SUM(f.line_amount) AS τζίρος
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.date_key
    WHERE f.status = 'paid'
    GROUP BY d.year, d.month_no, d.month_name
)
SELECT
    τ.year                                   AS έτος,
    τ.month_name                             AS μήνας,
    ROUND(τ.τζίρος, 2)                       AS τζίρος,
    ROUND(π.τζίρος, 2)                       AS πέρσι,
    ROUND(τ.τζίρος - π.τζίρος, 2)            AS διαφορά,
    CASE WHEN π.τζίρος IS NULL THEN NULL
         ELSE ROUND((τ.τζίρος - π.τζίρος) * 100.0 / π.τζίρος, 1)
    END                                      AS μεταβολή_pct
FROM ανά_μήνα τ
LEFT JOIN ανά_μήνα π
       ON π.year = τ.year - 1
      AND π.month_no = τ.month_no
ORDER BY τ.year, τ.month_no;

-- ------------------------------------------------------------
-- 3. YTD (από την αρχή του έτους) και αθροιστικά
-- ------------------------------------------------------------
WITH ανά_μήνα AS (
    SELECT d.year, d.month_key, SUM(f.line_amount) AS τζίρος
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.date_key
    WHERE f.status = 'paid'
    GROUP BY d.year, d.month_key
)
SELECT
    month_key                     AS μήνας,
    ROUND(τζίρος, 2)              AS τζίρος,
    ROUND(SUM(τζίρος) OVER (PARTITION BY year ORDER BY month_key), 2) AS ytd,
    ROUND(SUM(τζίρος) OVER (ORDER BY month_key), 2)                   AS από_την_αρχή
FROM ανά_μήνα
ORDER BY month_key;

-- ------------------------------------------------------------
-- 4. Pareto: ποια βιβλία φέρνουν το 80% του τζίρου;
--
-- Δύο window functions στην ίδια γραμμή — μερίδιο και αθροιστικό
-- μερίδιο. Είναι η ανάλυση που ζητά κάθε διοίκηση.
-- ------------------------------------------------------------
WITH έσοδα AS (
    SELECT
        b.title,
        b.category_name,
        SUM(f.line_amount) AS ποσό
    FROM fact_sales f
    JOIN dim_book b ON b.book_key = f.book_key
    WHERE f.status = 'paid'
    GROUP BY b.book_key, b.title, b.category_name
)
SELECT
    title                                                       AS βιβλίο,
    category_name                                               AS κατηγορία,
    ROUND(ποσό, 2)                                              AS έσοδα,
    ROUND(ποσό * 100.0 / SUM(ποσό) OVER (), 1)                  AS μερίδιο_pct,
    ROUND(SUM(ποσό) OVER (ORDER BY ποσό DESC) * 100.0
          / SUM(ποσό) OVER (), 1)                               AS αθροιστικά_pct,
    ROW_NUMBER() OVER (ORDER BY ποσό DESC)                      AS κατάταξη
FROM έσοδα
ORDER BY ποσό DESC;

-- ------------------------------------------------------------
-- 5. Μείγμα πωλήσεων ανά κατηγορία και κλίμακα τιμής
--    (το κλασικό pivot ενός dashboard)
-- ------------------------------------------------------------
SELECT
    b.category_name AS κατηγορία,
    ROUND(SUM(CASE WHEN b.price_band = '1. έως 12€'     THEN f.line_amount ELSE 0 END), 2) AS έως_12,
    ROUND(SUM(CASE WHEN b.price_band = '2. 12-18€'      THEN f.line_amount ELSE 0 END), 2) AS από_12_ως_18,
    ROUND(SUM(CASE WHEN b.price_band = '3. άνω των 18€' THEN f.line_amount ELSE 0 END), 2) AS άνω_18,
    ROUND(SUM(f.line_amount), 2)                                                           AS σύνολο
FROM fact_sales f
JOIN dim_book b ON b.book_key = f.book_key
WHERE f.status = 'paid'
GROUP BY b.category_name
ORDER BY σύνολο DESC;

-- ------------------------------------------------------------
-- 6. Cohort: κρατάμε τους πελάτες που αποκτήσαμε;
--
-- Γραμμή = έτος εγγραφής, στήλη = έτος αγοράς. Δείχνει πόσοι από
-- κάθε "γενιά" πελατών παρέμειναν ενεργοί στα επόμενα χρόνια.
-- ------------------------------------------------------------
SELECT
    c.cohort                                         AS γενιά_εγγραφής,
    COUNT(DISTINCT c.customer_key)                   AS πελάτες,
    COUNT(DISTINCT CASE WHEN d.year = 2023 THEN f.customer_key END) AS ενεργοί_2023,
    COUNT(DISTINCT CASE WHEN d.year = 2024 THEN f.customer_key END) AS ενεργοί_2024,
    COUNT(DISTINCT CASE WHEN d.year = 2025 THEN f.customer_key END) AS ενεργοί_2025
FROM dim_customer c
LEFT JOIN fact_sales f ON f.customer_key = c.customer_key AND f.status = 'paid'
LEFT JOIN dim_date   d ON d.date_key = f.date_key
GROUP BY c.cohort
ORDER BY c.cohort;

-- ------------------------------------------------------------
-- 7. Ποιότητα διαδικασίας: ποσοστό ακυρώσεων ανά έτος
--    Γι' αυτό κρατήσαμε ΟΛΑ τα status στη fact.
-- ------------------------------------------------------------
SELECT
    d.year                                                          AS έτος,
    COUNT(DISTINCT f.order_id)                                      AS παραγγελίες,
    COUNT(DISTINCT CASE WHEN f.status = 'cancelled' THEN f.order_id END) AS ακυρωμένες,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN f.status = 'cancelled' THEN f.order_id END)
          / COUNT(DISTINCT f.order_id), 1)                          AS ποσοστό_ακύρωσης,
    ROUND(SUM(CASE WHEN f.status = 'cancelled' THEN f.line_amount ELSE 0 END), 2) AS χαμένη_αξία
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.year
ORDER BY d.year;

-- ------------------------------------------------------------
-- 8. Το "KPI card" πάνω-πάνω σε κάθε dashboard
-- ------------------------------------------------------------
WITH παραγγελίες AS (
    SELECT order_id, customer_key, SUM(line_amount) AS ποσό, SUM(quantity) AS τεμ
    FROM fact_sales
    WHERE status = 'paid'
    GROUP BY order_id, customer_key
)
SELECT
    ROUND(SUM(ποσό), 2)                        AS τζίρος,
    COUNT(*)                                   AS παραγγελίες,
    ROUND(AVG(ποσό), 2)                        AS μέση_αξία_παραγγελίας,
    SUM(τεμ)                                   AS τεμάχια,
    ROUND(1.0 * SUM(τεμ) / COUNT(*), 2)        AS τεμάχια_ανά_παραγγελία,
    COUNT(DISTINCT customer_key)               AS ενεργοί_πελάτες,
    ROUND(SUM(ποσό) / COUNT(DISTINCT customer_key), 2) AS αξία_ανά_πελάτη
FROM παραγγελίες;
