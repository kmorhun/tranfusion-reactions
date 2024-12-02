-- Query for itemid 223762
SELECT DISTINCT subject_id
FROM physionet-data.mimiciii_clinical.chartevents
WHERE itemid = 223762 -- Temperature in Celsius
  AND valuenum IS NOT NULL
ORDER BY subject_id;
