# Μάθημα 6 — Υποερωτήματα και CTE

## Στόχος

Να χτίζεις ερωτήματα σε βήματα, χρησιμοποιώντας το αποτέλεσμα ενός ερωτήματος μέσα σε άλλο.

---

## 6.1 Υποερώτημα που επιστρέφει **μία τιμή**

```sql
-- Βιβλία ακριβότερα από τον μέσο όρο
SELECT title, price
FROM books
WHERE price > (SELECT AVG(price) FROM books)
ORDER BY price DESC;
```

Το εσωτερικό ερώτημα τρέχει πρώτα, δίνει έναν αριθμό, και το εξωτερικό τον χρησιμοποιεί σαν
να τον είχες γράψει με το χέρι. Αυτό **δεν** γίνεται με σκέτο `WHERE price > AVG(price)`:
οι συγκεντρωτικές συναρτήσεις δεν επιτρέπονται στο `WHERE`.

---

## 6.2 Υποερώτημα που επιστρέφει **λίστα**: `IN`

```sql
-- Βιβλία που έχουν πουληθεί τουλάχιστον μία φορά
SELECT title
FROM books
WHERE id IN (SELECT book_id FROM order_items);

-- ...και το αντίστροφο
SELECT title
FROM books
WHERE id NOT IN (SELECT book_id FROM order_items);
```

> **Προσοχή στο `NOT IN` με `NULL`.** Αν η λίστα του υποερωτήματος περιέχει έστω ένα `NULL`,
> το `NOT IN` δεν επιστρέφει **καμία** γραμμή. Λόγος: το `x NOT IN (1, NULL)` σημαίνει
> `x <> 1 AND x <> NULL`, και το δεύτερο σκέλος είναι πάντα άγνωστο.
> Γι' αυτό, όταν υπάρχει περίπτωση `NULL`, προτίμησε `NOT EXISTS`.

---

## 6.3 `EXISTS` και `NOT EXISTS`

Το `EXISTS` δεν ενδιαφέρεται *τι* επιστρέφει το υποερώτημα, μόνο *αν* επιστρέφει κάτι:

```sql
-- Πελάτες που έχουν γράψει τουλάχιστον μία κριτική με 5 αστέρια
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.customer_id = c.id      -- ← συσχέτιση με το εξωτερικό ερώτημα
      AND r.rating = 5
);
```

Πρόσεξε το `r.customer_id = c.id`: το υποερώτημα αναφέρεται σε στήλη του εξωτερικού.
Αυτό λέγεται **συσχετισμένο υποερώτημα** (correlated subquery) — εννοιολογικά εκτελείται
μία φορά για κάθε γραμμή του εξωτερικού ερωτήματος.

```sql
-- Βιβλία που δεν έχουν καμία κριτική
SELECT b.title
FROM books b
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.book_id = b.id);
```

Τρεις δρόμοι για το ίδιο πράγμα — `LEFT JOIN … IS NULL`, `NOT IN`, `NOT EXISTS`. Το
`NOT EXISTS` είναι το ασφαλέστερο απέναντι στα `NULL`.

---

## 6.4 Υποερώτημα ως **πίνακας** (`FROM`)

```sql
-- Μέσος όρος παραγγελιών ανά πελάτη, με βάση το σύνολο κάθε παραγγελίας
SELECT
    ROUND(AVG(σύνολο), 2) AS μέση_αξία_παραγγελίας
FROM (
    SELECT
        o.id,
        SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id
);
```

Πρώτα υπολογίζουμε το σύνολο **κάθε** παραγγελίας, μετά παίρνουμε τον μέσο όρο αυτών των
συνόλων. Δύο επίπεδα ομαδοποίησης — αδύνατο σε ένα μόνο `GROUP BY`.

---

## 6.5 CTE: `WITH` — ο πολιτισμένος τρόπος

Ένα **CTE** (Common Table Expression) είναι ένα ονομασμένο προσωρινό αποτέλεσμα που
δηλώνεις **πριν** το κυρίως ερώτημα. Ίδια δύναμη με το υποερώτημα, πολύ καλύτερη ανάγνωση:

