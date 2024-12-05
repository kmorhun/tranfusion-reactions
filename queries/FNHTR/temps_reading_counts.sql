-- Step 1: Find baseline temperature readings in Fahrenheit taken before transfusion starts
WITH baseline_temp AS (
    SELECT
        subject_id,
    FROM
        physionet-data.mimiciii_clinical.chartevents
    WHERE
        itemid IN (223761, 223762) -- Include both Fahrenheit and Celsius
    GROUP BY 
        subject_id
)

-- Final Step: Select all FNHTR candidates with relevant details
SELECT *
FROM baseline_temp
