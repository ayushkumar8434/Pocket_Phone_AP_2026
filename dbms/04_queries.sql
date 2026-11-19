-- ============================================================================
-- SQL QUERIES - Pocket Phone AP 2026
-- Version: 1.0
-- Description: Comprehensive SQL queries for phone marketplace operations
-- Database: MySQL 8.0+
-- Author: Pocket Phone AP 2026 Team
-- Date: 2024-11-17
-- ============================================================================
-- Bind values marked with ? in application code. Data modification examples
-- use safe sample values and should run inside an appropriate transaction.

-- ============================================================================
-- SECTION 1: BASIC RETRIEVAL QUERIES
-- ============================================================================

-- Query 1: List users with their city, state, and country.
SELECT u.user_id, u.username, u.email, u.phone_number,
       c.city_name, s.state_name, s.country
FROM Users AS u
JOIN Cities AS c ON c.city_id = u.city_id
JOIN States AS s ON s.state_id = c.state_id
ORDER BY u.registration_date DESC;

-- Query 2: List all active phone brands.
SELECT brand_id, brand_name, country_of_origin, description
FROM Brands
WHERE is_active = TRUE
ORDER BY brand_name;

-- Query 3: List phone models with brand information.
SELECT pm.model_id, b.brand_name, pm.model_name, pm.release_year,
       pm.display_size, pm.processor, pm.os_version, pm.battery_capacity
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY pm.release_year DESC, b.brand_name, pm.model_name;

-- Query 4: List available listings with current price and seller location.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, pl.condition, p.final_price, p.discount_amount,
       u.username AS seller_name, c.city_name, pl.is_verified, pl.listing_type
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS u ON u.user_id = pl.seller_id
JOIN Cities AS c ON c.city_id = u.city_id
WHERE pl.status = 'available'
ORDER BY pl.listing_date DESC;

-- Query 5: Get camera specifications for one model.
SELECT camera_type, megapixels, aperture, features
FROM Camera_Specs
WHERE model_id = ?
ORDER BY FIELD(camera_type, 'rear_primary', 'rear_secondary',
               'rear_tertiary', 'rear_quaternary', 'front');

-- Query 6: Get the 50 most recent reviews with listing details.
SELECT r.review_id, b.brand_name, pm.model_name, u.username AS reviewer_name,
       r.rating, r.review_text, r.review_date
FROM Reviews AS r
JOIN Users AS u ON u.user_id = r.reviewer_id
JOIN Phone_Listings AS pl ON pl.listing_id = r.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY r.review_date DESC
LIMIT 50;

-- ============================================================================
-- SECTION 2: FILTERING AND SEARCH QUERIES
-- ============================================================================

-- Query 7: Search available phones by brand.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, pl.condition, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE b.brand_name = ?
  AND pl.status = 'available'
ORDER BY p.final_price;

-- Query 8: Find available phones within an inclusive price range.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE p.final_price BETWEEN 15000 AND 50000
  AND pl.status = 'available'
ORDER BY p.final_price;

-- Query 9: Search available listings by partial model name.
SELECT pm.model_name, b.brand_name, pl.storage_capacity, pl.ram, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pm.model_name LIKE '%iPhone%'
  AND pl.status = 'available'
ORDER BY pm.release_year DESC, p.final_price;

-- Query 10: Find verified available listings.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.condition,
       p.final_price, pl.verification_date
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.is_verified = TRUE AND pl.status = 'available'
ORDER BY pl.verification_date DESC;

-- Query 11: Find phones in selected conditions.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.condition, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.condition IN ('new', 'like_new')
  AND pl.status = 'available'
ORDER BY p.final_price;

-- Query 12: Search by brand, storage, and condition.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.condition, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE b.brand_name IN ('Apple', 'Samsung')
  AND pl.storage_capacity >= 128
  AND pl.condition IN ('new', 'like_new')
  AND pl.status = 'available'
ORDER BY p.final_price;

