-- a. Which prescriber had the highest total number of claims
-- (totaled over all drugs)? Report the npi and the total number of claims. 
-- npi: 1881634483 claims: 99707


SELECT prescriber.npi, SUM(total_claim_count) AS most_claims
FROM prescription INNER JOIN prescriber ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi
ORDER BY most_claims DESC
LIMIT 1;

-- b. Repeat the above, but this time report the nppes_provider_first_name, 
-- nppes_provider_last_org_name, specialty_description, and the total number of claims.

-- 1881634483	"BRUCE"	"PENDLEY"	"Family Practice"	99707

SELECT prescriber.npi, 
		nppes_provider_first_name AS first_name,
		nppes_provider_last_org_name AS last_name, 
		specialty_description,
		SUM(total_claim_count) AS most_claims
FROM prescription INNER JOIN prescriber ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi, first_name, last_name, specialty_description
ORDER BY most_claims DESC
LIMIT 1;

-- a. Which specialty had the most total number of claims (totaled over all drugs)?
	-- Family Practice with 9752347

SELECT 
		specialty_description, 
		SUM(total_claim_count) AS most_claims
FROM 
		prescription INNER JOIN prescriber 
		ON prescriber.npi = prescription.npi
GROUP BY specialty_description
ORDER BY most_claims DESC
LIMIT 1;


-- b. Which specialty had the most total number of claims for opioids? 
-- Nurse Practitioner with 900845, idk how I got a different number of claims.


SELECT 
		specialty_description, 
		SUM(total_claim_count) AS most_claims
FROM 
		prescription INNER JOIN prescriber ON prescriber.npi = prescription.npi 
		INNER JOIN drug ON drug.drug_name = prescription.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY most_claims DESC
LIMIT 1;


SELECT 
	specialty_description
	,SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug 
		USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;
	
-- c. Challenge Question: Are there any specialties that appear in the prescriber 
-- table that have no associated prescriptions in the prescription table?


SELECT 
	specialty_description
	,SUM(total_claim_count) AS total_claims
	FROM prescriber
	LEFT JOIN prescription
	USING (npi)
	GROUP BY specialty_description
	HAVING SUM(total_claim_count) IS NULL;

	-- d. Difficult Bonus: Do not attempt until you have solved all other problems!
	-- For each specialty, report the percentage of total claims by that specialty 
	-- which are for opioids.
	-- Which specialties have a high percentage of opioids?

SELECT 
	specialty_description,
	ROUND((SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END)/
	SUM(total_claim_count)), 2) * 100
		AS percent_opioid
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid DESC NULLS LAST;

-- a. Which drug (generic_name) had the highest total drug cost? Insulin

SELECT generic_name, 
		SUM(total_drug_cost)::MONEY AS pricey
FROM prescription 
INNER JOIN drug 
	USING (drug_name)
GROUP BY generic_name
ORDER BY pricey DESC
LIMIT 1;

-- Which drug (generic_name) has the hightest total cost per day? C1 ESTERASE INHIBITOR

SELECT generic_name, 
		(SUM(total_drug_cost)/SUM(total_day_supply))::MONEY AS per_day_cost
FROM prescription 
INNER JOIN drug 
	USING(drug_name)
GROUP BY generic_name
ORDER BY per_day_cost DESC
LIMIT 1;



-- For each drug in the drug table, return the drug name and then a column named 'drug_type' 
-- which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
-- which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
-- Hint: You may want to use a CASE expression for this. 


SELECT drug_name, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' 
			END drug_type
FROM drug;


-- Building off of the query you wrote for part a, 
-- determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
-- Hint: Format the total costs as MONEY for easier comparision.
-- opioid: $105,080,626.37
-- antibiotic: $38,435,121.26


WITH opioid_expense AS (
	WITH type_filter AS (SELECT drug_name,
		CASE 
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' 
		END drug_type
	FROM drug) 
		SELECT CAST(SUM(total_drug_cost)AS MONEY) AS expense,
				prescription.drug_name
		FROM prescription INNER JOIN type_filter 
			ON type_filter.drug_name = prescription.drug_name
		WHERE drug_type = 'opioid'
		GROUP BY prescription.drug_name)
