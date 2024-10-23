SELECT label, itemid, category, dbsource, COUNT(*) AS count
FROM physionet-data.mimiciii_clinical.d_items
WHERE category = "Blood Products/Colloids"
GROUP BY itemid, label, category, dbsource;