-- ============================================================================
-- SECTION 3: AGGREGATE FUNCTIONS
-- ============================================================================

-- Query 13: Count total, available, and sold listings by brand.
SELECT b.brand_name, COUNT(pl.listing_id) AS total_listings,
       COALESCE(SUM(pl.status = 'available'), 0) AS available_count,
       COALESCE(SUM(pl.status = 'sold'), 0) AS sold_count
FROM Brands AS b
LEFT JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
LEFT JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
GROUP BY b.brand_id, b.brand_name
ORDER BY total_listings DESC;

-- Query 14: Calculate available-price statistics by brand.
SELECT b.brand_name, COUNT(p.price_id) AS listing_count,
       AVG(p.final_price) AS avg_price, MIN(p.final_price) AS min_price,
       MAX(p.final_price) AS max_price
FROM Brands AS b
JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id AND pl.status = 'available'
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
GROUP BY b.brand_id, b.brand_name
HAVING COUNT(p.price_id) > 0
ORDER BY avg_price DESC;

-- Query 15: Total completed sales and revenue per seller.
SELECT u.user_id AS seller_id, u.username, COUNT(t.transaction_id) AS total_sales,
       COALESCE(SUM(t.amount), 0) AS total_revenue, AVG(t.amount) AS avg_amount
FROM Users AS u
JOIN Phone_Listings AS pl ON pl.seller_id = u.user_id
JOIN Transactions AS t ON t.listing_id = pl.listing_id
WHERE t.payment_status = 'completed'
GROUP BY u.user_id, u.username
ORDER BY total_revenue DESC;

-- Query 16: Average rating for each reviewed listing.
SELECT pl.listing_id, b.brand_name, pm.model_name,
       COUNT(r.review_id) AS review_count, AVG(r.rating) AS avg_rating,
       MIN(r.rating) AS min_rating, MAX(r.rating) AS max_rating
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Reviews AS r ON r.listing_id = pl.listing_id
GROUP BY pl.listing_id, b.brand_name, pm.model_name
HAVING COUNT(r.review_id) > 0
ORDER BY avg_rating DESC, review_count DESC;

-- Query 17: Count users by city and state.
SELECT s.state_name, c.city_name, COUNT(u.user_id) AS user_count
FROM States AS s
JOIN Cities AS c ON c.state_id = s.state_id
LEFT JOIN Users AS u ON u.city_id = c.city_id
GROUP BY s.state_id, s.state_name, c.city_id, c.city_name
ORDER BY user_count DESC;

-- Query 18: Monthly transaction volume and payment outcomes.
SELECT DATE_FORMAT(transaction_date, '%Y') AS transaction_year,
       DATE_FORMAT(transaction_date, '%m') AS transaction_month,
       COUNT(*) AS total_transactions,
       SUM(amount) AS total_revenue, AVG(amount) AS avg_transaction_value,
       SUM(payment_status = 'completed') AS completed_count,
       SUM(payment_status = 'failed') AS failed_count
FROM Transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y'), DATE_FORMAT(transaction_date, '%m')
ORDER BY transaction_year DESC, transaction_month DESC;

-- ============================================================================
-- SECTION 4: JOIN QUERIES
-- ============================================================================

-- Query 19: Show transactions with complete buyer, seller, and phone details.
SELECT t.transaction_id, t.transaction_date, t.amount,
       buyer.username AS buyer_name, buyer.email AS buyer_email,
       seller.username AS seller_name, seller.email AS seller_email,
       b.brand_name, pm.model_name, t.payment_status, t.order_status
FROM Transactions AS t
JOIN Users AS buyer ON buyer.user_id = t.buyer_id
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY t.transaction_date DESC;

-- Query 20: Include phone models that have no listings.
SELECT pm.model_id, b.brand_name, pm.model_name,
       COUNT(pl.listing_id) AS listing_count,
       COALESCE(SUM(pl.status = 'available'), 0) AS available_count
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
GROUP BY pm.model_id, b.brand_name, pm.model_name
ORDER BY listing_count DESC;

