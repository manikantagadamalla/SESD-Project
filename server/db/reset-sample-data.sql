-- ============================================================================
-- IntelliStock: Remove ONLY the sample data created by seed-sample-data.sql
-- ============================================================================
-- Usage:
--   psql -U postgres -d <DB_NAME> -v ON_ERROR_STOP=1 -f reset-sample-data.sql
--
-- Your real products, customers, sales and demo users are not touched.
-- ============================================================================

BEGIN;

DELETE FROM customer_interactions
 WHERE customer_id IN (SELECT id FROM customers WHERE mobile_number LIKE '90000000%');

-- invoice_items are removed automatically (ON DELETE CASCADE)
DELETE FROM invoices WHERE invoice_number LIKE 'SEED-INV-%';

DELETE FROM sales WHERE transaction_id LIKE 'SEED-TXN-%';

DELETE FROM low_stock_alerts
 WHERE product_id IN (SELECT id FROM products WHERE sku LIKE 'SMP-%');

DELETE FROM notifications n
 WHERE n.message LIKE 'Low stock alert: %'
   AND EXISTS (SELECT 1 FROM products p
                WHERE p.sku LIKE 'SMP-%'
                  AND n.message LIKE 'Low stock alert: ' || p.name || '%');

DELETE FROM products  WHERE sku LIKE 'SMP-%';
DELETE FROM customers WHERE mobile_number LIKE '90000000%';

DELETE FROM loyalty_programs WHERE name IN ('Silver Member', 'Gold Member', 'Platinum Member');
DELETE FROM shop_details     WHERE gst_number = '29ABCDE1234F1Z5';

COMMIT;