SELECT SUM(expense) AS total_opioid_money
FROM opioid_expense;


WITH antibiotic_expense AS (
	WITH type_filter AS (SELECT drug_name,
		CASE 
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' 
		END drug_type
	FROM drug) 
		SELECT CAST(SUM(total_drug_cost)AS MONEY) AS expense,
				prescription.drug_name
		FROM prescription INNER JOIN type_filter 
			ON type_filter.drug_name = prescription.drug_name
		WHERE drug_type = 'antibiotic'
		GROUP BY prescription.drug_name)
SELECT SUM(expense) AS total_antibiotic_money
FROM antibiotic_expense;



-- Far better version, I overcomplicated everything

SELECT 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' 
			END drug_type,
			SUM(total_drug_cost)::MONEY AS total_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;


-- a. How many CBSAs are in Tennessee? 
-- Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa) AS count_cbsa, fips_county.state
FROM CBSA INNER JOIN fips_county
	USING (fipscounty)
WHERE fips_county.state = 'TN'
GROUP BY fips_county.state;


-- b. Which cbsa has the largest combined population? Which has the smallest? 
-- Report the CBSA name and total population.

-- Max: "Nashville-Davidson--Murfreesboro--Franklin, TN" with 1,830,410
-- Min: "Morristown, TN" with 116,352

SELECT 
		SUM(population) AS total_pop, 
		cbsaname
FROM population 
INNER JOIN cbsa
	USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? 
-- Report the county name and population. SHELBY with 937847

SELECT county, MAX(population) AS max_pop
FROM fips_county
LEFT JOIN cbsa
	USING (fipscounty)
INNER JOIN population
	USING (fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY max_pop DESC;


 -- Find all rows in the prescription table where total_claims is at least 3000. 
 -- Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- b. For each instance that you found in part a,
-- add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING (drug_name)
WHERE total_claim_count >= 3000;

 -- Add another column to you answer from the previous part which gives the prescriber
 -- first and last name associated with each row.


SELECT drug_name, 
		total_claim_count, 
		opioid_drug_flag,
		nppes_provider_first_name,
		nppes_provider_last_org_name
FROM prescription 
INNER JOIN drug
	USING (drug_name)
INNER JOIN prescriber 
	USING (npi)
WHERE total_claim_count >= 3000;


-- The goal of this exercise is to generate a full list of all pain management 
-- specialists in Nashville and the number of claims they had for each opioid.
-- Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville 
-- (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
-- Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you 
-- don't need the claims numbers yet.


SELECT drug_name, npi
FROM prescriber, drug
WHERE opioid_drug_flag = 'Y'
AND nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'

--  OR use: 

SELECT drug_name, npi
FROM prescriber 
	CROSS JOIN drug
WHERE opioid_drug_flag = 'Y'
AND nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'



-- Next, report the number of claims per drug per prescriber. 
-- Be sure to include all combinations, whether or not the prescriber had any claims. 
-- You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH pain_management AS (
	SELECT drug_name, npi
	FROM prescriber 
		CROSS JOIN drug
	WHERE opioid_drug_flag = 'Y'
	AND nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
)
SELECT drug_name, npi, total_claim_count
FROM pain_management
	LEFT JOIN prescription
	USING (npi, drug_name)
ORDER BY total_claim_count;

-- c. Finally, if you have not done so already, fill in any missing values for 
-- total_claim_count with 0.
-- Hint - Google the COALESCE function.


WITH pain_management AS (
	SELECT drug_name, npi
	FROM prescriber 
		CROSS JOIN drug
	WHERE opioid_drug_flag = 'Y'
	AND nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
)
SELECT drug_name, npi, COALESCE(total_claim_count, 0) AS claim_count
FROM pain_management
	LEFT JOIN prescription
	USING (npi, drug_name)
ORDER BY claim_count DESC;