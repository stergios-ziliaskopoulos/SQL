# Μάθημα 5 — `JOIN`: συνδυασμός πινάκων

## Στόχος

Να ενώνεις δεδομένα από πολλούς πίνακες. Εδώ ξεκλειδώνει η πραγματική δύναμη της SQL.

---

## 5.1 Γιατί τα δεδομένα είναι μοιρασμένα

Ο πίνακας `books` δεν αποθηκεύει το όνομα του συγγραφέα — κρατά ένα `author_id`:

| id | title | author_id |
|---|---|---|
| 7 | Νορβηγικό Δάσος | 4 |

Το όνομα ζει μία φορά, στον `authors`. Αυτό λέγεται **κανονικοποίηση** και το κάνουμε
για να μην γράφουμε «Χαρούκι Μουρακάμι» 5 φορές και να μην χρειάζεται να το διορθώσουμε
σε 5 σημεία αν έχει τυπογραφικό.

- **Πρωτεύον κλειδί** (primary key): η στήλη που ταυτοποιεί μοναδικά μια γραμμή (`authors.id`)
- **Ξένο κλειδί** (foreign key): η στήλη που δείχνει σε πρωτεύον κλειδί άλλου πίνακα (`books.author_id`)

Το `JOIN` είναι η πράξη που ξαναενώνει τα κομμάτια.

---

## 5.2 `INNER JOIN` — μόνο τα ταιριαστά

```sql
SELECT
    b.title,
    a.name AS συγγραφέας
FROM books b
JOIN authors a ON a.id = b.author_id;
```

Διάβασέ το ως: «για κάθε βιβλίο, βρες τη γραμμή του `authors` όπου `authors.id` ισούται με
το `books.author_id`, και κόλλησέ τες σε μία γραμμή».

- `b` και `a` είναι **ψευδώνυμα πινάκων** — γλιτώνουν πληκτρολόγηση και κάνουν σαφές
  σε ποιον πίνακα ανήκει κάθε στήλη.
- Το `ON` δηλώνει τη **συνθήκη σύνδεσης**.
- `JOIN` = `INNER JOIN` (η λέξη `INNER` είναι προαιρετική).

**Το κρίσιμο:** το `INNER JOIN` κρατά μόνο τις γραμμές που **ταιριάζουν και στις δύο πλευρές**.
Τα βιβλία 23 και 24 έχουν `author_id = NULL` — δεν εμφανίζονται καθόλου. 25 βιβλία μπαίνουν,
23 βγαίνουν. Η σιωπηλή απώλεια γραμμών είναι το #1 λάθος με τα JOIN.

---

## 5.3 `LEFT JOIN` — κράτα τα πάντα από αριστερά

```sql
SELECT
    b.title,
    a.name AS συγγραφέας
FROM books b
LEFT JOIN authors a ON a.id = b.author_id;
```

Τώρα επιστρέφονται **και τα 25** βιβλία. Όπου δεν υπάρχει ταίριασμα, οι στήλες του δεξιού
πίνακα γεμίζουν με `NULL`.

Το `LEFT JOIN` έχει μια εξαιρετικά χρήσιμη χρήση: **βρες ό,τι δεν έχει αντίστοιχο**.

```sql
-- Πελάτες που δεν έχουν κάνει ποτέ παραγγελία
SELECT c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
```

Το μοτίβο λέγεται *anti-join*: ένωσε τα πάντα, μετά κράτα όσα «δεν βρήκαν ζευγάρι».

### Η παγίδα `WHERE` vs `ON` στο `LEFT JOIN`

```sql
-- ✗ Αυτό συμπεριφέρεται σαν INNER JOIN!
SELECT c.first_name, COUNT(o.id)
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'paid'
GROUP BY c.id;

-- ✓ Η συνθήκη για τον δεξιό πίνακα πάει στο ON
SELECT c.first_name, COUNT(o.id) AS πληρωμένες
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'paid'
GROUP BY c.id;
```

Γιατί; Στο πρώτο, οι πελάτες χωρίς παραγγελίες παίρνουν `o.status = NULL`, και το
`NULL = 'paid'` δεν είναι αληθές — άρα το `WHERE` τους πετά έξω και χάνεται όλο το νόημα
του `LEFT JOIN`. Στο δεύτερο, η συνθήκη εφαρμόζεται **κατά τη σύνδεση**, οπότε ο πελάτης
μένει με μηδέν.

> **Κανόνας:** σε `LEFT JOIN`, οι συνθήκες για τον **δεξιό** πίνακα πάνε στο `ON`,
> οι συνθήκες για τον **αριστερό** στο `WHERE`.

Υπάρχει και `RIGHT JOIN` (το ίδιο ανάποδα) και `FULL OUTER JOIN` (κρατά τα πάντα κι από
τις δύο πλευρές). Στην πράξη σχεδόν όλοι γράφουν `LEFT JOIN` και αναδιατάσσουν τους πίνακες.

