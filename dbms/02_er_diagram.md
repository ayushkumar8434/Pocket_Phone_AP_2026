# Entity-Relationship Diagram - Pocket Phone AP 2026

## Visual ER Diagram

![Pocket Phone ER Diagram](./er_diagram_pocket_phone.png)

**Tagline**: *Buy • Sell • Review • Track - Your Trusted Phone Marketplace*

---

## Diagram Overview

The above Entity-Relationship Diagram represents the complete database structure for the **Pocket Phone AP 2026** marketplace platform. The diagram uses color-coding to organize entities into logical groups:

### Entity Categories (Color-Coded)

| Color | Category | Entities | Purpose |
|-------|----------|----------|---------|
| 🔵 **Blue** | Location Entities | States, Cities | Geographical data management |
| 🟢 **Green** | User Entities | Users | User account and authentication |
| 🟠 **Orange** | Product Entities | Brands, Phone_Models, Camera_Specs | Phone catalog and specifications |
| 🟣 **Purple** | Listing Entities | Phone_Listings, Pricing | Individual phone listings and pricing |
| 🔴 **Red/Pink** | Transaction Entities | Transactions, Shipping_Details | Purchase and delivery tracking |
| 🟢 **Light Green** | Interaction Entities | Reviews, Wishlist | User engagement features |

---

## Legend

- **PK** = Primary Key
- **FK** = Foreign Key
- **Entity Box** = Database table
- **Diamond** = Relationship
- **Line** = Connection between entities
- **1** = One (cardinality)
- **M** = Many (cardinality)

---

## ER Diagram Description

This document provides detailed documentation for the Entity-Relationship model shown in the visual diagram above.

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

## Relationships (As Shown in Diagram)

### Location Relationships

#### 1. **contains** (STATES → CITIES)
- **Type**: One-to-Many (1:M)
- **Description**: One state contains multiple cities
- **Foreign Key**: Cities.state_id → States.state_id
- **Business Rule**: A city must belong to exactly one state

#### 2. **has_residents** (CITIES → USERS)
- **Type**: One-to-Many (1:M)
- **Description**: One city has multiple user residents
- **Foreign Key**: Users.city_id → Cities.city_id
- **Business Rule**: Every user must have a city

#### 3. **ships_to** (CITIES → SHIPPING_DETAILS)
- **Type**: One-to-Many (1:M)
- **Description**: One city can have multiple shipments
- **Foreign Key**: Shipping_Details.city_id → Cities.city_id
- **Business Rule**: Shipping address must have a valid city

---

### Product Catalog Relationships

#### 4. **manufactures** (BRANDS → PHONE_MODELS)
- **Type**: One-to-Many (1:M)
- **Description**: One brand manufactures multiple phone models
- **Foreign Key**: Phone_Models.brand_id → Brands.brand_id
- **Business Rule**: Each phone model belongs to one brand (marked as UNIQUE)

#### 5. **has_camera** (PHONE_MODELS → CAMERA_SPECS)
- **Type**: One-to-Many (1:M)
- **Description**: One phone model can have multiple cameras
- **Foreign Key**: Camera_Specs.model_id → Phone_Models.model_id
- **Business Rule**: Cameras are specific to a phone model

#### 6. **model_of** (PHONE_MODELS → PHONE_LISTINGS)
- **Type**: One-to-Many (1:M)
- **Description**: One phone model can have multiple listings
- **Foreign Key**: Phone_Listings.model_id → Phone_Models.model_id
- **Business Rule**: Every listing must reference a valid phone model

---

### Listing and Pricing Relationships

#### 7. **priced_at** (PHONE_LISTINGS → PRICING)
- **Type**: One-to-Many (1:M)
- **Description**: One listing can have multiple pricing records (price history)
- **Foreign Key**: Pricing.listing_id → Phone_Listings.listing_id
- **Business Rule**: Active listing has one current price

#### 8. **sells** (USERS → PHONE_LISTINGS)
- **Type**: One-to-Many (1:M)
- **Description**: One user (seller) can have multiple listings
- **Foreign Key**: Phone_Listings.seller_id → Users.user_id
- **Business Rule**: Only registered users can sell

---

### Transaction Relationships

#### 9. **sold_via** (PHONE_LISTINGS → TRANSACTIONS)
- **Type**: One-to-Many (1:M)
- **Description**: One listing can be involved in multiple transactions
- **Foreign Key**: Transactions.listing_id → Phone_Listings.listing_id
- **Business Rule**: Transaction freezes listing status

#### 10. **purchases** (USERS → TRANSACTIONS)
- **Type**: One-to-Many (1:M)
- **Description**: One user (buyer) can make multiple purchases
- **Foreign Key**: Transactions.buyer_id → Users.user_id
- **Business Rule**: Buyer and seller must be different users

