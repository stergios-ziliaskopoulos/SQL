-- Dashboard πελατών — το πλήρες παράδειγμα του Μαθήματος 10.
-- Τρέξε το με:  python3 sql.py -f examples/dashboard.sql

WITH σύνολα_παραγγελιών AS (
    SELECT
        o.id          AS order_id,
        o.customer_id,
        o.order_date,
        SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, o.customer_id, o.order_date
),
ανά_πελάτη AS (
    SELECT
        customer_id,
        COUNT(*)        AS παραγγελίες,
        SUM(σύνολο)     AS τζίρος,
        MAX(order_date) AS τελευταία_αγορά
    FROM σύνολα_παραγγελιών
    GROUP BY customer_id
),
κατηγορίες_πελάτη AS (
    SELECT
        o.customer_id,
        c.name                         AS κατηγορία,
        SUM(i.quantity * i.unit_price) AS αξία,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY SUM(i.quantity * i.unit_price) DESC
        ) AS σειρά
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    JOIN books       b ON b.id = i.book_id
    JOIN categories  c ON c.id = b.category_id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id, c.name
)
SELECT
    cu.first_name || ' ' || cu.last_name AS πελάτης,
    COALESCE(cu.city, '(άγνωστη)')       AS πόλη,
    COALESCE(ap.παραγγελίες, 0)          AS παραγγελίες,
    ROUND(COALESCE(ap.τζίρος, 0), 2)     AS τζίρος,
    ap.τελευταία_αγορά,
    kp.κατηγορία                         AS αγαπημένη_κατηγορία,
    NTILE(4) OVER (ORDER BY COALESCE(ap.τζίρος, 0) DESC) AS τεταρτημόριο
FROM customers cu
LEFT JOIN ανά_πελάτη        ap ON ap.customer_id = cu.id
LEFT JOIN κατηγορίες_πελάτη kp ON kp.customer_id = cu.id AND kp.σειρά = 1
ORDER BY τζίρος DESC;