-- Query 21: Include users with no wishlist entries.
SELECT u.user_id, u.username, u.email, COUNT(w.wishlist_id) AS wishlist_count
FROM Users AS u
LEFT JOIN Wishlist AS w ON w.user_id = u.user_id
GROUP BY u.user_id, u.username, u.email
ORDER BY wishlist_count DESC;

-- Query 22: Show transaction, item, and shipping destination details.
SELECT t.transaction_id, t.transaction_date, buyer.username AS buyer_name,
       b.brand_name, pm.model_name, pl.storage_capacity, pl.color, t.amount,
       t.payment_status, t.order_status, sd.shipping_status, sd.tracking_number,
       sd.street_address AS shipping_address, c.city_name AS shipping_city,
       s.state_name AS shipping_state
FROM Transactions AS t
JOIN Users AS buyer ON buyer.user_id = t.buyer_id
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Shipping_Details AS sd ON sd.transaction_id = t.transaction_id
LEFT JOIN Cities AS c ON c.city_id = sd.city_id
LEFT JOIN States AS s ON s.state_id = c.state_id
ORDER BY t.transaction_date DESC;

-- Query 23: Find pairs of users who live in the same city.
SELECT u1.user_id AS user1_id, u1.username AS user1_name,
       u2.user_id AS user2_id, u2.username AS user2_name,
       c.city_name, s.state_name
FROM Users AS u1
JOIN Users AS u2 ON u2.city_id = u1.city_id AND u1.user_id < u2.user_id
JOIN Cities AS c ON c.city_id = u1.city_id
JOIN States AS s ON s.state_id = c.state_id
ORDER BY c.city_name, u1.username;

-- ============================================================================
-- SECTION 5: SUBQUERIES
-- ============================================================================

-- Query 24: Find available phones priced above the current-price average.
SELECT pl.listing_id, b.brand_name, pm.model_name, p.final_price,
       (SELECT AVG(final_price) FROM Pricing WHERE is_current = TRUE)
           AS average_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.status = 'available'
  AND p.final_price > (SELECT AVG(final_price)
                       FROM Pricing WHERE is_current = TRUE)
ORDER BY p.final_price DESC;

-- Query 25: Find sellers with more than five listings.
SELECT u.user_id, u.username, u.email,
       (SELECT COUNT(*) FROM Phone_Listings AS x
        WHERE x.seller_id = u.user_id) AS listing_count
FROM Users AS u
WHERE u.user_id IN (
    SELECT seller_id FROM Phone_Listings
    GROUP BY seller_id HAVING COUNT(*) > 5
)
ORDER BY listing_count DESC;

-- Query 26: Find the most expensive available listing for every brand.
SELECT b.brand_name, pm.model_name, pl.listing_id, p.final_price
FROM Brands AS b
JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id AND pl.status = 'available'
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE p.final_price = (
    SELECT MAX(p2.final_price)
    FROM Phone_Models AS pm2
    JOIN Phone_Listings AS pl2
      ON pl2.model_id = pm2.model_id AND pl2.status = 'available'
    JOIN Pricing AS p2
      ON p2.listing_id = pl2.listing_id AND p2.is_current = TRUE
    WHERE pm2.brand_id = b.brand_id
)
ORDER BY p.final_price DESC;

-- Query 27: Find users who have both bought and sold phones.
SELECT u.user_id, u.username, u.email,
       (SELECT COUNT(*) FROM Phone_Listings AS pl
        WHERE pl.seller_id = u.user_id) AS items_sold,
       (SELECT COUNT(*) FROM Transactions AS t
        WHERE t.buyer_id = u.user_id) AS items_bought
FROM Users AS u
WHERE EXISTS (SELECT 1 FROM Phone_Listings AS pl WHERE pl.seller_id = u.user_id)
  AND EXISTS (SELECT 1 FROM Transactions AS t WHERE t.buyer_id = u.user_id)
ORDER BY items_sold DESC;

