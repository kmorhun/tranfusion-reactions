CREATE TEMPORARY TABLE all_blood_inputs AS
-- temp_table is from all_blood_inputs.sql
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
        'Respiratory Rate',
        'Respiratory Rate Set',
        'Respiratory Rate (spontaneous)',
        'SpO2', 
        'O2 saturation pulseoxymetry',
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
        'Respiratory Rate',
        'Respiratory Rate Set',
        'Respiratory Rate (spontaneous)',
        'SpO2', 
        'O2 saturation pulseoxymetry',
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
