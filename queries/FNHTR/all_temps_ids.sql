-- Step 1: Analyze distributions of temperature-related measurements
WITH temperature_analysis AS (
    SELECT
        itemid,
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
)

-- Final query: Include temperature details
SELECT
    ta.itemid,
    di.label AS temperature_label,
    ta.unique_patients,
    ta.total_measurements,
    ta.avg_temperature,
    ta.min_temperature,
    ta.max_temperature
FROM
    temperature_analysis ta
LEFT JOIN
    physionet-data.mimiciii_clinical.d_items di
ON
    ta.itemid = di.itemid
ORDER BY
    ta.unique_patients DESC, -- Order by the number of unique patients
    ta.itemid;


