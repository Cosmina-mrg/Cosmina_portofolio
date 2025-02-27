									-- WORLD LIFE EXPECTANCY PROJECT

SELECT *
FROM world_life_expectancy;


-- First thing we want to do is create a staging table. This is the one we will work in and clean the data. 
-- We want a table with the raw data in case something happens

CREATE TABLE world_life_expectancy_staging 
LIKE world_life_expectancy;

INSERT world_life_expectancy_staging
SELECT *
FROM world_life_expectancy;


SELECT *
FROM world_life_expectancy_staging;

DESCRIBE world_life_expectancy_staging;

				-- A. DATA CLEANING 
-- Before diving into analysis, it's crucial to clean the data. 
-- This includes findind duplicates, handling missing values and ensuring consistency across the dataset.

					-- 1. Finding the duplicates
-- Count the Country and Year to see if there are duplicates
SELECT Country, YEAR, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy_staging
GROUP BY Country, YEAR, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;


SELECT * 
FROM ( SELECT Row_ID, CONCAT(Country, Year),
	ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS row_num
    FROM world_life_expectancy_staging ) AS row_table
WHERE row_num > 1;
    
-- Delete the duplicates
DELETE FROM world_life_expectancy_staging
WHERE 
Row_ID IN (
			SELECT Row_ID
			FROM (
					SELECT Row_ID, CONCAT(Country, Year),
					ROW_NUMBER () OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS row_num  
					FROM world_life_expectancy_staging
				) AS Row_table
WHERE row_num > 1) 
;

				-- Handling missing values	
-- Select the blank rows from Status
SELECT *
FROM world_life_expectancy_staging
WHERE Status = '';
    
SELECT DISTINCT(Status)
FROM world_life_expectancy_staging
WHERE Status <> '' ;   -- So, the Status can be 'Developing' or 'Developed'

SELECT DISTINCT(Country)
FROM world_life_expectancy_staging
WHERE Status = 'Developing';

-- Updating the blank rows
UPDATE  world_life_expectancy_staging t1
JOIN world_life_expectancy_staging t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

SELECT * 
FROM world_life_expectancy_staging
WHERE Status = '';

SELECT * 
FROM world_life_expectancy_staging
WHERE Country = 'United States of America';

UPDATE  world_life_expectancy_staging t1
JOIN world_life_expectancy_staging t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

-- Check the rows
SELECT * 
FROM world_life_expectancy_staging
WHERE Status IS NULL;

-- Analyze the column Life Expectancy
SELECT * 
FROM world_life_expectancy_staging
WHERE `Life expectancy` = '';

SELECT Country, Year, `Life expectancy` 
FROM world_life_expectancy_staging
WHERE `Life expectancy` = '';

-- Join the tables to see the values of previous year (2017) and next year(2019).
SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`
FROM world_life_expectancy_staging t1
JOIN world_life_expectancy_staging t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy_staging t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1 ;

-- Calculate the average of 2017 and 2019 I will populate the Life Expectancy blank value(2018)
SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy_staging t1
JOIN world_life_expectancy_staging t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy_staging t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1 
WHERE t1.`Life expectancy` = ''
;

-- Update the rows
UPDATE world_life_expectancy_staging t1
JOIN world_life_expectancy_staging t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';

-- Check the rows
SELECT Country, Year, `Life expectancy` 
FROM world_life_expectancy_staging
WHERE `Life expectancy` = '';

SELECT *
FROM world_life_expectancy_staging;


				-- B.EXPLORATORY DATA ANALYSIS
SELECT *
FROM world_life_expectancy_staging;		

-- First thing I will calculate the average life expectancy for each year
SELECT Year, ROUND(AVG(`Life expectancy`),2) AS average_life_expectancy
FROM world_life_expectancy_staging
WHERE `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year;  ## Based on the trend observed, the average life expectancy increased over a 15 years period.

-- How life expectancy increase over 15 years?
SELECT Country, 
MIN(`Life expectancy`), 
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS life_increase_15_years
FROM world_life_expectancy_staging
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY life_increase_15_years DESC;  ## When the minimum life expectancy is low, the potential for significant improvement is greater, leading to a larger increase over time. 
                                       ## In contrast, when life expectancy is already high, gains tend to be smaller due to biological and medical limitations.


-- Life expectancy vs GDP
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS life_exp, ROUND(AVG(GDP),1) AS gdp
FROM world_life_expectancy_staging
GROUP BY Country
HAVING life_exp > 0
AND gdp > 0
ORDER BY life_exp DESC ;

-- High GDP vs Low GDP  (1500 is the average that I thnik)
SELECT 
SUM(CASE WHEN gdp >= 1500 THEN 1 ELSE 0 END) high_gdp_count ,
AVG(CASE WHEN gdp >= 1500 THEN `Life expectancy` ELSE NULL END) high_gdp_Life_expectancy,
SUM(CASE WHEN gdp <= 1500 THEN 1 ELSE 0  END) low_gdp_count,
AVG(CASE WHEN gdp <= 1500 THEN `Life expectancy` ELSE NULL END) low_gdp_Life_expectancy
FROM world_life_expectancy_staging;
		## As we can observe, countries with a high GDP have a life expectancy approximately 10 years higher compared to those with a low GDP.


-- Corelation between status si life expectancy
SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy_staging
GROUP BY Status;

-- Corelation between status si life expectancy for each country
SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy_staging
GROUP BY Status;
		## The group of developing countries is more than five times larger, meaning it includes states with highly diverse levels of economic development.
        ## Some developed countries have small populations, but strong economies, which can increase the average life expectancy.
        
        
-- Life expectancy vs BMI
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS life_exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy_staging
GROUP BY Country
HAVING life_exp > 0
AND BMI > 0
ORDER BY BMI DESC ;        
        
        
 -- Rolling Total for Adult Mortality      
SELECT Country, Year, `Life expectancy`, `Adult Mortality`,
SUM(`Adult Mortality`)OVER(PARTITION BY Country ORDER BY Year) AS rolling_total
FROM world_life_expectancy_staging
WHERE Country LIKE '%United%';     ## Countries with low life expectancy have a higher adult mortality rate compared to those with high life expectancy.
        
-- Rolling Total for Infant deaths   
SELECT Country, Year, `Life expectancy`, `infant deaths`,
SUM(`infant deaths`)OVER(PARTITION BY Country ORDER BY Year) AS rolling_total
FROM world_life_expectancy_staging
WHERE Country LIKE '%United%';    ##Countries with low life expectancy have a higher number of infant deaths compared to those with high life expectancy.