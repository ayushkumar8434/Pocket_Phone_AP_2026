-- ============================================================================
-- SQL QUERIES - Pocket Phone AP 2026
-- Version: 2.0 (PostgreSQL)
-- Description: Every SQL query used by the phone marketplace app
-- Database: PostgreSQL 15 or newer (tables from 03_schema.sql)
-- ============================================================================
-- Each query is marked -- READ or -- WRITE and has an id: R1, R2, ... for reads
-- and W1, W2, ... for writes. The same ids name the plan files in dbms/plans/
-- and the rows in 05_query_timings.md.
-- Values that the app passes as parameters are written here as sample values
-- (listed in a "Parameters" comment), so every query runs as it is.
-- Write queries (W1-W10) should run inside a transaction (BEGIN ... ROLLBACK
-- when testing). W3 must run in the same session right after W2.
-- ============================================================================

-- ============================================================================
-- SECTION 1: BASIC RETRIEVAL QUERIES
-- ============================================================================

-- READ R1: List users with their city, state, and country.
SELECT u.user_id, u.username, u.email, u.phone_number,
       c.city_name, s.state_name, s.country
FROM Users AS u
JOIN Cities AS c ON c.city_id = u.city_id
JOIN States AS s ON s.state_id = c.state_id
ORDER BY u.registration_date DESC;

-- READ R2: List all active phone brands.
SELECT brand_id, brand_name, country_of_origin, description
FROM Brands
WHERE is_active = TRUE
ORDER BY brand_name;

-- READ R3: List phone models with brand information.
SELECT pm.model_id, b.brand_name, pm.model_name, pm.release_year,
       pm.display_size, pm.processor, pm.os_version, pm.battery_capacity
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY pm.release_year DESC, b.brand_name, pm.model_name;

-- READ R4: List available listings with current price and seller location.
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

-- READ R5: Get camera specifications for one model.
-- Parameters: model_id = 10
SELECT camera_type, megapixels, aperture, features
FROM Camera_Specs
WHERE model_id = 10
ORDER BY CASE camera_type
             WHEN 'rear_primary' THEN 1 WHEN 'rear_secondary' THEN 2
             WHEN 'rear_tertiary' THEN 3 WHEN 'rear_quaternary' THEN 4
             ELSE 5 END;

-- READ R6: Get the 50 most recent reviews with listing details.
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

-- READ R7: Search available phones by brand.
-- Parameters: brand_name = 'Apple'
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, pl.condition, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE b.brand_name = 'Apple'
  AND pl.status = 'available'
ORDER BY p.final_price;

-- READ R8: Find available phones within an inclusive price range.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE p.final_price BETWEEN 15000 AND 50000
  AND pl.status = 'available'
ORDER BY p.final_price;

-- READ R9: Search available listings by partial model name.
SELECT pm.model_name, b.brand_name, pl.storage_capacity, pl.ram, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pm.model_name LIKE '%iPhone%'
  AND pl.status = 'available'
ORDER BY pm.release_year DESC, p.final_price;

-- READ R10: Find verified available listings.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.condition,
       p.final_price, pl.verification_date
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.is_verified = TRUE AND pl.status = 'available'
ORDER BY pl.verification_date DESC;

-- READ R11: Find phones in selected conditions.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.condition, p.final_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.condition IN ('new', 'like_new')
  AND pl.status = 'available'
ORDER BY p.final_price;

-- READ R12: Search by brand, storage, and condition.
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

-- READ R13: Count total, available, and sold listings by brand.
SELECT b.brand_name, COUNT(pl.listing_id) AS total_listings,
       COUNT(*) FILTER (WHERE pl.status = 'available') AS available_count,
       COUNT(*) FILTER (WHERE pl.status = 'sold') AS sold_count
FROM Brands AS b
LEFT JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
LEFT JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
GROUP BY b.brand_id, b.brand_name
ORDER BY total_listings DESC;

-- READ R14: Calculate available-price statistics by brand.
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

-- READ R15: Total completed sales and revenue per seller.
SELECT u.user_id AS seller_id, u.username, COUNT(t.transaction_id) AS total_sales,
       COALESCE(SUM(t.amount), 0) AS total_revenue, AVG(t.amount) AS avg_amount