#### 11. **has_shipping** (TRANSACTIONS → SHIPPING_DETAILS)
- **Type**: One-to-One (1:1)
- **Description**: Each transaction has exactly one shipping detail
- **Foreign Key**: Shipping_Details.transaction_id → Transactions.transaction_id
- **Business Rule**: Shipping created after successful payment

---

### User Interaction Relationships

#### 12. **writes** (USERS → REVIEWS)
- **Type**: One-to-Many (1:M)
- **Description**: One user can write multiple reviews
- **Foreign Key**: Reviews.reviewer_id → Users.user_id
- **Business Rule**: Only verified buyers can review

#### 13. **reviewed_in** (PHONE_LISTINGS → REVIEWS)
- **Type**: One-to-Many (1:M)
- **Description**: One listing can have multiple reviews
- **Foreign Key**: Reviews.listing_id → Phone_Listings.listing_id
- **Business Rule**: Rating must be between 1-5

#### 14. **creates** (USERS → WISHLIST)
- **Type**: One-to-Many (1:M)
- **Description**: One user can create multiple wishlist entries
- **Foreign Key**: Wishlist.user_id → Users.user_id
- **Business Rule**: User can wishlist multiple items

#### 15. **wished_in** (PHONE_LISTINGS → WISHLIST)
- **Type**: One-to-Many (1:M)
- **Description**: One listing can be wishlisted by multiple users
- **Foreign Key**: Wishlist.listing_id → Phone_Listings.listing_id
- **Business Rule**: Same user cannot wishlist same item twice

---

## Database Flow and Key Features

### 1. **User Registration & Location**
```
STATES (1) → contains → (M) CITIES (1) → has_residents → (M) USERS
```
- Users register with location data (city, state, country)
- Hierarchical location structure ensures data consistency

### 2. **Product Catalog**
```
BRANDS (1) → manufactures → (M) PHONE_MODELS (1) → has_camera → (M) CAMERA_SPECS
```
- Brands own multiple phone models
- Each model has detailed camera specifications
- Separation allows reusability and consistency

### 3. **Listing Creation**
```
USERS (seller) → sells → PHONE_LISTINGS ← model_of ← PHONE_MODELS
PHONE_LISTINGS (1) → priced_at → (M) PRICING
```
- Sellers create listings based on existing phone models
- Each listing has pricing information with discount support
- Price history tracking enabled

### 4. **Purchase Flow**
```
USERS (buyer) → purchases → TRANSACTIONS ← sold_via ← PHONE_LISTINGS
TRANSACTIONS (1) → has_shipping → (1) SHIPPING_DETAILS → ships_to → CITIES
```
- Buyer initiates transaction on a listing
- Transaction creates unique shipping details
- Shipping links back to city for address validation

### 5. **User Engagement**
```
USERS → writes → REVIEWS ← reviewed_in ← PHONE_LISTINGS
USERS → creates → WISHLIST ← wished_in ← PHONE_LISTINGS
```
- Users can review purchased phones
- Users can wishlist phones for future purchase
- Reviews and wishlists enhance user experience

---

## Key Constraints and Validations

### Primary Key Constraints
- All entities have auto-increment integer primary keys
- Ensures unique identification for each record

### Foreign Key Constraints
| Child Table | Parent Table | Constraint |
|------------|--------------|------------|
| Cities | States | ON DELETE RESTRICT |
| Users | Cities | ON DELETE RESTRICT |
| Phone_Models | Brands | ON DELETE RESTRICT |
| Camera_Specs | Phone_Models | ON DELETE CASCADE |
| Phone_Listings | Phone_Models | ON DELETE RESTRICT |
| Phone_Listings | Users (seller) | ON DELETE RESTRICT |
| Pricing | Phone_Listings | ON DELETE CASCADE |
| Transactions | Phone_Listings | ON DELETE RESTRICT |
| Transactions | Users (buyer) | ON DELETE RESTRICT |
| Shipping_Details | Transactions | ON DELETE RESTRICT |
| Shipping_Details | Cities | ON DELETE RESTRICT |
| Reviews | Users | ON DELETE RESTRICT |
| Reviews | Phone_Listings | ON DELETE CASCADE |
| Wishlist | Users | ON DELETE CASCADE |
| Wishlist | Phone_Listings | ON DELETE CASCADE |

### Unique Constraints
- **Users.email** - No duplicate email addresses
- **Brands.brand_name** - Each brand name is unique (as shown in diagram)
- **Wishlist (user_id, listing_id)** - User cannot wishlist same item twice
- **Cities (city_name, state_id)** - City name unique within a state