-- Query 28: Find sold listings with no reviews.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.listing_date
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
WHERE pl.status = 'sold'
  AND NOT EXISTS (SELECT 1 FROM Reviews AS r WHERE r.listing_id = pl.listing_id)
ORDER BY pl.listing_date DESC;

-- ============================================================================
-- SECTION 6: ADVANCED QUERIES
-- ============================================================================

-- Query 29: Top ten models by listing count, with prices and sold counts.
SELECT b.brand_name, pm.model_name, COUNT(pl.listing_id) AS listing_count,
       AVG(p.final_price) AS avg_price,
       SUM(pl.status = 'sold') AS sold_count
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
GROUP BY pm.model_id, b.brand_name, pm.model_name
HAVING COUNT(pl.listing_id) >= 3
ORDER BY listing_count DESC, sold_count DESC
LIMIT 10;

-- Query 30: Best-rated listings with at least three reviews.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.condition, COUNT(r.review_id) AS review_count, AVG(r.rating) AS avg_rating,
       p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Reviews AS r ON r.listing_id = pl.listing_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
GROUP BY pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
         pl.condition, p.final_price
HAVING COUNT(r.review_id) >= 3 AND AVG(r.rating) >= 4.0
ORDER BY avg_rating DESC, review_count DESC;

-- Query 31: Seller performance across listings, sales, revenue, and reviews.
WITH listing_metrics AS (
    SELECT seller_id, COUNT(*) AS total_listings
    FROM Phone_Listings
    GROUP BY seller_id
),
sales_metrics AS (
    SELECT pl.seller_id, COUNT(t.transaction_id) AS total_sales,
           SUM(t.amount) AS total_revenue
    FROM Phone_Listings AS pl
    JOIN Transactions AS t ON t.listing_id = pl.listing_id
    WHERE t.payment_status = 'completed'
    GROUP BY pl.seller_id
),
review_metrics AS (
    SELECT pl.seller_id, COUNT(r.review_id) AS total_reviews,
           AVG(r.rating) AS avg_rating
    FROM Phone_Listings AS pl
    JOIN Reviews AS r ON r.listing_id = pl.listing_id
    GROUP BY pl.seller_id
)
SELECT u.user_id, u.username, lm.total_listings,
       COALESCE(sm.total_sales, 0) AS total_sales,
       COALESCE(sm.total_revenue, 0) AS total_revenue,
       COALESCE(rm.total_reviews, 0) AS total_reviews,
       COALESCE(rm.avg_rating, 0) AS avg_rating
FROM Users AS u
JOIN listing_metrics AS lm ON lm.seller_id = u.user_id
LEFT JOIN sales_metrics AS sm ON sm.seller_id = u.user_id
LEFT JOIN review_metrics AS rm ON rm.seller_id = u.user_id
ORDER BY total_revenue DESC, avg_rating DESC
LIMIT 20;

-- Query 32: Price distribution by storage capacity.
SELECT pl.storage_capacity, COUNT(*) AS listing_count, AVG(p.final_price) AS avg_price,
       MIN(p.final_price) AS min_price, MAX(p.final_price) AS max_price,
       STDDEV(p.final_price) AS price_stddev
FROM Phone_Listings AS pl
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.status = 'available'
GROUP BY pl.storage_capacity
ORDER BY pl.storage_capacity;

-- Query 33: Completed daily sales for the last 30 days.
SELECT DATE(t.transaction_date) AS sale_date, COUNT(*) AS total_transactions,
       SUM(t.amount) AS total_revenue, AVG(t.amount) AS avg_order_value
FROM Transactions AS t
WHERE t.transaction_date >= CURRENT_DATE - INTERVAL 30 DAY
  AND t.payment_status = 'completed'
GROUP BY DATE(t.transaction_date)
ORDER BY sale_date DESC;

-- ============================================================================
-- SECTION 7: DATA MODIFICATION QUERIES
-- ============================================================================