```sql
WITH σύνολα_παραγγελιών AS (
    SELECT
        o.id          AS order_id,
        o.customer_id,
        SUM(i.quantity * i.unit_price) AS σύνολο
    FROM orders o
    JOIN order_items i ON i.order_id = o.id
    WHERE o.status = 'paid'
    GROUP BY o.id, o.customer_id
)
SELECT
    c.first_name || ' ' || c.last_name AS πελάτης,
    COUNT(*)                           AS παραγγελίες,
    ROUND(SUM(s.σύνολο), 2)            AS συνολικά_ξόδεψε,
    ROUND(AVG(s.σύνολο), 2)            AS μέση_παραγγελία
FROM σύνολα_παραγγελιών s
JOIN customers c ON c.id = s.customer_id
GROUP BY c.id
ORDER BY συνολικά_ξόδεψε DESC;
```

Πολλά CTE, χωρισμένα με κόμμα, και το καθένα μπορεί να χρησιμοποιεί τα προηγούμενα:

```sql
WITH πωλήσεις AS (
    SELECT i.book_id, SUM(i.quantity) AS τεμάχια
    FROM order_items i
    JOIN orders o ON o.id = i.order_id
    WHERE o.status = 'paid'
    GROUP BY i.book_id
),
βαθμολογίες AS (
    SELECT book_id, ROUND(AVG(rating), 2) AS μέση, COUNT(*) AS πλήθος
    FROM reviews
    GROUP BY book_id
)
SELECT
    b.title,
    COALESCE(p.τεμάχια, 0) AS πωλήσεις,
    v.μέση                 AS βαθμολογία,
    v.πλήθος               AS κριτικές
FROM books b
LEFT JOIN πωλήσεις    p ON p.book_id = b.id
LEFT JOIN βαθμολογίες v ON v.book_id = b.id
ORDER BY πωλήσεις DESC, βαθμολογία DESC;
```

**Πότε CTE και πότε υποερώτημα;** Για οτιδήποτε πέρα από το τετριμμένο, CTE. Διαβάζεται από
πάνω προς τα κάτω σαν συνταγή, μπορείς να τρέξεις κάθε κομμάτι ξεχωριστά για έλεγχο, και
γλιτώνεις τις φωλιασμένες παρενθέσεις που καταλήγουν αδιάβαστες.

---

## 6.6 Αναδρομικά CTE (μπόνους)

Ένα CTE μπορεί να καλεί τον εαυτό του — ιδανικό για ιεραρχίες:

```sql
WITH RECURSIVE ιεραρχία AS (
    -- βάση: η κορυφή της πυραμίδας
    SELECT id, name, manager_id, 0 AS επίπεδο
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- βήμα: όποιος αναφέρεται σε κάποιον που ήδη βρήκαμε
    SELECT e.id, e.name, e.manager_id, ι.επίπεδο + 1
    FROM employees e
    JOIN ιεραρχία ι ON ι.id = e.manager_id
)
SELECT SUBSTR('                    ', 1, επίπεδο * 3) || name AS οργανόγραμμα, επίπεδο
FROM ιεραρχία
ORDER BY επίπεδο, name;
```

---

## 6.7 `UNION`: κάθετη ένωση αποτελεσμάτων

Το `JOIN` κολλά πίνακες **οριζόντια** (προσθέτει στήλες). Το `UNION` τους κολλά **κάθετα**
(προσθέτει γραμμές). Απαιτεί ίδιο πλήθος στηλών με συμβατούς τύπους.

```sql
SELECT 'ακριβό' AS κατηγορία, title, price FROM books WHERE price > 25
UNION ALL
SELECT 'φθηνό',              title, price FROM books WHERE price < 10
ORDER BY price;
```

- `UNION` → αφαιρεί τα διπλότυπα (κοστίζει)
- `UNION ALL` → τα κρατά όλα (γρηγορότερο· χρησιμοποίησέ το όταν ξέρεις ότι δεν υπάρχουν)

---

## Περίληψη

| Θέλω | Γράφω |
|---|---|
| μία τιμή για σύγκριση | `WHERE x > (SELECT AVG(...) …)` |
| λίστα τιμών | `WHERE id IN (SELECT …)` |
| «υπάρχει τουλάχιστον ένα» | `WHERE EXISTS (SELECT 1 …)` |
| «δεν υπάρχει κανένα» | `WHERE NOT EXISTS (…)` |
| ενδιάμεσο αποτέλεσμα | `WITH όνομα AS (…) SELECT …` |
| ένωση γραμμών | `UNION ALL` |

➡️ **Ασκήσεις:** [`exercises/lesson-06.md`](../exercises/lesson-06.md)
➡️ **Επόμενο:** [Μάθημα 7 — Window functions](07-window-functions.md)
