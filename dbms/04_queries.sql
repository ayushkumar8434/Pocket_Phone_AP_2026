-- ============================================================================
-- Pocket Phone AP 2026 - SQL Query Reference
-- Version: 1.0
-- Description: 50 MySQL/MariaDB queries for marketplace browsing, operations,
--              reporting, and administration. Matches dbms/03_schema.sql.
-- Compatibility: MySQL 8.0+ / MariaDB versions supporting CTEs and window funcs
-- ============================================================================
-- Examples below are read-only unless explicitly marked DATA MODIFICATION.
-- Replace sample IDs, values, and password hashes with validated application
-- inputs. Never concatenate untrusted input into SQL; use prepared statements.

-- ============================================================================
-- SECTION 1: BASIC RETRIEVAL QUERIES
-- ============================================================================

-- Query 1: Retrieve active users together with their city, state, and country.
-- Use case: Admin user lookup; filter and paginate in the application as needed.
SELECT
    u.user_id,
    u.username,
    u.email,
    u.phone_number,
    c.city_name AS city,
    s.state_name AS state,
    s.country,
    u.registration_date
FROM Users AS u
JOIN Cities AS c ON c.city_id = u.city_id
JOIN States AS s ON s.state_id = c.state_id
WHERE u.is_active = TRUE
ORDER BY u.username ASC;

-- Query 2: List all active phone brands.
-- Use case: Populate brand filters and marketplace navigation.
SELECT
    b.brand_id,
    b.brand_name,
    b.brand_logo,
    b.description,
    b.country_of_origin
FROM Brands AS b
WHERE b.is_active = TRUE
ORDER BY b.brand_name ASC;

-- Query 3: List phone models and their brand names.
-- Use case: Browse the catalog; the brand/model unique key supports lookups.
SELECT
    pm.model_id,
    b.brand_name,
    pm.model_name,
    pm.release_year,
    pm.display_size,
    pm.processor,
    pm.os_version,
    pm.battery_capacity
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
WHERE b.is_active = TRUE
ORDER BY b.brand_name ASC, pm.release_year DESC, pm.model_name ASC;

-- Query 4: Get available listings with model, brand, seller, and current price.
-- Use case: Main marketplace inventory; idx_status and idx_listing_current help.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.storage_capacity,
    pl.ram,
    pl.color,
    pl.condition AS phone_condition,
    pl.listing_date,
    pl.is_verified,
    pl.listing_type,
    u.username AS seller_name,
    COALESCE(p.base_price, 0.00) AS base_price,
    COALESCE(p.discount_amount, 0.00) AS discount_amount,
    COALESCE(p.final_price, 0.00) AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Users AS u ON u.user_id = pl.seller_id
LEFT JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.status = 'available'
ORDER BY pl.listing_date DESC, pl.listing_id DESC;

-- Query 5: Retrieve camera specifications for each phone model.
-- Use case: Display technical details; models without cameras are omitted.
SELECT
    b.brand_name,
    pm.model_name,
    cs.camera_type,
    cs.megapixels,
    cs.aperture,
    cs.features AS camera_features
FROM Camera_Specs AS cs
JOIN Phone_Models AS pm ON pm.model_id = cs.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY b.brand_name ASC, pm.model_name ASC, cs.camera_type ASC;

-- ============================================================================
-- SECTION 2: FILTERING AND SEARCH QUERIES
-- ============================================================================

-- Query 6: Find available phones from a selected brand.
-- Use case: Brand page; bind the brand name as a prepared-statement parameter.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.storage_capacity,
    pl.ram,
    pl.color,
    pl.condition AS phone_condition,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE b.brand_name = 'Samsung'
  AND pl.status = 'available'
ORDER BY p.final_price ASC, pl.listing_date DESC;

-- Query 7: Find available listings in a price range, inclusive of both bounds.
-- Use case: Price filter; idx_final_price can help depending on join order.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    p.final_price AS current_price,
    pl.condition AS phone_condition,
    pl.storage_capacity
