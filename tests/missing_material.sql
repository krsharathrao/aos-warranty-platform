SELECT COUNT(*) AS violation_count
FROM aos_warranty_raw.sales_orders s
LEFT JOIN aos_warranty_raw.materials m ON s.material_id = m.material_id
WHERE m.material_id IS NULL;
