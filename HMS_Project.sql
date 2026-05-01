-- ============================================================
--  HOSPITAL MANAGEMENT SYSTEM — PostgreSQL Implementation
--  Course  : Database Management Systems – UCS310
--  Institute: Thapar Institute of Engineering and Technology
--  Group   : Harnoor Kaur Dran (1024170436)
--             Nandini Sharma    (1024170445)
--  Session : Jan–May 2026
-- ============================================================

-- ============================================================
-- SECTION 1 : DDL — CREATE TABLES  (3NF / BCNF Schema)
-- ============================================================

-- Drop tables in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS payment    CASCADE;
DROP TABLE IF EXISTS bill       CASCADE;
DROP TABLE IF EXISTS treatment  CASCADE;
DROP TABLE IF EXISTS appointment CASCADE;
DROP TABLE IF EXISTS doctor     CASCADE;
DROP TABLE IF EXISTS patient    CASCADE;

-- -----------------------------------------------
-- PATIENT  (PK: patient_id)
-- -----------------------------------------------
CREATE TABLE patient (
    patient_id  SERIAL          PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    age         SMALLINT        NOT NULL CHECK (age BETWEEN 0 AND 150),
    gender      CHAR(1)         NOT NULL CHECK (gender IN ('M','F','O')),
    phone       VARCHAR(15)     NOT NULL UNIQUE,
    address     VARCHAR(255)
);

-- -----------------------------------------------
-- DOCTOR  (PK: doctor_id)
-- -----------------------------------------------
CREATE TABLE doctor (
    doctor_id       SERIAL          PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    specialization  VARCHAR(60)     NOT NULL,
    phone           VARCHAR(15)     NOT NULL UNIQUE
);

-- -----------------------------------------------
-- APPOINTMENT  (PK: app_id | FK → patient, doctor)
-- -----------------------------------------------
CREATE TABLE appointment (
    app_id      SERIAL          PRIMARY KEY,
    patient_id  INT             NOT NULL REFERENCES patient(patient_id)  ON DELETE CASCADE,
    doctor_id   INT             NOT NULL REFERENCES doctor(doctor_id)    ON DELETE CASCADE,
    app_date    DATE            NOT NULL,
    app_time    VARCHAR(10)     NOT NULL,
    status      VARCHAR(20)     NOT NULL DEFAULT 'Scheduled'
                                CHECK (status IN ('Scheduled','Completed','Cancelled')),
    UNIQUE (doctor_id, app_date, app_time)   -- prevents double-booking same slot
);

-- -----------------------------------------------
-- TREATMENT  (PK: treatment_id | FK → appointment)
-- -----------------------------------------------
CREATE TABLE treatment (
    treatment_id  SERIAL          PRIMARY KEY,
    app_id        INT             NOT NULL UNIQUE REFERENCES appointment(app_id) ON DELETE CASCADE,
    diagnosis     VARCHAR(200)    NOT NULL,
    medicines     VARCHAR(300)
);

-- -----------------------------------------------
-- BILL  (PK: bill_id | FK → treatment)
-- -----------------------------------------------
CREATE TABLE bill (
    bill_id       SERIAL              PRIMARY KEY,
    treatment_id  INT                 NOT NULL UNIQUE REFERENCES treatment(treatment_id) ON DELETE CASCADE,
    amount        NUMERIC(10,2)       NOT NULL CHECK (amount >= 0),
    bill_date     DATE                NOT NULL DEFAULT CURRENT_DATE,
    status        VARCHAR(15)         NOT NULL DEFAULT 'Unpaid'
                                      CHECK (status IN ('Unpaid','Paid'))
);

-- -----------------------------------------------
-- PAYMENT  (PK: payment_id | FK → bill)
-- -----------------------------------------------
CREATE TABLE payment (
    payment_id  SERIAL          PRIMARY KEY,
    bill_id     INT             NOT NULL UNIQUE REFERENCES bill(bill_id) ON DELETE CASCADE,
    mode        VARCHAR(20)     NOT NULL CHECK (mode IN ('Cash','Card','UPI','Net Banking')),
    status      VARCHAR(15)     NOT NULL DEFAULT 'Completed'
                                CHECK (status IN ('Completed','Failed','Pending')),
    pay_date    DATE            NOT NULL DEFAULT CURRENT_DATE
);


-- ============================================================
-- SECTION 2 : DML — SAMPLE DATA  (INSERT)
-- ============================================================

