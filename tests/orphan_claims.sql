SELECT COUNT(*) AS violation_count
FROM aos_warranty_raw.warranty_claims w
LEFT JOIN aos_warranty_raw.sales_orders s ON w.order_id = s.order_id
WHERE s.order_id IS NULL;
