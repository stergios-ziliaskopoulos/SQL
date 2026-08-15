# Λύσεις — Μάθημα 12 (Oracle)

## Μεταφράσεις

**1.**
```sql
SELECT SYSDATE FROM dual;
-- ή, μόνο η ημερομηνία χωρίς ώρα:
SELECT TRUNC(SYSDATE) FROM dual;
```

**2.**
```sql
SELECT title, NVL(author_id, 0) AS συγγραφέας FROM books;
```
Το `COALESCE(author_id, 0)` δουλεύει επίσης — το `NVL` είναι το «ντόπιο» και δέχεται
ακριβώς δύο ορίσματα.

**3.**
```sql
SELECT title, price FROM books ORDER BY price DESC FETCH FIRST 5 ROWS ONLY;

-- Σε 11g και παλαιότερα:
SELECT * FROM (SELECT title, price FROM books ORDER BY price DESC) WHERE ROWNUM <= 5;
```

**4.**
```sql
SELECT title, price FROM books
ORDER BY price DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
```

**5.** Δύο αλλαγές: `TO_CHAR` αντί `STRFTIME`, και **επανάληψη της έκφρασης** στο `GROUP BY`
(η Oracle δεν δέχεται ψευδώνυμο εκεί).
```sql
SELECT TO_CHAR(order_date, 'YYYY-MM') AS μήνας, SUM(id) AS x
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY μήνας;
```
Καθαρότερα, με CTE — δουλεύει και στις δύο βάσεις:
```sql
WITH βάση AS (
    SELECT TO_CHAR(order_date, 'YYYY-MM') AS μήνας, id FROM orders
)
SELECT μήνας, SUM(id) AS x FROM βάση GROUP BY μήνας ORDER BY μήνας;
```

**6.**
```sql
SELECT id, order_date FROM orders
WHERE order_date >= TO_DATE('2025-01-01', 'YYYY-MM-DD')
  AND order_date <  TO_DATE('2025-02-01', 'YYYY-MM-DD');
```
Στην Oracle η `order_date` είναι πραγματικός τύπος `DATE`, όχι κείμενο — η σύγκριση με
συμβολοσειρά θα βασιζόταν στο `NLS_DATE_FORMAT` της συνεδρίας.

**7.**
```sql
SELECT category_id,
       LISTAGG(title, ', ') WITHIN GROUP (ORDER BY title) AS τίτλοι
FROM books
GROUP BY category_id;
```

**8.**
```sql
SELECT
    LEVEL                              AS επίπεδο,
    LPAD(' ', (LEVEL - 1) * 3) || name AS οργανόγραμμα
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR id = manager_id
ORDER SIBLINGS BY name;
```

**9.**
```sql
MERGE INTO categories c
USING (SELECT 1 AS id, 'Λογοτεχνία & Ποίηση' AS name FROM dual) s
   ON (c.id = s.id)
WHEN MATCHED THEN
    UPDATE SET c.name = s.name
WHEN NOT MATCHED THEN
    INSERT (id, name) VALUES (s.id, s.name);
```

**10.**
```sql
SELECT id FROM books
MINUS
SELECT book_id FROM order_items;
```
Η Oracle δεν έχει `EXCEPT` (το πρόσθεσε μόλις στην 21c ως συνώνυμο). Το `MINUS`, όπως και το
`EXCEPT`, αφαιρεί **και** τα διπλότυπα.

---

## Ερωτήσεις κατανόησης

**11.** Ο τύπος `DATE` της Oracle περιέχει και **ώρα**. Το `TO_DATE('2025-01-31','YYYY-MM-DD')`
είναι η 31η Ιανουαρίου στις **00:00:00**, οπότε το `BETWEEN` αποκλείει ό,τι συνέβη μέσα στην
ημέρα — μια ολόκληρη μέρα συναλλαγών χάνεται σιωπηλά. Σωστά:
```sql
WHERE order_date >= TO_DATE('2025-01-01','YYYY-MM-DD')
  AND order_date <  TO_DATE('2025-02-01','YYYY-MM-DD')
```
Το `>= αρχή AND < επόμενη αρχή` είναι σωστό σε κάθε βάση, με ή χωρίς ώρα.

**12.** Επιστρέφει **0**. Στην Oracle το κενό κείμενο αποθηκεύεται ως `NULL`, και κάθε
σύγκριση με `NULL` δίνει «άγνωστο» — άρα καμία γραμμή δεν περνά το φίλτρο. Ο έλεγχος που
θέλεις είναι `WHERE city IS NULL`. (Σε PostgreSQL/SQLite το `''` και το `NULL` είναι
διαφορετικά, γι' αυτό ο ίδιος κώδικας συμπεριφέρεται αλλιώς μετά από μετάπτωση.)

**13.** Οι δύο βάσεις ταξινομούν τα `NULL` αντίθετα: η SQLite τα θεωρεί **μικρότερα** από όλα
(βγαίνουν πρώτα σε αύξουσα), η Oracle **μεγαλύτερα** (βγαίνουν τελευταία). Κλείδωσέ το ρητά:
```sql
ORDER BY country NULLS LAST
```
Γενικός κανόνας: αν η σειρά έχει σημασία για την αναφορά, δήλωσέ την — μην την κληρονομείς
από τη βάση.

**14.** Το `ROWNUM` αποδίδεται **καθώς** οι γραμμές περνούν το `WHERE`, δηλαδή **πριν** από
το `ORDER BY`. Άρα κρατάς 5 αυθαίρετες γραμμές και μετά τις ταξινομείς. Λύση: ταξινόμησε σε
υποερώτημα και φίλτραρε απ' έξω, ή χρησιμοποίησε `FETCH FIRST 5 ROWS ONLY`.

**15.** Το bind variable είναι θέση παραμέτρου (`:email`) που η τιμή της περνά **χωριστά** από
το κείμενο του ερωτήματος. Λύνει δύο προβλήματα:
- **Ασφάλεια:** η τιμή δεν ερμηνεύεται ποτέ ως SQL, άρα αποκλείεται το SQL injection.
- **Απόδοση:** η Oracle αποθηκεύει το πλάνο ανά κείμενο ερωτήματος. Με συνένωση τιμών κάθε
  εκτέλεση είναι «νέο» ερώτημα και ξαναϋπολογίζεται πλάνο (*hard parse*) — από τις πιο συχνές
  αιτίες επιβάρυνσης σε εταιρικά συστήματα.

**16.** Η προεπιλογή είναι `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. Με το `RANGE`,
όλες οι γραμμές που έχουν **ίδια τιμή** στο `ORDER BY` θεωρούνται μία «θέση» και μπαίνουν όλες
μαζί στο παράθυρο. Αν δύο πωλήσεις έχουν την ίδια ημερομηνία, το αθροιστικό σύνολο τους
περιλαμβάνει και τις δύο ήδη από την πρώτη γραμμή — αποτέλεσμα που φαίνεται «λάθος» στο
γράφημα. Όταν θέλεις κυριολεκτικά «οι γραμμές μέχρι εδώ», γράψε ρητά:
```sql
SUM(ποσό) OVER (ORDER BY ημερομηνία ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
```
Ισχύει σε Oracle, PostgreSQL και SQLite.
