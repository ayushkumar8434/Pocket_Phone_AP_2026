# Query Timings - Pocket Phone AP 2026

Timings for every query in [04_queries.sql](./04_queries.sql), measured on PostgreSQL with `EXPLAIN (ANALYZE, BUFFERS)`. The full plan of every run is in [plans/](./plans/), one file per query (for example [plans/R1.txt](./plans/R1.txt) and [plans/W1.txt](./plans/W1.txt)). Each file holds the plans of the 3 runs.

## Test Environment

| Item | Value |
|------|-------|
| Database | PostgreSQL 17.11 (Homebrew), default settings (`shared_buffers` 128 MB, `work_mem` 4 MB) |
| Machine | Apple M4, 16 GB RAM, macOS, local connection |
| Schema | [03_schema.sql](./03_schema.sql) |
| Data | [06_sample_data.sql](./06_sample_data.sql): 10,000 users, 30 cities, 320 phone models, 960 camera specs, 30,000 listings, 36,000 price rows, 9,000 transactions, 9,000 shipping rows, 20,000 reviews, 6,000 wishlist rows |
| Statistics | `VACUUM (ANALYZE)` after loading |
| Date measured | 2026-11-23 |

## Method

1. Load the schema and the sample data, then run `VACUUM (ANALYZE)`.
2. Run each query 3 times with `EXPLAIN (ANALYZE, BUFFERS)` and read the `Execution Time` line. The average is the mean of the 3 runs.
3. Write queries (W1 to W10) run inside `BEGIN; ... ROLLBACK;`, so the data does not change. W3 uses `currval()`, so the timing script runs W2 first in the same transaction. Only W3 is timed.
4. The parameter values are the sample values written in `04_queries.sql`.
5. The scan type is read from the last run's plan. When a plan uses several scan types, all are listed. A dash means the plan has no scan node (a plain INSERT).

## Results