-- Query 34: Insert a new user. Store an application-generated password hash.
INSERT INTO Users (username, email, password, phone_number, street_address,
                   city_id, pincode)
VALUES ('new_user', 'new.user@example.com', '<PASSWORD_HASH>',
        '+919876543210', '12 Example Street', ?, '400001');

-- Query 35: Insert a new phone listing.
INSERT INTO Phone_Listings (model_id, seller_id, storage_capacity, ram, color,
                            condition, listing_type, description)
VALUES (?, ?, 128, 8, 'Black', 'good', 'regular', 'Verified device listing');

-- Query 36: Insert pricing for the listing just created in the session.
SET @new_listing_id = LAST_INSERT_ID();
INSERT INTO Pricing (listing_id, base_price, discount_amount, final_price,
                     is_current)
VALUES (@new_listing_id, 50000.00, 5000.00, 45000.00, TRUE);

-- Query 37: Create a new pending transaction.
INSERT INTO Transactions (listing_id, buyer_id, amount, payment_method)
VALUES (?, ?, ?, 'upi');

-- Query 38: Mark a listing sold only when it is still available or reserved.
UPDATE Phone_Listings
SET status = 'sold'
WHERE listing_id = ? AND status IN ('available', 'reserved');

-- Query 39: Update user contact information and last-login time.
UPDATE Users
SET phone_number = ?, street_address = ?, last_login = CURRENT_TIMESTAMP
WHERE user_id = ?;

-- Query 40: Complete a pending payment and confirm its order.
UPDATE Transactions
SET payment_status = 'completed', order_status = 'confirmed'
WHERE transaction_id = ? AND payment_status = 'pending';

-- Query 41: Mark a shipment as shipped.
UPDATE Shipping_Details
SET shipping_status = 'shipped', shipped_date = CURRENT_TIMESTAMP,
    tracking_number = ?
WHERE shipping_id = ?;

-- Query 42: Soft-deactivate a user.
UPDATE Users
SET is_active = FALSE
WHERE user_id = ? AND is_active = TRUE;

-- Query 43: Delete old non-current price history for one listing.
DELETE FROM Pricing
WHERE listing_id = ?
  AND is_current = FALSE
  AND price_updated_date < CURRENT_DATE - INTERVAL 6 MONTH;

-- ============================================================================
-- SECTION 8: BUSINESS-SPECIFIC QUERIES
-- ============================================================================

-- Query 44: Get today's available drops.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, p.final_price, p.discount_amount, u.username AS seller_name
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS u ON u.user_id = pl.seller_id
WHERE pl.listing_type = 'todays_drop' AND pl.status = 'available'
  AND pl.listing_date >= CURRENT_DATE
  AND pl.listing_date < CURRENT_DATE + INTERVAL 1 DAY
ORDER BY pl.listing_date DESC;

-- Query 45: Get the ten most-wishlisted available phones.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       p.final_price, COUNT(w.wishlist_id) AS wishlist_count, pl.views_count
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
LEFT JOIN Wishlist AS w ON w.listing_id = pl.listing_id
WHERE pl.status = 'available'
GROUP BY pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
         p.final_price, pl.views_count
ORDER BY wishlist_count DESC, pl.views_count DESC
LIMIT 10;

-- Query 46: Get available good deals with at least a 15% discount.
SELECT pl.listing_id, b.brand_name, pm.model_name, p.base_price,
       p.discount_amount, p.final_price,
       ROUND(100 * p.discount_amount / NULLIF(p.base_price, 0), 2)
           AS discount_percentage
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.status = 'available' AND p.discount_amount > 0
GROUP BY pl.listing_id, b.brand_name, pm.model_name, p.base_price,
         p.discount_amount, p.final_price
HAVING discount_percentage >= 15
ORDER BY discount_percentage DESC
LIMIT 20;

-- Query 47: Get a user's purchase history and shipping status.
SELECT t.transaction_id, t.transaction_date, b.brand_name, pm.model_name,
       pl.storage_capacity, pl.color, t.amount, t.payment_status, t.order_status,
       sd.shipping_status, sd.tracking_number