FROM Users AS u
JOIN Phone_Listings AS pl ON pl.seller_id = u.user_id
JOIN Transactions AS t ON t.listing_id = pl.listing_id
WHERE t.payment_status = 'completed'
GROUP BY u.user_id, u.username
ORDER BY total_revenue DESC;

-- READ R16: Average rating for each reviewed listing.
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

-- READ R17: Count users by city and state.
SELECT s.state_name, c.city_name, COUNT(u.user_id) AS user_count
FROM States AS s
JOIN Cities AS c ON c.state_id = s.state_id
LEFT JOIN Users AS u ON u.city_id = c.city_id
GROUP BY s.state_id, s.state_name, c.city_id, c.city_name
ORDER BY user_count DESC;

-- READ R18: Monthly transaction volume and payment outcomes.
SELECT to_char(transaction_date, 'YYYY') AS transaction_year,
       to_char(transaction_date, 'MM') AS transaction_month,
       COUNT(*) AS total_transactions,
       SUM(amount) AS total_revenue, AVG(amount) AS avg_transaction_value,
       COUNT(*) FILTER (WHERE payment_status = 'completed') AS completed_count,
       COUNT(*) FILTER (WHERE payment_status = 'failed') AS failed_count
FROM Transactions
GROUP BY to_char(transaction_date, 'YYYY'), to_char(transaction_date, 'MM')
ORDER BY transaction_year DESC, transaction_month DESC;

-- ============================================================================
-- SECTION 4: JOIN QUERIES
-- ============================================================================

-- READ R19: Show transactions with complete buyer, seller, and phone details.
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

-- READ R20: Include phone models that have no listings.
SELECT pm.model_id, b.brand_name, pm.model_name,
       COUNT(pl.listing_id) AS listing_count,
       COUNT(*) FILTER (WHERE pl.status = 'available') AS available_count
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
GROUP BY pm.model_id, b.brand_name, pm.model_name
ORDER BY listing_count DESC;

-- READ R21: Include users with no wishlist entries.
SELECT u.user_id, u.username, u.email, COUNT(w.wishlist_id) AS wishlist_count
FROM Users AS u
LEFT JOIN Wishlist AS w ON w.user_id = u.user_id
GROUP BY u.user_id, u.username, u.email
ORDER BY wishlist_count DESC;

-- READ R22: Show transaction, item, and shipping destination details.
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

-- READ R23: Find pairs of users who live in the same city.
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

-- READ R24: Find available phones priced above the current-price average.
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

-- READ R25: Find sellers with more than five listings.
SELECT u.user_id, u.username, u.email,
       (SELECT COUNT(*) FROM Phone_Listings AS x
        WHERE x.seller_id = u.user_id) AS listing_count
FROM Users AS u
WHERE u.user_id IN (
    SELECT seller_id FROM Phone_Listings
    GROUP BY seller_id HAVING COUNT(*) > 5
)
ORDER BY listing_count DESC;

-- READ R26: Find the most expensive available listing for every brand.
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

-- READ R27: Find users who have both bought and sold phones.
SELECT u.user_id, u.username, u.email,
       (SELECT COUNT(*) FROM Phone_Listings AS pl
        WHERE pl.seller_id = u.user_id) AS items_sold,
       (SELECT COUNT(*) FROM Transactions AS t
        WHERE t.buyer_id = u.user_id) AS items_bought
FROM Users AS u
WHERE EXISTS (SELECT 1 FROM Phone_Listings AS pl WHERE pl.seller_id = u.user_id)
  AND EXISTS (SELECT 1 FROM Transactions AS t WHERE t.buyer_id = u.user_id)
ORDER BY items_sold DESC;

-- READ R28: Find sold listings with no reviews.
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

-- READ R29: Top ten models by listing count, with prices and sold counts.
SELECT b.brand_name, pm.model_name, COUNT(pl.listing_id) AS listing_count,
       AVG(p.final_price) AS avg_price,
       COUNT(*) FILTER (WHERE pl.status = 'sold') AS sold_count
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
GROUP BY pm.model_id, b.brand_name, pm.model_name
HAVING COUNT(pl.listing_id) >= 3
ORDER BY listing_count DESC, sold_count DESC
LIMIT 10;

