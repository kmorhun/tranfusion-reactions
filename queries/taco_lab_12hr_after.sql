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

-- Get lab values before transfusion reactions 
CREATE TEMPORARY TABLE before_lab AS
SELECT 
    chart.SUBJECT_ID, 
    chart.CHARTTIME, 
    abi.starttime, 
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
    chart.CHARTTIME BETWEEN 
        abi.starttime - INTERVAL 12 HOUR 
        AND 
        abi.starttime
    AND 
    d_items.LABEL IN (
        'Heart Rate', 
        'Resp Rate (Spont)', 
        'Resp Rate (Total)', 
        'SpO2', 
        'Manual Blood Pressure Diastolic Left', 
        'Non Invasive Blood Pressure diastolic', 
        'Manual Blood Pressure Systolic Left', 
        'Manual Blood Pressure Systolic Right', 
        'Non Invasive Blood Pressure systolic', 
        'Arterial Blood Pressure systolic', 
        'Arterial Blood Pressure diastolic', 
        'Manual Blood Pressure Diastolic Right'
    );

-- Get lab values after transfusion reactions 
CREATE TEMPORARY TABLE after_lab AS
SELECT 
    chart.SUBJECT_ID, 
    chart.CHARTTIME, 
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
    chart.CHARTTIME BETWEEN 
        abi.endtime 
        AND 
        abi.endtime + INTERVAL 12 HOUR
    AND 
    d_items.LABEL IN (
        'Heart Rate', 
        'Resp Rate (Spont)', 
        'Resp Rate (Total)', 
        'SpO2', 
        'Manual Blood Pressure Diastolic Left', 
        'Non Invasive Blood Pressure diastolic', 
        'Manual Blood Pressure Systolic Left', 
        'Manual Blood Pressure Systolic Right', 
        'Non Invasive Blood Pressure systolic', 
        'Arterial Blood Pressure systolic', 
        'Arterial Blood Pressure diastolic', 
        'Manual Blood Pressure Diastolic Right'
    );

SELECT * 
FROM after_lab;




    