-- Patients
INSERT INTO patient (name, age, gender, phone, address) VALUES
('Rahul Sharma',   28, 'M', '9876543210', '12 MG Road, Delhi'),
('Priya Singh',    35, 'F', '9123456780', '45 Park Street, Mumbai'),
('Amit Verma',     52, 'M', '9988776655', '7 Lake View, Chandigarh'),
('Sunita Devi',    41, 'F', '9001122334', '88 GT Road, Ludhiana'),
('Rohan Kapoor',   19, 'M', '9871234560', '23 Sector 17, Patiala');

-- Doctors
INSERT INTO doctor (name, specialization, phone) VALUES
('Dr. Rajiv Mehta',  'General Medicine',   '9811122233'),
('Dr. Sneha Gupta',  'Cardiology',         '9822233344'),
('Dr. Arvind Kumar', 'Orthopaedics',       '9833344455'),
('Dr. Pooja Nair',   'Dermatology',        '9844455566');

-- Appointments
INSERT INTO appointment (patient_id, doctor_id, app_date, app_time, status) VALUES
(1, 1, '2026-05-01', '09:00 AM', 'Completed'),
(2, 2, '2026-05-01', '10:30 AM', 'Completed'),
(3, 3, '2026-05-02', '11:00 AM', 'Completed'),
(4, 1, '2026-05-03', '02:00 PM', 'Scheduled'),
(5, 4, '2026-05-03', '03:30 PM', 'Scheduled');

-- Treatments (only for completed appointments)
INSERT INTO treatment (app_id, diagnosis, medicines) VALUES
(1, 'Viral Fever',          'Paracetamol 500mg, Crocin, ORS'),
(2, 'Hypertension (BP)',    'Amlodipine 5mg, Telmisartan 40mg'),
(3, 'Knee Osteoarthritis',  'Diclofenac Gel, Calcium Supplements');

-- Bills (auto-generated after treatment)
INSERT INTO bill (treatment_id, amount, bill_date, status) VALUES
(1, 500.00,  '2026-05-01', 'Paid'),
(2, 800.00,  '2026-05-01', 'Paid'),
(3, 1200.00, '2026-05-02', 'Unpaid');

-- Payments (for paid bills)
INSERT INTO payment (bill_id, mode, status, pay_date) VALUES
(1, 'Cash',  'Completed', '2026-05-01'),
(2, 'Card',  'Completed', '2026-05-01');


-- ============================================================
-- SECTION 3 : DML — UPDATE & DELETE EXAMPLES
-- ============================================================

-- Update appointment status when completed
UPDATE appointment
SET    status = 'Completed'
WHERE  app_id = 4;

-- Update patient phone number
UPDATE patient
SET    phone = '9000011111'
WHERE  name  = 'Sunita Devi';

-- Cancel an appointment (soft delete via status)
UPDATE appointment
SET    status = 'Cancelled'
WHERE  app_id = 5;

-- Hard delete a cancelled appointment
DELETE FROM appointment
WHERE  status = 'Cancelled'
AND    app_id = 5;


-- ============================================================
-- SECTION 4 : SELECT QUERIES
-- ============================================================

-- 4.1  All patients with their details
SELECT patient_id, name, age, gender, phone, address
FROM   patient
ORDER  BY name;

-- 4.2  Doctor schedule: doctor name + all appointments
SELECT d.name   AS doctor,
       d.specialization,
       a.app_date,
       a.app_time,
       p.name   AS patient,
       a.status
FROM   appointment a
JOIN   doctor  d ON a.doctor_id  = d.doctor_id
JOIN   patient p ON a.patient_id = p.patient_id
ORDER  BY a.app_date, a.app_time;

-- 4.3  Complete patient treatment history
SELECT p.name        AS patient,
       a.app_date,
       d.name        AS doctor,
       t.diagnosis,
       t.medicines,
       b.amount,
       b.status      AS bill_status
FROM   patient    p
JOIN   appointment a ON a.patient_id  = p.patient_id
JOIN   doctor      d ON a.doctor_id   = d.doctor_id
JOIN   treatment   t ON t.app_id      = a.app_id
JOIN   bill        b ON b.treatment_id = t.treatment_id
ORDER  BY a.app_date;

-- 4.4  Billing and payment report
SELECT b.bill_id,
       p.name          AS patient,
       b.amount,
       b.bill_date,
       b.status        AS bill_status,
       py.mode         AS payment_mode,
       py.pay_date
