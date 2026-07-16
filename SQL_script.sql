CREATE TABLE stg_pan_number_dataset(
	pan_number text
);
select count(*) from stg_pan_number_dataset

-- Handling Missing data
SELECT * FROM stg_pan_number_dataset WHERE pan_number is null

-- Check for Duplicates

SELECT pan_number , count(1) FROM stg_pan_number_dataset
GROUP BY pan_number
having count(*) > 1

-- Handling spaces
SELECT * FROM stg_pan_number_dataset WHERE pan_number <> trim(pan_number)

-- Correct letter case
SELECT * FROM stg_pan_number_dataset WHERE pan_number <> UPPER(pan_number)

-- Now Task is to merge all above Query and get refined table or dataset.
--  CLEANED PAN NUMBER

SELECT DISTINCT UPPER(TRIM(pan_number)) AS pan_number
	FROM stg_pan_number_dataset 
	WHERE pan_number is not null
	AND trim(pan_number) <> '';


-- CREATING FUNCTION to check IF adjacent charater are same -- UCYZV9250R -> UCYZV (Taking only first 5 character)
CREATE OR REPLACE FUNCTION check_adj_char(p_str text)
returns boolean
language plpgsql
as $$
	begin
		FOR i in 1 .. (length(p_str)-1)
		loop
			if substring(p_str, i, 1) = substring(p_str, i+1 , 1)
			then
				return True;
			end if;
		end loop;
		return False;
	end;
	$$;

select check_adj_char('AASASA')
 
--  FUNCTION to Check IF sequencial character is used
	
CREATE OR REPLACE FUNCTION check_sequential_char(p_str  text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
 FOR i in 1 .. (length(p_str)-1)
	LOOP
		IF  ASCII(substring(p_str, i+1, 1)) - ASCII(substring(p_str, i, 1)) <> 1
		THEN
			RETURN False;
		END IF;
	END LOOP;
	RETURN True;
END;
$$;

SELECT check_sequential_char('ABCDX')

-- Regular Expression to validate the pattern or structure of PAN Number -- QWERT1827A
select * 
FROM stg_pan_number_dataset
WHERE pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'

-- Valid and Invalid PAN Categorization
CREATE OR REPLACE VIEW  valid_invalid_pan_dataset
	AS
with cte_cleaned_pan as(
	SELECT DISTINCT UPPER(TRIM(pan_number)) AS pan_number
	FROM stg_pan_number_dataset 
	WHERE pan_number is not null
	AND trim(pan_number) <> ''
),
cte_valid_pans as(
select * from cte_cleaned_pan
WHERE check_adj_char(pan_number) = false
AND check_sequential_char(substring(pan_number,1,5)) = false
AND check_sequential_char(substring(pan_number,6,4)) = false
AND pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'
	)
SELECT cln.pan_number AS PAN_Number,
	CASE 
		WHEN vld.pan_number is not null THEN 'Valid PAN'
		ELSE 'Invalid PAN'
	END  AS status
FROM cte_cleaned_pan cln
LEFT JOIN cte_valid_pans vld ON vld.pan_number = cln.pan_number


SELECT * FROM valid_invalid_pan_dataset

-- Summary Report

WITH report_cte as
	(SELECT  (select count(*) from stg_pan_number_dataset) as total_processed_dataset,
		count(*) as total_cleaned_pans,
		count(*) filter (where status = 'Valid PAN') as total_valid_pans,
		count(*) filter (where status = 'Invalid PAN') as total_invalid_pans
		FROM valid_invalid_pan_dataset)
select 	
	total_processed_dataset, 
	total_cleaned_pans, total_valid_pans, 
	total_invalid_pans,
	(total_processed_dataset- (total_valid_pans + total_invalid_pans)) as total_missing_pans
FROM report_cte;