FROM Pricing AS p
JOIN Phone_Listings AS pl ON pl.listing_id = p.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
WHERE p.is_current = TRUE
  AND p.final_price BETWEEN 10000.00 AND 50000.00
  AND pl.status = 'available'
ORDER BY p.final_price ASC, pl.listing_id ASC;

-- Query 8: Search model names with a partial, case-insensitive match.
-- Use case: Search box suggestion; a leading wildcard may prevent index use.
SELECT
    pm.model_id,
    b.brand_name,
    pm.model_name,
    pm.release_year,
    pm.processor
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
WHERE pm.model_name LIKE '%iPhone 15%'
ORDER BY pm.release_year DESC, b.brand_name ASC;

-- Query 9: Show only available listings that have passed verification.
-- Use case: Trusted inventory filter; idx_verified and idx_status are available.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.condition AS phone_condition,
    pl.is_verified,
    pl.verification_date,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.is_verified = TRUE
  AND pl.status = 'available'
ORDER BY pl.verification_date DESC, pl.listing_id DESC;

-- Query 10: Find available phones in selected conditions.
-- Use case: Condition filter; values must match the listing condition ENUM.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.condition AS phone_condition,
    pl.storage_capacity,
    pl.ram,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.condition IN ('new', 'like_new', 'good')
  AND pl.status = 'available'
ORDER BY p.final_price ASC;

-- ============================================================================
-- SECTION 3: AGGREGATE FUNCTIONS
-- ============================================================================

-- Query 11: Count all listings per brand, including brands with zero listings.
-- Use case: Catalog metrics; LEFT JOIN preserves brands without inventory.
SELECT
    b.brand_id,
    b.brand_name,
    COUNT(pl.listing_id) AS total_listings
FROM Brands AS b
LEFT JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
LEFT JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
GROUP BY b.brand_id, b.brand_name
ORDER BY total_listings DESC, b.brand_name ASC;

-- Query 12: Show average, minimum, and maximum current listing price per brand.
-- Use case: Compare brand price bands; COALESCE displays zero when no prices exist.
SELECT
    b.brand_id,
    b.brand_name,
    COALESCE(AVG(p.final_price), 0.00) AS average_price,
    COALESCE(MIN(p.final_price), 0.00) AS minimum_price,
    COALESCE(MAX(p.final_price), 0.00) AS maximum_price,
    COUNT(p.price_id) AS priced_listing_count
FROM Brands AS b
LEFT JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
LEFT JOIN Phone_Listings AS pl
    ON pl.model_id = pm.model_id
   AND pl.status = 'available'
LEFT JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
GROUP BY b.brand_id, b.brand_name
ORDER BY average_price DESC, b.brand_name ASC;

-- Query 13: Sum completed transaction revenue by seller.
-- Use case: Seller financial reporting; revenue is based on completed payments.
SELECT
    u.user_id AS seller_id,
    u.username AS seller_name,
    COALESCE(SUM(t.amount), 0.00) AS completed_revenue,
    COUNT(t.transaction_id) AS completed_sales
FROM Users AS u
LEFT JOIN Phone_Listings AS pl ON pl.seller_id = u.user_id
LEFT JOIN Transactions AS t
    ON t.listing_id = pl.listing_id
   AND t.payment_status = 'completed'
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username
ORDER BY completed_revenue DESC, completed_sales DESC;

-- Query 14: Calculate average rating and review count per listing.
-- Use case: Listing quality summaries; COALESCE handles listings without reviews.
SELECT
    pl.listing_id,
    COALESCE(AVG(r.rating), 0.00) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM Phone_Listings AS pl
LEFT JOIN Reviews AS r ON r.listing_id = pl.listing_id
GROUP BY pl.listing_id
ORDER BY average_rating DESC, review_count DESC, pl.listing_id ASC;

-- Query 15: Count users grouped by city and state.
-- Use case: Geographic adoption report; indexed city/state foreign keys help.
SELECT
    s.state_name,
    c.city_name,
    COUNT(u.user_id) AS user_count
FROM States AS s
JOIN Cities AS c ON c.state_id = s.state_id
LEFT JOIN Users AS u ON u.city_id = c.city_id
GROUP BY s.state_id, s.state_name, c.city_id, c.city_name
ORDER BY s.state_name ASC, user_count DESC, c.city_name ASC;

