# Database Normalization - Pocket Phone AP 2026

## Project Overview
Pocket Phone is a marketplace platform for buying and selling pre-owned and new phones. The platform allows users to browse phones by brand, check phone values, sell their devices, and purchase verified phones.

## Entities and Attributes (Unnormalized)

### Initial Entity Structure

**Users**
- user_id, username, email, password, phone_number, address, city, state, pincode, registration_date, user_type (buyer/seller/both)

**Phones**
- phone_id, brand_name, model_name, storage_capacity, ram, color, condition (new/good/fair), price, release_year, display_size, camera_specs, battery_capacity, processor, os_version, seller_id, listing_date, status (available/sold/reserved)

**Transactions**
- transaction_id, buyer_id, seller_id, phone_id, transaction_date, amount, payment_method, payment_status, shipping_address, order_status

**Phone_Listings**
- listing_id, phone_id, seller_id, listed_price, discount_percentage, is_verified, verification_date, listing_type (sell/today's drops/popular)

**Reviews**
- review_id, reviewer_id, phone_id, seller_id, rating, review_text, review_date

**Wishlist**
- wishlist_id, user_id, phone_id, added_date

**Brands**
- brand_id, brand_name, brand_logo, description, country_of_origin

---

## Normalization Process

### First Normal Form (1NF)
**Requirement**: Eliminate repeating groups and ensure atomic values.

**Issues Identified**:
1. `camera_specs` in Phones table may contain multiple values (e.g., "48MP + 12MP + 5MP")
2. `address` in Users table contains composite data (street, city, state, pincode)
3. `user_type` might have multiple values if user is both buyer and seller

**Solution**:

**Users (1NF)**
- user_id (PK)
- username
- email
- password
- phone_number
- street_address
- city
- state
- pincode
- registration_date

**Phones (1NF)**
- phone_id (PK)
- brand_id (FK)
- model_name
- storage_capacity
- ram
- color
- condition
- price
- release_year
- display_size
- battery_capacity
- processor
- os_version
- seller_id (FK)
- listing_date
- status

**Camera_Specs (1NF) - New Table**
- camera_id (PK)
- phone_id (FK)
- camera_type (front/rear_primary/rear_secondary/rear_tertiary)
- megapixels
- aperture

---

### Second Normal Form (2NF)
**Requirement**: Must be in 1NF and all non-key attributes must be fully dependent on the primary key.

**Issues Identified**:
1. In Phones table: `brand_name` depends only on `brand_id`, not on `phone_id`
2. In Transactions table: buyer and seller details are dependent on their IDs, not transaction_id
3. Phone specifications are dependent on phone_id but some attributes like `release_year` and basic specs might be model-specific, not listing-specific

**Solution**: Separate Brands and create Phone_Models

**Brands (2NF)**
- brand_id (PK)
- brand_name
- brand_logo
- description
- country_of_origin

**Phone_Models (2NF) - New Table**
- model_id (PK)
- brand_id (FK)
- model_name
- release_year
- display_size
- processor
- os_version
- battery_capacity

**Phone_Listings (2NF) - Modified**
- listing_id (PK)
- model_id (FK)
- seller_id (FK)
- storage_capacity
- ram
- color
- condition
- listed_price
- discount_percentage
- listing_date
- status
- is_verified
- verification_date
- listing_type

**Camera_Specs (2NF)**
- camera_id (PK)
- model_id (FK)
- camera_type
- megapixels
- aperture

**Transactions (2NF)**
- transaction_id (PK)
- listing_id (FK)
- buyer_id (FK)
- transaction_date
- amount
- payment_method
- payment_status
- order_status

**Shipping_Details (2NF) - New Table**
- shipping_id (PK)
- transaction_id (FK)
- street_address
- city
- state
- pincode
- shipping_status
- tracking_number

**Reviews (2NF)**
- review_id (PK)
- reviewer_id (FK)
- listing_id (FK)
- rating
- review_text
- review_date

**Wishlist (2NF)**
- wishlist_id (PK)
- user_id (FK)
- listing_id (FK)
- added_date

---

### Third Normal Form (3NF)
**Requirement**: Must be in 2NF and no transitive dependencies (non-key attributes should not depend on other non-key attributes).

**Issues Identified**:
1. In Shipping_Details: `city` might determine `state` (transitive dependency)
2. In Phone_Models: `os_version` might be dependent on `release_year` or specific to brands
3. Price calculations: `discount_percentage` and `listed_price` might create dependency

**Solution**:

**Cities (3NF) - New Table**
- city_id (PK)
- city_name
- state_id (FK)

**States (3NF) - New Table**
- state_id (PK)
- state_name
- country

**Users (3NF) - Modified**
- user_id (PK)
- username
- email
- password
- phone_number
- street_address
- city_id (FK)
- pincode
- registration_date

**Shipping_Details (3NF) - Modified**
- shipping_id (PK)
- transaction_id (FK)
- street_address
- city_id (FK)
- pincode
- shipping_status
- tracking_number
- shipped_date
- delivered_date

**Pricing (3NF) - New Table**
- price_id (PK)
- listing_id (FK)
- base_price
- discount_amount
- final_price
- price_updated_date

---

## Final Normalized Schema (3NF)

### Core Tables

**1. Users**
- user_id (PK)
- username
- email
- password
- phone_number
- street_address
- city_id (FK → Cities)
- pincode
- registration_date

**2. States**
- state_id (PK)
- state_name
- country

**3. Cities**
- city_id (PK)
- city_name
- state_id (FK → States)

**4. Brands**
- brand_id (PK)
- brand_name
- brand_logo
- description
- country_of_origin

**5. Phone_Models**
- model_id (PK)
- brand_id (FK → Brands)
- model_name
- release_year
- display_size
- processor
- os_version
- battery_capacity

**6. Camera_Specs**
- camera_id (PK)
- model_id (FK → Phone_Models)
- camera_type
- megapixels
- aperture

**7. Phone_Listings**
- listing_id (PK)
- model_id (FK → Phone_Models)
- seller_id (FK → Users)
- storage_capacity
- ram
- color
- condition
- listing_date
- status
- is_verified
- verification_date
- listing_type

**8. Pricing**
- price_id (PK)
- listing_id (FK → Phone_Listings)
- base_price
- discount_amount
- final_price
- price_updated_date

**9. Transactions**
- transaction_id (PK)
- listing_id (FK → Phone_Listings)
- buyer_id (FK → Users)
- transaction_date
- amount
- payment_method
- payment_status
- order_status

**10. Shipping_Details**
- shipping_id (PK)
- transaction_id (FK → Transactions)
- street_address
- city_id (FK → Cities)
- pincode
- shipping_status
- tracking_number
- shipped_date
- delivered_date

**11. Reviews**
- review_id (PK)
- reviewer_id (FK → Users)
- listing_id (FK → Phone_Listings)
- rating
- review_text
- review_date

**12. Wishlist**
- wishlist_id (PK)
- user_id (FK → Users)
- listing_id (FK → Phone_Listings)
- added_date

---

## Functional Dependencies

### Users
- user_id → username, email, password, phone_number, street_address, city_id, pincode, registration_date

### Cities
- city_id → city_name, state_id
- city_name, state_id → city_id (unique constraint)

### States
- state_id → state_name, country

### Brands
- brand_id → brand_name, brand_logo, description, country_of_origin

### Phone_Models
- model_id → brand_id, model_name, release_year, display_size, processor, os_version, battery_capacity

### Camera_Specs
- camera_id → model_id, camera_type, megapixels, aperture

### Phone_Listings
- listing_id → model_id, seller_id, storage_capacity, ram, color, condition, listing_date, status, is_verified, verification_date, listing_type

### Pricing
- price_id → listing_id, base_price, discount_amount, final_price, price_updated_date
- listing_id → current pricing (one active price per listing)

### Transactions
- transaction_id → listing_id, buyer_id, transaction_date, amount, payment_method, payment_status, order_status

### Shipping_Details
- shipping_id → transaction_id, street_address, city_id, pincode, shipping_status, tracking_number, shipped_date, delivered_date

### Reviews
- review_id → reviewer_id, listing_id, rating, review_text, review_date

### Wishlist
- wishlist_id → user_id, listing_id, added_date
- user_id, listing_id → wishlist_id (unique constraint)

---

## Advantages of This Normalized Design

1. **Data Integrity**: Eliminates redundancy and ensures consistency
2. **Scalability**: Easy to add new brands, models, and phone variants
3. **Maintainability**: Changes to phone specifications affect only relevant records
4. **Flexibility**: Supports multiple camera configurations per phone model
5. **Location Management**: Centralized city/state management prevents inconsistencies
6. **Price History**: Separate pricing table allows tracking price changes over time
7. **Transaction Tracking**: Clean separation between listings, transactions, and shipping

---

## Potential Denormalization Considerations

For performance optimization in a production environment, consider:

1. **Read-heavy queries**: Cache frequently accessed phone listing details
2. **Brand popularity**: Maintain a denormalized count of listings per brand
3. **User statistics**: Store aggregated data like total sales, average rating
4. **Search optimization**: Create indexed views combining Phone_Models, Brands, and Listings

These denormalizations should be implemented only after profiling indicates performance bottlenecks.
