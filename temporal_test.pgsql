-- Create a table for employee
CREATE TABLE employee (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    department VARCHAR(50)
);

-- create a table for employee history
CREATE TABLE employee_history (
    history_id SERIAL PRIMARY KEY,
    employee_id INT,
    name VARCHAR(100),
    age INT,
    department VARCHAR(50),
    operation_at TIMESTAMP,
    operation VARCHAR(10)
);

-- Create a function for the trigger
CREATE OR REPLACE FUNCTION log_employee_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_history (employee_id, name, age, department, operation_at, operation)
        VALUES (NEW.id, NEW.name, NEW.age, NEW.department, NOW(), 'INSERT');
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employee_history (employee_id, name, age, department, operation_at, operation)
        VALUES (NEW.id, NEW.name, NEW.age, NEW.department, NOW(), 'UPDATE');
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employee_history (employee_id, name, age, department, operation_at, operation)
        VALUES (OLD.id, OLD.name, OLD.age, OLD.department, NOW(), 'DELETE');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers using the function
CREATE TRIGGER employee_insert_trigger AFTER INSERT ON employee FOR EACH ROW EXECUTE FUNCTION log_employee_changes();
CREATE TRIGGER employee_update_trigger AFTER UPDATE ON employee FOR EACH ROW EXECUTE FUNCTION log_employee_changes();
CREATE TRIGGER employee_delete_trigger AFTER DELETE ON employee FOR EACH ROW EXECUTE FUNCTION log_employee_changes();

-- insert some data into employee
INSERT INTO employee (id, name, age, department) VALUES (1, 'John Doe', 30, 'HR');
INSERT INTO employee (id, name, age, department) VALUES (2, 'Jane Smith', 25, 'IT');

-- select all data from employee
SELECT * FROM employee; 

-- select all data from employee_history
SELECT * FROM employee_history;

-- update the employee
UPDATE employee SET age = 31 WHERE id = 1;

-- select all data from employee    
SELECT * FROM employee;

-- select all data from employee_history
SELECT * FROM employee_history;

-- delete the employee
DELETE FROM employee WHERE id = 2;

-- select all data from employee
SELECT * FROM employee;

-- select all data from employee_history
SELECT * FROM employee_history;

-- Drop everything (cleanup)
DROP TRIGGER IF EXISTS employee_insert_trigger ON employee;
DROP TRIGGER IF EXISTS employee_update_trigger ON employee;
DROP TRIGGER IF EXISTS employee_delete_trigger ON employee;
DROP FUNCTION IF EXISTS log_employee_changes();
DROP TABLE IF EXISTS employee_history;
DROP TABLE IF EXISTS employee;