| Query | Type | What it does | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type |
|-------|------|--------------|-----------:|-----------:|-----------:|-------------:|-----------|
| R1 | READ | List users with their city, state, and country. | 11.298 | 8.357 | 4.361 | 8.005 | Seq Scan |
| R2 | READ | List all active phone brands. | 0.058 | 0.155 | 0.074 | 0.096 | Seq Scan |
| R3 | READ | List phone models with brand information. | 0.839 | 0.864 | 0.890 | 0.864 | Seq Scan |
| R4 | READ | List available listings with current price and seller location. | 27.486 | 23.721 | 21.090 | 24.099 | Seq Scan |
| R5 | READ | Get camera specifications for one model. | 0.036 | 0.037 | 0.034 | 0.036 | Index Scan, Bitmap Heap Scan |
| R6 | READ | Get the 50 most recent reviews with listing details. | 0.568 | 0.357 | 0.371 | 0.432 | Index Scan |
| R7 | READ | Search available phones by brand. | 4.607 | 4.995 | 5.167 | 4.923 | Index Scan, Seq Scan |
| R8 | READ | Find available phones within an inclusive price range. | 9.821 | 9.386 | 9.213 | 9.473 | Seq Scan |
| R9 | READ | Search available listings by partial model name. | 7.388 | 7.368 | 7.235 | 7.330 | Seq Scan |
| R10 | READ | Find verified available listings. | 6.551 | 6.369 | 6.757 | 6.559 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R11 | READ | Find phones in selected conditions. | 9.095 | 8.781 | 8.729 | 8.868 | Seq Scan |
| R12 | READ | Search by brand, storage, and condition. | 3.967 | 3.894 | 3.853 | 3.905 | Index Scan, Seq Scan |
| R13 | READ | Count total, available, and sold listings by brand. | 7.323 | 7.320 | 7.244 | 7.296 | Seq Scan |
| R14 | READ | Calculate available-price statistics by brand. | 9.835 | 9.715 | 10.266 | 9.939 | Seq Scan |
| R15 | READ | Total completed sales and revenue per seller. | 6.717 | 6.452 | 6.199 | 6.456 | Seq Scan |
| R16 | READ | Average rating for each reviewed listing. | 13.326 | 13.260 | 12.351 | 12.979 | Seq Scan |
| R17 | READ | Count users by city and state. | 2.330 | 2.239 | 2.356 | 2.308 | Seq Scan |
| R18 | READ | Monthly transaction volume and payment outcomes. | 4.460 | 4.579 | 4.221 | 4.420 | Seq Scan |
| R19 | READ | Show transactions with complete buyer, seller, and phone details. | 11.478 | 11.402 | 11.234 | 11.371 | Seq Scan |
| R20 | READ | Include phone models that have no listings. | 8.325 | 8.249 | 8.109 | 8.228 | Seq Scan |
| R21 | READ | Include users with no wishlist entries. | 4.104 | 4.082 | 4.358 | 4.181 | Seq Scan |
| R22 | READ | Show transaction, item, and shipping destination details. | 12.621 | 12.598 | 12.479 | 12.566 | Seq Scan |
| R23 | READ | Find pairs of users who live in the same city. | 927.355 | 957.917 | 926.579 | 937.284 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R24 | READ | Find available phones priced above the current-price average. | 12.375 | 12.305 | 12.544 | 12.408 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R25 | READ | Find sellers with more than five listings. | 3.072 | 3.154 | 3.085 | 3.104 | Index Only Scan, Seq Scan |
| R26 | READ | Find the most expensive available listing for every brand. | 37.318 | 37.144 | 36.966 | 37.143 | Index Scan, Seq Scan |
| R27 | READ | Find users who have both bought and sold phones. | 10.518 | 10.429 | 10.735 | 10.561 | Index Only Scan, Seq Scan |
| R28 | READ | Find sold listings with no reviews. | 4.258 | 4.181 | 4.444 | 4.294 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R29 | READ | Top ten models by listing count, with prices and sold counts. | 14.527 | 14.626 | 14.404 | 14.519 | Seq Scan |
| R30 | READ | Best-rated listings with at least three reviews. | 18.141 | 18.001 | 19.009 | 18.384 | Seq Scan |
| R31 | READ | Seller performance across listings, sales, revenue, and reviews. | 17.022 | 16.802 | 16.681 | 16.835 | Index Only Scan, Seq Scan |
| R32 | READ | Price distribution by storage capacity. | 8.178 | 8.300 | 8.501 | 8.326 | Seq Scan |
| R33 | READ | Completed daily sales for the last 30 days. | 0.304 | 0.264 | 0.265 | 0.278 | Index Scan, Bitmap Heap Scan |
| R34 | READ | Get today's available drops. | 0.326 | 0.681 | 0.996 | 0.668 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R35 | READ | Get the ten most-wishlisted available phones. | 24.973 | 21.104 | 19.388 | 21.822 | Seq Scan |
| R36 | READ | Get available good deals with at least a 15% discount. | 9.366 | 9.513 | 9.043 | 9.307 | Seq Scan |
| R37 | READ | Get a user's purchase history and shipping status. | 0.090 | 0.089 | 0.102 | 0.094 | Index Scan, Bitmap Heap Scan |
| R38 | READ | Get a user's selling history, including unsold listings. | 4.412 | 4.304 | 4.453 | 4.390 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R39 | READ | Get a user's wishlist with current prices. | 0.053 | 0.054 | 0.064 | 0.057 | Index Scan |
| R40 | READ | Search using multiple optional marketplace filters. | 5.618 | 5.882 | 5.351 | 5.617 | Index Scan, Seq Scan |
| R41 | READ | Estimate value from recent similar model listings. | 0.370 | 0.547 | 0.431 | 0.449 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R42 | READ | Find available listings in a selected state and optional city. | 10.671 | 11.768 | 10.960 | 11.133 | Index Scan, Bitmap Heap Scan, Seq Scan |
| R43 | READ | Return all admin dashboard headline statistics in one row. | 5.440 | 5.530 | 5.107 | 5.359 | Index Only Scan, Seq Scan |
| W1 | WRITE | Insert a new user. Store an application-generated password hash. | 0.469 | 0.436 | 0.385 | 0.430 | — |
| W2 | WRITE | Insert a new phone listing. | 0.799 | 0.714 | 0.718 | 0.744 | — |
| W3 | WRITE | Insert pricing for the listing just created in the session. | 1.011 | 0.991 | 1.378 | 1.127 | — |
| W4 | WRITE | Create a new pending transaction. | 0.756 | 1.059 | 0.873 | 0.896 | — |
| W5 | WRITE | Mark a listing sold only when it is still available or reserved. | 0.322 | 0.163 | 0.366 | 0.284 | Index Scan |
| W6 | WRITE | Update user contact information and last-login time. | 0.357 | 0.514 | 0.348 | 0.406 | Index Scan |
| W7 | WRITE | Complete a pending payment and confirm its order. | 3.872 | 2.870 | 2.599 | 3.114 | Index Scan |
| W8 | WRITE | Mark a shipment as shipped. | 0.158 | 0.482 | 0.499 | 0.380 | Index Scan |
| W9 | WRITE | Soft-deactivate a user. | 0.692 | 0.436 | 0.272 | 0.467 | Index Scan |
| W10 | WRITE | Delete old non-current price history for one listing. | 0.170 | 0.178 | 0.201 | 0.183 | Index Scan |

## Slowest Queries

| Query | What it does | Average (ms) |
|-------|--------------|-------------:|
| R23 | Find pairs of users who live in the same city. | 937.284 |
| R26 | Find the most expensive available listing for every brand. | 37.143 |
| R4 | List available listings with current price and seller location. | 24.099 |
| R35 | Get the ten most-wishlisted available phones. | 21.822 |
| R30 | Best-rated listings with at least three reviews. | 18.384 |

R23 is slow because it builds every pair of users in the same city: the plan produces about 1.66 million pairs and sorts them, with a 3 MB sort on disk. It grows with the square of the users per city. The other queries stay under 40 ms on this data. Most of them use a sequential scan because every table has at most 36,000 rows, and the planner reads a whole small table faster than it follows an index. The selective queries (R5, R6, R33, R37 and R39) and the UPDATE and DELETE queries (W5 to W10) use index scans.
