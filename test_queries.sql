--All Queries

--Check all the invoices from the last year
SELECT * FROM "invoice_final"
    WHERE "due_date" BETWEEN '2024-04-30' AND '2025-04-30';

--Check which customer is associated with the final invoice
SELECT * FROM "invoice_final"
    WHERE "customer_id" IN (
        SELECT "id" FROM "customer"
        WHERE "first_name" = 'Wanda' AND "last_name" = 'Rios'
    );

--See which customers have had their invoice due date over 6 months ago
SELECT "first_name", "last_name", "invoice_number", "remaining_balance"
    FROM "AR_Ageing_Report"
    WHERE "ageing_bucket" = '6-months';

--Check which items and subtotal before tax where invoiced to Drew Mcgee
SELECT "item_name", "item_group"."unit_price(£)", "quantity", "group_total(£)"
    FROM "items" 
    JOIN "item_group" ON "item_group"."item_number" = "items"."id"
    WHERE "invoice_num" IN (
        SELECT "id" FROM "invoice" WHERE "customer_id" IN (
            SELECT "id" FROM "customer"
            WHERE "first_name" = 'Kenneth'
            AND "last_name" = 'Wolf'
            )
        );

--Check the amount paid and date from customers younger than 25 years old that havent fully paid their invoice
SELECT "amount(£)", "date"
    FROM "payments"
    WHERE "customer_number" IN (
        SELECT "id" FROM "customer" WHERE "DOB" < '2000-01-01'
    ) AND "status" = 'partial'
    ORDER BY "date";

--Key KPI's:

--Balance sheet
SELECT SUM("amount(£)") AS "cash_asset", (SUM("grand_total(£)") - SUM("amount(£)")) AS "accounts_receivable", (SUM("amount(£)") + (SUM("grand_total(£)") - SUM("amount(£)"))) AS "total_assets"
    FROM "payments" JOIN "invoice_final" ON "invoice_final"."customer_id" = "payments"."customer_number"
    WHERE "payments"."date" > '2023-12-31' AND "payments"."date" < '2025-01-01';


--Days Sales Outstanding (DSO): (AR/Credit sales paid)*days in year
--Note can change the number 365 (days in year) to user preference.
SELECT (((SUM("grand_total(£)") - SUM("amount(£)"))/SUM("amount(£)"))*365) AS "DSO"
    FROM "invoice_final"
    JOIN "payments" ON "invoice_final"."customer_id" = "payments"."customer_number"
    WHERE "method" = 'credit';

--AR Turnover : Net Credit Sales/Avg Accounts Receivable
SELECT SUM("group_total(£)") /
    ((SELECT (SUM("grand_total(£)") - SUM("amount(£)"))
        FROM "payments" JOIN "invoice_final" ON "invoice_final"."customer_id" = "payments"."customer_number"
        WHERE "payments"."date" > '2023-12-31' AND "payments"."date" < '2025-01-01') +
    (SELECT (SUM("grand_total(£)") - SUM("amount(£)"))
        FROM "payments" JOIN "invoice_final" ON "invoice_final"."customer_id" = "payments"."customer_number"
        WHERE "payments"."date" > '2022-12-31' AND "payments"."date" < '2024-01-01') / 2)
    AS "AR turnover"
    FROM "invoice_final";
