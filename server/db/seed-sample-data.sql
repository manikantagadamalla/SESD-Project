-- ============================================================================
-- IntelliStock: Sample Data Seed
-- ============================================================================
-- Run AFTER schema.sql and add-shop-and-customers.sql
--
-- Usage:
--   psql -U postgres -d <DB_NAME> -v ON_ERROR_STOP=1 -f seed-sample-data.sql
--
-- Safe to run more than once (it skips anything already seeded).
-- To remove all sample data, run reset-sample-data.sql.
--
-- Sample rows are tagged so they can be found/removed later:
--   products   -> sku starts with 'SMP-'
--   customers  -> mobile_number starts with '90000000'
--   sales      -> transaction_id starts with 'SEED-TXN-'
--   invoices   -> invoice_number starts with 'SEED-INV-'
-- Your demo users (admin/staff/client) are NOT touched.
-- ============================================================================

BEGIN;

-- Fixed seed so the generated data is the same every run
SELECT setseed(0.42);

-- The app adds this column at startup (db.js); make sure it exists
ALTER TABLE sales ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(80);

-- ── 1) Shop details (only if you have none yet) ─────────────────────────
INSERT INTO shop_details (name, address, city, state, postal_code, contact_number, email, gst_number, pan_number, business_type)
SELECT 'IntelliStock Store', '123 Business Street', 'Bengaluru', 'Karnataka', '560001',
       '+91-9876543210', 'store@intellistock.com', '29ABCDE1234F1Z5', 'ABCDE1234F', 'Retail'
WHERE NOT EXISTS (SELECT 1 FROM shop_details);

-- ── 2) Loyalty programs ─────────────────────────────────────────────────
INSERT INTO loyalty_programs (name, purchase_threshold, discount_percentage, loyalty_points_per_rupee, is_active)
SELECT v.name, v.threshold, v.disc, v.pts, TRUE
FROM (VALUES
  ('Silver Member',   5000.00,  2.00, 0.01),
  ('Gold Member',    15000.00,  5.00, 0.02),
  ('Platinum Member', 40000.00, 8.00, 0.03)
) AS v(name, threshold, disc, pts)
WHERE NOT EXISTS (SELECT 1 FROM loyalty_programs lp WHERE lp.name = v.name);

-- ── 3) Products (40 items, prices in INR) ───────────────────────────────
-- Includes: low-stock items, out-of-stock items, near-expiry items,
-- and one inactive product so every filter/alert has something to show.
INSERT INTO products
  (sku, name, category, brand, cost_price, selling_price, discount_percentage,
   stock_quantity, reorder_level, expiry_date, is_active)
SELECT v.sku, v.name, v.category, v.brand, v.cost, v.price, v.disc,
       v.stock, v.reorder,
       CASE WHEN v.exp_days IS NULL THEN NULL ELSE CURRENT_DATE + v.exp_days END,
       v.active
