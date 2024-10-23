SELECT itemid, label, category, dbsource, COUNT(*) AS count
FROM physionet-data.mimiciii_clinical.d_items
WHERE (LOWER(label) LIKE '%rbc%' 
OR LOWER(label) LIKE '%platelet%'
OR LOWER(label) LIKE '%ffp%'
OR LOWER(label) LIKE '%cryoprecipitate%'
OR LOWER(label) LIKE '%blood–– cell%'
OR LOWER(label) LIKE '%pheresis%')
AND dbsource='carevue'
GROUP BY itemid, label, category, dbsource;