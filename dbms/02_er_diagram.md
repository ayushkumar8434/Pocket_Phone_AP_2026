# Entity-Relationship Diagram - Pocket Phone AP 2026

## ER Diagram Description

This document describes the Entity-Relationship model for the Pocket Phone marketplace database. The actual visual diagram is provided in `02_er_diagram.mermaid`.

---

## Entities

### 1. **Users**
- **Description**: Stores information about registered users (buyers and sellers)
- **Primary Key**: user_id
- **Attributes**:
  - user_id (PK)
  - username
  - email (unique)
  - password
  - phone_number
  - street_address
  - city_id (FK)
  - pincode
  - registration_date

### 2. **States**
- **Description**: Stores state information
- **Primary Key**: state_id
- **Attributes**:
  - state_id (PK)
  - state_name
  - country

### 3. **Cities**
- **Description**: Stores city information linked to states
- **Primary Key**: city_id
- **Attributes**:
  - city_id (PK)
  - city_name
  - state_id (FK)

### 4. **Brands**
- **Description**: Stores phone brand/manufacturer information
- **Primary Key**: brand_id
- **Attributes**:
  - brand_id (PK)
  - brand_name (unique)
  - brand_logo
  - description
  - country_of_origin

### 5. **Phone_Models**
- **Description**: Stores base phone model specifications
- **Primary Key**: model_id
- **Attributes**:
  - model_id (PK)
  - brand_id (FK)
  - model_name
  - release_year
  - display_size
  - processor
  - os_version
  - battery_capacity

### 6. **Camera_Specs**
- **Description**: Stores camera specifications for each phone model
- **Primary Key**: camera_id
- **Attributes**:
  - camera_id (PK)
  - model_id (FK)
  - camera_type (front/rear_primary/rear_secondary/rear_tertiary)
  - megapixels
  - aperture

### 7. **Phone_Listings**
- **Description**: Stores individual phone listings by sellers
- **Primary Key**: listing_id
- **Attributes**:
  - listing_id (PK)
  - model_id (FK)
  - seller_id (FK)
  - storage_capacity
  - ram
  - color
  - condition
  - listing_date
  - status
  - is_verified
  - verification_date
  - listing_type

### 8. **Pricing**
- **Description**: Stores pricing information for listings
- **Primary Key**: price_id
- **Attributes**:
  - price_id (PK)
  - listing_id (FK)
  - base_price
  - discount_amount
  - final_price
  - price_updated_date

### 9. **Transactions**
- **Description**: Stores purchase transactions
- **Primary Key**: transaction_id
- **Attributes**:
  - transaction_id (PK)
  - listing_id (FK)
  - buyer_id (FK)
  - transaction_date
  - amount
  - payment_method
  - payment_status
  - order_status

### 10. **Shipping_Details**
- **Description**: Stores shipping information for transactions
- **Primary Key**: shipping_id
- **Attributes**:
  - shipping_id (PK)
  - transaction_id (FK)
  - street_address
  - city_id (FK)
  - pincode
  - shipping_status
  - tracking_number
  - shipped_date
  - delivered_date

### 11. **Reviews**
- **Description**: Stores user reviews for purchased phones
- **Primary Key**: review_id
- **Attributes**:
  - review_id (PK)
  - reviewer_id (FK)
  - listing_id (FK)
  - rating
  - review_text
  - review_date

### 12. **Wishlist**
- **Description**: Stores user wishlists
- **Primary Key**: wishlist_id
- **Attributes**:
  - wishlist_id (PK)
  - user_id (FK)
  - listing_id (FK)
  - added_date

---

## Relationships

### 1. **Users - Cities** (Many-to-One)
- Multiple users can belong to one city
- **Cardinality**: N:1
- **Foreign Key**: Users.city_id → Cities.city_id

### 2. **Cities - States** (Many-to-One)
- Multiple cities belong to one state
- **Cardinality**: N:1
- **Foreign Key**: Cities.state_id → States.state_id

### 3. **Phone_Models - Brands** (Many-to-One)
- Multiple phone models belong to one brand
- **Cardinality**: N:1
- **Foreign Key**: Phone_Models.brand_id → Brands.brand_id

### 4. **Camera_Specs - Phone_Models** (Many-to-One)
- Multiple cameras can belong to one phone model
- **Cardinality**: N:1
- **Foreign Key**: Camera_Specs.model_id → Phone_Models.model_id

### 5. **Phone_Listings - Phone_Models** (Many-to-One)
- Multiple listings can reference the same phone model
- **Cardinality**: N:1
- **Foreign Key**: Phone_Listings.model_id → Phone_Models.model_id

### 6. **Phone_Listings - Users (Seller)** (Many-to-One)
- One seller can have multiple listings
- **Cardinality**: N:1
- **Foreign Key**: Phone_Listings.seller_id → Users.user_id

### 7. **Pricing - Phone_Listings** (One-to-One or One-to-Many)
- Each listing has pricing information (can track price history)
- **Cardinality**: 1:1 (current) or 1:N (historical)
- **Foreign Key**: Pricing.listing_id → Phone_Listings.listing_id

### 8. **Transactions - Phone_Listings** (Many-to-One)
- Multiple transactions can reference the same listing (bid history, multiple purchases)
- **Cardinality**: N:1
- **Foreign Key**: Transactions.listing_id → Phone_Listings.listing_id

### 9. **Transactions - Users (Buyer)** (Many-to-One)
- One buyer can have multiple transactions
- **Cardinality**: N:1
- **Foreign Key**: Transactions.buyer_id → Users.user_id

