-- ============================================================================
-- Database Schema for Pocket Phone AP 2026
-- Version: 1.0
-- Description: Complete database schema for phone marketplace platform
-- ============================================================================

-- Drop existing tables (in reverse order of dependencies)
DROP TABLE IF EXISTS Wishlist;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Shipping_Details;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS Pricing;
DROP TABLE IF EXISTS Phone_Listings;
DROP TABLE IF EXISTS Camera_Specs;
DROP TABLE IF EXISTS Phone_Models;
DROP TABLE IF EXISTS Brands;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Cities;
DROP TABLE IF EXISTS States;

-- ============================================================================
-- LOCATION TABLES
-- ============================================================================

-- States Table
CREATE TABLE States (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state_name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    UNIQUE KEY uk_state_name (state_name, country),
    INDEX idx_state_name (state_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cities Table
CREATE TABLE Cities (
    city_id INT AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state_id INT NOT NULL,
    CONSTRAINT fk_cities_state FOREIGN KEY (state_id) 
        REFERENCES States(state_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    UNIQUE KEY uk_city_state (city_name, state_id),
    INDEX idx_city_name (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- USER MANAGEMENT TABLES
-- ============================================================================

-- Users Table
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15),
    street_address TEXT,
    city_id INT NOT NULL,
    pincode VARCHAR(10),
    registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_users_city FOREIGN KEY (city_id) 
        REFERENCES Cities(city_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_phone_number (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PHONE CATALOG TABLES
-- ============================================================================

-- Brands Table
CREATE TABLE Brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    brand_logo VARCHAR(255),
    description TEXT,
    country_of_origin VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_brand_name (brand_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Phone Models Table
CREATE TABLE Phone_Models (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_id INT NOT NULL,
    model_name VARCHAR(150) NOT NULL,
    release_year INT,
    display_size DECIMAL(4,2), -- in inches
    processor VARCHAR(100),
    os_version VARCHAR(50),
    battery_capacity INT, -- in mAh
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_models_brand FOREIGN KEY (brand_id) 
        REFERENCES Brands(brand_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    UNIQUE KEY uk_brand_model (brand_id, model_name),
    INDEX idx_model_name (model_name),
    INDEX idx_release_year (release_year),
    CHECK (release_year >= 2000 AND release_year <= YEAR(CURRENT_DATE) + 1),
    CHECK (display_size > 0),
    CHECK (battery_capacity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Camera Specifications Table
CREATE TABLE Camera_Specs (
    camera_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT NOT NULL,
    camera_type ENUM('front', 'rear_primary', 'rear_secondary', 'rear_tertiary', 'rear_quaternary') NOT NULL,
    megapixels INT NOT NULL,
    aperture DECIMAL(3,2), -- e.g., 1.8, 2.2
    features TEXT, -- JSON string for additional features
    CONSTRAINT fk_camera_model FOREIGN KEY (model_id) 
        REFERENCES Phone_Models(model_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    INDEX idx_model_camera (model_id, camera_type),
    CHECK (megapixels > 0),
    CHECK (aperture > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LISTING AND PRICING TABLES
-- ============================================================================

-- Phone Listings Table
CREATE TABLE Phone_Listings (
    listing_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT NOT NULL,
    seller_id INT NOT NULL,
    storage_capacity INT NOT NULL, -- in GB
    ram INT NOT NULL, -- in GB
    color VARCHAR(50) NOT NULL,
    condition ENUM('new', 'like_new', 'good', 'fair', 'poor') NOT NULL,
    listing_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('available', 'sold', 'reserved', 'removed') NOT NULL DEFAULT 'available',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_date DATETIME,
    listing_type ENUM('regular', 'popular', 'todays_drop', 'good_deal', 'featured') DEFAULT 'regular',
    description TEXT,
    image_urls TEXT, -- JSON array of image URLs
    views_count INT DEFAULT 0,
    CONSTRAINT fk_listing_model FOREIGN KEY (model_id) 
        REFERENCES Phone_Models(model_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_listing_seller FOREIGN KEY (seller_id) 
        REFERENCES Users(user_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    INDEX idx_status (status),
    INDEX idx_listing_type (listing_type),
    INDEX idx_seller (seller_id),
    INDEX idx_listing_date (listing_date),
    INDEX idx_verified (is_verified),
    CHECK (storage_capacity > 0),
    CHECK (ram > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pricing Table
CREATE TABLE Pricing (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id INT NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    final_price DECIMAL(10,2) NOT NULL,
    price_updated_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_pricing_listing FOREIGN KEY (listing_id) 
        REFERENCES Phone_Listings(listing_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    INDEX idx_listing_current (listing_id, is_current),
    INDEX idx_final_price (final_price),
    CHECK (base_price >= 0),
    CHECK (discount_amount >= 0),
    CHECK (final_price >= 0),
    CHECK (final_price <= base_price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRANSACTION TABLES
-- ============================================================================

-- Transactions Table
CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id INT NOT NULL,
    buyer_id INT NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('credit_card', 'debit_card', 'upi', 'net_banking', 'wallet', 'cod') NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    order_status ENUM('processing', 'confirmed', 'shipped', 'delivered', 'cancelled', 'returned') NOT NULL DEFAULT 'processing',
    payment_reference VARCHAR(100),
    notes TEXT,
    CONSTRAINT fk_transaction_listing FOREIGN KEY (listing_id) 
        REFERENCES Phone_Listings(listing_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_transaction_buyer FOREIGN KEY (buyer_id) 
        REFERENCES Users(user_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    INDEX idx_buyer (buyer_id),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_payment_status (payment_status),
    INDEX idx_order_status (order_status),
    INDEX idx_payment_reference (payment_reference),
    CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Shipping Details Table
CREATE TABLE Shipping_Details (
    shipping_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL UNIQUE,
    street_address TEXT NOT NULL,
    city_id INT NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    shipping_status ENUM('pending', 'packed', 'shipped', 'in_transit', 'out_for_delivery', 'delivered', 'failed') DEFAULT 'pending',
    tracking_number VARCHAR(100),
    courier_service VARCHAR(100),
    shipped_date DATETIME,
    estimated_delivery_date DATE,
    delivered_date DATETIME,
    CONSTRAINT fk_shipping_transaction FOREIGN KEY (transaction_id) 
        REFERENCES Transactions(transaction_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_shipping_city FOREIGN KEY (city_id) 
        REFERENCES Cities(city_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    INDEX idx_tracking_number (tracking_number),
    INDEX idx_shipping_status (shipping_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- USER INTERACTION TABLES
-- ============================================================================

-- Reviews Table
CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reviewer_id INT NOT NULL,
    listing_id INT NOT NULL,
    rating INT NOT NULL,
    review_text TEXT,
    review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_count INT DEFAULT 0,
    CONSTRAINT fk_review_user FOREIGN KEY (reviewer_id) 
        REFERENCES Users(user_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_review_listing FOREIGN KEY (listing_id) 
        REFERENCES Phone_Listings(listing_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    INDEX idx_listing_reviews (listing_id),
    INDEX idx_reviewer (reviewer_id),
    INDEX idx_rating (rating),
    INDEX idx_review_date (review_date),
    CHECK (rating >= 1 AND rating <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wishlist Table
CREATE TABLE Wishlist (
    wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    listing_id INT NOT NULL,
    added_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    CONSTRAINT fk_wishlist_user FOREIGN KEY (user_id) 
        REFERENCES Users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_wishlist_listing FOREIGN KEY (listing_id) 
        REFERENCES Phone_Listings(listing_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    UNIQUE KEY uk_user_listing (user_id, listing_id),
    INDEX idx_user_wishlist (user_id),
    INDEX idx_listing_wishlist (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Update listing status when transaction is completed
DELIMITER //
CREATE TRIGGER trg_update_listing_status_after_transaction
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' AND OLD.payment_status != 'completed' THEN
        UPDATE Phone_Listings 
        SET status = 'sold' 
        WHERE listing_id = NEW.listing_id;
    END IF;
END//
DELIMITER ;

-- Trigger: Ensure only one current price per listing
DELIMITER //
CREATE TRIGGER trg_set_old_prices_non_current
BEFORE INSERT ON Pricing
FOR EACH ROW
BEGIN
    IF NEW.is_current = TRUE THEN
        UPDATE Pricing 
        SET is_current = FALSE 
        WHERE listing_id = NEW.listing_id;
    END IF;
END//
DELIMITER ;

-- Trigger: Auto-calculate final price if not provided
DELIMITER //
CREATE TRIGGER trg_calculate_final_price
BEFORE INSERT ON Pricing
FOR EACH ROW
BEGIN
    IF NEW.final_price IS NULL OR NEW.final_price = 0 THEN
        SET NEW.final_price = NEW.base_price - NEW.discount_amount;
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Active Listings with Full Details
CREATE OR REPLACE VIEW vw_active_listings AS
SELECT 
    pl.listing_id,
    pl.listing_date,
    pl.status,
    pl.listing_type,
    pl.is_verified,
    pl.storage_capacity,
    pl.ram,
    pl.color,
    pl.condition,
    pl.description,
    pl.views_count,
    pm.model_id,
    pm.model_name,
    pm.release_year,
    pm.display_size,
    pm.processor,
    pm.os_version,
    pm.battery_capacity,
    b.brand_id,
    b.brand_name,
    b.brand_logo,
    p.final_price,
    p.base_price,
    p.discount_amount,
    u.user_id AS seller_id,
    u.username AS seller_name,
    u.email AS seller_email,
    c.city_name AS seller_city,
    s.state_name AS seller_state
FROM Phone_Listings pl
JOIN Phone_Models pm ON pl.model_id = pm.model_id
JOIN Brands b ON pm.brand_id = b.brand_id
LEFT JOIN Pricing p ON pl.listing_id = p.listing_id AND p.is_current = TRUE
JOIN Users u ON pl.seller_id = u.user_id
JOIN Cities c ON u.city_id = c.city_id
JOIN States s ON c.state_id = s.state_id
WHERE pl.status = 'available';

-- View: User Transaction History
CREATE OR REPLACE VIEW vw_user_transactions AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.payment_method,
    t.payment_status,
    t.order_status,
    u.user_id AS buyer_id,
    u.username AS buyer_name,
    u.email AS buyer_email,
    pl.listing_id,
    pm.model_name,
    b.brand_name,
    pl.storage_capacity,
    pl.ram,
    pl.color,
    seller.username AS seller_name,
    sd.shipping_status,
    sd.tracking_number,
    sd.delivered_date
FROM Transactions t
JOIN Users u ON t.buyer_id = u.user_id
JOIN Phone_Listings pl ON t.listing_id = pl.listing_id
JOIN Phone_Models pm ON pl.model_id = pm.model_id
JOIN Brands b ON pm.brand_id = b.brand_id
JOIN Users seller ON pl.seller_id = seller.user_id
LEFT JOIN Shipping_Details sd ON t.transaction_id = sd.transaction_id;

-- View: Popular Phone Models (by listing count)
CREATE OR REPLACE VIEW vw_popular_models AS
SELECT 
    pm.model_id,
    pm.model_name,
    b.brand_name,
    COUNT(pl.listing_id) AS listing_count,
    AVG(p.final_price) AS avg_price,
    MIN(p.final_price) AS min_price,
    MAX(p.final_price) AS max_price,
    AVG(r.rating) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS review_count
FROM Phone_Models pm
JOIN Brands b ON pm.brand_id = b.brand_id
JOIN Phone_Listings pl ON pm.model_id = pl.model_id
LEFT JOIN Pricing p ON pl.listing_id = p.listing_id AND p.is_current = TRUE
LEFT JOIN Reviews r ON pl.listing_id = r.listing_id
WHERE pl.status IN ('available', 'sold')
GROUP BY pm.model_id, pm.model_name, b.brand_name
ORDER BY listing_count DESC;

-- View: Seller Performance Metrics
CREATE OR REPLACE VIEW vw_seller_metrics AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    COUNT(DISTINCT pl.listing_id) AS total_listings,
    COUNT(DISTINCT CASE WHEN pl.status = 'sold' THEN pl.listing_id END) AS sold_count,
    COUNT(DISTINCT CASE WHEN pl.status = 'available' THEN pl.listing_id END) AS active_count,
    COALESCE(SUM(t.amount), 0) AS total_revenue,
    COALESCE(AVG(r.rating), 0) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS review_count
FROM Users u
LEFT JOIN Phone_Listings pl ON u.user_id = pl.seller_id
LEFT JOIN Transactions t ON pl.listing_id = t.listing_id AND t.payment_status = 'completed'
LEFT JOIN Reviews r ON pl.listing_id = r.listing_id
GROUP BY u.user_id, u.username, u.email;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Procedure: Create New Listing with Price
DELIMITER //
CREATE PROCEDURE sp_create_listing(
    IN p_model_id INT,
    IN p_seller_id INT,
    IN p_storage_capacity INT,
    IN p_ram INT,
    IN p_color VARCHAR(50),
    IN p_condition VARCHAR(20),
    IN p_base_price DECIMAL(10,2),
    IN p_discount_amount DECIMAL(10,2),
    IN p_description TEXT,
    IN p_listing_type VARCHAR(20),
    OUT p_listing_id INT
)
BEGIN
    DECLARE v_final_price DECIMAL(10,2);
    
    -- Calculate final price
    SET v_final_price = p_base_price - COALESCE(p_discount_amount, 0);
    
    -- Insert listing
    INSERT INTO Phone_Listings (
        model_id, seller_id, storage_capacity, ram, color, 
        condition, listing_type, description
    ) VALUES (
        p_model_id, p_seller_id, p_storage_capacity, p_ram, p_color,
        p_condition, p_listing_type, p_description
    );
    
    SET p_listing_id = LAST_INSERT_ID();
    
    -- Insert pricing
    INSERT INTO Pricing (
        listing_id, base_price, discount_amount, final_price, is_current
    ) VALUES (
        p_listing_id, p_base_price, COALESCE(p_discount_amount, 0), v_final_price, TRUE
    );
END//
DELIMITER ;

-- Procedure: Process Transaction
DELIMITER //
CREATE PROCEDURE sp_process_transaction(
    IN p_listing_id INT,
    IN p_buyer_id INT,
    IN p_payment_method VARCHAR(50),
    IN p_shipping_address TEXT,
    IN p_city_id INT,
    IN p_pincode VARCHAR(10),
    OUT p_transaction_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_listing_status VARCHAR(20);
    DECLARE v_final_price DECIMAL(10,2);
    DECLARE v_seller_id INT;
    
    -- Check if listing is available
    SELECT status, seller_id INTO v_listing_status, v_seller_id
    FROM Phone_Listings
    WHERE listing_id = p_listing_id;
    
    IF v_listing_status != 'available' THEN
        SET p_message = 'Listing is not available';
        SET p_transaction_id = NULL;
    ELSEIF v_seller_id = p_buyer_id THEN
        SET p_message = 'Cannot buy your own listing';
        SET p_transaction_id = NULL;
    ELSE
        -- Get current price
        SELECT final_price INTO v_final_price
        FROM Pricing
        WHERE listing_id = p_listing_id AND is_current = TRUE;
        
        -- Create transaction
        INSERT INTO Transactions (
            listing_id, buyer_id, amount, payment_method
        ) VALUES (
            p_listing_id, p_buyer_id, v_final_price, p_payment_method
        );
        
        SET p_transaction_id = LAST_INSERT_ID();
        
        -- Create shipping details
        INSERT INTO Shipping_Details (
            transaction_id, street_address, city_id, pincode
        ) VALUES (
            p_transaction_id, p_shipping_address, p_city_id, p_pincode
        );
        
        -- Reserve listing
        UPDATE Phone_Listings
        SET status = 'reserved'
        WHERE listing_id = p_listing_id;
        
        SET p_message = 'Transaction created successfully';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- INDEXES FOR OPTIMIZATION
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX idx_listing_model_status ON Phone_Listings(model_id, status);
CREATE INDEX idx_listing_seller_status ON Phone_Listings(seller_id, status);
CREATE INDEX idx_transaction_buyer_date ON Transactions(buyer_id, transaction_date);
CREATE INDEX idx_pricing_listing_current ON Pricing(listing_id, is_current);

-- Full-text search indexes
ALTER TABLE Phone_Models ADD FULLTEXT idx_ft_model_search(model_name);
ALTER TABLE Phone_Listings ADD FULLTEXT idx_ft_listing_desc(description);

-- ============================================================================
-- SAMPLE DATA INSERTION (Optional)
-- ============================================================================

-- Insert States
INSERT INTO States (state_name, country) VALUES
('Maharashtra', 'India'),
('Karnataka', 'India'),
('Tamil Nadu', 'India'),
('Delhi', 'India'),
('West Bengal', 'India');

-- Insert Cities
INSERT INTO Cities (city_name, state_id) VALUES
('Mumbai', 1),
('Pune', 1),
('Bangalore', 2),
('Chennai', 3),
('New Delhi', 4),
('Kolkata', 5);

-- Insert Brands
INSERT INTO Brands (brand_name, brand_logo, country_of_origin) VALUES
('Apple', '/images/brands/apple.png', 'USA'),
('Samsung', '/images/brands/samsung.png', 'South Korea'),
('OnePlus', '/images/brands/oneplus.png', 'China'),
('Xiaomi', '/images/brands/xiaomi.png', 'China'),
('Google', '/images/brands/google.png', 'USA'),
('Realme', '/images/brands/realme.png', 'China'),
('OPPO', '/images/brands/oppo.png', 'China'),
('Vivo', '/images/brands/vivo.png', 'China');

-- ============================================================================
-- GRANTS (Adjust based on your user setup)
-- ============================================================================

-- Example: Grant permissions to application user
-- GRANT SELECT, INSERT, UPDATE, DELETE ON pocket_phone.* TO 'app_user'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
