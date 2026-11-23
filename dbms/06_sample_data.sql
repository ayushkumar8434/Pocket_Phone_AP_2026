-- ============================================================================
-- Generated test data for query timings - Pocket Phone AP 2026
-- Database: PostgreSQL 15 or newer
-- Run after 03_schema.sql:   psql -d <database> -f dbms/06_sample_data.sql
--
-- Creates deterministic data (no random values) so the timings in
-- 05_query_timings.md can be reproduced:
--   30 cities, 320 phone models, 960 camera specs, 10,000 users,
--   30,000 listings, 36,000 price rows, ~9,000 transactions with shipping rows,
--   20,000 reviews, 6,000 wishlist rows.
-- ============================================================================

-- Skip triggers while bulk loading (final_price and is_current are set explicitly)
SET session_replication_role = replica;

-- 24 more cities (6 already exist from 03_schema.sql)
INSERT INTO Cities (city_name, state_id)
SELECT 'City_' || n, 1 + (n % 5) FROM generate_series(1, 24) AS n;

-- Phone models: 40 per brand
INSERT INTO Phone_Models (brand_id, model_name, release_year, display_size, processor,
                          os_version, battery_capacity)
SELECT 1 + ((n - 1) % 8),
       CASE WHEN (n - 1) % 8 = 0 THEN 'iPhone ' || n || ' ' || (ARRAY['Pro','Max','Mini'])[1 + n % 3]
            ELSE (ARRAY['Nova','Pixel','Galaxy','Edge','Ultra'])[1 + n % 5] || ' ' || n || ' '
                 || (ARRAY['Pro','Max','Lite'])[1 + n % 3] END,
       2018 + (n % 8), 5.5 + (n % 15) / 10.0,
       (ARRAY['Snapdragon 8','A16','Dimensity 9000','Tensor G3'])[1 + n % 4],
       (ARRAY['Android 13','Android 14','iOS 17'])[1 + n % 3],
       3000 + (n % 40) * 100
FROM generate_series(1, 320) AS n;

-- Camera specs: front + two rear cameras per model
INSERT INTO Camera_Specs (model_id, camera_type, megapixels, aperture, features)
SELECT m.model_id, t.camera_type, 8 + (m.model_id * 7 % 100), 1.5 + (m.model_id % 10) / 10.0, '{}'
FROM Phone_Models m
CROSS JOIN (VALUES ('front'), ('rear_primary'), ('rear_secondary')) AS t(camera_type);

-- Users
INSERT INTO Users (username, email, password, phone_number, street_address, city_id, pincode,
                   registration_date, last_login, is_active)
SELECT 'user' || n, 'user' || n || '@example.com', md5('pw' || n),
       '9' || lpad(n::text, 9, '0'), n || ' Main Street', 1 + (n % 30),
       lpad((400000 + n % 9000)::text, 6, '0'),
       now() - (n % 900) * INTERVAL '1 day', now() - (n % 60) * INTERVAL '1 day',
       (n % 25 <> 0)
FROM generate_series(1, 10000) AS n;

-- Listings
INSERT INTO Phone_Listings (model_id, seller_id, storage_capacity, ram, condition, color,
                            listing_date, status, is_verified, verification_date, listing_type,
                            description, image_urls, views_count)
SELECT 1 + (n * 7 % 320), CASE WHEN n % 10 = 0 THEN 1 + (n % 50) ELSE 1 + (n * 13 % 10000) END,
       (ARRAY[64,128,256,512,1024])[1 + n % 5], (ARRAY[4,6,8,12])[1 + n % 4],
       (ARRAY['new','like_new','good','fair','poor'])[1 + n % 5],
       (ARRAY['Black','White','Blue','Red','Green','Gold'])[1 + n % 6],
       now() - (n % 700) * INTERVAL '1 day' - (n % 1440) * INTERVAL '1 minute',
       (ARRAY['available','available','available','available','available','available',
              'sold','sold','reserved','removed'])[1 + n % 10],
       (n % 3 = 0), CASE WHEN n % 3 = 0 THEN now() - (n % 300) * INTERVAL '1 day' END,
       (ARRAY['regular','popular','todays_drop','good_deal','featured'])[1 + n % 5],
       'Well kept phone number ' || n, '[]', n % 5000
