SELECT inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
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
    inputs.orderid, 
    inputs.linkorderid
FROM physionet-data.mimiciii_clinical.inputevents_cv inputs 
INNER JOIN physionet-data.mimiciii_clinical.d_items items ON inputs.itemid = items.itemid
WHERE inputs.itemid IN 
    (
        30179,  -- PRBC's
        30001,  -- Packed RBC's
        30004   -- Washed PRBC's
    )
GROUP BY inputs.subject_id, 
    inputs.hadm_id, 
    inputs.icustay_id, 
    inputs.itemid, 
    inputs.rate,
    inputs.rateuom,
    items.label,
    inputs.amount,
    inputs.amountuom,
    inputs.orderid, 
    inputs.linkorderid;