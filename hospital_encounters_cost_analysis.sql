USE hospital_db;
-- OBJECTIVE 1: ENCOUNTER OVERVIEW
-- 1a. Total encounters each year
SELECT 
	year(start) as Start_Year,
    count(*) as encounters
FROM encounters
GROUP BY 1
ORDER BY 1;


-- 1b. Percentage of encounters by class for each year
SELECT 
	a.start_year,
	a.encounterclass,
	a.encounters/b.yearly_total * 100 as Percentage
FROM
(SELECT 
	year(start) as Start_Year,
	encounterclass,count(*) as encounters
FROM encounters
GROUP BY 1,2) a
JOIN
(select 
	year(start) as Start_Year,
	count(*) as yearly_total
FROM encounters
GROUP BY 1 ) b
ON a.start_year=b.start_year
ORDER BY 1;


-- 1c. Percentage of encounters over 24 hours vs. under 24 hours
SELECT 
	a.duration,
    a.count,
    (a.count/b.total)* 100 as percentage
FROM

(
	SELECT 
		case 
			when TIMESTAMPDIFF(HOUR, start, stop)>=24 then'24+'
			else 'under 24'  
		end as duration,
		count(*) as count
    
	FROM encounters
	GROUP BY 1
    ) a

CROSS JOIN 
(
	SELECT COUNT(*) AS total
	FROM encounters
    ) b;


-- OBJECTIVE 2: COST & COVERAGE ANALYSIS
-- 2a. Number and percentage of encounters with zero payer coverage
SELECT 
	a.zero_coverage_encounters,
    a.zero_coverage_encounters/b.total*100 as percentage_zero_coverage 
from    
(SELECT 
	count(*) as zero_coverage_encounters
FROM encounters
where payer_coverage = 0) a
cross join
(SELECT 
	count(*) as total
from encounters) b;

-- 2b. Top 10 most frequent procedures and their average base cost

SELECT 
	description as procedures,
    count(*) as Frequency,
    avg(base_cost) avg_cost
FROM PROCEDURES
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 2c. Top 10 procedures by average base cost and number of times performed
SELECT 
	description as procedures,
    count(*) as Frequency,
    avg(base_cost) avg_cost
FROM PROCEDURES
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

-- 2d. Average total claim cost per encounter by payer
SELECT p.name,
		avg(e.total_claim_cost) as avg_total
FROM encounters e
JOIN payers p
ON p.id=e.payer
GROUP BY 1
order by 2 DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
-- 3a. Unique patients by quarter over time
SELECT 
	quarter(start) as Quarter,
    YEAR(start) as Year,
    count(distinct patient) unique_patients
   
FROM encounters
group by 1 , 2
order by 2,1;

-- 3b. Number of patients readmitted within 30 days of a previous encounter
SELECT  
    COUNT(DISTINCT a.patient) AS readmitted
FROM encounters a
JOIN encounters b
    ON a.patient = b.patient
    WHERE a.start >= b.stop and TIMESTAMPDIFF(DAY, b.stop, a.start) BETWEEN 0 AND 30;
    
-- 3c. Patients with the most 30-day readmissions
SELECT  
    a.patient,
    COUNT(DISTINCT a.id) AS readmitted_patients
FROM encounters a
JOIN encounters b
    ON a.patient = b.patient
    WHERE a.start >= b.stop 
    AND TIMESTAMPDIFF(DAY, b.stop, a.start) BETWEEN 0 AND 30
GROUP BY 1
ORDER BY 2 DESC;