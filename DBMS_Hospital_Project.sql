CREATE TABLE Patient(
    patient_id NUMBER Primary Key,
    name VARCHAR2(100) NOT NULL,
    age NUMBER CHECK(age > 0),
    gender VARCHAR2(10),
    phone VARCHAR2(15) UNIQUE,
    address VARCHAR2(200)
);
CREATE TABLE Doctor (
    doctor_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    specialization VARCHAR2(100),
    phone VARCHAR2(15) UNIQUE
);

CREATE TABLE Appointment(
    appointment_id NUMBER PRIMARY KEY,
    patient_id NUMBER,
    doctor_id NUMBER,
    appointment_date DATE,
    status VARCHAR2(20),
    CONSTRAINT fk_patient FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id),
    CONSTRAINT fk_doctor FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
);

CREATE TABLE Treatment (
    treatment_id NUMBER PRIMARY KEY,
    appointment_id NUMBER,
    diagnosis VARCHAR2(200),
    medicines VARCHAR2(200),
    CONSTRAINT fk_appointment FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id)
);

CREATE TABLE Bill (
    bill_id NUMBER PRIMARY KEY,
    treatment_id NUMBER,
    amount NUMBER(10,2),
    bill_date DATE,
    status VARCHAR2(20),
    CONSTRAINT fk_treatment FOREIGN KEY (treatment_id)
        REFERENCES Treatment(treatment_id)
);


INSERT INTO Patient VALUES (1, 'Rahul Sharma', 25, 'Male', '9876543210', 'Delhi');
INSERT INTO Doctor VALUES (101, 'Dr. Mehta', 'Cardiologist', '9123456780');

INSERT INTO Appointment VALUES (1001, 1, 101, SYSDATE, 'Scheduled');
INSERT INTO Treatment VALUES (5001, 1001, 'High BP', 'Medicine A');
INSERT INTO Bill VALUES (9001, 5001, 2000, SYSDATE, 'Unpaid');


COMMIT;


-- JOIN QUERY
SELECT p.name AS Patient, d.name AS Doctor, a.appointment_date
FROM Patient p
JOIN Appointment a ON p.patient_id = a.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id;

-- AGGREGATE FXN
SELECT doctor_id, COUNT(*) AS total_appointments
FROM Appointment
GROUP BY doctor_id;

-- SUBQUERY
SELECT name
FROM Patient
WHERE patient_id IN (
    SELECT patient_id
    FROM Appointment
    WHERE doctor_id = 101
);


-- CREATING VIEW
CREATE VIEW Doctor_Appointments AS
SELECT d.name AS Doctor_Name,
       COUNT(a.appointment_id) AS Total_Appointments
FROM Doctor d
LEFT JOIN Appointment a
ON d.doctor_id = a.doctor_id
GROUP BY d.name;


