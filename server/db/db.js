const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const dbPort = process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432;

const isSslEnabled = () => {
  if (process.env.DB_SSL === "true" || process.env.DB_SSL === "require") return true;
  if (process.env.DB_SSL === "false" || process.env.DB_SSL === "disable") return false;
  if (process.env.DATABASE_URL && process.env.DATABASE_URL.includes("sslmode=require")) return true;
  return process.env.NODE_ENV === "production";
};

const poolConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: isSslEnabled() ? { rejectUnauthorized: false } : false,
    }
  : {
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      host: process.env.DB_HOST,
      port: Number.isNaN(dbPort) ? 5432 : dbPort,
      database: process.env.DB_NAME,
      ssl: isSslEnabled() ? { rejectUnauthorized: false } : false,
    };

const pool = new Pool(poolConfig);

const ensureDatabaseSchema = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff', 'customer')),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS shop_details (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      address VARCHAR(500) NOT NULL,
      city VARCHAR(100) NOT NULL,
      state VARCHAR(100) NOT NULL,
      postal_code VARCHAR(20),
      contact_number VARCHAR(20) NOT NULL,
      email VARCHAR(255),
      gst_number VARCHAR(50) NOT NULL UNIQUE,
      pan_number VARCHAR(50),
      business_type VARCHAR(100),
      logo_url VARCHAR(500),
      website VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      sku VARCHAR(100) UNIQUE,
      category VARCHAR(100),
      brand VARCHAR(100),
      cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0),
      selling_price DECIMAL(10, 2) NOT NULL CHECK (selling_price >= 0),
      discount_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
      stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
      reorder_level INT DEFAULT 10 CHECK (reorder_level >= 0),
      expiry_date DATE,
      image_url VARCHAR(500),
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sales (
      id SERIAL PRIMARY KEY,
      product_id INT NOT NULL,
      quantity INT NOT NULL CHECK (quantity > 0),
      total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
      payment_method VARCHAR(50) DEFAULT 'cash',
      transaction_id VARCHAR(80),
      sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS customers (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      mobile_number VARCHAR(20) NOT NULL UNIQUE,
      email VARCHAR(255),
      address VARCHAR(500),
      city VARCHAR(100),
      state VARCHAR(100),
      postal_code VARCHAR(20),
      total_purchases INT DEFAULT 0,
      total_amount_spent DECIMAL(12, 2) DEFAULT 0,
      loyalty_points INT DEFAULT 0,
      is_frequent_customer BOOLEAN DEFAULT FALSE,
      first_purchase_date TIMESTAMP,
      last_purchase_date TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS customer_interactions (
      id SERIAL PRIMARY KEY,
      customer_id INT NOT NULL,
      interaction_type VARCHAR(50) NOT NULL,
      details TEXT,
      amount DECIMAL(12, 2),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      message TEXT NOT NULL,
      role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'staff', 'customer')),
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
      id SERIAL PRIMARY KEY,
      user_id INT REFERENCES users(id) ON DELETE SET NULL,
      action VARCHAR(100) NOT NULL,
      table_name VARCHAR(100) NOT NULL,
      record_id INT,
      old_values JSONB,
      new_values JSONB,
      ip_address INET,
      user_agent TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS loyalty_programs (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      purchase_threshold DECIMAL(12, 2),
      discount_percentage DECIMAL(5, 2) NOT NULL,
      loyalty_points_per_rupee DECIMAL(5, 2) DEFAULT 0.01,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS invoices (
      id SERIAL PRIMARY KEY,
      invoice_number VARCHAR(50) NOT NULL UNIQUE,
      customer_id INT,
      subtotal DECIMAL(12, 2) NOT NULL,
      tax DECIMAL(12, 2) NOT NULL,
      discount DECIMAL(12, 2) DEFAULT 0,
      discount_percentage DECIMAL(5, 2) DEFAULT 0,
      total DECIMAL(12, 2) NOT NULL,
      payment_method VARCHAR(50) DEFAULT 'cash',
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS invoice_items (
      id SERIAL PRIMARY KEY,
      invoice_id INT NOT NULL,
      product_id INT NOT NULL,
      quantity INT NOT NULL CHECK (quantity > 0),
      rate DECIMAL(12, 2) NOT NULL,
      gst_percentage DECIMAL(5, 2) DEFAULT 18,
      gst_amount DECIMAL(12, 2),
      total DECIMAL(12, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
    );

    CREATE TABLE IF NOT EXISTS low_stock_alerts (
      id SERIAL PRIMARY KEY,
      product_id INT NOT NULL,
      alert_status VARCHAR(20) DEFAULT 'pending',
      current_stock INT,
      reorder_level INT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      acknowledged_at TIMESTAMP,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
    );

    ALTER TABLE sales ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(80);
  `);
};

const ensureShopDetailsTable = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS shop_details (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      address VARCHAR(500) NOT NULL,
      city VARCHAR(100) NOT NULL,
      state VARCHAR(100) NOT NULL,
      postal_code VARCHAR(20),
      contact_number VARCHAR(20) NOT NULL,
      email VARCHAR(255),
      gst_number VARCHAR(50) NOT NULL UNIQUE,
      pan_number VARCHAR(50),
      business_type VARCHAR(100),
      logo_url VARCHAR(500),
      website VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
};

const ensureSalesTransactionColumn = async () => {
  await pool.query(`
    ALTER TABLE sales
    ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(80)
  `);
};

const seedSampleData = async () => {
  const seedSqlPath = path.join(__dirname, "seed-sample-data.sql");
  if (fs.existsSync(seedSqlPath)) {
    const sql = fs.readFileSync(seedSqlPath, "utf8");
    await pool.query(sql);

    const prods = await pool.query("SELECT COUNT(*) FROM products WHERE sku LIKE 'SMP-%'");
    const custs = await pool.query("SELECT COUNT(*) FROM customers WHERE mobile_number LIKE '90000000%'");
    const sales = await pool.query("SELECT COUNT(*) FROM sales WHERE transaction_id LIKE 'SEED-TXN-%'");
    const invs = await pool.query("SELECT COUNT(*) FROM invoices WHERE invoice_number LIKE 'SEED-INV-%'");

    return {
      products: parseInt(prods.rows[0].count, 10),
      customers: parseInt(custs.rows[0].count, 10),
      sales: parseInt(sales.rows[0].count, 10),
      invoices: parseInt(invs.rows[0].count, 10),
    };
  }
  return null;
};

pool.ensureDatabaseSchema = ensureDatabaseSchema;
pool.ensureShopDetailsTable = ensureShopDetailsTable;
pool.ensureSalesTransactionColumn = ensureSalesTransactionColumn;
pool.seedSampleData = seedSampleData;

pool.connect()
  .then(() => console.log("PostgreSQL Connected Successfully ✅"))
  .catch(err => console.error("PostgreSQL Connection Error ❌", err.message || err));

module.exports = pool;
