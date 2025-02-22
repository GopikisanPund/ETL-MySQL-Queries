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



SHOW VARIABLES LIKE 'secure_file_priv';










