						-- HEALTH CARE PROJECT

		-- A. DATA CLEANING
-- Create a staging table
SELECT *
FROM healthcare_dataset;

CREATE TABLE healthcare_dataset_staging
LIKE healthcare_dataset;

INSERT healthcare_dataset_staging
SELECT *
FROM healthcare_dataset;

SELECT *
FROM healthcare_dataset_staging;

-- Check if there are duplicates
SELECT *,
ROW_NUMBER() OVER(PARTITION BY Name, Age, Gender, `Medical Condition`) AS row_num
FROM healthcare_dataset_staging;

SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER(PARTITION BY Name, Age, Gender, `Medical Condition`) AS row_num
		FROM healthcare_dataset_staging) AS duplicates_table
WHERE row_num > 1;

SELECT *
FROM healthcare_dataset_staging
WHERE Name = 'dAvId yU';
-- It looks like these are all legitimate entries and shouldn't be deleted. 
-- Even if the name and age are the same, the other informations doesn't match, so we consider that they are different patients.


-- Handling missing/null values
SELECT *
FROM healthcare_dataset_staging;
-- It seems that, at first glace, there are no null values.


-- Delete less relevant columns for efficiency
ALTER TABLE healthcare_dataset_staging
DROP `Doctor`;

ALTER TABLE healthcare_dataset_staging
DROP `Hospital`;

ALTER TABLE healthcare_dataset_staging
DROP `Room Number`;

SELECT *
FROM healthcare_dataset_staging;


			-- B. Exploratory data analysis

-- 1. Most Common & Least Common Conditions
SELECT `Medical Condition`, COUNT(`Medical Condition`) AS condition_count
FROM healthcare_dataset_staging
GROUP BY `Medical Condition`
ORDER BY condition_count DESC; 
-- Most common condition: Arthritis (4867 cases)
-- Least common condition: Obesity (4709 cases)
-- Knowing the most common conditions helps prioritize hospital resources and treatment focus. The differences between conditions are small, meaning all these conditions need similar attention in healthcare planning.


-- 2. Find the common Medical Condition per year
SELECT `Medical Condition`, COUNT(`Medical Condition`) AS condition_count, YEAR(`Date of Admission`) AS year_admission
FROM healthcare_dataset_staging
GROUP BY `Medical Condition`, YEAR(`Date of Admission`)
ORDER BY condition_count DESC, year_admission; 
-- Based on my findings, there were 28.697 patients admitted and diagnosed with a medical condition. 
-- Year 2020 having the higheset amount of admission. Cancer, obesity and hypertensions recorded the highest rates that year.


-- 3. Which age group is most affected by each condition?
SELECT age_group, `Medical Condition`, COUNT(*) AS condition_count
FROM ( SELECT `Medical Condition`,
           CASE 
               WHEN Age BETWEEN 18 AND 39 THEN 'Adults'
               WHEN Age BETWEEN 40 AND 64 THEN 'Middle-aged'
               WHEN Age >= 65 THEN 'Seniors'
           END AS age_group
    FROM healthcare_dataset_staging
	  ) AS subquery
GROUP BY age_group, `Medical Condition`
ORDER BY condition_count DESC;
-- Middle aged group occupies the first position, for all medical conditions.
-- Middle aged individuals (40-64) might have the highest count because they are at the peak risk for lifestyle-related diseases like obesity, hypertension and  diabetes.
-- Second place is held by Adults, and the last place by Seniors, both affected by Arthritis.
-- Adults (18-39) are generally healthier, but still susceptible to common illnesses.

SELECT age_group, COUNT(*) AS total_patients
FROM ( SELECT CASE 
            WHEN Age BETWEEN 18 AND 39 THEN 'Adults'
            WHEN Age BETWEEN 40 AND 64 THEN 'Middle-aged'
            WHEN Age >= 65 THEN 'Seniors'
	        END AS age_group
	   FROM healthcare_dataset_staging ) AS subquery
GROUP BY age_group;
-- There seem to be no major differences between the number of patients in each group.
-- The database contains data between 2019 and 2024, which could be an explanation for why middle-aged is in first position, being a relatively small period analyzed. 


