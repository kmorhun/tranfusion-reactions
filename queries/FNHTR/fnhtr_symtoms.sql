-- Create a temporary table to store transfusion events
CREATE TEMPORARY TABLE transfusion_temp AS
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
    items.label;

-- Step 2: Extract relevant notes from noteevents mentioning "rigors" or "chills"
WITH note_symptoms AS (
    SELECT
        ne.subject_id,
        ne.hadm_id,
        tt.icustay_id,
        tt.linkorderid, -- Include linkorderid to link with specific transfusion events
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
        AND ne.charttime BETWEEN tt.transfusion_starttime AND TIMESTAMP_ADD(tt.transfusion_endtime, INTERVAL 4 HOUR)
    WHERE
        (LOWER(ne.text) LIKE '%chill%'
        OR LOWER(ne.text) LIKE '%rigor%')
)

-- Final Query: Count unique transfusion events with symptoms
SELECT
    tt.subject_id,
    tt.linkorderid, -- Unique transfusion events identified by subject_id + linkorderid
    COUNT(DISTINCT CONCAT(tt.subject_id, tt.linkorderid)) AS unique_transfusion_events,
    ns.symptom_mentioned,
    COUNT(*) AS symptom_count -- Count occurrences of each symptom type
FROM
    note_symptoms ns
JOIN
    transfusion_temp tt
ON
    ns.subject_id = tt.subject_id
    AND ns.linkorderid = tt.linkorderid -- Ensure accurate mapping of symptoms to unique transfusion events
GROUP BY
    tt.subject_id,
    tt.linkorderid,
    ns.symptom_mentioned
ORDER BY
    unique_transfusion_events DESC,
    tt.subject_id,
    tt.linkorderid;