-- ============================================================================
-- SECTION 4: JOIN QUERIES
-- ============================================================================

-- Query 16: Show transactions with buyer and seller identity and phone details.
-- Use case: Transaction operations; use idx_buyer and idx_seller for lookups.
SELECT
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.payment_status,
    t.order_status,
    buyer.user_id AS buyer_id,
    buyer.username AS buyer_name,
    seller.user_id AS seller_id,
    seller.username AS seller_name,
    b.brand_name,
    pm.model_name,
    pl.listing_id
FROM Transactions AS t
JOIN Users AS buyer ON buyer.user_id = t.buyer_id
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
ORDER BY t.transaction_date DESC, t.transaction_id DESC;

-- Query 17: List all models, including those that do not yet have listings.
-- Use case: Catalog coverage report; listing filters belong in the JOIN to keep
--          unmatched models in the results.
SELECT
    b.brand_name,
    pm.model_id,
    pm.model_name,
    pl.listing_id,
    pl.status AS listing_status
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Phone_Listings AS pl
    ON pl.model_id = pm.model_id
ORDER BY b.brand_name ASC, pm.model_name ASC, pl.listing_id ASC;

-- Query 18: List users and their wishlist counts, including empty wishlists.
-- Use case: Engagement reporting; LEFT JOIN avoids dropping users with no saves.
SELECT
    u.user_id,
    u.username,
    COUNT(w.wishlist_id) AS wishlist_count
FROM Users AS u
LEFT JOIN Wishlist AS w ON w.user_id = u.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username
ORDER BY wishlist_count DESC, u.username ASC;

-- Query 19: Retrieve complete transaction and shipping destination details.
-- Use case: Fulfillment console; LEFT JOIN also shows transactions not yet shipped.
SELECT
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.payment_status,
    t.order_status,
    buyer.username AS buyer_name,
    seller.username AS seller_name,
    b.brand_name,
    pm.model_name,
    sd.shipping_status,
    sd.tracking_number,
    sd.shipped_date,
    sd.delivered_date,
    c.city_name AS shipping_city,
    s.state_name AS shipping_state,
    sd.pincode AS shipping_pincode
FROM Transactions AS t
JOIN Users AS buyer ON buyer.user_id = t.buyer_id
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Shipping_Details AS sd ON sd.transaction_id = t.transaction_id
LEFT JOIN Cities AS c ON c.city_id = sd.city_id
LEFT JOIN States AS s ON s.state_id = c.state_id
ORDER BY t.transaction_date DESC, t.transaction_id DESC;

-- Query 20: Find distinct pairs of users who live in the same city.
-- Use case: Community/location features; user_id ordering prevents mirror pairs.
SELECT
    u1.city_id,
    c.city_name,
    u1.user_id AS first_user_id,
    u1.username AS first_username,
    u2.user_id AS second_user_id,
    u2.username AS second_username
FROM Users AS u1
JOIN Users AS u2
    ON u2.city_id = u1.city_id
   AND u2.user_id > u1.user_id
JOIN Cities AS c ON c.city_id = u1.city_id
WHERE u1.is_active = TRUE
  AND u2.is_active = TRUE
ORDER BY c.city_name ASC, u1.username ASC, u2.username ASC;

-- ============================================================================
-- SECTION 5: SUBQUERIES
-- ============================================================================

-- Query 21: Find available current listings priced above the marketplace average.
-- Use case: Identify premium inventory; the scalar subquery calculates the
--          average only over current prices.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.status = 'available'
  AND p.final_price > (
      SELECT AVG(p2.final_price)
      FROM Pricing AS p2
      WHERE p2.is_current = TRUE
  )
ORDER BY p.final_price DESC;

-- Query 22: Find active sellers with more than five listings.
-- Use case: Seller segmentation; change the threshold to a bound parameter.
SELECT
    u.user_id AS seller_id,
    u.username AS seller_name,
    (
        SELECT COUNT(*)
        FROM Phone_Listings AS pl
        WHERE pl.seller_id = u.user_id
    ) AS listing_count