---

## 5.4 Πολλαπλά `JOIN` στη σειρά

Ένα ερώτημα μπορεί να ενώσει όσους πίνακες θέλεις:

```sql
SELECT
    o.id                       AS παραγγελία,
    o.order_date               AS ημερομηνία,
    c.last_name                AS πελάτης,
    b.title                    AS βιβλίο,
    i.quantity                 AS τεμάχια,
    i.quantity * i.unit_price  AS σύνολο_γραμμής
FROM orders o
JOIN customers   c ON c.id = o.customer_id
JOIN order_items i ON i.order_id = o.id
JOIN books       b ON b.id = i.book_id
WHERE o.status = 'paid'
ORDER BY o.order_date DESC, o.id
LIMIT 20;
```

Αυτό είναι το τυπικό σχήμα «παραγγελία → γραμμές → προϊόν». Ο πίνακας `order_items` λέγεται
**πίνακας σύνδεσης** και υλοποιεί τη σχέση **πολλά-προς-πολλά**: μία παραγγελία έχει πολλά
βιβλία, ένα βιβλίο εμφανίζεται σε πολλές παραγγελίες.

---

## 5.5 `JOIN` + `GROUP BY`: ο συνηθέστερος συνδυασμός στην πράξη

```sql
-- Τα 10 βιβλία με τις περισσότερες πωλήσεις
SELECT
    b.title,
    SUM(i.quantity)                          AS τεμάχια,
    ROUND(SUM(i.quantity * i.unit_price), 2) AS έσοδα
FROM books b
JOIN order_items i ON i.book_id = b.id
JOIN orders      o ON o.id = i.order_id
WHERE o.status = 'paid'
GROUP BY b.id, b.title
ORDER BY τεμάχια DESC
LIMIT 10;
```

```sql
-- Τζίρος ανά πόλη, με τους πελάτες χωρίς παραγγελίες να εμφανίζονται με 0
SELECT
    COALESCE(c.city, '(άγνωστη)')                     AS πόλη,
    COUNT(DISTINCT c.id)                              AS πελάτες,
    ROUND(COALESCE(SUM(i.quantity * i.unit_price), 0), 2) AS τζίρος
FROM customers c
LEFT JOIN orders      o ON o.customer_id = c.id AND o.status = 'paid'
LEFT JOIN order_items i ON i.order_id = o.id
GROUP BY πόλη
ORDER BY τζίρος DESC;
```

---

## 5.6 `SELF JOIN` — ο πίνακας με τον εαυτό του

Ο `employees` κρατά τον προϊστάμενο ως `manager_id` που δείχνει στον **ίδιο** πίνακα:

```sql
SELECT
    e.name AS υπάλληλος,
    e.role AS θέση,
    m.name AS προϊστάμενος
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY m.name, e.name;
```

Δύο ψευδώνυμα (`e`, `m`) για τον ίδιο πίνακα — η βάση τους αντιμετωπίζει ως δύο ανεξάρτητα
αντίγραφα. Το `LEFT JOIN` κρατά και τη διευθύντρια, που δεν έχει προϊστάμενο.

---

## 5.7 Ο πολλαπλασιασμός γραμμών

Αν ξεχάσεις το `ON`, παίρνεις **καρτεσιανό γινόμενο**: κάθε γραμμή με κάθε γραμμή.

```sql
SELECT COUNT(*) FROM books, authors;   -- 25 × 12 = 300 γραμμές!
```

Πιο ύπουλο: ακόμα και με σωστό `ON`, ένα `JOIN` προς πίνακα «πολλών» πολλαπλασιάζει τις
γραμμές. Γι' αυτό αυτό είναι **λάθος**:

```sql
-- ✗ Το stock μετριέται όσες φορές πουλήθηκε το βιβλίο
SELECT SUM(b.stock)
FROM books b JOIN order_items i ON i.book_id = b.id;
```

Όποτε αθροίζεις στήλη του «ενός» πίνακα μετά από `JOIN` με τον «πολλά», σταμάτα και σκέψου.
Η λύση συνήθως είναι υποερώτημα ή CTE — Μάθημα 6.

---

## Περίληψη

| Τύπος | Κρατά |
|---|---|
| `INNER JOIN` | μόνο τα ταιριαστά ζεύγη |
| `LEFT JOIN` | όλα τα αριστερά + ό,τι ταιριάξει |
| `LEFT JOIN … WHERE δεξί.id IS NULL` | όσα **δεν** έχουν αντίστοιχο |
| `SELF JOIN` | ιεραρχίες μέσα στον ίδιο πίνακα |

➡️ **Ασκήσεις:** [`exercises/lesson-05.md`](../exercises/lesson-05.md)
➡️ **Επόμενο:** [Μάθημα 6 — Υποερωτήματα και CTE](06-subqueries.md)
