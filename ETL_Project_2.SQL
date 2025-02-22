# Create Database
Create database ETL_Process_Project;

# Use Database
use ETL_Process_Project;

# Show ETL_Process_Project Database
show databases;

#Create a tables 
CREATE TABLE Raw_Engine_Test_Data (
    TestID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    TestDate VARCHAR(20),
    EngineTemp FLOAT,
    FuelConsumption FLOAT,
    EmissionLevel FLOAT,
    Speed INT
);

#Insert data into tables
INSERT INTO Raw_Engine_Test_Data (VehicleID, TestDate, EngineTemp, FuelConsumption, EmissionLevel, Speed)
VALUES 
(101, '12/02/2024', 85.5, 6.2, 0.08, 120),
(102, '13/02/2024', 90.1, 7.1, 0.10, 110),
(101, '12/02/2024', 88.3, 6.8, 0.09, 130),
(103, '14/02/2024', 95.1, 5.5, 0.07, 140),
(102, '13/02/2024', 89.8, 7.3, 0.11, 100);




#Delete all data from table
truncate table Raw_Engine_Test_Data;
truncate table Transformed_Engine_Test_Data;

# CREATE TABLE Transformed_Engine_Test_Data
CREATE TABLE Transformed_Engine_Test_Data (
    TestID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    TestDate DATE,
    Avg_EngineTemp FLOAT,
    Total_FuelConsumption FLOAT,
    EmissionStatus VARCHAR(20),
    Avg_Speed INT,
    Avg_RPM INT
);

# Drop table 
drop table Transformed_Engine_Test_Data;

#Transformation 
#1.Step 1: Convert Date Format
Select TestDate,str_to_date(TestDate,'%d/%m/%Y')As ConvertedDate from Raw_Engine_Test_Data;

#Step 2: Remove Invalid Engine Temperatures
#Problem:
#Engine temperature should not exceed 100°C.
# We need to remove records where EngineTemp > 100.
SELECT 
    EngineTemp
FROM
    Raw_Engine_Test_Data
WHERE
    EngineTemp < 0;

#Step 3: Remove Outlier Speed Values
#Problem:
#A vehicle's speed should not exceed 200 km/h.
#We need to remove outlier speeds from calculations.

Select Speed from Raw_Engine_Test_Data where Speed <= 200;

#Step 4: Aggregate Fuel Consumption (SUM)
#Problem:
#We want total fuel consumption per vehicle on a given day.
SELECT 
    VehicleID, 
    STR_TO_DATE(TestDate, '%d/%m/%Y') AS TestDate,
    SUM(FuelConsumption) AS TotalFuelUsed
FROM Raw_Engine_Test_Data
GROUP BY VehicleID, TestDate;

#Step 5: Categorize Emission Levels
#Problem:
#Emission levels should be categorized as Low, Moderate, or High.

SELECT 
    EmissionLevel,
    CASE 
        WHEN EmissionLevel < 0.09 THEN 'Low'
        WHEN EmissionLevel BETWEEN 0.09 AND 0.1 THEN 'Moderate'
        ELSE 'High'
    END AS EmissionCategory
FROM Raw_Engine_Test_Data;

#Step 6: Calculate Average RPM
#Problem:
#We want to calculate the average RPM per vehicle on a given day.

SELECT 
    VehicleID, 
    STR_TO_DATE(TestDate, '%d/%m/%Y') AS TestDate,
    AVG(Speed) AS AvgRPM
FROM Raw_Engine_Test_Data
GROUP BY VehicleID, TestDate;

#FInal Transeformation
INSERT INTO Transformed_Engine_Test_Data (VehicleID, TestDate, Avg_EngineTemp, Total_FuelConsumption, EmissionStatus, Avg_Speed, Avg_RPM)
SELECT 
    VehicleID, 
    STR_TO_DATE(TestDate, '%d/%m/%Y') AS TestDate,  -- Convert Date Format
    AVG(CASE WHEN EngineTemp <= 100 THEN EngineTemp ELSE NULL END) AS Avg_EngineTemp, -- Remove invalid temperature values
    SUM(FuelConsumption) AS Total_FuelConsumption, -- Aggregate Fuel Consumption
    CASE 
        WHEN AVG(EmissionLevel) < 0.09 THEN 'Low'
        WHEN AVG(EmissionLevel) BETWEEN 0.09 AND 0.1 THEN 'Moderate'
        ELSE 'High'
    END AS EmissionStatus, -- Categorize Emission Levels
    AVG(CASE WHEN Speed <= 200 THEN Speed ELSE NULL END) AS Avg_Speed, -- Remove Outliers
    AVG(RPM) AS Avg_RPM -- Aggregate RPM
FROM Raw_Engine_Test_Data
GROUP BY VehicleID, TestDate;