FROM Users AS u
WHERE u.is_active = TRUE
  AND (
      SELECT COUNT(*)
      FROM Phone_Listings AS pl
      WHERE pl.seller_id = u.user_id
  ) > 5
ORDER BY listing_count DESC, u.username ASC;

-- Query 23: Find the highest-priced current listing(s) for each brand.
-- Use case: Brand-level premium showcase; equality preserves ties.
SELECT
    b.brand_name,
    pm.model_name,
    pl.listing_id,
    p.final_price AS current_price
FROM Brands AS b
JOIN Phone_Models AS pm ON pm.brand_id = b.brand_id
JOIN Phone_Listings AS pl
    ON pl.model_id = pm.model_id
   AND pl.status = 'available'
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE p.final_price = (
    SELECT MAX(p2.final_price)
    FROM Phone_Models AS pm2
    JOIN Phone_Listings AS pl2
        ON pl2.model_id = pm2.model_id
       AND pl2.status = 'available'
    JOIN Pricing AS p2
        ON p2.listing_id = pl2.listing_id
       AND p2.is_current = TRUE
    WHERE pm2.brand_id = b.brand_id
)
ORDER BY b.brand_name ASC, pl.listing_id ASC;

-- Query 24: Find active users who have both purchased and sold at least one phone.
-- Use case: Identify marketplace participants in both buyer and seller roles.
SELECT
    u.user_id,
    u.username
FROM Users AS u
WHERE u.is_active = TRUE
  AND EXISTS (
      SELECT 1
      FROM Transactions AS t
      WHERE t.buyer_id = u.user_id
  )
  AND EXISTS (
      SELECT 1
      FROM Phone_Listings AS pl
      WHERE pl.seller_id = u.user_id
  )
ORDER BY u.username ASC;

-- Query 25: Find available listings that have never received a review.
-- Use case: Find listings where post-purchase feedback is not yet available.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.listing_date
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
WHERE pl.status = 'available'
  AND NOT EXISTS (
      SELECT 1
      FROM Reviews AS r
      WHERE r.listing_id = pl.listing_id
  )
ORDER BY pl.listing_date DESC;

-- ============================================================================
-- SECTION 6: ADVANCED QUERIES
-- ============================================================================

-- Query 26: Rank the ten most popular phone models by wishlist saves.
-- Use case: Popularity report; HAVING excludes models without wishlist activity.
SELECT
    pm.model_id,
    b.brand_name,
    pm.model_name,
    COUNT(DISTINCT w.wishlist_id) AS wishlist_count,
    COUNT(DISTINCT pl.listing_id) AS listing_count
FROM Phone_Models AS pm
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Phone_Listings AS pl ON pl.model_id = pm.model_id
JOIN Wishlist AS w ON w.listing_id = pl.listing_id
GROUP BY pm.model_id, b.brand_name, pm.model_name
HAVING COUNT(DISTINCT w.wishlist_id) > 0
ORDER BY wishlist_count DESC, listing_count DESC, pm.model_name ASC
LIMIT 10;

-- Query 27: Summarize transaction volume and revenue by calendar month.
-- Use case: Monthly finance dashboard; date range predicates can use
--          idx_transaction_date when a reporting window is added.
SELECT
    YEAR(t.transaction_date) AS transaction_year,
    MONTH(t.transaction_date) AS transaction_month,
    COUNT(t.transaction_id) AS transaction_count,
    COALESCE(SUM(CASE
        WHEN t.payment_status = 'completed' THEN t.amount
        ELSE 0.00
    END), 0.00) AS completed_revenue,
    SUM(t.payment_status = 'completed') AS completed_payment_count
FROM Transactions AS t
GROUP BY YEAR(t.transaction_date), MONTH(t.transaction_date)
ORDER BY transaction_year DESC, transaction_month DESC;

-- Query 28: Show highly rated listings with at least three reviews.
-- Use case: Curated recommendations; HAVING enforces rating volume and quality.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Reviews AS r ON r.listing_id = pl.listing_id
GROUP BY pl.listing_id, b.brand_name, pm.model_name
HAVING COUNT(r.review_id) >= 3
   AND AVG(r.rating) >= 4.00
