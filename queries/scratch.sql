CREATE TEMPORARY TABLE all_blood_inputs AS
SELECT inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.starttime, 
    inputs.endtime, 
    DATETIME_DIFF(inputs.endtime, inputs.starttime, MINUTE) AS duration_minutes,
    inputs.itemid, 
    inputs.rate,
    inputs.rateuom,
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
    inputs.isopenbag,
    inputs.orderid, 
    inputs.linkorderid
FROM physionet-data.mimiciii_clinical.inputevents_mv inputs 
INNER JOIN physionet-data.mimiciii_clinical.d_items items ON inputs.itemid = items.itemid
WHERE inputs.itemid IN 
    (
        225168,   -- Packed Red Blood Cells
        226368,   -- OR Packed RBC Intake
        227070   -- PACU Packed RBC Intake
    )
GROUP BY inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.starttime, 
    inputs.endtime, 
    duration_minutes,
    inputs.itemid, 
    inputs.rate,
    inputs.rateuom,
    items.label,
    inputs.amount,
    inputs.amountuom,
    inputs.totalamount,
    inputs.totalamountuom,
    inputs.statusdescription, 
    inputs.cancelreason, 
    inputs.isopenbag,
    inputs.orderid, 
    inputs.linkorderid;

WITH latest_endtime_per_linkorderid AS (
  -- Step 1: Find the entry with the largest endtime for each unique linkorderid
  SELECT
      inputs.linkorderid,
      MAX(inputs.endtime) AS latest_endtime
  FROM physionet-data.mimiciii_clinical.inputevents_mv inputs
  GROUP BY linkorderid
),

first_note_after_endtime AS (
  -- Step 2: For each linkorderid, find the first note written after the latest_endtime
  SELECT 
      i.linkorderid,
      n.subject_id,
      n.hadm_id,
      MIN(n.chartdate) as earliest_note_date, -- smallest time greater than latest_endtime
      n.charttime,
      n.storetime,
      n.category,
      n.description,
      n.cgid,
      n.iserror,
      n.text,
    --   ROW_NUMBER() OVER (PARTITION BY i.linkorderid ORDER BY n.chartdate ASC) AS row_number
  FROM latest_endtime_per_linkorderid i
  JOIN physionet-data.mimiciii_notes.noteevents n
    ON n.chartdate > i.latest_endtime -- Only consider notes after the latest endtime
  GROUP BY i.linkorderid,
    n.subject_id,
    n.hadm_id,
    n.charttime,
    n.storetime,
    n.category,
    n.description,
    n.cgid,
    n.iserror,
    n.text
)

SELECT *
FROM first_note_after_endtime;