SELECT 
    chart.ITEMID, 
    items.LABEL, 
    chart.VALUEUOM
FROM 
    physionet-data.mimiciii_clinical.chartevents AS chart
JOIN 
    physionet-data.mimiciii_clinical.d_items AS items
    ON chart.ITEMID = items.ITEMID
WHERE 
    chart.ITEMID IN (44007, 44037, 44074, 44104, 224642, 224351, 223762, 223761)
GROUP BY 
    chart.ITEMID, 
    items.LABEL, 
    chart.VALUEUOM
ORDER BY 
    chart.ITEMID;