ORDER BY average_rating DESC, review_count DESC, pl.listing_id ASC;

-- Query 29: Rank sellers by sales, completed revenue, and buyer review score.
-- Use case: Seller performance dashboard; MySQL 8 window functions are used.
WITH seller_metrics AS (
    SELECT
        u.user_id AS seller_id,
        u.username AS seller_name,
        COALESCE(ss.completed_sales, 0) AS completed_sales,
        COALESCE(ss.completed_revenue, 0.00) AS completed_revenue,
        COALESCE(sr.average_listing_rating, 0.00) AS average_listing_rating
    FROM Users AS u
    LEFT JOIN (
        SELECT
            pl.seller_id,
            COUNT(DISTINCT CASE
                WHEN t.payment_status = 'completed' THEN t.transaction_id
            END) AS completed_sales,
            SUM(CASE
                WHEN t.payment_status = 'completed' THEN t.amount
                ELSE 0.00
            END) AS completed_revenue
        FROM Phone_Listings AS pl
        LEFT JOIN Transactions AS t ON t.listing_id = pl.listing_id
        GROUP BY pl.seller_id
    ) AS ss ON ss.seller_id = u.user_id
    LEFT JOIN (
        SELECT
            pl.seller_id,
            AVG(r.rating) AS average_listing_rating
        FROM Phone_Listings AS pl
        LEFT JOIN Reviews AS r ON r.listing_id = pl.listing_id
        GROUP BY pl.seller_id
    ) AS sr ON sr.seller_id = u.user_id
    WHERE u.is_active = TRUE
)
SELECT
    sm.seller_id,
    sm.seller_name,
    sm.completed_sales,
    sm.completed_revenue,
    ROUND(sm.average_listing_rating, 2) AS average_listing_rating,
    RANK() OVER (
        ORDER BY sm.completed_revenue DESC, sm.completed_sales DESC
    ) AS seller_rank
FROM seller_metrics AS sm
ORDER BY seller_rank ASC, sm.seller_name ASC;

-- Query 30: Compare current price averages across storage capacities.
-- Use case: Pricing analysis; include only currently available inventory.
SELECT
    pl.storage_capacity AS storage_capacity_gb,
    COUNT(pl.listing_id) AS available_listing_count,
    COALESCE(AVG(p.final_price), 0.00) AS average_price,
    COALESCE(MIN(p.final_price), 0.00) AS minimum_price,
    COALESCE(MAX(p.final_price), 0.00) AS maximum_price
FROM Phone_Listings AS pl
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.status = 'available'
GROUP BY pl.storage_capacity
ORDER BY pl.storage_capacity ASC;

-- ============================================================================
-- SECTION 7: DATA MODIFICATION QUERIES
-- ============================================================================
-- These are templates: validate IDs/inputs and run in an application
-- transaction where the related business operation must be atomic.

-- Query 31: Insert a new user account.
-- Use only during validated registration; hash the password in the application
-- and bind it as a prepared-statement parameter (never store plaintext).
-- Replace city_id with an existing Cities.city_id.
INSERT INTO Users (
    username, email, password, phone_number, street_address,
    city_id, pincode, registration_date, is_active
) VALUES (
    'riya_sharma',
    'riya.sharma@example.com',
    '<APPLICATION_GENERATED_PASSWORD_HASH>',
    '+919876543210',
    '12 Jubilee Hills Road',
    1,
    '500033',
    CURRENT_TIMESTAMP,
    TRUE
);

-- Query 32: Insert a new phone listing for an existing seller and model.
-- Use only after validating model/seller ownership and all listing attributes.
-- Replace model_id and seller_id with existing IDs; add pricing separately.
INSERT INTO Phone_Listings (
    model_id, seller_id, storage_capacity, ram, color, condition,
    listing_date, status, is_verified, listing_type, description
) VALUES (
    1, 1, 256, 8, 'Black', 'good',
    CURRENT_TIMESTAMP, 'available', FALSE, 'regular',
    'Example listing; replace with accurate device details.'
);

