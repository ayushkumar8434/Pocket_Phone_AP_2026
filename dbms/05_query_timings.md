# Query Timings - Pocket Phone AP 2026

Execution timings for the queries in [04_queries.sql](./04_queries.sql). Query plans (`EXPLAIN ANALYZE` for SELECT queries, `EXPLAIN` for data modification queries) are in [plans/](./plans/), one file per query named `qNN.txt` (for example [plans/q07.txt](./plans/q07.txt)).

## Test Environment

| Item | Value |
|------|-------|
| Database | MySQL 26.10.0 (Homebrew), InnoDB, `innodb_buffer_pool_size` = 128 MB |
| Schema | [03_schema.sql](./03_schema.sql), with the workarounds listed under "Schema and Query Issues Found While Running on MySQL" |
| Hardware | Apple M4, 16 GB RAM, macOS 27.2.1, local socket connection |
| Date measured | 2026-11-23 |
| Dataset | Generated sample data: 20000 users, 30 cities, 320 phone models, 960 camera specs, 60000 listings, 72000 price rows, 18000 transactions, 18000 shipping rows, 40000 reviews, 12000 wishlist rows |

## Method

1. Load the schema, generate the sample data, then run `ANALYZE TABLE` on every table.
2. Run each query 6 times in one session. Discard the first run (cold cache) and average the other 5. Query 23 is the exception: it takes about 4 minutes per run, so it ran 2 times and the second run is reported.
3. Time is the server-side execution time from `performance_schema.events_statements_history_long` (`timer_wait`). It excludes client and network time.
4. Rows is the number of rows returned (SELECT) or affected (INSERT, UPDATE, DELETE).
5. Each `?` placeholder was replaced with a fixed sample value.
6. Data modification queries (34-43) ran inside a transaction that was rolled back after each run.
7. Plans in `plans/` come from `EXPLAIN ANALYZE` (SELECT) or `EXPLAIN FORMAT=TRADITIONAL` (data modification), run once on the same data.

## Results

### Basic Retrieval

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 1 | List users with their city, state, and country. | 35.07 | 20,000 | [q01](./plans/q01.txt) | index: fk_cities_state, fk_users_city, uk_state_name; sort |
| 2 | List all active phone brands. | 0.03 | 8 | [q02](./plans/q02.txt) | full scan: Brands; sort |
| 3 | List phone models with brand information. | 1.31 | 320 | [q03](./plans/q03.txt) | index: brand_name, uk_brand_model; sort |
| 4 | List available listings with current price and seller location. | 138.81 | 36,000 | [q04](./plans/q04.txt) | index: PRIMARY; full scan: p; sort |
| 5 | Get camera specifications for one model. | 0.06 | 3 | [q05](./plans/q05.txt) | index: idx_model_camera; sort |
| 6 | Get the 50 most recent reviews with listing details. | 0.19 | 50 | [q06](./plans/q06.txt) | index: PRIMARY, idx_review_date |

### Filtering and Search

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 7 | Search available phones by brand. | 10.81 | 4,500 | [q07](./plans/q07.txt) | index: PRIMARY; full scan: p; sort |
| 8 | Find available phones within an inclusive price range. | 45.43 | 14,187 | [q08](./plans/q08.txt) | index: PRIMARY; full scan: p; sort |
| 9 | Search available listings by partial model name. | 11.44 | 4,500 | [q09](./plans/q09.txt) | index: PRIMARY, idx_listing_model_status, idx_pricing_listing_current; full scan: pm; sort |
| 10 | Find verified available listings. | 58.84 | 12,000 | [q10](./plans/q10.txt) | index: PRIMARY; full scan: p; sort |
| 11 | Find phones in selected conditions. | 75.31 | 18,000 | [q11](./plans/q11.txt) | index: PRIMARY; full scan: p; sort |
| 12 | Search by brand, storage, and condition. | 27.13 | 1,500 | [q12](./plans/q12.txt) | index: PRIMARY, idx_pricing_listing_current, idx_status; sort |

### Aggregate Functions

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 13 | Count total, available, and sold listings by brand. | 25.86 | 8 | [q13](./plans/q13.txt) | index: brand_name, idx_listing_model_status, temporary, uk_brand_model; temp table; sort |
| 14 | Calculate available-price statistics by brand. | 99.99 | 8 | [q14](./plans/q14.txt) | index: PRIMARY, temporary; full scan: p; temp table; sort |
| 15 | Total completed sales and revenue per seller. | 25.65 | 4,000 | [q15](./plans/q15.txt) | index: PRIMARY, idx_payment_status, temporary; temp table; sort |
| 16 | Average rating for each reviewed listing. | 85.11 | 10,000 | [q16](./plans/q16.txt) | index: PRIMARY, temporary; full scan: r; temp table; sort |
| 17 | Count users by city and state. | 8.47 | 30 | [q17](./plans/q17.txt) | index: fk_cities_state, fk_users_city, idx_state_name, temporary; temp table; sort |
| 18 | Monthly transaction volume and payment outcomes. | 11.35 | 14 | [q18](./plans/q18.txt) | index: temporary; full scan: Transactions; temp table; sort |

