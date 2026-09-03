SELECT COUNT(*) AS violation_count
FROM aos_warranty_raw.warranty_claims w
JOIN aos_warranty_raw.sales_orders s ON w.order_id = s.order_id
WHERE w.claim_date < s.sale_date;
