SELECT itemid, label, category, dbsource, COUNT(category) AS count
FROM physionet-data.mimiciii_clinical.d_items
WHERE category IS NOT NULL AND dbsource="metavision"
GROUP BY itemid, label, category, dbsource;