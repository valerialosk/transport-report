# Кейс: Оптимизация обработки заявок на перевозку и контроль внесения предоплаты

**Компания:** КРОК  
**Роль:** ИТ-аналитик  
**Задача:** Разработать процессное и логическое описание бизнес-процесса «Обработка заявки на перевозку фурой», а также подготовить универсальный SQL-отчёт для руководителя по клиентам, не внесшим предоплату в срок.

---

## 1. Описание бизнес-процесса (BPMN 2.0)

Процесс начинается с поступления заявки от клиента (телефон, email). Менеджер проверяет возможность перевозки, при необходимости согласует с сотрудником эксплуатации. Если перевозка невозможна – отказ клиенту. Если возможна – заявка фиксируется в ИБ, выставляется счёт на предоплату (для клиентов с типом `prepayment`). Далее логист подбирает машину; при успехе менеджер сопровождает рейс, по завершении отправляет закрывающие документы и контролирует оплату (при отсрочке). При любом отказе процесс завершается.

![BPMN диаграмма](https://disk.yandex.ru/i/KwkCifVLx2UuKg)  
*Для просмотра диаграммы в формате pdf - нажмите на ссылку (она выполнена в нотации BPMN 2.0)*

---

## 2. ER-модель данных

### Концептуальная модель
Сущности и связи (1:N, 1:0..1, N:1):

- **Клиент** (1) — оставляет — **Заявку** (N)
- **Сотрудник-менеджер** (1) — обрабатывает — **Заявку** (N)
- **Заявка** (1) — выставляет — **Счёт** (0..1) (только при предоплате)
- **Счёт** (1) — оплачивается — **Платежами** (N)
- **Заявка** (1) — выполняется как — **Рейс** (0..1) (если найден ТС)
- **Рейс** (N) — использует — **Транспортное средство** (1)
- **Сотрудник-логист** (1) — назначает — **Рейс** (N)

### Логическая модель (физическая схема)
Все таблицы, ключи, индексы описаны в файле [`schema.sql`](./schema.sql). Основные сущности:

- `Client` – клиенты (тип оплаты `prepayment` / `credit`)
- `Invoice` – счета с полем `payment_due_date` (срок предоплаты)
- `Payment` – платежи
- `Request`, `Employee`, `Vehicle`, `Trip` – обеспечивают полный контекст.

Тестовые данные находятся в [`data.sql`](./data.sql).

---

## 3. SQL-отчёт: просроченная предоплата за текущий и предыдущий месяц

**Бизнес-требование:**  
Руководитель получает ежемесячный отчёт: сколько клиентов не заплатили предоплату в установленный срок и на какую сумму, а также сравнение с прошлым месяцем.

**Универсальность решения:**  
Запрос не содержит жёстких дат – он вычисляет текущий и предыдущий месяц на основе `CURRENT_DATE`. Поэтому его можно использовать без доработок в любом периоде.

**Учтённые нюансы:**
- Только клиенты с `payment_type = 'prepayment'`
- Частичные платежи: если оплата поступила до `payment_due_date` – она вычитается из долга
- Счета со статусом «отменен» исключены
- Просрочка = сумма счета – оплаченная вовремя часть, если остаток > 0.

```sql
-- Файл query.sql (см. в репозитории)

WITH invoice_balance AS (
    SELECT 
        r.id_client,
        i.amount,
        i.payment_due_date,
        COALESCE(SUM(p.amount), 0) AS paid_on_time
    FROM Invoice i
    JOIN Request r ON i.id_request = r.id_request
    LEFT JOIN Payment p ON i.id_invoice = p.id_invoice 
                      AND p.payment_date <= i.payment_due_date
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
