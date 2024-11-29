SELECT inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    MIN(inputs.starttime) as starttime,
    MAX(inputs.endtime) as endtime, 
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