### Joins

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 19 | Show transactions with complete buyer, seller, and phone details. | 47.84 | 18,000 | [q19](./plans/q19.txt) | index: PRIMARY; full scan: t; sort |
| 20 | Include phone models that have no listings. | 28.99 | 320 | [q20](./plans/q20.txt) | index: brand_name, idx_listing_model_status, temporary, uk_brand_model; temp table; sort |
| 21 | Include users with no wishlist entries. | 27.61 | 20,000 | [q21](./plans/q21.txt) | index: idx_user_wishlist, temporary; full scan: u; temp table; sort |
| 22 | Show transaction, item, and shipping destination details. | 57.57 | 18,000 | [q22](./plans/q22.txt) | index: PRIMARY, transaction_id; full scan: t; sort |
| 23 | Find pairs of users who live in the same city. | 247,135 | 6,656,670 | [q23](./plans/q23.txt) | index: fk_cities_state, fk_users_city, idx_state_name; sort |

### Subqueries

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 24 | Find available phones priced above the current-price average. | 61.74 | 18,083 | [q24](./plans/q24.txt) | index: PRIMARY; full scan: Pricing, p; sort |
| 25 | Find sellers with more than five listings. | 7.29 | 0 | [q25](./plans/q25.txt) | index: idx_seller; full scan: u; sort |
| 26 | Find the most expensive available listing for every brand. | 123.05 | 8 | [q26](./plans/q26.txt) | index: PRIMARY, brand_name, idx_final_price, idx_listing_model_status, idx_pricing_listing_current, uk_brand_model; sort |
| 27 | Find users who have both bought and sold phones. | 19.74 | 6,000 | [q27](./plans/q27.txt) | index: PRIMARY, idx_buyer, idx_seller; sort |
| 28 | Find sold listings with no reviews. | 21.88 | 10,000 | [q28](./plans/q28.txt) | index: PRIMARY, idx_listing_reviews, idx_status; sort |

### Advanced Queries

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 29 | Top ten models by listing count, with prices and sold counts. | 95.77 | 10 | [q29](./plans/q29.txt) | index: brand_name, idx_listing_model_status, idx_pricing_listing_current, temporary, uk_brand_model; temp table; sort |
| 30 | Best-rated listings with at least three reviews. | 137.82 | 4,000 | [q30](./plans/q30.txt) | index: PRIMARY, idx_pricing_listing_current, temporary; full scan: r; temp table; sort |
| 31 | Seller performance across listings, sales, revenue, and reviews. | 74.05 | 20 | [q31](./plans/q31.txt) | index: PRIMARY, idx_payment_status, idx_seller, temporary; full scan: lm, r; temp table; sort |
| 32 | Price distribution by storage capacity. | 58.31 | 5 | [q32](./plans/q32.txt) | index: PRIMARY, temporary; full scan: p; temp table; sort |
| 33 | Completed daily sales for the last 30 days. | 0.91 | 10 | [q33](./plans/q33.txt) | index: idx_transaction_date, temporary; temp table; sort |

### Data Modification

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 34 | Insert a new user. Store an application-generated password hash. | 0.18 | 1 | [q34](./plans/q34.txt) | Uses filtered |
| 35 | Insert a new phone listing. | 0.08 | 1 | [q35](./plans/q35.txt) | Uses filtered |
| 36 | Insert pricing for the listing just created in the session. | 0.02 | 1 | [q36](./plans/q36.txt) | Uses filtered |
| 37 | Create a new pending transaction. | 0.05 | 1 | [q37](./plans/q37.txt) | Uses filtered |
| 38 | Mark a listing sold only when it is still available or reserved. | 0.06 | 1 | [q38](./plans/q38.txt) | Uses PRIMARY, filtered |
| 39 | Update user contact information and last-login time. | 0.07 | 1 | [q39](./plans/q39.txt) | Uses PRIMARY, filtered |
| 40 | Complete a pending payment and confirm its order. | 0.07 | 1 | [q40](./plans/q40.txt) | Uses PRIMARY, filtered |
| 41 | Mark a shipment as shipped. | 0.03 | 1 | [q41](./plans/q41.txt) | Uses PRIMARY, filtered |
| 42 | Soft-deactivate a user. | 0.06 | 1 | [q42](./plans/q42.txt) | Uses PRIMARY, filtered |
| 43 | Delete old non-current price history for one listing. | 0.03 | 1 | [q43](./plans/q43.txt) | Uses filtered, idx_listing_current |