FROM   bill       b
JOIN   treatment  t  ON b.treatment_id  = t.treatment_id
JOIN   appointment a ON t.app_id        = a.app_id
JOIN   patient    p  ON a.patient_id    = p.patient_id
LEFT   JOIN payment py ON py.bill_id   = b.bill_id
ORDER  BY b.bill_date;

-- 4.5  Unpaid bills (outstanding)
SELECT b.bill_id, p.name AS patient, b.amount, b.bill_date
FROM   bill b
JOIN   treatment  t ON b.treatment_id = t.treatment_id
JOIN   appointment a ON t.app_id      = a.app_id
JOIN   patient     p ON a.patient_id  = p.patient_id
WHERE  b.status = 'Unpaid';

-- 4.6  Sub-query: patients who have been treated more than once
SELECT name FROM patient
WHERE  patient_id IN (
    SELECT p2.patient_id
    FROM   patient p2
    JOIN   appointment a ON a.patient_id = p2.patient_id
    JOIN   treatment   t ON t.app_id     = a.app_id
    GROUP  BY p2.patient_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- SECTION 5 : AGGREGATE FUNCTIONS, GROUP BY & HAVING
-- ============================================================

-- 5.1  Total number of patients
SELECT COUNT(*) AS total_patients FROM patient;

-- 5.2  Total appointments per doctor
SELECT d.name AS doctor, COUNT(a.app_id) AS total_appointments
FROM   doctor d
LEFT   JOIN appointment a ON a.doctor_id = d.doctor_id
GROUP  BY d.name
ORDER  BY total_appointments DESC;

-- 5.3  Total revenue collected (paid bills)
SELECT SUM(amount) AS total_revenue FROM bill WHERE status = 'Paid';

-- 5.4  Average treatment cost per doctor
SELECT d.name AS doctor, ROUND(AVG(b.amount), 2) AS avg_bill
FROM   doctor d
JOIN   appointment a ON a.doctor_id   = d.doctor_id
JOIN   treatment   t ON t.app_id      = a.app_id
JOIN   bill        b ON b.treatment_id = t.treatment_id
GROUP  BY d.name;

-- 5.5  Doctors with more than 1 completed appointment (HAVING)
SELECT d.name, COUNT(*) AS completed
FROM   doctor d
JOIN   appointment a ON a.doctor_id = d.doctor_id
WHERE  a.status = 'Completed'
GROUP  BY d.name
HAVING COUNT(*) > 1;


-- ============================================================
-- SECTION 6 : VIEWS
-- ============================================================

-- 6.1  Doctor Schedule View
CREATE OR REPLACE VIEW vw_doctor_schedule AS
SELECT d.doctor_id,
       d.name        AS doctor_name,
       d.specialization,
       a.app_id,
       a.app_date,
       a.app_time,
       p.name        AS patient_name,
       a.status
FROM   doctor d
JOIN   appointment a ON a.doctor_id  = d.doctor_id
JOIN   patient     p ON a.patient_id = p.patient_id;

-- 6.2  Billing Summary View
CREATE OR REPLACE VIEW vw_billing_summary AS
SELECT b.bill_id,
       p.name        AS patient_name,
       d.name        AS doctor_name,
       t.diagnosis,
       b.amount,
       b.bill_date,
       b.status      AS bill_status,
       COALESCE(py.mode, 'N/A') AS payment_mode,
       py.pay_date
FROM   bill b
JOIN   treatment   t  ON b.treatment_id  = t.treatment_id
JOIN   appointment a  ON t.app_id        = a.app_id
JOIN   patient     p  ON a.patient_id    = p.patient_id
JOIN   doctor      d  ON a.doctor_id     = d.doctor_id
LEFT   JOIN payment py ON py.bill_id     = b.bill_id;

-- Usage
SELECT * FROM vw_doctor_schedule;
SELECT * FROM vw_billing_summary;


-- ============================================================
-- SECTION 7 : PL/pgSQL — STORED PROCEDURES
-- ============================================================

-- 7.1  Generate_Bill : inserts a bill record after treatment
CREATE OR REPLACE PROCEDURE generate_bill(
    p_treatment_id INT,
    p_amount       NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Check treatment exists
    SELECT COUNT(*) INTO v_exists
    FROM   treatment
    WHERE  treatment_id = p_treatment_id;

    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Treatment ID % not found.', p_treatment_id;
    END IF;

    -- Prevent duplicate bill
    SELECT COUNT(*) INTO v_exists
    FROM   bill
    WHERE  treatment_id = p_treatment_id;

    IF v_exists > 0 THEN
        RAISE EXCEPTION 'Bill already exists for Treatment ID %.', p_treatment_id;
    END IF;

    INSERT INTO bill (treatment_id, amount, bill_date, status)
    VALUES (p_treatment_id, p_amount, CURRENT_DATE, 'Unpaid');

    RAISE NOTICE 'Bill generated successfully for Treatment ID %.', p_treatment_id;
END;
$$;

-- Call example (bill for treatment_id 3 already inserted above; this demonstrates usage)
-- CALL generate_bill(3, 1200.00);


-- 7.2  Register_Patient : inserts a new patient safely
CREATE OR REPLACE PROCEDURE register_patient(
    p_name    VARCHAR,
    p_age     SMALLINT,
    p_gender  CHAR,
    p_phone   VARCHAR,
    p_address VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_dup INT;
BEGIN
    SELECT COUNT(*) INTO v_dup
    FROM   patient
    WHERE  phone = p_phone;

    IF v_dup > 0 THEN
        RAISE EXCEPTION 'Patient with phone % is already registered.', p_phone;
    END IF;

    INSERT INTO patient (name, age, gender, phone, address)
    VALUES (p_name, p_age, p_gender, p_phone, p_address);

    RAISE NOTICE 'Patient "%" registered successfully.', p_name;
END;
$$;

-- Call example
-- CALL register_patient('Neha Joshi', 30, 'F', '9700012345', 'Sector 22, Patiala');


-- ============================================================
-- SECTION 8 : PL/pgSQL — FUNCTIONS
-- ============================================================

-- 8.1  Get_Bill_Amount : returns total bill amount for a patient
CREATE OR REPLACE FUNCTION get_bill_amount(p_patient_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_total NUMERIC := 0;
BEGIN
    SELECT COALESCE(SUM(b.amount), 0)
    INTO   v_total
    FROM   patient     p
    JOIN   appointment a  ON a.patient_id   = p.patient_id
    JOIN   treatment   t  ON t.app_id       = a.app_id
    JOIN   bill        b  ON b.treatment_id = t.treatment_id
    WHERE  p.patient_id = p_patient_id;

    IF v_total = 0 THEN
        RAISE NOTICE 'No billing records found for Patient ID %.', p_patient_id;
    END IF;

    RETURN v_total;
END;
$$;

-- Usage
SELECT get_bill_amount(1) AS total_amount_patient_1;


-- ============================================================
-- SECTION 9 : PL/pgSQL — TRIGGERS
-- ============================================================

-- 9.1  trg_bill_paid : update bill status to 'Paid' after payment
CREATE OR REPLACE FUNCTION fn_update_bill_status()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'Completed' THEN
        UPDATE bill
        SET    status = 'Paid'
        WHERE  bill_id = NEW.bill_id;

        RAISE NOTICE 'Bill ID % marked as Paid.', NEW.bill_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bill_paid
AFTER INSERT ON payment
FOR EACH ROW
EXECUTE FUNCTION fn_update_bill_status();


-- 9.2  trg_prevent_double_booking : raise error if slot is taken
CREATE OR REPLACE FUNCTION fn_check_doctor_slot()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_conflict INT;
BEGIN
    SELECT COUNT(*) INTO v_conflict
    FROM   appointment
    WHERE  doctor_id = NEW.doctor_id
    AND    app_date  = NEW.app_date
    AND    app_time  = NEW.app_time
    AND    status   <> 'Cancelled'
    AND    app_id   <> COALESCE(NEW.app_id, -1);   -- ignore self on UPDATE

    IF v_conflict > 0 THEN
        RAISE EXCEPTION
            'Doctor (ID %) already has an appointment on % at %.',
            NEW.doctor_id, NEW.app_date, NEW.app_time;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT OR UPDATE ON appointment
FOR EACH ROW
EXECUTE FUNCTION fn_check_doctor_slot();


-- ============================================================
-- SECTION 10 : PL/pgSQL — CURSORS
-- ============================================================

-- 10.1  Daily appointment list for a given doctor
CREATE OR REPLACE PROCEDURE daily_appointments(
    p_doctor_id INT,
    p_date      DATE
)
LANGUAGE plpgsql AS $$
DECLARE
    cur_appts CURSOR FOR
        SELECT a.app_id,
               a.app_time,
               p.name   AS patient_name,
               a.status
        FROM   appointment a
        JOIN   patient     p ON p.patient_id = a.patient_id
        WHERE  a.doctor_id = p_doctor_id
        AND    a.app_date  = p_date
        ORDER  BY a.app_time;

    rec RECORD;
BEGIN
    RAISE NOTICE '--- Appointments for Doctor ID % on % ---', p_doctor_id, p_date;
    OPEN cur_appts;
    LOOP
        FETCH cur_appts INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'App# %, Time: %, Patient: %, Status: %',
            rec.app_id, rec.app_time, rec.patient_name, rec.status;
    END LOOP;
    CLOSE cur_appts;
END;
$$;

-- Call example
CALL daily_appointments(1, '2026-05-01');


-- 10.2  Patient treatment history report via cursor
CREATE OR REPLACE PROCEDURE patient_history(p_patient_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    cur_hist CURSOR FOR
        SELECT a.app_date,
               d.name       AS doctor,
               t.diagnosis,
               t.medicines,
               b.amount,
               b.status     AS bill_status
        FROM   appointment a
        JOIN   doctor      d  ON a.doctor_id    = d.doctor_id
        JOIN   treatment   t  ON t.app_id       = a.app_id
        JOIN   bill        b  ON b.treatment_id = t.treatment_id
        WHERE  a.patient_id = p_patient_id
        ORDER  BY a.app_date;

    rec    RECORD;
    p_name VARCHAR(100);
BEGIN
    SELECT name INTO p_name FROM patient WHERE patient_id = p_patient_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Patient ID % not found.', p_patient_id;
    END IF;

    RAISE NOTICE '=== Treatment History for Patient: % ===', p_name;
    OPEN cur_hist;
    LOOP
        FETCH cur_hist INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Date: % | Doctor: % | Diagnosis: % | Medicines: % | Amount: % | Status: %',
            rec.app_date, rec.doctor, rec.diagnosis, rec.medicines, rec.amount, rec.bill_status;
    END LOOP;
    CLOSE cur_hist;
END;
$$;

CALL patient_history(1);


-- ============================================================
-- SECTION 11 : EXCEPTION HANDLING EXAMPLES
-- ============================================================

-- 11.1  Safe patient lookup with NO_DATA_FOUND equivalent
CREATE OR REPLACE PROCEDURE safe_patient_lookup(p_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_name VARCHAR;
BEGIN
    SELECT name INTO STRICT v_name
    FROM   patient
    WHERE  patient_id = p_id;

    RAISE NOTICE 'Patient found: %', v_name;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'No patient found with ID %', p_id;
    WHEN TOO_MANY_ROWS THEN
        RAISE NOTICE 'Multiple records returned — check data integrity.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END;
$$;

CALL safe_patient_lookup(1);
CALL safe_patient_lookup(999);  -- triggers NO_DATA_FOUND


-- 11.2  Duplicate registration guard (uses register_patient procedure above)
-- CALL register_patient('Rahul Sharma', 28, 'M', '9876543210', 'Delhi');
-- → Raises: Patient with phone 9876543210 is already registered.


-- ============================================================
-- SECTION 12 : TRANSACTION MANAGEMENT (ACID)
-- ============================================================

-- Atomicity + Durability:
-- Treatment + Bill inserted together; if Bill fails, Treatment rolls back.
BEGIN;

    SAVEPOINT before_treatment;

    INSERT INTO treatment (app_id, diagnosis, medicines)
    VALUES (4, 'Common Cold', 'Cetirizine 10mg, Vitamin C');

    SAVEPOINT before_bill;

    INSERT INTO bill (treatment_id, amount, bill_date, status)
    VALUES (
        (SELECT treatment_id FROM treatment WHERE app_id = 4),
        350.00,
        CURRENT_DATE,
        'Unpaid'
    );

COMMIT;

-- Rollback demo: if bill insert fails, roll back to savepoint
-- BEGIN;
--   SAVEPOINT sp1;
--   INSERT INTO treatment (app_id, diagnosis, medicines) VALUES (5, 'Acne', 'Adapalene Gel');
--   SAVEPOINT sp2;
--   -- Simulate failure:
--   INSERT INTO bill (treatment_id, amount, bill_date, status)
--   VALUES (-99, 400.00, CURRENT_DATE, 'Unpaid');  -- FK violation
--   -- On error: ROLLBACK TO sp2;
-- COMMIT;


-- ============================================================
-- END OF SCRIPT
-- ============================================================