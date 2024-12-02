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

-- Final query: Count total transfusion events
SELECT
    COUNT(DISTINCT linkorderid) AS total_transfusion_events -- Count unique transfusion events by linkorderid
FROM
    transfusion_temp;
