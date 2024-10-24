CREATE TEMPORARY TABLE all_blood_inputs AS
-- temp_table is from all_blood_inputs.sql
SELECT inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.starttime, 
    inputs.endtime, 
    inputs.itemid, 
    items.label,
    CASE 
        WHEN inputs.amountuom = "uL" THEN inputs.amount * 1000 
        ELSE inputs.amount 
    END AS amount,
    CASE 
        WHEN inputs.amountuom = "uL" THEN "ml"
        ELSE inputs.amountuom 
    END AS amountuom,
    inputs.totalamount,
    inputs.totalamountuom,
    inputs.statusdescription, 
    inputs.cancelreason, 
    inputs.orderid, 
    inputs.linkorderid
FROM physionet-data.mimiciii_clinical.inputevents_mv inputs 
INNER JOIN physionet-data.mimiciii_clinical.d_items items ON inputs.itemid = items.itemid
WHERE inputs.itemid IN (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
GROUP BY inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.starttime, 
    inputs.endtime, 
    inputs.itemid, 
    items.label,
    inputs.amount,
    inputs.amountuom,
    inputs.totalamount,
    inputs.totalamountuom,
    inputs.statusdescription, 
    inputs.cancelreason, 
    inputs.orderid, 
    inputs.linkorderid;

-- Get notes with matching patients records 
SELECT * 
FROM physionet-data.mimiciii_notes.noteevents
WHERE (SUBJECT_ID IN (SELECT subject_id FROM all_blood_inputs))
    -- Selects notes on start date or one day after end day 
    -- Note: dates are internally consistent in the database: https://mimic.mit.edu/docs/iii/about/time/
     AND (
        DATE(CHARTDATE) IN (SELECT DATE(starttime) FROM all_blood_inputs)
        OR DATE(CHARTDATE) IN (SELECT DATE(endtime + INTERVAL 1 DAY) FROM all_blood_inputs)
    );
