SELECT 
    COUNT(DISTINCT subject_id) AS total_unique_patients
FROM 
    physionet-data.mimiciii_clinical.patients;
