SELECT *
FROM physionet-data.mimiciii_clinical.inputevents_mv
WHERE itemid > 225168
LIMIT 100
-- GROUP BY itemid, label, category;