-- READ R30: Best-rated listings with at least three reviews.
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

-- READ R31: Seller performance across listings, sales, revenue, and reviews.
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

-- READ R32: Price distribution by storage capacity.
SELECT pl.storage_capacity, COUNT(*) AS listing_count, AVG(p.final_price) AS avg_price,
       MIN(p.final_price) AS min_price, MAX(p.final_price) AS max_price,
       STDDEV(p.final_price) AS price_stddev
FROM Phone_Listings AS pl
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.status = 'available'
GROUP BY pl.storage_capacity
ORDER BY pl.storage_capacity;

-- READ R33: Completed daily sales for the last 30 days.
SELECT DATE(t.transaction_date) AS sale_date, COUNT(*) AS total_transactions,
       SUM(t.amount) AS total_revenue, AVG(t.amount) AS avg_order_value
FROM Transactions AS t
WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
  AND t.payment_status = 'completed'
GROUP BY DATE(t.transaction_date)
ORDER BY sale_date DESC;

-- ============================================================================
-- SECTION 7: DATA MODIFICATION QUERIES
-- ============================================================================

-- WRITE W1: Insert a new user. Store an application-generated password hash.
-- Parameters: city_id = 1
INSERT INTO Users (username, email, password, phone_number, street_address,
                   city_id, pincode)
VALUES ('new_user', 'new.user@example.com', '<PASSWORD_HASH>',
        '+919876543210', '12 Example Street', 1, '400001');

-- WRITE W2: Insert a new phone listing.
-- Parameters: model_id = 10, seller_id = 5
INSERT INTO Phone_Listings (model_id, seller_id, storage_capacity, ram, color,
                            condition, listing_type, description)
VALUES (10, 5, 128, 8, 'Black', 'good', 'regular', 'Verified device listing')
RETURNING listing_id;

-- WRITE W3: Insert pricing for the listing just created in the session.
-- Run in the same session right after W2: currval() returns the listing_id just created.
INSERT INTO Pricing (listing_id, base_price, discount_amount, final_price,
                     is_current)
VALUES (currval(pg_get_serial_sequence('phone_listings', 'listing_id')),
        50000.00, 5000.00, 45000.00, TRUE);

-- WRITE W4: Create a new pending transaction.
-- Parameters: listing_id = 1, buyer_id = 2, amount = 45000.00
INSERT INTO Transactions (listing_id, buyer_id, amount, payment_method)
VALUES (1, 2, 45000.00, 'upi');

-- WRITE W5: Mark a listing sold only when it is still available or reserved.
-- Parameters: listing_id = 1
UPDATE Phone_Listings
SET status = 'sold'
WHERE listing_id = 1 AND status IN ('available', 'reserved');

-- WRITE W6: Update user contact information and last-login time.
-- Parameters: phone_number, street_address, user_id = 7
UPDATE Users
SET phone_number = '9999999999', street_address = '1 Test Street', last_login = CURRENT_TIMESTAMP
WHERE user_id = 7;

-- WRITE W7: Complete a pending payment and confirm its order.
-- Parameters: transaction_id = 11 (a pending payment)
UPDATE Transactions
SET payment_status = 'completed', order_status = 'confirmed'
WHERE transaction_id = 11 AND payment_status = 'pending';

-- WRITE W8: Mark a shipment as shipped.
-- Parameters: tracking_number = 'TRK-NEW', shipping_id = 1
UPDATE Shipping_Details
SET shipping_status = 'shipped', shipped_date = CURRENT_TIMESTAMP,
    tracking_number = 'TRK-NEW'
WHERE shipping_id = 1;

-- WRITE W9: Soft-deactivate a user.
-- Parameters: user_id = 7
UPDATE Users
SET is_active = FALSE
WHERE user_id = 7 AND is_active = TRUE;

-- WRITE W10: Delete old non-current price history for one listing.
-- Parameters: listing_id = 5
DELETE FROM Pricing
WHERE listing_id = 5
  AND is_current = FALSE
  AND price_updated_date < CURRENT_DATE - INTERVAL '6 months';