FROM generate_series(1, 30000) AS n;

-- A few of today's drops (query R34)
UPDATE Phone_Listings
SET listing_type = 'todays_drop', status = 'available',
    listing_date = CURRENT_DATE + INTERVAL '1 hour' + (listing_id % 600) * INTERVAL '1 minute'
WHERE listing_id % 1000 = 0;

-- Prices: one current price per listing (every 7th listing has a 20% discount), plus an old price for every 5th listing
INSERT INTO Pricing (listing_id, base_price, discount_amount, final_price, price_updated_date, is_current)
SELECT n, b.base, b.disc, b.base - b.disc, now() - (n % 100) * INTERVAL '1 day', TRUE
FROM generate_series(1, 30000) AS n
CROSS JOIN LATERAL (SELECT 8000 + (n * 37 % 90000) AS base,
                           CASE WHEN n % 7 = 0 THEN round((8000 + (n * 37 % 90000)) * 0.2)
                                ELSE (n % 10) * 200 END AS disc) AS b;
INSERT INTO Pricing (listing_id, base_price, discount_amount, final_price, price_updated_date, is_current)
SELECT n, 9000 + (n * 37 % 90000), 0, 9000 + (n * 37 % 90000),
       now() - (200 + n % 100) * INTERVAL '1 day', FALSE
FROM generate_series(1, 30000) AS n WHERE n % 5 = 0;

-- Transactions for sold and reserved listings
INSERT INTO Transactions (listing_id, buyer_id, transaction_date, amount, payment_method,
                          payment_status, order_status, payment_reference)
SELECT l.listing_id, 1 + (l.listing_id * 31 % 10000),
       now() - (l.listing_id % 400) * INTERVAL '1 day' - (l.listing_id % 1440) * INTERVAL '1 minute',
       p.final_price,
       (ARRAY['credit_card','debit_card','upi','net_banking','wallet','cod'])[1 + l.listing_id % 6],
       (ARRAY['completed','completed','completed','completed','completed','pending','failed','refunded'])[1 + l.listing_id % 8],
       (ARRAY['delivered','delivered','confirmed','shipped','processing','cancelled'])[1 + l.listing_id % 6],
       'PAY' || l.listing_id
FROM Phone_Listings l
JOIN Pricing p ON p.listing_id = l.listing_id AND p.is_current
WHERE l.status IN ('sold', 'reserved');

INSERT INTO Shipping_Details (transaction_id, street_address, city_id, pincode, shipping_status,
                              tracking_number, courier_service, shipped_date, estimated_delivery_date)
SELECT transaction_id, transaction_id || ' Ship Road', 1 + (transaction_id % 30), '400001',
       (ARRAY['pending','shipped','in_transit','delivered'])[1 + transaction_id % 4],
       'TRK' || transaction_id, 'BlueDart',
       transaction_date + INTERVAL '1 day', (transaction_date + INTERVAL '5 days')::date
FROM Transactions;

-- Reviews
INSERT INTO Reviews (reviewer_id, listing_id, rating, review_text, review_date,
                     is_verified_purchase, helpful_count)
SELECT 1 + (n * 17 % 10000), 1 + (n * 3 % 15000), 1 + (n % 5), 'Review ' || n,
       now() - (n % 500) * INTERVAL '1 day', (n % 2 = 0), n % 20
FROM generate_series(1, 20000) AS n;

-- Wishlist (unique user/listing pairs)
INSERT INTO Wishlist (user_id, listing_id, added_date)
SELECT 1 + (n % 6000), 1 + (n * 5 % 30000), now() - (n % 200) * INTERVAL '1 day'
FROM generate_series(1, 12000) AS n
ON CONFLICT (user_id, listing_id) DO NOTHING;

SET session_replication_role = DEFAULT;

-- Fresh statistics for the planner
VACUUM (ANALYZE);
