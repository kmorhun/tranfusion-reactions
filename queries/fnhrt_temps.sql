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

-- Step 2: Identify transfusion events and link with post-transfusion temperature readings in Fahrenheit
transfusion_temp AS (
    SELECT
        bt.subject_id,
        bt.hadm_id,
        bt.icustay_id,
        bt.starttime AS transfusion_starttime,
        ce.charttime AS temp_recorded_time,
        ce.valuenum AS temperature_fahrenheit,
        bt.itemid AS transfusion_itemid
    FROM
        physionet-data.mimiciii_clinical.inputevents_mv bt
    JOIN
        physionet-data.mimiciii_clinical.chartevents ce
    ON
        bt.subject_id = ce.subject_id
        AND bt.icustay_id = ce.icustay_id
        AND ce.itemid IN (223761, 676) -- Temperature measurements
    WHERE
        bt.itemid IN (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
        AND ce.charttime >= bt.starttime
),

-- Step 3: Check for patients meeting FNHTR criteria using Fahrenheit thresholds
potential_fnthr AS (
    SELECT
        tt.subject_id,
        tt.hadm_id,
        tt.icustay_id,
        tt.transfusion_starttime,
        tt.temp_recorded_time,
        tt.temperature_fahrenheit,
        COALESCE(bt.baseline_temp_f, 98.6) AS baseline_temp_f,
        CASE 
            WHEN bt.baseline_temp_f >= 98.6 AND tt.temperature_fahrenheit >= bt.baseline_temp_f + 1.8 THEN 'Temperature rise ≥1°C (1.8°F) above baseline'
            WHEN tt.temperature_fahrenheit >= 100.4 THEN 'Temperature ≥38°C (100.4°F)'
            ELSE NULL
        END AS fnthr_criteria
    FROM
        transfusion_temp tt
    LEFT JOIN
        baseline_temp bt
    ON
        tt.subject_id = bt.subject_id
        AND tt.hadm_id = bt.hadm_id
        AND tt.icustay_id = bt.icustay_id
    WHERE
        (bt.baseline_temp_f IS NULL OR tt.temperature_fahrenheit >= bt.baseline_temp_f + 1.8)
        OR tt.temperature_fahrenheit >= 100.4
)

-- Step 6: Select all FNHTR candidates with relevant details
SELECT *
FROM potential_fnthr
WHERE fnthr_criteria IS NOT NULL
ORDER BY subject_id, transfusion_starttime;