-- ============================================================================
-- SECTION 8: BUSINESS-SPECIFIC QUERIES
-- ============================================================================

-- READ R34: Get today's available drops.
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.ram, pl.color, p.final_price, p.discount_amount, u.username AS seller_name
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS u ON u.user_id = pl.seller_id
WHERE pl.listing_type = 'todays_drop' AND pl.status = 'available'
  AND pl.listing_date >= CURRENT_DATE
  AND pl.listing_date < CURRENT_DATE + INTERVAL '1 days'
ORDER BY pl.listing_date DESC;

-- READ R35: Get the ten most-wishlisted available phones.
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

-- READ R36: Get available good deals with at least a 15% discount.
SELECT pl.listing_id, b.brand_name, pm.model_name, p.base_price,
       p.discount_amount, p.final_price,
       ROUND(100 * p.discount_amount / NULLIF(p.base_price, 0), 2)
           AS discount_percentage
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.status = 'available' AND p.discount_amount > 0
  AND 100 * p.discount_amount / NULLIF(p.base_price, 0) >= 15
ORDER BY discount_percentage DESC
LIMIT 20;

-- READ R37: Get a user's purchase history and shipping status.
-- Parameters: buyer_id = 187
SELECT t.transaction_id, t.transaction_date, b.brand_name, pm.model_name,
       pl.storage_capacity, pl.color, t.amount, t.payment_status, t.order_status,
       sd.shipping_status, sd.tracking_number
FROM Transactions AS t
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Shipping_Details AS sd ON sd.transaction_id = t.transaction_id
WHERE t.buyer_id = 187
ORDER BY t.transaction_date DESC;

-- READ R38: Get a user's selling history, including unsold listings.
-- Parameters: seller_id = 11
SELECT pl.listing_id, b.brand_name, pm.model_name, pl.storage_capacity,
       pl.condition, pl.status, p.final_price, pl.listing_date,
       t.transaction_date AS sold_date, t.amount AS sold_amount
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
LEFT JOIN Transactions AS t ON t.listing_id = pl.listing_id
WHERE pl.seller_id = 11
ORDER BY pl.listing_date DESC;

-- READ R39: Get a user's wishlist with current prices.
-- Parameters: user_id = 3
SELECT w.wishlist_id, w.added_date, b.brand_name, pm.model_name,
       pl.storage_capacity, pl.ram, pl.color, pl.condition, p.final_price,
       pl.status, pl.is_verified
FROM Wishlist AS w
JOIN Phone_Listings AS pl ON pl.listing_id = w.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE w.user_id = 3
ORDER BY w.added_date DESC;

-- READ R40: Search using multiple optional marketplace filters.
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

-- READ R41: Estimate value from recent similar model listings.
-- Parameters: model_id = 201, storage_capacity = 64
SELECT pm.model_name, pl.storage_capacity, pl.ram, pl.condition,
       COUNT(p.price_id) AS similar_listings_count, AVG(p.final_price) AS estimated_value,
       MIN(p.final_price) AS min_value, MAX(p.final_price) AS max_value
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
WHERE pl.model_id = 201
  AND pl.storage_capacity = 64
  AND pl.condition IN ('new', 'like_new', 'good')
  AND pl.status IN ('available', 'sold')
  AND pl.listing_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY pm.model_id, pm.model_name, pl.storage_capacity, pl.ram, pl.condition;

-- READ R42: Find available listings in a selected state and optional city.
-- Parameters: state_name = 'Maharashtra', city = NULL (no city filter)
SELECT pl.listing_id, b.brand_name, pm.model_name, p.final_price,
       seller.username AS seller_name, c.city_name, s.state_name
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p ON p.listing_id = pl.listing_id AND p.is_current = TRUE
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Cities AS c ON c.city_id = seller.city_id
JOIN States AS s ON s.state_id = c.state_id
WHERE s.state_name = 'Maharashtra'
  AND (CAST(NULL AS VARCHAR) IS NULL OR c.city_name = CAST(NULL AS VARCHAR))
  AND pl.status = 'available'
ORDER BY c.city_name, p.final_price;

-- READ R43: Return all admin dashboard headline statistics in one row.
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
-- END OF QUERIES
-- ============================================================================