### Business-Specific Queries

| # | Description | Avg (ms) | Rows | Plan | Notes |
|---|-------------|----------|------|------|-------|
| 44 | Get today's available drops. | 0.19 | 30 | [q44](./plans/q44.txt) | index: PRIMARY, idx_listing_date, idx_pricing_listing_current |
| 45 | Get the ten most-wishlisted available phones. | 113.81 | 10 | [q45](./plans/q45.txt) | index: PRIMARY, idx_listing_wishlist, temporary; full scan: p; temp table; sort |
| 46 | Get available good deals with at least a 15% discount. | 81.33 | 0 | [q46](./plans/q46.txt) | index: PRIMARY; full scan: p; temp table; sort |
| 47 | Get a user's purchase history and shipping status. | 0.05 | 3 | [q47](./plans/q47.txt) | index: PRIMARY, idx_transaction_buyer_date, transaction_id |
| 48 | Get a user's selling history, including unsold listings. | 0.05 | 3 | [q48](./plans/q48.txt) | index: PRIMARY, fk_transaction_listing, idx_pricing_listing_current, idx_seller; sort |
| 49 | Get a user's wishlist with current prices. | 0.03 | 1 | [q49](./plans/q49.txt) | index: PRIMARY, idx_pricing_listing_current, uk_user_listing; sort |
| 50 | Search using multiple optional marketplace filters. | 31.32 | 591 | [q50](./plans/q50.txt) | index: PRIMARY, idx_pricing_listing_current, idx_status, multiple; sort |
| 51 | Estimate value from recent similar model listings. | 0.29 | 1 | [q51](./plans/q51.txt) | index: idx_listing_model_status, idx_pricing_listing_current, temporary; temp table |
| 52 | Find available listings in a selected state and optional city. | 42.90 | 8,001 | [q52](./plans/q52.txt) | index: PRIMARY, fk_cities_state, fk_users_city, idx_pricing_listing_current, idx_seller, uk_state_name; sort |
| 53 | Return all admin dashboard headline statistics in one row. | 16.68 | 1 | [q53](./plans/q53.txt) | index: idx_payment_status, idx_rating, idx_status; full scan: Brands, Users |

## Slowest Queries

| # | Avg (ms) | Why it is slow |
|---|----------|----------------|
| 23 | 247,135 | Self-join of Users on city_id produces every user pair in a city (6.6 million rows), then sorts them. The cost grows with the square of users per city. |
| 4 | 138.81 | Returns every available listing (36,000 rows) joined to 5 tables and sorts by listing_date. |
| 30 | 137.82 | Groups all 40,000 reviews by listing, then filters with HAVING, so every review is read. |
| 26 | 123.05 | Correlated subquery runs once per row to find each brand's maximum price. |
| 45 | 113.81 | Joins and groups every available listing with its wishlist rows before applying LIMIT 10. |
| 14 | 99.99 | Joins all available listings to Pricing for every brand before grouping. |

## Optimization Notes

| # | Problem | Suggested fix | Before (ms) | After (ms) |
|---|---------|---------------|-------------|------------|
| 26 | Correlated subquery per row | Replace with `RANK() OVER (PARTITION BY brand_id ORDER BY final_price DESC)` and keep rank 1 | 123.05 | 97.90 |
| 23 | Quadratic pair count | Add `LIMIT`, or return a per-city count (`GROUP BY city_id`) instead of every pair | 247,135 | not measured |
| 4, 10, 11 | Return tens of thousands of rows | Paginate with `LIMIT`/`OFFSET` in the application | 138.81 / 58.84 / 75.31 | not measured |

## Query Results With Zero Rows

Queries 25 and 46 return 0 rows on the generated data (no seller has more than 5 listings, and no available listing has a 15% or larger discount). Their timings show the cost of finding no match. Real data will give different timings.

## Schema and Query Issues Found While Running on MySQL

These stop `03_schema.sql` and `04_queries.sql` from running as written. The timings above used patched local copies. The files in this repository were not changed.

| Where | Problem | Local workaround |
|-------|---------|------------------|
| `03_schema.sql`, `Phone_Models` CHECK | `YEAR(CURRENT_DATE)` is not allowed in a CHECK constraint (error 3814) | Replaced with the constant 2100 |
| `03_schema.sql`, `Phone_Listings.condition` | `condition` is a reserved word, so the unquoted column fails (also in the `vw_active_listings` view and `sp_create_listing`) | Wrapped in backticks |
| `03_schema.sql`, trigger `trg_set_old_prices_non_current` | A trigger on `Pricing` updates `Pricing`, so every insert into `Pricing` fails with error 1442 | Dropped this trigger in the test database |
| `04_queries.sql`, Query 35 | Column `condition` is unquoted in the INSERT column list | Wrapped in backticks |
