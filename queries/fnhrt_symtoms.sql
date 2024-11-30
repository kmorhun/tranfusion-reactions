
CREATE TEMPORARY TABLE transfusion_temp AS
-- temp_table is from all_blood_inputs.sql
SELECT inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    MIN(inputs.starttime) as transfusion_starttime,
    MAX(inputs.endtime) as transfusion_endtime, 
    COUNT(inputs.endtime) as num_segments,
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
    items.label,
    inputs.linkorderid
FROM physionet-data.mimiciii_clinical.inputevents_mv inputs 
INNER JOIN physionet-data.mimiciii_clinical.d_items items ON inputs.itemid = items.itemid
WHERE inputs.itemid IN (225168, 225170, 225171, 220970, 227532)
    AND NOT inputs.statusdescription = "Rewritten"
GROUP BY inputs.linkorderid,
    inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.amountuom,
    inputs.itemid,
    items.label;

-- Step 2: Extract relevant notes from noteevents mentioning "rigors" or "chills"
With note_symptoms AS (
    SELECT
        ne.subject_id,
        ne.hadm_id,
        tt.icustay_id,
        tt.transfusion_starttime,
        tt.transfusion_endtime,
        ne.chartdate,
        ne.charttime,
        ne.text,
        CASE
            WHEN LOWER(ne.text) LIKE '%rigor%' AND LOWER(ne.text) LIKE '%chill%' THEN 'Rigors, Chills'
            WHEN LOWER(ne.text) LIKE '%rigor%' THEN 'Rigors'
            WHEN LOWER(ne.text) LIKE '%chill%' THEN 'Chills'
            ELSE NULL
        END AS symptom_mentioned
    FROM
        physionet-data.mimiciii_notes.noteevents ne
    JOIN
        transfusion_temp tt
    ON
        ne.subject_id = tt.subject_id
        AND ne.hadm_id = tt.hadm_id
    WHERE
        (LOWER(ne.text) LIKE '%chill%'
        OR LOWER(ne.text) LIKE '%rigor%')
        AND ne.charttime BETWEEN tt.transfusion_starttime AND TIMESTAMP_ADD(tt.transfusion_endtime, INTERVAL 4 HOUR)
)

-- Final Query: Select all relevant notes with "rigors" or "chills"
SELECT *
FROM note_symptoms
ORDER BY subject_id, transfusion_starttime;
