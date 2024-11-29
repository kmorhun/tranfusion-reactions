-- Step 1: Find baseline temperature readings in Fahrenheit taken before transfusion starts
WITH baseline_temp AS (
    SELECT
        subject_id,
        hadm_id,
        icustay_id,
        MIN(charttime) AS baseline_time,
        MAX(valuenum) AS baseline_temp_f -- Baseline temperature before transfusion in Fahrenheit
    FROM
        physionet-data.mimiciii_clinical.chartevents
    WHERE
        itemid IN (223761, 676) -- Temperature measurements
        AND valuenum >= 98.6 -- Baseline temperature of 37°C in Fahrenheit
        AND charttime < (
            SELECT MIN(starttime)
            FROM physionet-data.mimiciii_clinical.inputevents_mv
            WHERE subject_id = chartevents.subject_id
              AND itemid IN (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
        )
    GROUP BY subject_id, hadm_id, icustay_id
),

-- Step 4: Identify additional symptoms (chills, rigors, respiratory rate, blood pressure, anxiety, headache), excluding null values
symptoms AS (
    SELECT
        ce.subject_id,
        ce.hadm_id,
        ce.icustay_id,
        ce.charttime AS symptom_time,
        di.label AS symptom
    FROM
        physionet-data.mimiciii_clinical.chartevents ce
    JOIN
        physionet-data.mimiciii_clinical.d_items di
    ON
        ce.itemid = di.itemid
    WHERE
        LOWER(di.label) IN ('chills', 'rigors', 'respiratory rate', 'blood pressure', 'anxiety', 'headache')
        AND ce.charttime >= (
            SELECT MIN(starttime)
            FROM physionet-data.mimiciii_clinical.inputevents_mv
            WHERE subject_id = ce.subject_id
              AND itemid IN (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
        )
        AND di.label IS NOT NULL -- Ensure symptom is not null
)

-- Step 6: Select all FNHTR candidates with relevant details
SELECT *
FROM symptoms
WHERE fnthr_criteria IS NOT NULL
ORDER BY subject_id, transfusion_starttime;