FROM (VALUES
  -- Electronics
  ('SMP-ELE-001', 'Dell Inspiron 15 Laptop',            'Electronics', 'Dell',      42000.00, 49990.00,  5,  14,  5, NULL, TRUE),
  ('SMP-ELE-002', 'HP 15s Laptop',                      'Electronics', 'HP',        38500.00, 45990.00,  0,   9,  5, NULL, TRUE),
  ('SMP-ELE-003', 'Samsung Galaxy M14 5G',              'Electronics', 'Samsung',   11500.00, 13999.00,  3,  22,  8, NULL, TRUE),
  ('SMP-ELE-004', 'Logitech M221 Wireless Mouse',       'Electronics', 'Logitech',    480.00,   799.00,  0,  85, 20, NULL, TRUE),
  ('SMP-ELE-005', 'Logitech K380 Bluetooth Keyboard',   'Electronics', 'Logitech',   1900.00,  2795.00,  5,  30, 10, NULL, TRUE),
  ('SMP-ELE-006', 'boAt Rockerz 255 Neckband',          'Electronics', 'boAt',        700.00,  1299.00, 10,   6, 15, NULL, TRUE),
  ('SMP-ELE-007', 'Sony 43-inch 4K Smart TV',           'Electronics', 'Sony',      31000.00, 36990.00,  0,   0,  3, NULL, TRUE),
  ('SMP-ELE-008', 'Mi Power Bank 20000mAh',             'Electronics', 'Xiaomi',     1250.00,  1899.00,  5,  48, 15, NULL, TRUE),
  -- Accessories
  ('SMP-ACC-001', 'SanDisk 64GB Pen Drive',             'Accessories', 'SanDisk',     380.00,   599.00,  0, 120, 30, NULL, TRUE),
  ('SMP-ACC-002', 'Zebronics USB-C Cable 1m',           'Accessories', 'Zebronics',    90.00,   199.00,  0,   8, 25, NULL, TRUE),
  ('SMP-ACC-003', 'Wildcraft Laptop Backpack 15.6 inch','Accessories', 'Wildcraft',   750.00,  1399.00, 15,  40, 10, NULL, TRUE),
  ('SMP-ACC-004', 'Samsung EVO 128GB microSD',          'Accessories', 'Samsung',     720.00,  1099.00,  0,  55, 15, NULL, TRUE),
  ('SMP-ACC-005', 'Spigen Silicone Phone Cover',        'Accessories', 'Spigen',      220.00,   499.00, 20,   0, 20, NULL, TRUE),
  ('SMP-ACC-006', 'Old Model Phone Charger 10W',        'Accessories', 'Xiaomi',      160.00,   299.00,  0,  12, 10, NULL, FALSE),
  -- Groceries
  ('SMP-GRO-001', 'Aashirvaad Atta 5kg',                'Groceries',   'Aashirvaad',  235.00,   289.00,  0,  90, 25, 150, TRUE),
  ('SMP-GRO-002', 'Fortune Sunflower Oil 1L',           'Groceries',   'Fortune',     128.00,   155.00,  0, 120, 30, 240, TRUE),
  ('SMP-GRO-003', 'Tata Salt 1kg',                      'Groceries',   'Tata',         22.00,    28.00,  0, 200, 50, 500, TRUE),
  ('SMP-GRO-004', 'Tata Tea Gold 500g',                 'Groceries',   'Tata',        265.00,   310.00,  5,  70, 20, 300, TRUE),
  ('SMP-GRO-005', 'Britannia Marie Gold 250g',          'Groceries',   'Britannia',    28.00,    40.00,  0,  12, 40,  90, TRUE),
  ('SMP-GRO-006', 'Amul Butter 500g',                   'Groceries',   'Amul',        255.00,   285.00,  0,  25, 15,  20, TRUE),
  ('SMP-GRO-007', 'Maggi Noodles 12-Pack',              'Groceries',   'Nestle',      132.00,   168.00,  0, 140, 40, 180, TRUE),
  ('SMP-GRO-008', 'India Gate Basmati Rice 5kg',        'Groceries',   'India Gate',  520.00,   640.00,  0,  55, 20, 365, TRUE),
  -- Stationery
  ('SMP-STA-001', 'Classmate Notebook 200 Pages',       'Stationery',  'Classmate',    38.00,    65.00,  0, 180, 50, NULL, TRUE),
  ('SMP-STA-002', 'Reynolds Trimax Pen Box (10)',       'Stationery',  'Reynolds',     70.00,   120.00,  0,  95, 30, NULL, TRUE),
  ('SMP-STA-003', 'Camlin Geometry Box',                'Stationery',  'Camlin',       85.00,   150.00,  5,  60, 20, NULL, TRUE),
  ('SMP-STA-004', 'JK A4 Paper Ream 500 Sheets',        'Stationery',  'JK Paper',    235.00,   320.00,  0,   4, 15, NULL, TRUE),
  ('SMP-STA-005', 'Fevicol MR 200g',                    'Stationery',  'Pidilite',     52.00,    85.00,  0,  75, 20, NULL, TRUE),
  ('SMP-STA-006', 'Kangaro HS-10 Stapler',              'Stationery',  'Kangaro',      55.00,    99.00,  0,  45, 15, NULL, TRUE),
  -- Home & Kitchen
  ('SMP-HOM-001', 'Prestige Induction Cooktop',         'Home & Kitchen', 'Prestige', 2100.00,  3195.00, 10,  18,  6, NULL, TRUE),
  ('SMP-HOM-002', 'Milton Thermosteel Bottle 1L',       'Home & Kitchen', 'Milton',    480.00,   799.00,  5,  65, 15, NULL, TRUE),
  ('SMP-HOM-003', 'Philips LED Bulb 9W (Pack of 4)',    'Home & Kitchen', 'Philips',   280.00,   449.00,  0, 110, 30, NULL, TRUE),
  ('SMP-HOM-004', 'Pigeon Pressure Cooker 3L',          'Home & Kitchen', 'Pigeon',    890.00,  1395.00,  8,   3,  8, NULL, TRUE),
  ('SMP-HOM-005', 'Bajaj Room Heater 1000W',            'Home & Kitchen', 'Bajaj',    1400.00,  2150.00,  0,  20,  6, NULL, TRUE),
  ('SMP-HOM-006', 'Cello Water Bottle Set (4)',         'Home & Kitchen', 'Cello',     210.00,   350.00,  0,  70, 20, NULL, TRUE),
  -- Personal Care
  ('SMP-PER-001', 'Dove Shampoo 340ml',                 'Personal Care', 'Dove',       235.00,   320.00,  0,  80, 25, 400, TRUE),
  ('SMP-PER-002', 'Colgate MaxFresh 150g',              'Personal Care', 'Colgate',     78.00,   105.00,  0, 160, 40, 450, TRUE),
  ('SMP-PER-003', 'Dettol Handwash Refill 900ml',       'Personal Care', 'Dettol',     135.00,   189.00,  0,   9, 20, 400, TRUE),
  ('SMP-PER-004', 'Nivea Men Face Wash 100g',           'Personal Care', 'Nivea',      150.00,   225.00, 10,  50, 15, 380, TRUE),
  ('SMP-PER-005', 'Gillette Guard Razor (Pack of 3)',   'Personal Care', 'Gillette',    52.00,    90.00,  0, 100, 30, NULL, TRUE),
  ('SMP-PER-006', 'Parachute Coconut Oil 500ml',        'Personal Care', 'Parachute',  195.00,   245.00,  0,  85, 25, 320, TRUE)
) AS v(sku, name, category, brand, cost, price, disc, stock, reorder, exp_days, active)
ON CONFLICT (sku) DO NOTHING;