### 10. **Shipping_Details - Transactions** (One-to-One)
- Each transaction has one shipping record
- **Cardinality**: 1:1
- **Foreign Key**: Shipping_Details.transaction_id → Transactions.transaction_id

### 11. **Shipping_Details - Cities** (Many-to-One)
- Multiple shipments can go to the same city
- **Cardinality**: N:1
- **Foreign Key**: Shipping_Details.city_id → Cities.city_id

### 12. **Reviews - Users** (Many-to-One)
- One user can write multiple reviews
- **Cardinality**: N:1
- **Foreign Key**: Reviews.reviewer_id → Users.user_id

### 13. **Reviews - Phone_Listings** (Many-to-One)
- One listing can have multiple reviews
- **Cardinality**: N:1
- **Foreign Key**: Reviews.listing_id → Phone_Listings.listing_id

### 14. **Wishlist - Users** (Many-to-One)
- One user can have multiple wishlist items
- **Cardinality**: N:1
- **Foreign Key**: Wishlist.user_id → Users.user_id

### 15. **Wishlist - Phone_Listings** (Many-to-One)
- One listing can be in multiple users' wishlists
- **Cardinality**: N:1
- **Foreign Key**: Wishlist.listing_id → Phone_Listings.listing_id

---

## Cardinality Summary

| Relationship | Parent Entity | Child Entity | Type |
|--------------|--------------|--------------|------|
| Lives In | Cities | Users | 1:N |
| Located In | States | Cities | 1:N |
| Manufactures | Brands | Phone_Models | 1:N |
| Has Camera | Phone_Models | Camera_Specs | 1:N |
| Model Of | Phone_Models | Phone_Listings | 1:N |
| Sells | Users | Phone_Listings | 1:N |
| Priced At | Phone_Listings | Pricing | 1:N |
| For Listing | Phone_Listings | Transactions | 1:N |
| Purchases | Users | Transactions | 1:N |
| Has Shipping | Transactions | Shipping_Details | 1:1 |
| Ships To | Cities | Shipping_Details | 1:N |
| Writes | Users | Reviews | 1:N |
| Reviews For | Phone_Listings | Reviews | 1:N |
| Adds to Wishlist | Users | Wishlist | 1:N |
| Wished By | Phone_Listings | Wishlist | 1:N |

---

## Business Rules

1. A user must have a valid city_id before registration
2. A phone listing must reference a valid phone model
3. Only registered users can sell phones (seller_id must exist in Users)
4. A transaction must have both a valid buyer and a valid listing
5. A listing can only be sold once (status changes to 'sold')
6. Reviews can only be written by users who purchased the phone
7. A user cannot add the same listing to wishlist multiple times (unique constraint)
8. Shipping details are created only after a successful transaction
9. Pricing must have a final_price calculated from base_price and discount_amount
10. A phone model must belong to a valid brand

---

## Constraints

### Primary Keys
- All entities have a single-attribute primary key (surrogate keys)

### Foreign Keys
- All foreign key constraints enforce referential integrity
- ON DELETE restrictions:
  - Users: RESTRICT (cannot delete if has listings or transactions)
  - Phone_Listings: RESTRICT (cannot delete if has transactions)
  - Transactions: RESTRICT (cannot delete if has shipping)
  - Cities, States, Brands, Phone_Models: RESTRICT

### Unique Constraints
- Users.email
- Brands.brand_name
- Wishlist(user_id, listing_id)

### Check Constraints
- Reviews.rating BETWEEN 1 AND 5
- Pricing.final_price >= 0
- Pricing.discount_amount >= 0
- Phone_Listings.status IN ('available', 'sold', 'reserved')
- Transactions.payment_status IN ('pending', 'completed', 'failed', 'refunded')
- Transactions.order_status IN ('processing', 'shipped', 'delivered', 'cancelled')

### NOT NULL Constraints
- All primary keys
- All foreign keys
- Essential attributes like email, username, model_name, brand_name, etc.

---

## Indexes (Recommended)

### Primary Indexes (Automatic)
- All primary keys automatically indexed

### Foreign Key Indexes
- Users.city_id
- Cities.state_id
- Phone_Models.brand_id
- Camera_Specs.model_id
- Phone_Listings.model_id
- Phone_Listings.seller_id
- Pricing.listing_id
- Transactions.listing_id
- Transactions.buyer_id
- Shipping_Details.transaction_id
- Shipping_Details.city_id
- Reviews.reviewer_id
- Reviews.listing_id
- Wishlist.user_id
- Wishlist.listing_id

### Additional Indexes for Performance
- Users.email (unique index)
- Brands.brand_name (unique index)
- Phone_Listings.status
- Phone_Listings.listing_type
- Transactions.transaction_date
- Reviews.rating

---

## ER Diagram Notation

- **Rectangle**: Entity
- **Oval**: Attribute
- **Diamond**: Relationship
- **Lines**: Connections
- **Crow's Foot**: Many (N)
- **Single Line**: One (1)
- **Double Rectangle**: Weak Entity (none in this schema)
- **Underline**: Primary Key
- **Dashed underline**: Foreign Key

---

## Notes

This ER model is designed to:
1. Support the full lifecycle of phone marketplace operations
2. Maintain data integrity through proper normalization (3NF)
3. Allow efficient querying for common operations (browsing, searching, purchasing)
4. Enable analytics and reporting on sales, popular models, and user behavior
5. Provide flexibility for future enhancements (e.g., auctions, negotiations)

For the visual representation, refer to `02_er_diagram.mermaid` which can be rendered using Mermaid-compatible tools.
