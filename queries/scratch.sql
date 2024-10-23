-- SELECT count(*) 
-- FROM physionet-data.mimiciii_clinical.inputevents_mv
-- WHERE amount < 0;
-- -- count = 5582 rows 

SELECT count(*) 
FROM physionet-data.mimiciii_clinical.inputevents_mv
WHERE amount < 0 
AND CANCELREASON < 1;
-- count = 20 rows