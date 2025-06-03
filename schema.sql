-- Customer table to collect customer data (would be confidential)
CREATE TABLE IF NOT EXISTS "customer" (
    "id" SERIAL PRIMARY KEY,
    "first_name" VARCHAR(60) NOT NULL,
    "last_name" VARCHAR(60) NOT NULL,
    "DOB" DATE NOT NULL,
    "email" VARCHAR(60) NOT NULL,
    "bank_ACC_number" INTEGER,
    "address" TEXT,
    "phone_number" TEXT
);

--Table for invoices by this business to customers
CREATE TABLE IF NOT EXISTS "invoice" (
    "id" SERIAL PRIMARY KEY,
    "customer_id" INTEGER NOT NULL,
    "date" DATE NOT NULL,
    "due_date" DATE NOT NULL,
    "subject" TEXT,
    FOREIGN KEY ("customer_id") REFERENCES "customer" ("id")
);

--Table for the items that are to be included in each invoice
CREATE TABLE IF NOT EXISTS "items" (
    "id" SERIAL PRIMARY KEY,
    "item_name" TEXT,
    "unit_price(£)" NUMERIC (12,2)
);

--New attribute types to be used in this payments table
CREATE TYPE "pay_method" AS ENUM ('debit', 'credit');
CREATE TYPE "status" AS ENUM ('paid', 'partial', 'pending');
--Table to store payment details by customers for different invoices
CREATE TABLE IF NOT EXISTS "payments" (
    "id" SERIAL PRIMARY KEY,
    "invoice_number" INTEGER NOT NULL,
    "customer_number" INTEGER NOT NULL,
    "method" pay_method NOT NULL,
    "amount(£)" NUMERIC (12,2) NOT NULL,
    "date" DATE NOT NULL,
    "status" status NOT NULL,
    FOREIGN KEY ("invoice_number") REFERENCES "invoice" ("id"),
    FOREIGN KEY ("customer_number") REFERENCES "customer" ("id")
);
--An aggregated final invoice with subtotal and grand total after tax that can then be queried per customer ID
CREATE TABLE IF NOT EXISTS "item_group" (
   "id" SERIAL PRIMARY KEY,
   "invoice_num" INTEGER,
   "item_number" INTEGER,
   "quantity" SMALLINT,
   "unit_price" NUMERIC(7,2),
   "group_total" NUMERIC(12,2),
   "tax" NUMERIC(5,2),
   FOREIGN KEY ("invoice_num") REFERENCES "invoice" ("id"),
   FOREIGN KEY ("item_number") REFERENCES "items" ("id")
);
--An aggregated final invoice with subtotal and grand total after tax that can then be queried per customer ID
CREATE OR REPLACE VIEW "invoice_final" AS
    SELECT "customer_id", "date", "due_date", "subject", "tax(%)", "item_group"."group_total(£)", (("item_group"."group_total(£)" * "tax(%)")/100) AS "tax_amount", ("item_group"."group_total(£)" + (("item_group"."group_total(£)" * "tax(%)")/100)) AS "grand_total(£)"
    FROM "invoice"
    JOIN "item_group" ON "invoice"."id" = "item_group"."invoice_num"
    GROUP BY "customer_id", "date","due_date", "subject", "tax(%)", "item_group"."group_total(£)"; 

--An accounts receivable ageing report to partition the data in different quarters (from approximate current date) for the financial year.
CREATE OR REPLACE VIEW "AR_Ageing_Report" AS 
    SELECT "first_name", "last_name", "invoice_number", "invoice"."date", 
    "invoice"."due_date", (CURRENT_DATE - "invoice"."due_date") AS "age", "grand_total(£)", 
    "payments"."amount(£)", ("grand_total(£)" - "payments"."amount(£)") AS "remaining_balance",
    CASE
        WHEN "invoice"."due_date" > '01-03-2025' AND "invoice"."due_date" < '30-05-2025' THEN '3-months'
        WHEN "invoice"."due_date" > '01-12-2024' AND "invoice"."due_date" < '30-05-2025' THEN '6-months'
        WHEN "invoice"."due_date" > '01-09-2024' AND "invoice"."due_date" < '30-05-2025' THEN '9-months'
        WHEN "invoice"."due_date" > '01-06-2024' AND "invoice"."due_date" < '30-05-2025' THEN '12-months'
        ELSE 
            'Outside report range'
        END AS "ageing_bucket"
    FROM "customer"
    RIGHT JOIN "invoice" ON "customer"."id" = "invoice"."customer_id"
    LEFT JOIN "payments" ON "payments"."invoice_number" = "invoice"."id"
    JOIN "invoice_final" ON "invoice_final"."customer_id" = "payments"."customer_number";

--indexes for the most likely queries
CREATE INDEX "find_customer_names" ON "customer" ("first_name", "last_name");
CREATE INDEX "find_customer_id_from_invoice" ON "invoice" ("customer_id");
CREATE INDEX "find_due_date_invoice" ON "invoice" ("due_date");
CREATE INDEX "find_unit_item_cost" ON "items" ("unit_price(£)");
CREATE INDEX "find_invoice_in_itemgroup" ON "item_group" ("invoice_num");
CREATE INDEX "find_subtotal&tax" ON "item_group" ("group_total", "tax");
CREATE INDEX "find_payment_amount" ON "payments" ("amount(£)");
CREATE INDEX "find_payment_invoice" ON "payments" ("invoice_number");
CREATE INDEX "find_payment_method" ON "payments" ("method");
CREATE INDEX "find_payment_date" ON "payments" ("date");
