import psycopg2
from faker import Faker
from datetime import timedelta
import random

pw = '' ##Input your personal PostgreSQL password
cursor = None
conn = None

try:
    ##To connect add your PostgreSQL database connection details
    conn = psycopg2.connect(
        host = '',
        dbname = '',
        user = '',
        password = pw,
        port = 
    )
    cursor = conn.cursor()

    fake = Faker()
    countcustomer = []
    countinvoice = []
    countitems = []

    for _ in range(100):
        customer_first_name = fake.first_name()
        customer_last_name = fake.last_name()
        fDOB = fake.date_of_birth(minimum_age=18, maximum_age=90)
        femail = fake.email()
        fbank = fake.random_int(min=9999999, max= 99999999)
        faddress = fake.address()
        fnumber = fake.phone_number()
        customer_script = '''INSERT INTO customer ("first_name", "last_name", "DOB", "email", "bank_ACC_number", "address", "phone_number")
        VALUES(%s,%s,%s,%s,%s,%s,%s) RETURNING id'''
        cursor.execute(customer_script,(customer_first_name, customer_last_name,fDOB,femail, fbank, faddress, fnumber))
        customerid = cursor.fetchone()[0]
        countcustomer.append(customerid)

    for _ in range (100):
        fcustomerID = random.choice(countcustomer)
        fdate = fake.date_between(start_date = '-3y', end_date = 'today')
        fdue_date = fake.date_between(start_date = fdate + timedelta(days=30), end_date = fdate + timedelta(days=90))
        fsubject = fake.text(max_nb_chars=30)
        invoice_script = '''INSERT INTO invoice ("customer_id", "date", "due_date", "subject")
        VALUES(%s, %s, %s, %s) RETURNING id'''
        cursor.execute(invoice_script, (fcustomerID, fdate, fdue_date, fsubject))
        invoiceid = cursor.fetchone()[0]
        countinvoice.append(invoiceid)

    for _ in range (20):
        
        fname = fake.text(max_nb_chars=10)
        fprice = fake.pyfloat(left_digits=3, right_digits=2, positive=True)
        items_script = '''INSERT INTO items ("item_name","unit_price(£)")
        VALUES(%s, %s) RETURNING id'''
        cursor.execute(items_script, (fname, fprice))
        itemid = cursor.fetchone()[0]
        countitems.append(itemid)

    methodchoices = ["debit", "credit"]
    statuschoice = ["paid", "partial", "pending"]

    for _ in range (100):
        finvoicenum2 = random.choice(countinvoice)
        fcustomernum = random.choice(countcustomer)
        fmethod = random.choice(methodchoices)
        ftotal = fake.pyfloat(left_digits= 3, right_digits= 2, positive= True)
        fdate2 = fake.date_between(start_date = '-3y', end_date = 'today') ##potential issue as it will not match up with customer invoice date
        fstatus = random.choice(statuschoice)
        payments_script = '''INSERT INTO payments ("invoice_number", "customer_number", "method", "amount(£)", "date", "status")
        VALUES (%s, %s, %s, %s, %s, %s)'''
        cursor.execute(payments_script, (finvoicenum2, fcustomernum, fmethod, ftotal, fdate2, fstatus))

    for _ in range (50):
        finvoicenum = random.choice(countinvoice)
        fitem_num = random.choice(countitems)
        fprice = fake.pyfloat(left_digits=3, right_digits=2, positive=True)
        fquantity = fake.random_int(min = 1, max = 9)
        ftotal = fake.pyfloat(left_digits=4, right_digits=2, positive=True)
        ftax = 20.00 ##original was random but will keep standard
        itemgroup_script = '''INSERT INTO item_group ("invoice_num", "item_number","quantity","unit_price(£)", "group_total(£)", "tax(%)")
        VALUES(%s, %s, %s, %s, %s, %s)'''
        cursor.execute(itemgroup_script, (finvoicenum, fitem_num, fquantity, fprice, ftotal, ftax))
    conn.commit()

except Exception as error:                  #Return error if try failed
    print('Could not connect to database because of:', error)

finally:                                    ##Close db connection and cursor if the try function did work
    if cursor is not None:
        cursor.close()
    if conn is not None:
        conn.close()