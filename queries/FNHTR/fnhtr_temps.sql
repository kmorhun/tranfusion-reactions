-- Step 1: Find baseline temperature readings in Fahrenheit taken before transfusion starts
WITH baseline_temp AS (
    SELECT
        subject_id,
        hadm_id,
        icustay_id,
        MIN(charttime) AS baseline_time,
        MAX(
            CASE 
                WHEN itemid = 223761 THEN valuenum -- Fahrenheit readings
                WHEN itemid = 223762 THEN (valuenum * 9/5) + 32 -- Convert Celsius to Fahrenheit
                ELSE NULL
            END
        ) AS baseline_temp_f -- Baseline temperature in Fahrenheit
        
    FROM
        physionet-data.mimiciii_clinical.chartevents
    WHERE
        itemid IN (223761, 223762) -- Include both Fahrenheit and Celsius
        AND (
            (itemid = 223761 AND valuenum BETWEEN 86 AND 109.4) -- Fahrenheit: 86°F to 109.4°F
            OR (itemid = 223762 AND valuenum BETWEEN 30 AND 43) -- Celsius: 30°C to 43°C
        )
        AND charttime < (
            SELECT MIN(starttime)
            FROM physionet-data.mimiciii_clinical.inputevents_mv
            WHERE subject_id = chartevents.subject_id
              AND itemid IN (225168, 225170, 225171, 220970, 227532)
        )
    GROUP BY 
        subject_id, hadm_id, icustay_id
),

-- Step 2: Define transfusion events with linkorderid
transfusion_events AS (
    SELECT 
        inputs.subject_id, 
        inputs.hadm_id, 
        inputs.icustay_id, 
        inputs.linkorderid, -- Use linkorderid to identify unique transfusion events
        MIN(inputs.starttime) AS transfusion_starttime,
        MAX(inputs.endtime) AS transfusion_endtime, 
        COUNT(inputs.endtime) AS num_segments,
        DATETIME_DIFF(MAX(inputs.endtime), MIN(inputs.starttime), MINUTE) AS duration_minutes,
        CASE 
            WHEN inputs.amountuom = "uL" THEN SUM(inputs.amount * 1000) 
            ELSE SUM(inputs.amount)
        END AS amount,
        CASE 
            WHEN inputs.amountuom = "uL" THEN "ml"
            ELSE inputs.amountuom 
        END AS amountuom,
        inputs.itemid, 
        items.label
    FROM 
        physionet-data.mimiciii_clinical.inputevents_mv inputs
    INNER JOIN 
        physionet-data.mimiciii_clinical.d_items items 
    ON 
        inputs.itemid = items.itemid
    WHERE 
        inputs.itemid IN (225168, 225170, 225171, 220970, 227532) -- Transfusion-related items
        AND NOT inputs.statusdescription = "Rewritten"
    GROUP BY 
        inputs.linkorderid, -- Ensure each linkorderid is counted as a unique event
        inputs.subject_id, 
        inputs.hadm_id, 
        inputs.icustay_id, 
        inputs.amountuom,
        inputs.itemid,
        items.label
),

-- Step 3: Identify temperature readings post-transfusion
temperature_readings AS (
    SELECT
        te.subject_id,
        te.hadm_id,
        te.icustay_id,
        te.linkorderid, -- Include linkorderid to link with specific transfusion events
        te.transfusion_starttime,
        te.transfusion_endtime,
        ce.charttime AS temp_recorded_time,
        CASE 
            WHEN ce.itemid = 223761 THEN ce.valuenum -- Fahrenheit readings
            WHEN ce.itemid = 223762 THEN (ce.valuenum * 9/5) + 32 -- Convert Celsius to Fahrenheit
            ELSE NULL
        END AS temperature_fahrenheit -- Unified temperature in Fahrenheit
    FROM
        transfusion_events te
    JOIN
        physionet-data.mimiciii_clinical.chartevents ce
    ON
        te.subject_id = ce.subject_id
        AND te.icustay_id = ce.icustay_id
        AND ce.itemid IN (223761, 223762) -- Include both Fahrenheit and Celsius
    WHERE
        ce.charttime BETWEEN te.transfusion_starttime AND TIMESTAMP_ADD(te.transfusion_endtime, INTERVAL 4 HOUR)
        AND (
            (ce.itemid = 223761 AND ce.valuenum BETWEEN 86 AND 109.4) -- Fahrenheit: 86°F to 109.4°F
            OR (ce.itemid = 223762 AND ce.valuenum BETWEEN 30 AND 43) -- Celsius: 30°C to 43°C
        )
),
-- Step 4: Check for patients meeting FNHTR criteria
fnthr_candidates AS (
    SELECT
        tr.subject_id,
        tr.hadm_id,
        tr.icustay_id,
        tr.linkorderid, -- Include linkorderid to track unique transfusion events
        tr.transfusion_starttime,
        tr.temp_recorded_time,
        tr.temperature_fahrenheit,
        bt.baseline_temp_f,
        CASE 
            WHEN tr.temperature_fahrenheit >= 100.4 AND bt.baseline_temp_f IS NOT NULL AND tr.temperature_fahrenheit >= bt.baseline_temp_f + 1.8 THEN 'Temperature ≥38°C (100.4°F) & Temperature rise ≥1°C (1.8°F) above baseline'
            ELSE NULL
        END AS fnthr_criteria
    FROM
        temperature_readings tr
    LEFT JOIN
        baseline_temp bt
    ON
        tr.subject_id = bt.subject_id
        AND tr.hadm_id = bt.hadm_id
        AND tr.icustay_id = bt.icustay_id
    WHERE
        tr.temperature_fahrenheit >= 100.4
        OR (bt.baseline_temp_f IS NOT NULL AND tr.temperature_fahrenheit >= bt.baseline_temp_f + 1.8)
)

-- Final Step: Select all FNHTR candidates with relevant details
SELECT
    linkorderid, -- Include linkorderid to track unique transfusion events
    subject_id,
    hadm_id,
    icustay_id, 
    transfusion_starttime,
    temp_recorded_time,
    temperature_fahrenheit,
    baseline_temp_f,
    fnthr_criteria
FROM fnthr_candidates
WHERE fnthr_criteria IS NOT NULL
ORDER BY linkorderid, subject_id, transfusion_starttime;