### Check Constraints
- **Reviews.rating** ∈ [1, 5] - Rating must be 1 to 5 stars
- **Pricing.final_price** ≥ 0 - Price cannot be negative
- **Pricing.discount_amount** ≥ 0 - Discount cannot be negative
- **Phone_Models.release_year** - Valid year range
- **Phone_Listings.status** ∈ {available, sold, reserved, removed}
- **Transactions.payment_status** ∈ {pending, completed, failed, refunded}

---

## Entity Details (From Diagram)

### Location Entities (Blue)

**STATES**
- **Primary Key**: state_id
- **Attributes**: state_name, country
- **Color Code**: Light Blue (#A8D8EA)

**CITIES**
- **Primary Key**: city_id
- **Foreign Key**: state_id
- **Attributes**: city_name, state_id (FK)
- **Color Code**: Light Blue (#A8D8EA)

### User Entities (Green)

**USERS**
- **Primary Key**: user_id
- **Foreign Key**: city_id
- **Unique**: email (marked as UNIQUE in diagram)
- **Attributes**: username, email, password, phone_number, street_address, city_id, pincode, registration_date
- **Color Code**: Light Green (#B8E6B8)
- **Roles**: Can act as both buyer and seller

### Product Entities (Orange)

**BRANDS**
- **Primary Key**: brand_id
- **Unique**: brand_name (marked as UNIQUE in diagram)
- **Attributes**: brand_name, brand_logo, description, country_of_origin
- **Color Code**: Light Orange (#FFD7BE)

**PHONE_MODELS**
- **Primary Key**: model_id
- **Foreign Key**: brand_id
- **Attributes**: model_name, release_year, display_size, processor, os_version, battery_capacity
- **Color Code**: Light Orange (#FFD7BE)

**CAMERA_SPECS**
- **Primary Key**: camera_id
- **Foreign Key**: model_id
- **Attributes**: camera_type, megapixels, aperture
- **Color Code**: Light Salmon (#FFA07A)
- **Note**: Multiple cameras per model supported

### Listing Entities (Purple)

**PHONE_LISTINGS**
- **Primary Key**: listing_id
- **Foreign Keys**: model_id, seller_id (FK to Users)
- **Attributes**: storage_capacity, ram, color, condition, listing_date, status, is_verified, verification_date, listing_type
- **Color Code**: Light Purple (#E6D5FF)
- **Status Values**: available, sold, reserved, removed
- **Listing Types**: regular, popular, todays_drop, good_deal, featured

**PRICING**
- **Primary Key**: price_id
- **Foreign Key**: listing_id
- **Attributes**: base_price, discount_amount, final_price, price_updated_date
- **Color Code**: Light Purple (#E6D5FF)
- **Formula**: final_price = base_price - discount_amount

### Transaction Entities (Red/Pink)

**TRANSACTIONS**
- **Primary Key**: transaction_id
- **Foreign Keys**: listing_id, buyer_id (FK to Users)
- **Attributes**: transaction_date, amount, payment_method, payment_status, order_status
- **Color Code**: Light Red/Pink (#FFB6C1)
- **Payment Methods**: credit_card, debit_card, UPI, net_banking, wallet, COD
- **Payment Status**: pending, completed, failed, refunded
- **Order Status**: processing, shipped, delivered, cancelled

**SHIPPING_DETAILS**
- **Primary Key**: shipping_id
- **Foreign Keys**: transaction_id (1:1), city_id
- **Attributes**: street_address, pincode, shipping_status, tracking_number, shipped_date, delivered_date
- **Color Code**: Light Cyan (#B0E0E6)

### Interaction Entities (Light Green)

**REVIEWS**
- **Primary Key**: review_id
- **Foreign Keys**: reviewer_id (FK to Users), listing_id
- **Attributes**: rating (1-5), review_text, review_date
- **Color Code**: Pale Green (#D4EDDA)

**WISHLIST**
- **Primary Key**: wishlist_id
- **Foreign Keys**: user_id, listing_id
- **Attributes**: added_date
- **Color Code**: Pale Green (#D4EDDA)
- **Unique Constraint**: (user_id, listing_id)

---

## Design Patterns and Best Practices

### 1. **Normalization (3NF)**
- All entities are in Third Normal Form
- No transitive dependencies
- Minimal data redundancy

### 2. **Surrogate Keys**
- All tables use auto-increment integer primary keys
- Simplifies relationships and indexing
- Better performance than composite keys

### 3. **Lookup Tables**
- States and Cities act as lookup/reference tables
- Brands serve as master data
- Phone_Models provide reusable catalog

### 4. **Historical Data**
- Pricing table maintains price history
- is_current flag identifies active price
- Transaction history preserved

### 5. **Referential Integrity**
- Foreign key constraints enforce relationships
- RESTRICT prevents orphaned records
- CASCADE for dependent data (e.g., Camera_Specs)

### 6. **Data Validation**
- UNIQUE constraints prevent duplicates
- CHECK constraints validate data ranges
- NOT NULL ensures required fields

### 7. **Separation of Concerns**
- User management separated from transactions
- Product catalog independent of listings
- Pricing decoupled from listings (price history)

---

## Query Patterns and Use Cases

### Common Query Scenarios

#### 1. Browse Phones by Brand
```
BRANDS → PHONE_MODELS → PHONE_LISTINGS (status='available') → PRICING (is_current=true)
```

#### 2. Search Available Listings
```
PHONE_LISTINGS (status='available') 
  JOIN PHONE_MODELS 
  JOIN BRANDS 
  JOIN PRICING (is_current=true)
```

#### 3. View User's Purchase History
```
USERS → TRANSACTIONS → PHONE_LISTINGS → PHONE_MODELS → BRANDS
```

#### 4. Track Order Shipment
```
TRANSACTIONS → SHIPPING_DETAILS → CITIES → STATES
```

#### 5. Get Phone Reviews
```
PHONE_LISTINGS → REVIEWS → USERS (reviewer)
```

#### 6. User Wishlist
```
USERS → WISHLIST → PHONE_LISTINGS → PHONE_MODELS → BRANDS → PRICING
```

#### 7. Seller Dashboard
```
USERS (seller) → PHONE_LISTINGS → TRANSACTIONS → SHIPPING_DETAILS
```

---

## Indexes for Performance

### Primary Indexes (Automatic)
- All primary keys automatically indexed

### Foreign Key Indexes (Recommended)
```sql
-- Location indexes
CREATE INDEX idx_cities_state ON Cities(state_id);
CREATE INDEX idx_users_city ON Users(city_id);

-- Product indexes
CREATE INDEX idx_models_brand ON Phone_Models(brand_id);
CREATE INDEX idx_camera_model ON Camera_Specs(model_id);

-- Listing indexes
CREATE INDEX idx_listings_model ON Phone_Listings(model_id);
CREATE INDEX idx_listings_seller ON Phone_Listings(seller_id);
CREATE INDEX idx_listings_status ON Phone_Listings(status);
CREATE INDEX idx_pricing_listing ON Pricing(listing_id);

-- Transaction indexes
CREATE INDEX idx_trans_listing ON Transactions(listing_id);
CREATE INDEX idx_trans_buyer ON Transactions(buyer_id);
CREATE INDEX idx_shipping_trans ON Shipping_Details(transaction_id);
CREATE INDEX idx_shipping_city ON Shipping_Details(city_id);

-- Interaction indexes
CREATE INDEX idx_reviews_listing ON Reviews(listing_id);
CREATE INDEX idx_reviews_user ON Reviews(reviewer_id);
CREATE INDEX idx_wishlist_user ON Wishlist(user_id);
CREATE INDEX idx_wishlist_listing ON Wishlist(listing_id);
```

---

## Platform Features Supported

### ✅ Core Marketplace Features
- 📱 Phone listings with detailed specifications
- 💰 Dynamic pricing with discounts
- 🛒 Shopping cart and checkout
- 📦 Order tracking and shipment
- ⭐ Product reviews and ratings
- ❤️ Wishlist management

### ✅ User Features  
- 👤 User registration and authentication
- 🏠 Location-based services
- 💼 Dual role (buyer & seller)
- 📊 Purchase history
- 📝 Review history

### ✅ Admin Features
- 🏢 Brand management
- 📱 Phone model catalog
- ✅ Listing verification
- 📈 Sales analytics (via queries)
- 🚚 Shipment tracking

### ✅ Business Features
- 🎯 Featured listings (popular, today's drops)
- 💸 Discount management
- 📊 Price history tracking
- 🔍 Advanced search capabilities
- 📍 Location-based filtering

---

## Summary

This ER diagram represents a **complete, normalized (3NF) database schema** for the Pocket Phone AP 2026 marketplace with:

- **12 entities** organized into 6 logical categories
- **15 relationships** with proper cardinality
- **Foreign key integrity** with appropriate constraints
- **Unique constraints** preventing duplicate data
- **Check constraints** ensuring data validity
- **Historical tracking** for pricing and transactions
- **Scalable design** supporting future enhancements

The schema supports the complete lifecycle of a phone marketplace: **Buy • Sell • Review • Track** - making it a trusted platform for phone trading.

---

*For SQL implementation details, refer to `03_schema.sql`*  
*For normalization analysis, refer to `01_normalization.md`*