-- Query 33: Add the initial current price for a newly created listing.
-- Use only after Query 32 succeeds; replace listing_id and set truthful prices.
INSERT INTO Pricing (
    listing_id, base_price, discount_amount, final_price,
    price_updated_date, is_current
) VALUES (
    1, 25000.00, 2000.00, 23000.00,
    CURRENT_TIMESTAMP, TRUE
);

-- Query 34: Mark a listing as sold after the sale is confirmed.
-- Use only when the associated order has reached the business-defined sold state.
-- The schema trigger also marks it sold when payment_status changes to completed.
UPDATE Phone_Listings AS pl
SET status = 'sold'
WHERE pl.listing_id = 1
  AND pl.status IN ('available', 'reserved');

-- Query 35: Update a user's contact and address information.
-- Use only after authenticating the user and validating the replacement values.
UPDATE Users AS u
SET phone_number = '+919876543211',
    street_address = '24 Banjara Hills Road',
    pincode = '500034'
WHERE u.user_id = 1
  AND u.is_active = TRUE;

-- Query 36: Mark a payment as completed after payment-provider confirmation.
-- Use only after verifying the provider callback/reference; the schema trigger
-- automatically changes the linked listing status to sold.
UPDATE Transactions AS t
SET payment_status = 'completed',
    order_status = 'confirmed',
    payment_reference = 'PAYMENT_REFERENCE_FROM_PROVIDER'
WHERE t.transaction_id = 1
  AND t.payment_status = 'pending';

-- Query 37: Update shipment progress using a verified transaction/shipment ID.
-- Use only when the carrier reports the package has shipped.
UPDATE Shipping_Details AS sd
SET shipping_status = 'shipped',
    tracking_number = 'TRACKING_NUMBER_FROM_CARRIER',
    shipped_date = CURRENT_TIMESTAMP
WHERE sd.shipping_id = 1
  AND sd.shipping_status IN ('pending', 'packed');

-- Query 38: Soft-deactivate a user without deleting transaction history.
-- Use only for an approved account closure or moderation action.
UPDATE Users AS u
SET is_active = FALSE
WHERE u.user_id = 1
  AND u.is_active = TRUE;

-- Query 39: Remove a listing from marketplace visibility without deleting it.
-- Use only for a seller removal or moderation action; history remains intact.
UPDATE Phone_Listings AS pl
SET status = 'removed'
WHERE pl.listing_id = 1
  AND pl.status IN ('available', 'reserved');

-- Query 40: Delete old, non-current pricing history records.
-- Use only under an approved retention policy and after backup/audit review.
-- Current prices are explicitly excluded; foreign keys cascade only from listings.
DELETE FROM Pricing
WHERE is_current = FALSE
  AND price_updated_date < CURRENT_TIMESTAMP - INTERVAL 365 DAY;

-- ============================================================================
-- SECTION 8: BUSINESS-SPECIFIC QUERIES
-- ============================================================================

-- Query 41: Get today's available "Today's Drops" listings with current prices.
-- Use case: Homepage daily-drop module; listing_date index supports date filtering.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.condition AS phone_condition,
    pl.listing_date,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.listing_type = 'todays_drop'
  AND pl.status = 'available'
  AND pl.listing_date >= CURRENT_DATE
  AND pl.listing_date < CURRENT_DATE + INTERVAL 1 DAY
ORDER BY pl.listing_date DESC, pl.listing_id DESC;

-- Query 42: Rank available phones by a combined wishlist and view popularity.
-- Use case: Popular phones module; both interaction counts are calculated once
--          per listing to avoid multiplying counts across joins.
WITH wishlist_counts AS (
    SELECT
        w.listing_id,
        COUNT(*) AS wishlist_count
    FROM Wishlist AS w
    GROUP BY w.listing_id
)
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.views_count,
    COALESCE(wc.wishlist_count, 0) AS wishlist_count,
    (pl.views_count + 10 * COALESCE(wc.wishlist_count, 0)) AS popularity_score,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