#Show Created Table
Select * from Raw_Engine_Test_Data;
Select * from Transformed_Engine_Test_Data;

#Delete a Duplicate column
alter table Transformed_Engine_Test_Data
drop column Avg_RPM;

SHOW TABLES;

SELECT * FROM raw_engine_test_data  
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/raw_engine_data.csv'  
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'  
LINES TERMINATED BY '\n';


CREATE TABLE raw_vehicle_test_data (
    test_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique test ID
    vehicle_id VARCHAR(20),  -- Vehicle identifier
    engine_temperature FLOAT,  -- Temperature in °C
    fuel_pressure FLOAT,  -- Fuel pressure in bars
    engine_rpm INT,  -- Engine speed (RPM)
    test_timestamp DATETIME,  -- Timestamp of test
    test_result VARCHAR(10),  -- Pass/Fail result
    test_comments TEXT  -- Additional details
);


INSERT INTO raw_vehicle_test_data (vehicle_id, engine_temperature, fuel_pressure, engine_rpm, test_timestamp, test_result, test_comments)
VALUES
('VH-001', 98.5, 2.7, 3100, '2024-02-22 08:30:00', 'pass', 'Normal operation'),
('VH-002', 105.2, NULL, 2500, '2024-02-22 09:15:00', 'fail', 'Missing fuel pressure'),
('VH-003', 87.0, 3.0, NULL, '2024-02-22 10:00:00', 'pass', 'RPM not recorded'),
('VH-004', 103.8, 2.9, 2800, '2024-02-22 11:45:00', 'fail', 'Engine overheating');


CREATE TABLE cleaned_vehicle_test_data (
    test_id INT PRIMARY KEY,  -- Same test_id as raw data
    vehicle_id VARCHAR(20),
    engine_temperature FLOAT,
    fuel_pressure FLOAT,
    engine_rpm INT,
    test_timestamp DATETIME,
    test_result VARCHAR(10),
    validation_status VARCHAR(20),  -- Data validation flag
    formatted_test_time VARCHAR(30)  -- Readable timestamp format
);

INSERT INTO cleaned_vehicle_test_data (test_id, vehicle_id, engine_temperature, fuel_pressure, engine_rpm, test_timestamp, test_result, validation_status, formatted_test_time)
SELECT 
    test_id, 
    vehicle_id, 
    engine_temperature, 
    fuel_pressure, 
    engine_rpm, 
    test_timestamp, 
    test_result,
    CASE 
        WHEN engine_temperature BETWEEN 90 AND 100 THEN 'Valid'
        ELSE 'Invalid'
    END AS validation_status,
    DATE_FORMAT(test_timestamp, '%Y-%m-%d %h:%i %p') AS formatted_test_time
FROM raw_vehicle_test_data;


UPDATE raw_vehicle_test_data 
SET fuel_pressure = COALESCE(fuel_pressure, 2.5),engine_rpm = COALESCE(engine_rpm, 2000);

SELECT test_id, 
       vehicle_id, 
       engine_temperature, 
       fuel_pressure, 
       engine_rpm, 
       test_result,
       DATE_FORMAT(test_timestamp, '%Y-%m-%d %h:%i %p') AS formatted_test_time
FROM raw_vehicle_test_data;


SELECT test_id, 
       vehicle_id, 
       engine_temperature, 
       fuel_pressure, 
       engine_rpm, 
       test_result,
       CASE 
           WHEN engine_temperature BETWEEN 90 AND 100 THEN 'Valid'
           ELSE 'Invalid'
       END AS validation_status
FROM raw_vehicle_test_data;

SELECT vehicle_id, COUNT(*)
FROM cleaned_vehicle_test_data
GROUP BY vehicle_id
HAVING COUNT(*) > 1;


SELECT * FROM cleaned_vehicle_test_data 
WHERE engine_temperature IS NULL OR fuel_pressure IS NULL OR engine_rpm IS NULL;

SELECT * FROM cleaned_vehicle_test_data 
WHERE validation_status = 'Invalid';

show tables;

INSERT INTO raw_engine_test_data (vehicle_id, engine_temp, fuel_pressure, rpm, test_timestamp, test_status, comments)
VALUES
('VHC1001', 95.5, 2.5, 3000, '2024-02-21 10:30:00', 'pass', 'Normal operation'),
('VHC1002', 105.2, NULL, 2500, '2024-02-21 11:00:00', 'fail', 'Fuel pressure missing'),
('VHC1003', 88.0, 2.8, NULL, '2024-02-21 12:00:00', 'pass', 'RPM missing'),
('VHC1004', 102.3, 3.1, 2900, '2024-02-21 13:00:00', 'fail', 'Engine overheating');