-- ── 4) Customers (15) ───────────────────────────────────────────────────
INSERT INTO customers (name, mobile_number, email, address, city, state, postal_code)
VALUES
  ('Rahul Sharma',    '9000000001', 'rahul.sharma@example.com',   '12 MG Road',          'Bengaluru', 'Karnataka',   '560001'),
  ('Priya Reddy',     '9000000002', 'priya.reddy@example.com',    '45 Banjara Hills',    'Hyderabad', 'Telangana',   '500034'),
  ('Anil Kumar',      '9000000003', 'anil.kumar@example.com',     '8 Anna Salai',        'Chennai',   'Tamil Nadu',  '600002'),
  ('Sneha Patil',     '9000000004', 'sneha.patil@example.com',    '21 FC Road',          'Pune',      'Maharashtra', '411004'),
  ('Vikram Singh',    '9000000005', 'vikram.singh@example.com',   '3 Connaught Place',   'New Delhi', 'Delhi',       '110001'),
  ('Lakshmi Narayan', '9000000006', 'lakshmi.n@example.com',      '17 T Nagar',          'Chennai',   'Tamil Nadu',  '600017'),
  ('Mohammed Irfan',  '9000000007', 'irfan.m@example.com',        '9 Charminar Road',    'Hyderabad', 'Telangana',   '500002'),
  ('Divya Nair',      '9000000008', 'divya.nair@example.com',     '30 MG Road',          'Kochi',     'Kerala',      '682016'),
  ('Suresh Babu',     '9000000009', 'suresh.babu@example.com',    '5 Gandhi Nagar',      'Vijayawada','Andhra Pradesh','520010'),
  ('Kavita Joshi',    '9000000010', 'kavita.joshi@example.com',   '14 Shivaji Nagar',    'Pune',      'Maharashtra', '411005'),
  ('Arjun Rao',       '9000000011', 'arjun.rao@example.com',      '27 Indiranagar',      'Bengaluru', 'Karnataka',   '560038'),
  ('Pooja Gupta',     '9000000012', 'pooja.gupta@example.com',    '6 Sector 17',         'Chandigarh','Chandigarh',  '160017'),
  ('Ramesh Yadav',    '9000000013', 'ramesh.yadav@example.com',   '41 Civil Lines',      'Lucknow',   'Uttar Pradesh','226001'),
  ('Ananya Iyer',     '9000000014', 'ananya.iyer@example.com',    '19 Jayanagar',        'Bengaluru', 'Karnataka',   '560011'),
  ('Karthik Goud',    '9000000015', 'karthik.goud@example.com',   '33 Jubilee Hills',    'Hyderabad', 'Telangana',   '500033')
ON CONFLICT (mobile_number) DO NOTHING;

