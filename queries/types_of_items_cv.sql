SELECT itemid, label, category, dbsource, COUNT(*) AS count
FROM physionet-data.mimiciii_clinical.d_items
WHERE itemid IN (30179, 30001, 30004, 30005, 30180)
GROUP BY itemid, label, category, dbsource;