FROM Transactions AS t
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Shipping_Details AS sd ON sd.transaction_id = t.transaction_id
WHERE t.buyer_id = ?
ORDER BY t.transaction_date DESC;

-- Query 48: Get a user's selling history, including unsold listings.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.condition, pl.status, p.final_price, pl.listing_date,
       t.transaction_date AS sold_date, t.amount AS sold_amount
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
LEFT JOIN Transactions AS t ON t.listing_id = pl.listing_id
WHERE pl.seller_id = ?
ORDER BY pl.listing_date DESC;

-- Query 49: Get a user's wishlist with current prices.
SELECT w.wishlist_id, w.added_date, b.brand_name, pm.model_name,
       pl.storage_capacity, pl.ram, pl.color, pl.condition, p.final_price,
       pl.status, pl.is_verified
FROM Wishlist AS w
JOIN Phone_Listings AS pl ON pl.listing_id = w.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE w.user_id = ?
ORDER BY w.added_date DESC;

-- Query 50: Search using multiple optional marketplace filters.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, pl.condition, p.final_price, pl.is_verified,
       seller.username AS seller_name, c.city_name
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Cities AS c ON c.city_id = seller.city_id
WHERE pl.status = 'available'
  AND b.brand_name IN ('Apple', 'Samsung')
  AND p.final_price BETWEEN 15000 AND 50000
  AND pl.condition IN ('new', 'like_new')
  AND pl.storage_capacity >= 128
ORDER BY p.final_price;

-- Query 51: Estimate value from recent similar model listings.
SELECT pm.model_name, pl.storage_capacity, pl.ram, pl.condition,
       COUNT(p.price_id) AS similar_listings_count, AVG(p.final_price) AS estimated_value,
       MIN(p.final_price) AS min_value, MAX(p.final_price) AS max_value
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.model_id = ?
  AND pl.storage_capacity = ?
  AND pl.condition IN ('new', 'like_new', 'good')
  AND pl.status IN ('available', 'sold')
  AND pl.listing_date >= CURRENT_DATE - INTERVAL 3 MONTH
GROUP BY pm.model_id, pm.model_name, pl.storage_capacity, pl.ram, pl.condition;

-- Query 52: Find available listings in a selected state and optional city.
SELECT pl.listing_id, b.brand_name, pm.model_name, p.final_price,
       seller.username AS seller_name, c.city_name, s.state_name
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Cities AS c ON c.city_id = seller.city_id
JOIN States AS s ON s.state_id = c.state_id
WHERE s.state_name = ?
  AND (? IS NULL OR c.city_name = ?)
  AND pl.status = 'available'
ORDER BY c.city_name, p.final_price;

-- Query 53: Return all admin dashboard headline statistics in one row.
SELECT
    (SELECT COUNT(*) FROM Users WHERE is_active = TRUE) AS total_active_users,
    (SELECT COUNT(*) FROM Phone_Listings WHERE status = 'available')
        AS total_available_listings,
    (SELECT COUNT(*) FROM Phone_Listings WHERE status = 'sold')
        AS total_sold_listings,
    (SELECT COUNT(*) FROM Transactions WHERE payment_status = 'completed')
        AS total_completed_transactions,
    COALESCE((SELECT SUM(amount) FROM Transactions
              WHERE payment_status = 'completed'), 0) AS total_revenue,
    (SELECT COUNT(*) FROM Reviews) AS total_reviews,
    COALESCE((SELECT AVG(rating) FROM Reviews), 0) AS overall_avg_rating,
    (SELECT COUNT(*) FROM Wishlist) AS total_wishlist_items,
    (SELECT COUNT(*) FROM Brands WHERE is_active = TRUE) AS total_active_brands,
    (SELECT COUNT(*) FROM Phone_Models) AS total_phone_models;

-- ============================================================================
-- END OF QUERY REFERENCE
-- ============================================================================
