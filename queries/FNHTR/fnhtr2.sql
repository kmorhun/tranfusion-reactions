
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

-- Temporary table to filter temperature-related measurements within 4 hours of transfusion
CREATE TEMPORARY TABLE fnthr_temperature AS
SELECT 
    chart.SUBJECT_ID, 
    chart.CHARTTIME, 
    abi.starttime, 
    abi.endtime, 
    d_items.ITEMID, 
    d_items.LABEL, 
    chart.VALUE, 
    chart.VALUENUM, 
    chart.VALUEUOM
FROM 
    physionet-data.mimiciii_clinical.chartevents AS chart
LEFT JOIN 
    physionet-data.mimiciii_clinical.d_items AS d_items 
    ON chart.ITEMID = d_items.ITEMID
INNER JOIN 
    all_blood_inputs AS abi
    ON chart.SUBJECT_ID = abi.subject_id
WHERE 
    chart.CHARTTIME BETWEEN abi.starttime AND abi.endtime + INTERVAL 4 HOUR
    AND d_items.ITEMID IN (44007, 44037, 44074, 44104, 224642, 224351, 223762, 223761) -- Temperature-related item IDs
GROUP BY 
    chart.SUBJECT_ID, 
    chart.CHARTTIME, 
    abi.starttime, 
    abi.endtime, 
    d_items.ITEMID, 
    d_items.LABEL, 
    chart.VALUE, 
    chart.VALUENUM, 
    chart.VALUEUOM;

-- Final query to output patients with FNHTR-related data
SELECT 
    abi.subject_id, 
    abi.hadm_id, 
    abi.icustay_id, 
    abi.starttime AS transfusion_starttime, 
    abi.endtime AS transfusion_endtime, 
    temp.CHARTTIME AS measurement_time, 
    temp.ITEMID AS temperature_itemid, 
    temp.LABEL AS temperature_label, 
    temp.VALUE AS temperature_value, 
    temp.VALUENUM AS temperature_numeric_value, 
    temp.VALUEUOM AS temperature_unit
FROM 
    all_blood_inputs AS abi
INNER JOIN 
    fnthr_temperature AS temp
    ON abi.subject_id = temp.subject_id
WHERE 
    temp.VALUENUM >= 38 -- Temperature >= 38°C
    OR (temp.VALUENUM >= 37 AND temp.VALUENUM - (SELECT MIN(temp_start.VALUENUM) 
                                                 FROM fnthr_temperature AS temp_start 
                                                 WHERE temp_start.SUBJECT_ID = temp.SUBJECT_ID 
                                                 AND temp_start.CHARTTIME < abi.starttime) >= 1)
ORDER BY 
    abi.subject_id, 
    temp.CHARTTIME;
