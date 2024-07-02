SELECT * FROM layoffs_staging;

# 	DATA CLEANING PROJECT PROCEDURE
#1. Remove Duplicates if there are any
#2. Standardize the data
#3. Handle the NULL values or the BLANK values
#4. Remove columns that are not necessary


#Checking for duplicates in the raw data using CTE.
WITH CTE_Duplicate AS (
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) row_num
FROM layoffs
)
SELECT * FROM CTE_Duplicate 
WHERE row_num > 1
;

#Duplicates found. To avoid tampering with the raw data which is a bad practice, 
#I created a staging database where I inserted the data and also remove duplicate rows
INSERT INTO layoffs_staging
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) row_num
FROM layoffs
;

# Deleting the duplicate data
DELETE
FROM layoffs_staging
WHERE row_num > 1;

#Trimming the company column. Some company names had bad formatting.
UPDATE layoffs_staging 
SET company =  TRIM(company);

#The industry column contains some data that are similar we need to unify data that are similar and actually mean the same thing
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%'
;

#Inside the country column there's two distinct value that looks similar. 
# (i) United States (ii) United States. 
# I removed the the period(.) in the second value

UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE  'United States.%';

#converting date column from text data type to date data type
UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

#Hanlding NULL/BLANK values
SELECT *
FROM layoffs_staging
WHERE industry IS NULL OR industry = ''
;

# I set the values of company with blank spaces to NULLs
UPDATE layoffs_staging 
SET industry = NULL
WHERE industry = ''
;

# I performed a self join operation. Joining ON the company name where the industry is not null. 
# This helps to identify company that appears multiple times and has at least its industry  to populate the NULL industries.
SELECT *
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL
;

UPDATE layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

#Removing rows that has null values for both percent laid off and total laid off
DELETE FROM layoffs_staging WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;

#Removing the row_num column
ALTER TABLE layoffs_staging
DROP COLUMN row_num;

