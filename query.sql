WITH 
-- Остатки по каждому счету на дату срока оплаты
invoice_balance AS (
    SELECT 
        i.id_invoice,
        i.id_request,
        i.amount,
        i.payment_due_date,
        r.id_client,
        COALESCE(SUM(p.amount) FILTER (WHERE p.payment_date <= i.payment_due_date), 0) AS paid_on_time_amount
    FROM Invoice i
    JOIN Request r ON i.id_request = r.id_request
    LEFT JOIN Payment p ON i.id_invoice = p.id_invoice
    WHERE r.id_client IN (SELECT id_client FROM Client WHERE payment_type = 'prepayment')
      AND i.payment_due_date IS NOT NULL
      AND i.status <> 'отменен'
    GROUP BY i.id_invoice, r.id_client, i.amount, i.payment_due_date
),

-- Счета с неоплаченным остатком на дату срока
overdue_invoices AS (
    SELECT 
        id_client,
        id_invoice,
        (amount - paid_on_time_amount) AS overdue_amount,
        payment_due_date
    FROM invoice_balance
    WHERE amount - paid_on_time_amount > 0
),

-- Месяцы отчёта 
current_month AS (
    SELECT DATE '2026-05-01' AS start_date, DATE '2026-05-31' AS end_date
),
prev_month AS (
    SELECT DATE '2026-04-01' AS start_date, DATE '2026-04-30' AS end_date
),

-- Данные за текущий месяц
current_data AS (
    SELECT 
        COUNT(DISTINCT o.id_client) AS client_count,
        COALESCE(SUM(o.overdue_amount), 0) AS total_amount
    FROM overdue_invoices o, current_month cm
    WHERE o.payment_due_date BETWEEN cm.start_date AND cm.end_date
),

-- Данные за предыдущий месяц
prev_data AS (
    SELECT 
        COUNT(DISTINCT o.id_client) AS client_count,
        COALESCE(SUM(o.overdue_amount), 0) AS total_amount
    FROM overdue_invoices o, prev_month pm
    WHERE o.payment_due_date BETWEEN pm.start_date AND pm.end_date
)

SELECT 'Текущий месяц (май 2026)' AS period, client_count, total_amount FROM current_data
UNION ALL
SELECT 'Предыдущий месяц (апрель 2026)' AS period, client_count, total_amount FROM prev_data;