-- ── 5) Sales history: last 180 days (feeds dashboard + ML forecasting) ──
-- Patterns baked in so forecasts look realistic:
--   * weekends busier (Sat/Sun x1.5, Fri x1.2)
--   * gradual upward trend (+40% over the period)
--   * festive spike 20 Oct - 10 Nov (x1.6)
--   * groceries/stationery sell more often than electronics
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM sales WHERE transaction_id LIKE 'SEED-TXN-%') THEN
    RAISE NOTICE 'Sales already seeded - skipping.';
    RETURN;
  END IF;

  INSERT INTO sales (product_id, quantity, total_amount, payment_method, sale_date, created_at, transaction_id)
  SELECT s.product_id,
         s.qty,
         ROUND(s.qty * s.selling_price * (1 - s.discount_percentage / 100.0), 2),
         s.pay,
         s.ts,
         s.ts,
         'SEED-TXN-' || to_char(s.ts, 'YYYYMMDD') || '-' ||
           LPAD(ROW_NUMBER() OVER (ORDER BY s.ts, s.product_id)::text, 5, '0')
  FROM (
    SELECT p.id AS product_id,
           p.selling_price,
           p.discount_percentage,
           CASE
             WHEN p.selling_price > 10000 THEN 1
             WHEN p.selling_price < 200   THEN 1 + FLOOR(random() * 5)::int
             ELSE                              1 + FLOOR(random() * 3)::int
           END AS qty,
           (ARRAY['cash','card','upi','upi','wallet'])[1 + FLOOR(random() * 5)::int] AS pay,
           LEAST(d.day + INTERVAL '9 hours' + random() * INTERVAL '12 hours', NOW()::timestamp) AS ts
    FROM generate_series((CURRENT_DATE - 180)::timestamp, CURRENT_DATE::timestamp, INTERVAL '1 day') AS d(day)
    CROSS JOIN products p
    WHERE p.sku LIKE 'SMP-%'
      AND p.is_active
      AND random() < LEAST(0.95,
            (CASE p.category
               WHEN 'Groceries'      THEN 0.35
               WHEN 'Stationery'     THEN 0.25
               WHEN 'Personal Care'  THEN 0.25
               WHEN 'Accessories'    THEN 0.18
               WHEN 'Home & Kitchen' THEN 0.15
               ELSE 0.08
             END)
            * (CASE WHEN EXTRACT(DOW FROM d.day) IN (0, 6) THEN 1.5
                    WHEN EXTRACT(DOW FROM d.day) = 5       THEN 1.2
                    ELSE 1.0 END)
            * (0.8 + 0.4 * ((d.day::date - (CURRENT_DATE - 180)) / 180.0))
            * (CASE WHEN d.day::date BETWEEN DATE '2026-10-20' AND DATE '2026-11-10'
                    THEN 1.6 ELSE 1.0 END)
          )
  ) s;
END $$;

-- ── 6) Invoices + invoice items + customer stats (60 invoices, last 90 days)
DO $$
DECLARE
  v_i        INT;
  v_inv_id   INT;
  v_cust_id  INT;
  v_items    INT;
  v_ts       TIMESTAMP;
  v_sub      NUMERIC;
  v_tax      NUMERIC;