-- 4. Medical Condition per gender
SELECT Gender, Count(Gender) AS Count_Gender, `Medical Condition`
FROM healthcare_dataset_staging 
GROUP BY Gender, `Medical Condition`
ORDER BY Count_Gender DESC;
-- There are no major differences between genders

-- 5. What are the top conditions for males and females across different age groups?
SELECT Gender, age_group, `Medical Condition`, COUNT(*) AS condition_count,
ROW_NUMBER() OVER (PARTITION BY Gender, age_group ORDER BY COUNT(*) DESC) AS row_num
FROM (SELECT Gender, `Medical Condition`,
		CASE 
		 WHEN Age BETWEEN 18 AND 39 THEN 'Adults'
		 WHEN Age BETWEEN 40 AND 64 THEN 'Middle-aged'
		 WHEN Age >= 65 THEN 'Seniors'
		 END AS age_group
	 FROM healthcare_dataset_staging ) AS subquery
GROUP BY Gender, age_group, `Medical Condition`;


WITH condition_counts AS
( SELECT Gender, age_group, `Medical Condition`, COUNT(*) AS condition_count,
	ROW_NUMBER() OVER (PARTITION BY Gender, age_group ORDER BY COUNT(*) DESC) AS row_num
    FROM ( SELECT Gender, `Medical Condition`,
               CASE 
                   WHEN Age BETWEEN 18 AND 39 THEN 'Adults'
                   WHEN Age BETWEEN 40 AND 64 THEN 'Middle-aged'
                   WHEN Age >= 65 THEN 'Seniors'
               END AS age_group
        FROM healthcare_dataset_staging ) AS subquery
    GROUP BY Gender, age_group, `Medical Condition`
)
SELECT Gender, age_group, `Medical Condition`, condition_count
FROM condition_counts
WHERE row_num <= 3 
ORDER BY Gender, age_group, condition_count DESC;
-- For both, female and male, arthritis, cancer and hypertension might be dominant in adults groups.
-- Hypertension and arthritis might be dominant in middle-aged groups.
-- Seniors likely have chronic conditions like arthritis, asthma


-- 6. Average Billing for Admission Type
SELECT  `Admission Type`, AVG(`Billing Amount`) AS Average_Billing
FROM healthcare_dataset_staging
GROUP BY  `Admission Type`
ORDER BY Average_Billing DESC;
-- Elective admissions have the highest average cost (~$25,800), slightly above Emergency and Urgent admissions.

-- 7. What is the medical bill for each medical condition?
SELECT  `Medical Condition`, SUM(`Billing Amount`) AS Total_Billing
FROM healthcare_dataset_staging
GROUP BY  `Medical Condition`
ORDER BY Total_Billing DESC;
-- Based on my analysis, the highest billing amount was for arthritis. 

-- 8. Show top 3 most expensive conditions per admission type
WITH Billing_Data AS 
(SELECT `Medical Condition`, `Admission Type`, SUM(`Billing Amount`) AS Total_Billing,
           ROW_NUMBER() OVER (PARTITION BY `Admission Type` ORDER BY SUM(`Billing Amount`) DESC) AS row_num
    FROM healthcare_dataset_staging
    GROUP BY `Medical Condition`, `Admission Type`
)
SELECT `Medical Condition`, `Admission Type`, Total_Billing
FROM Billing_Data
WHERE row_num <= 3
ORDER BY `Admission Type`, Total_Billing DESC;
-- Elective: cancer, diabetes, hypertension
-- Emergency: asthma, arthritis, obesity
-- Urgent: diabetes, arthritis, hypertension


-- 9. What is the average billing amount per provider?
SELECT `Insurance Provider`, AVG(`Billing Amount`) AS Average_Billing
FROM healthcare_dataset_staging
GROUP BY  `Insurance Provider`
ORDER BY Average_Billing DESC;
-- Highest Billing: Aetna ($25.740)
-- Lowest Billing: Blue Cross ($25,537)







