WITH 
invoice_balance AS (
    SELECT 
        r.id_client,   
        i.amount,
        i.payment_due_date,
        COALESCE(SUM(p.amount), 0) AS paid_on_time
    FROM Invoice i
    JOIN Request r ON i.id_request = r.id_request
    LEFT JOIN Payment p ON i.id_invoice = p.id_invoice AND p.payment_date <= i.payment_due_date
    WHERE r.id_client IN (SELECT id_client FROM Client WHERE payment_type = 'prepayment')
      AND i.payment_due_date IS NOT NULL
      AND i.status != 'отменен'
    GROUP BY i.id_invoice, r.id_client, i.amount, i.payment_due_date
),
overdue_invoices AS (
    SELECT 
        id_client,
        (amount - paid_on_time) AS overdue_amount,
        payment_due_date
    FROM invoice_balance
    WHERE amount - paid_on_time > 0
)
SELECT 'Текущий месяц' AS period,
       COUNT(DISTINCT id_client) AS client_count,
       COALESCE(SUM(overdue_amount), 0) AS total_amount
FROM overdue_invoices
WHERE EXTRACT(YEAR FROM payment_due_date) = EXTRACT(YEAR FROM CURRENT_DATE)
  AND EXTRACT(MONTH FROM payment_due_date) = EXTRACT(MONTH FROM CURRENT_DATE)

UNION ALL

SELECT 'Предыдущий месяц' AS period,
       COUNT(DISTINCT id_client) AS client_count,
       COALESCE(SUM(overdue_amount), 0) AS total_amount
FROM overdue_invoices
WHERE EXTRACT(YEAR FROM payment_due_date) = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 month')
  AND EXTRACT(MONTH FROM payment_due_date) = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month');