BEGIN
  IF EXISTS (SELECT 1 FROM invoices WHERE invoice_number LIKE 'SEED-INV-%') THEN
    RAISE NOTICE 'Invoices already seeded - skipping.';
    RETURN;
  END IF;

  FOR v_i IN 1..60 LOOP
    -- ~20% walk-in customers (no customer record)
    SELECT id INTO v_cust_id
    FROM customers WHERE mobile_number LIKE '90000000%'
    ORDER BY random() LIMIT 1;
    IF random() < 0.2 THEN v_cust_id := NULL; END IF;

    v_ts := (CURRENT_DATE - FLOOR(random() * 90)::int)::timestamp
            + INTERVAL '9 hours' + random() * INTERVAL '12 hours';
    v_ts := LEAST(v_ts, NOW()::timestamp);
    v_items := 1 + FLOOR(random() * 4)::int;

    INSERT INTO invoices (invoice_number, customer_id, subtotal, tax, discount, discount_percentage,
                          total, payment_method, notes, created_at, updated_at)
    VALUES ('SEED-INV-' || LPAD(v_i::text, 4, '0'), v_cust_id, 0, 0, 0, 0, 0,
            (ARRAY['cash','card','upi','upi','wallet','cheque'])[1 + FLOOR(random() * 6)::int],
            'Sample invoice', v_ts, v_ts)
    RETURNING id INTO v_inv_id;

    INSERT INTO invoice_items (invoice_id, product_id, quantity, rate, gst_percentage, gst_amount, total, created_at)
    SELECT v_inv_id, x.id, x.q, x.selling_price, 18,
           ROUND(x.q * x.selling_price * 0.18, 2),
           ROUND(x.q * x.selling_price * 1.18, 2),
           v_ts
    FROM (
      SELECT id, selling_price,
             CASE WHEN selling_price > 10000 THEN 1 ELSE 1 + FLOOR(random() * 3)::int END AS q
      FROM products
      WHERE sku LIKE 'SMP-%' AND is_active AND stock_quantity > 0
      ORDER BY random()
      LIMIT v_items
    ) x;

    SELECT COALESCE(SUM(rate * quantity), 0), COALESCE(SUM(gst_amount), 0)
      INTO v_sub, v_tax
    FROM invoice_items WHERE invoice_id = v_inv_id;

    UPDATE invoices
       SET subtotal = v_sub, tax = v_tax, total = v_sub + v_tax
     WHERE id = v_inv_id;
  END LOOP;

  -- Customer purchase history / loyalty stats derived from the invoices above
  UPDATE customers c
     SET total_purchases      = a.cnt,
         total_amount_spent   = a.sum_total,
         loyalty_points       = FLOOR(a.sum_total * 0.01)::int,
         is_frequent_customer = (a.cnt >= 4),
         first_purchase_date  = a.first_dt,
         last_purchase_date   = a.last_dt
    FROM (
      SELECT customer_id,
             COUNT(*)        AS cnt,
             SUM(total)      AS sum_total,
             MIN(created_at) AS first_dt,
             MAX(created_at) AS last_dt
      FROM invoices
      WHERE invoice_number LIKE 'SEED-INV-%' AND customer_id IS NOT NULL
      GROUP BY customer_id
    ) a
   WHERE c.id = a.customer_id;

  INSERT INTO customer_interactions (customer_id, interaction_type, details, amount, created_at)
  SELECT customer_id, 'purchase', 'Invoice ' || invoice_number, total, created_at
  FROM invoices
  WHERE invoice_number LIKE 'SEED-INV-%' AND customer_id IS NOT NULL;

  INSERT INTO customer_interactions (customer_id, interaction_type, details, amount, created_at)
  SELECT id, 'feedback', 'Happy with the service and product quality.', NULL, NOW() - INTERVAL '5 days'
  FROM customers WHERE mobile_number IN ('9000000001', '9000000005', '9000000011');
END $$;

-- ── 7) Low-stock alerts + notifications ─────────────────────────────────
INSERT INTO low_stock_alerts (product_id, alert_status, current_stock, reorder_level)
SELECT p.id, 'pending', p.stock_quantity, p.reorder_level
FROM products p
WHERE p.sku LIKE 'SMP-%' AND p.is_active AND p.stock_quantity <= p.reorder_level
  AND NOT EXISTS (
    SELECT 1 FROM low_stock_alerts a
    WHERE a.product_id = p.id AND a.alert_status = 'pending'
  );

INSERT INTO notifications (message, role, is_read)
SELECT 'Low stock alert: ' || p.name || ' has only ' || p.stock_quantity ||
       ' unit(s) left (reorder level ' || p.reorder_level || ')',
       r.role, FALSE
FROM products p
CROSS JOIN (VALUES ('admin'), ('staff')) AS r(role)
WHERE p.sku LIKE 'SMP-%' AND p.is_active AND p.stock_quantity <= p.reorder_level
  AND NOT EXISTS (
    SELECT 1 FROM notifications n
    WHERE n.role = r.role AND n.message LIKE 'Low stock alert: ' || p.name || '%'
  );

COMMIT;

-- ── Summary ─────────────────────────────────────────────────────────────
SELECT 'products'     AS table_name, COUNT(*) AS rows FROM products WHERE sku LIKE 'SMP-%'
UNION ALL SELECT 'customers',      COUNT(*) FROM customers   WHERE mobile_number LIKE '90000000%'
UNION ALL SELECT 'sales',          COUNT(*) FROM sales       WHERE transaction_id LIKE 'SEED-TXN-%'
UNION ALL SELECT 'invoices',       COUNT(*) FROM invoices    WHERE invoice_number LIKE 'SEED-INV-%'
UNION ALL SELECT 'invoice_items',  COUNT(*) FROM invoice_items ii JOIN invoices i ON i.id = ii.invoice_id WHERE i.invoice_number LIKE 'SEED-INV-%'
UNION ALL SELECT 'low_stock_alerts', COUNT(*) FROM low_stock_alerts
UNION ALL SELECT 'notifications',  COUNT(*) FROM notifications;
