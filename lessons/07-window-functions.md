# Μάθημα 7 — Window functions

## Στόχος

Να κάνεις υπολογισμούς «ανά ομάδα» **χωρίς** να χάσεις τις επιμέρους γραμμές.

---

## 7.1 Το πρόβλημα που λύνουν

Το `GROUP BY` συμπτύσσει: 25 βιβλία → 7 γραμμές, μία ανά κατηγορία. Τι γίνεται όμως αν
θέλεις να δεις **κάθε βιβλίο** και δίπλα του τη μέση τιμή της κατηγορίας του;

Οι **window functions** το κάνουν ακριβώς αυτό: υπολογίζουν πάνω σε ένα «παράθυρο»
γειτονικών γραμμών, αλλά επιστρέφουν **μία τιμή ανά γραμμή**.

```sql
SELECT
    title,
    category_id,
    price,
    ROUND(AVG(price) OVER (PARTITION BY category_id), 2) AS μέση_κατηγορίας,
    ROUND(price - AVG(price) OVER (PARTITION BY category_id), 2) AS διαφορά
FROM books
ORDER BY category_id, price DESC;
```

Η μαγική λέξη είναι το **`OVER`**. Ό,τι έχει `OVER`, είναι window function.

- `PARTITION BY` → πώς χωρίζονται οι γραμμές σε παράθυρα (σαν `GROUP BY`, χωρίς σύμπτυξη)
- χωρίς `PARTITION BY` → το παράθυρο είναι **όλες** οι γραμμές

```sql
SELECT title, price,
       ROUND(price * 100.0 / SUM(price) OVER (), 2) AS ποσοστό_επί_του_συνόλου
FROM books
ORDER BY ποσοστό_επί_του_συνόλου DESC;
```

---

## 7.2 Κατάταξη: `ROW_NUMBER`, `RANK`, `DENSE_RANK`

```sql
SELECT
    title,
    category_id,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS σειρά,
    RANK()       OVER (PARTITION BY category_id ORDER BY price DESC) AS κατάταξη,
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS πυκνή_κατάταξη
FROM books
ORDER BY category_id, price DESC;
```

Η διαφορά τους φαίνεται μόνο στις **ισοπαλίες**. Για τιμές 20, 15, 15, 12:

| τιμή | `ROW_NUMBER` | `RANK` | `DENSE_RANK` |
|---|---|---|---|
| 20 | 1 | 1 | 1 |
| 15 | 2 | 2 | 2 |
| 15 | 3 | 2 | 2 |
| 12 | 4 | 4 | 3 |

- `ROW_NUMBER` → πάντα μοναδικός αύξων αριθμός (σπάει αυθαίρετα τις ισοπαλίες)
- `RANK` → ίδια κατάταξη στις ισοπαλίες, μετά **πηδά**
- `DENSE_RANK` → ίδια κατάταξη, **χωρίς κενά**

### Top-N ανά ομάδα — το κλασικό μοτίβο

Window function **δεν** μπαίνει στο `WHERE` (τρέχει μετά από αυτό). Άρα τυλίγεις σε CTE:

```sql
-- Τα 2 ακριβότερα βιβλία κάθε κατηγορίας
WITH κατάταξη AS (
    SELECT
        title, category_id, price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS σειρά
    FROM books
)
SELECT category_id, title, price
FROM κατάταξη
WHERE σειρά <= 2
ORDER BY category_id, price DESC;
```

Θυμήσου το — είναι από τις πιο συχνές ερωτήσεις σε συνεντεύξεις SQL.

---

## 7.3 `LAG` και `LEAD`: η προηγούμενη και η επόμενη γραμμή

```sql
-- Μηνιαίος τζίρος και μεταβολή από τον προηγούμενο μήνα
WITH ανά_μήνα AS (
    SELECT
        STRFTIME('%Y-%m', o.order_date)          AS μήνας,
        SUM(i.quantity * i.unit_price)           AS τζίρος
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY μήνας
)
SELECT
    μήνας,
    ROUND(τζίρος, 2)                              AS τζίρος,
    ROUND(LAG(τζίρος) OVER (ORDER BY μήνας), 2)   AS προηγούμενος,
    ROUND(τζίρος - LAG(τζίρος) OVER (ORDER BY μήνας), 2) AS μεταβολή
FROM ανά_μήνα
ORDER BY μήνας;
```

`LAG(x)` = η τιμή της προηγούμενης γραμμής, `LEAD(x)` = της επόμενης. Στην πρώτη/τελευταία
γραμμή δίνουν `NULL` — εκτός αν ορίσεις προεπιλογή: `LAG(τζίρος, 1, 0)`.

---

## 7.4 Αθροιστικά σύνολα (running total)

Εδώ μπαίνει το `ORDER BY` **μέσα** στο `OVER`: ορίζει ότι το παράθυρο μεγαλώνει καθώς
προχωράμε.

```sql
WITH ανά_μήνα AS (
    SELECT
        STRFTIME('%Y-%m', o.order_date)  AS μήνας,
        SUM(i.quantity * i.unit_price)   AS τζίρος
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY μήνας
)
SELECT
    μήνας,
    ROUND(τζίρος, 2)                                    AS τζίρος,
    ROUND(SUM(τζίρος) OVER (ORDER BY μήνας), 2)         AS αθροιστικά,
    ROUND(AVG(τζίρος) OVER (ORDER BY μήνας
                            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS κινητός_μ_ο_3μήνου
FROM ανά_μήνα
ORDER BY μήνας;
```

Δύο πράγματα να κρατήσεις:

- `SUM(x) OVER (ORDER BY …)` → αθροιστικό σύνολο (το παράθυρο είναι «από την αρχή ως εδώ»)
- `ROWS BETWEEN n PRECEDING AND CURRENT ROW` → κυλιόμενο παράθυρο σταθερού μεγέθους

---

## 7.5 Πότε window και πότε `GROUP BY`

| Ερώτηση | Εργαλείο |
|---|---|
| «Πόσα βιβλία ανά κατηγορία;» | `GROUP BY` |
| «Κάθε βιβλίο + ο μέσος όρος της κατηγορίας του» | window |
| «Ποιο είναι το ακριβότερο κάθε κατηγορίας;» | window (`ROW_NUMBER`) |
| «Αθροιστικός τζίρος στον χρόνο» | window |
| «Σύνολο τζίρου ανά έτος» | `GROUP BY` |

Ο κανόνας σε μία γραμμή: **θέλεις να κρατήσεις τις γραμμές; window. Θέλεις να τις
συμπτύξεις; `GROUP BY`.**

---

➡️ **Ασκήσεις:** [`exercises/lesson-07.md`](../exercises/lesson-07.md)
➡️ **Επόμενο:** [Μάθημα 8 — Εισαγωγή, ενημέρωση, διαγραφή](08-insert-update-delete.md)