LEFT JOIN wishlist_counts AS wc ON wc.listing_id = pl.listing_id
WHERE pl.status = 'available'
ORDER BY popularity_score DESC, pl.listing_id DESC
LIMIT 20;

-- Query 43: Find discounted listings by discount percentage.
-- Use case: Good-deals module; NULLIF prevents division by zero for free items.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    p.base_price,
    p.discount_amount,
    p.final_price,
    ROUND(100.0 * p.discount_amount / NULLIF(p.base_price, 0), 2)
        AS discount_percentage
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE pl.status = 'available'
  AND p.discount_amount > 0
  AND 100.0 * p.discount_amount / NULLIF(p.base_price, 0) >= 15.00
ORDER BY discount_percentage DESC, p.final_price ASC;

-- Query 44: Retrieve one user's purchase history with phone and seller details.
-- Use case: Buyer account order history; replace the sample ID with a bound value.
SELECT
    t.transaction_id,
    t.transaction_date,
    t.amount AS purchase_amount,
    t.payment_method,
    t.payment_status,
    t.order_status,
    b.brand_name,
    pm.model_name,
    pl.storage_capacity,
    pl.ram,
    seller.username AS seller_name
FROM Transactions AS t
JOIN Phone_Listings AS pl ON pl.listing_id = t.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Users AS seller ON seller.user_id = pl.seller_id
WHERE t.buyer_id = 1
ORDER BY t.transaction_date DESC, t.transaction_id DESC;

-- Query 45: Retrieve one user's selling history and associated transaction data.
-- Use case: Seller dashboard; LEFT JOIN keeps unsold listings in the history.
SELECT
    pl.listing_id,
    pl.listing_date,
    pl.status AS listing_status,
    b.brand_name,
    pm.model_name,
    p.final_price AS current_price,
    t.transaction_id,
    t.transaction_date,
    t.amount AS sale_amount,
    t.payment_status
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
LEFT JOIN Transactions AS t ON t.listing_id = pl.listing_id
WHERE pl.seller_id = 1
ORDER BY pl.listing_date DESC, t.transaction_date DESC;

-- Query 46: Get a user's wishlist with each phone's current price and status.
-- Use case: Wishlist page; LEFT JOIN retains saved listings with no current price.
SELECT
    w.wishlist_id,
    w.added_date,
    pl.listing_id,
    pl.status AS listing_status,
    b.brand_name,
    pm.model_name,
    pl.storage_capacity,
    pl.condition AS phone_condition,
    COALESCE(p.final_price, 0.00) AS current_price
FROM Wishlist AS w
JOIN Phone_Listings AS pl ON pl.listing_id = w.listing_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE w.user_id = 1
ORDER BY w.added_date DESC, w.wishlist_id DESC;

-- Query 47: Search available listings using brand, price, condition, and storage.
-- Use case: Combined marketplace filters; bind values rather than constructing SQL.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    pl.storage_capacity,
    pl.ram,
    pl.condition AS phone_condition,
    pl.color,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE b.brand_name = 'Apple'
  AND p.final_price BETWEEN 20000.00 AND 80000.00
  AND pl.condition IN ('like_new', 'good')
  AND pl.storage_capacity >= 128
  AND pl.status = 'available'
ORDER BY p.final_price ASC, pl.storage_capacity DESC;

-- Query 48: Estimate a phone's value using current prices of similar listings.
-- Use case: Pricing guidance; compare same model, storage, and condition against
--          other available listings; replace listing_id with the target listing.
SELECT
    target.listing_id AS target_listing_id,
    b.brand_name,
    pm.model_name,
    target.storage_capacity AS storage_capacity_gb,
    target.condition AS phone_condition,
    COALESCE(AVG(similar_price.final_price), 0.00) AS estimated_market_value,
    COUNT(similar_price.price_id) AS comparable_listing_count
FROM Phone_Listings AS target
JOIN Phone_Models AS pm ON pm.model_id = target.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
LEFT JOIN Phone_Listings AS similar
    ON similar.model_id = target.model_id
   AND similar.storage_capacity = target.storage_capacity
   AND similar.condition = target.condition
   AND similar.status = 'available'
   AND similar.listing_id <> target.listing_id
