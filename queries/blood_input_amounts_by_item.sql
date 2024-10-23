SELECT
    inputs.itemid, 
    items.label,
    COUNT(CASE 
        WHEN inputs.amountuom = "uL" THEN inputs.amount * 1000 
        ELSE inputs.amount 
    END) AS count,
    AVG(CASE 
        WHEN inputs.amountuom = "uL" THEN inputs.amount * 1000 
        ELSE inputs.amount 
    END) AS avg_ml,
    MIN(CASE 
        WHEN inputs.amountuom = "uL" THEN inputs.amount * 1000 
        ELSE inputs.amount 
    END) AS min_ml,
    MAX(CASE 
        WHEN inputs.amountuom = "uL" THEN inputs.amount * 1000 
        ELSE inputs.amount 
    END) AS max_ml,
FROM physionet-data.mimiciii_clinical.inputevents_mv inputs 
INNER JOIN physionet-data.mimiciii_clinical.d_items items ON inputs.itemid = items.itemid
WHERE inputs.itemid IN (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
GROUP BY
    inputs.itemid, 
    items.label;