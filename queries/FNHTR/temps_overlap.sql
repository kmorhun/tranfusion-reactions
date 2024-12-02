-- Step 1: Analyze distributions of temperature-related measurements
WITH temperature_analysis AS (
    SELECT
        itemid,
        ARRAY_AGG(subject_id) AS subject_ids, -- Collect subject IDs
        COUNT(DISTINCT subject_id) AS unique_patients, -- Count unique patients
        COUNT(*) AS total_measurements,               -- Total measurements for each itemid
        AVG(valuenum) AS avg_temperature,             -- Average temperature
        MIN(valuenum) AS min_temperature,             -- Minimum temperature
        MAX(valuenum) AS max_temperature              -- Maximum temperature
    FROM
        physionet-data.mimiciii_clinical.chartevents
    WHERE
        itemid IN (44007, 44037, 44074, 44104, 224642, 224351, 223762, 223761) -- Temperature-related item IDs
        AND valuenum IS NOT NULL -- Ensure temperature values are not null
    GROUP BY
        itemid
),

-- Step 2: Extract specific temperature item data for comparison
temperature_a AS (
    SELECT subject_id
    FROM physionet-data.mimiciii_clinical.chartevents
    WHERE itemid = 223761 -- First temperature item ID (Fahrenheit)
    AND valuenum IS NOT NULL
),

temperature_b AS (
    SELECT subject_id
    FROM physionet-data.mimiciii_clinical.chartevents
    WHERE itemid = 223762 -- Second temperature item ID (Celsius)
    AND valuenum IS NOT NULL
)

-- Step 3: Compare subject IDs and count overlaps
SELECT
    (SELECT COUNT(DISTINCT ta.subject_id) FROM temperature_a ta) AS unique_patients_a,
    (SELECT COUNT(DISTINCT tb.subject_id) FROM temperature_b tb) AS unique_patients_b,
    COUNT(DISTINCT ta.subject_id) AS overlapping_subjects
FROM
    temperature_a ta
INNER JOIN
    temperature_b tb
ON
    ta.subject_id = tb.subject_id;