LEFT JOIN Pricing AS similar_price
    ON similar_price.listing_id = similar.listing_id
   AND similar_price.is_current = TRUE
WHERE target.listing_id = 1
GROUP BY
    target.listing_id,
    b.brand_name,
    pm.model_name,
    target.storage_capacity,
    target.condition;

-- Query 49: Find available listings offered by sellers in a selected location.
-- Use case: Local marketplace filter; city and state name make the filter readable.
SELECT
    pl.listing_id,
    b.brand_name,
    pm.model_name,
    seller.username AS seller_name,
    c.city_name,
    s.state_name,
    pl.condition AS phone_condition,
    p.final_price AS current_price
FROM Phone_Listings AS pl
JOIN Users AS seller ON seller.user_id = pl.seller_id
JOIN Cities AS c ON c.city_id = seller.city_id
JOIN States AS s ON s.state_id = c.state_id
JOIN Phone_Models AS pm ON pm.model_id = pl.model_id
JOIN Brands AS b ON b.brand_id = pm.brand_id
JOIN Pricing AS p
    ON p.listing_id = pl.listing_id
   AND p.is_current = TRUE
WHERE c.city_name = 'Hyderabad'
  AND s.state_name = 'Telangana'
  AND pl.status = 'available'
ORDER BY p.final_price ASC, pl.listing_date DESC;

-- ============================================================================
-- SECTION 9: ANALYTICS / DASHBOARD QUERY
-- ============================================================================

-- Query 50: Return key admin dashboard totals in a single result row.
-- Use case: Top-level dashboard cards; each scalar aggregate avoids cross-join
--          fan-out that would inflate counts and revenue.
SELECT
    (SELECT COUNT(*) FROM Users AS u WHERE u.is_active = TRUE)
        AS active_user_count,
    (SELECT COUNT(*) FROM Phone_Listings AS pl WHERE pl.status = 'available')
        AS available_listing_count,
    (SELECT COUNT(*) FROM Transactions AS t)
        AS total_transaction_count,
    (SELECT COUNT(*) FROM Transactions AS t
     WHERE t.payment_status = 'completed')
        AS completed_transaction_count,
    COALESCE(
        (SELECT SUM(t.amount) FROM Transactions AS t
         WHERE t.payment_status = 'completed'),
        0.00
    ) AS completed_revenue,
    (SELECT COUNT(*) FROM Reviews AS r)
        AS total_review_count,
    COALESCE(
        (SELECT AVG(r.rating) FROM Reviews AS r),
        0.00
    ) AS average_review_rating,
    (SELECT COUNT(*) FROM Wishlist AS w)
        AS total_wishlist_count,
    (SELECT COUNT(*) FROM Phone_Listings AS pl WHERE pl.is_verified = TRUE)
        AS verified_listing_count;

-- ============================================================================
-- PERFORMANCE TIPS AND BEST PRACTICES
-- ============================================================================
-- 1. Use EXPLAIN (or EXPLAIN ANALYZE where supported) on representative queries
--    with production-like data before adding/changing indexes.
-- 2. Schema indexes already cover common lookups such as listing status,
--    seller, verification, current price, buyer, transaction date, reviews,
--    and wishlist user/listing relationships. Avoid duplicate indexes.
-- 3. Add composite indexes only after measuring query plans; candidate patterns
--    may include (status, listing_type, listing_date) for drops or
--    (model_id, status, storage_capacity) for filtered inventory.
-- 4. Prefer sargable date ranges (start <= column AND column < end) over
--    DATE(column) in WHERE when querying indexed DATETIME columns.
-- 5. Bind all values in prepared statements. Never interpolate user input,
--    credentials, or search terms directly into SQL strings.
-- 6. Keep database credentials and password hashes protected; never select or
--    log Users.password in application-facing queries.
-- 7. Paginate large result sets with a stable ORDER BY and LIMIT; consider
--    keyset pagination for deep pages.
-- 8. For multi-step writes (listing plus pricing, or order plus shipping), use
--    transactions and validate affected-row counts before committing.
-- ============================================================================
