-- =============================================================
-- VEHICLE RENTAL SYSTEM - MySQL Schema
-- Target: MySQL 8.0+ (InnoDB, utf8mb4)
-- The application runs on SQLite by default (see backend/config.py);
-- this schema documents the production MySQL layout and can be used
-- with DATABASE_URL=mysql+pymysql://... .
-- =============================================================

CREATE DATABASE IF NOT EXISTS vehicle_rental CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vehicle_rental;

-- -------------------------------------------------------------
-- USERS (customers / owner accounts)
-- -------------------------------------------------------------
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    phone VARCHAR(30) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'customer',
    profile_image VARCHAR(500) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    is_email_verified TINYINT(1) NOT NULL DEFAULT 0,
    is_phone_verified TINYINT(1) NOT NULL DEFAULT 0,
    otp VARCHAR(6) NULL,
    otp_expiry DATETIME NULL,
    driving_license_no VARCHAR(60) NULL,
    driving_license_photo VARCHAR(500) NULL,
    address VARCHAR(500) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_role (role),
    INDEX idx_users_status (status),
    INDEX idx_users_created (created_at)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- OWNERS (KYC verified vehicle owners)
-- -------------------------------------------------------------
CREATE TABLE owners (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    address VARCHAR(500) NULL,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    rejection_reason VARCHAR(500) NULL,
    admin_note VARCHAR(500) NULL,
    verified_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_owners_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owners_verification (verification_status)
) ENGINE=InnoDB;

CREATE TABLE owner_documents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT UNSIGNED NOT NULL,
    doc_type VARCHAR(60) NOT NULL,
    url VARCHAR(500) NOT NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_owner_docs FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- ADMINS
-- -------------------------------------------------------------
CREATE TABLE admins (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'admin',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- VEHICLES
-- -------------------------------------------------------------
CREATE TABLE vehicles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT UNSIGNED NOT NULL,
    category VARCHAR(30) NOT NULL,
    brand VARCHAR(80) NOT NULL,
    model VARCHAR(80) NOT NULL,
    name VARCHAR(120) NOT NULL,
    registration_number VARCHAR(30) NOT NULL UNIQUE,
    fuel_type VARCHAR(20) NOT NULL,
    transmission VARCHAR(20) NOT NULL,
    seating_capacity INT NOT NULL,
    location_name VARCHAR(200) NOT NULL,
    latitude DOUBLE NULL,
    longitude DOUBLE NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    price_per_day DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    description TEXT NULL,
    features JSON NULL,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    rejection_reason VARCHAR(500) NULL,
    availability_status VARCHAR(30) NOT NULL DEFAULT 'available',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicles_owner FOREIGN KEY (owner_id) REFERENCES owners(id),
    INDEX idx_vehicles_category (category),
    INDEX idx_vehicles_approval (approval_status),
    INDEX idx_vehicles_availability (availability_status),
    INDEX idx_vehicles_location (location_name)
) ENGINE=InnoDB;

CREATE TABLE vehicle_images (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(500) NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_veh_images FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vehicle_documents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    doc_type VARCHAR(60) NOT NULL,
    url VARCHAR(500) NOT NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_veh_docs FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- BOOKINGS
-- -------------------------------------------------------------
CREATE TABLE bookings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(20) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    owner_id BIGINT UNSIGNED NOT NULL,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    pickup_location VARCHAR(200) NULL,
    return_location VARCHAR(200) NULL,
    rental_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    deposit_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    additional_charges DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    rejection_reason VARCHAR(500) NULL,
    cancel_reason VARCHAR(500) NULL,
    cancelled_by VARCHAR(20) NULL,
    cancelled_at DATETIME NULL,
    accepted_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id) REFERENCES users(id),
    CONSTRAINT fk_bookings_owner FOREIGN KEY (owner_id) REFERENCES owners(id),
    CONSTRAINT fk_bookings_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    INDEX idx_bookings_customer (customer_id),
    INDEX idx_bookings_owner (owner_id),
    INDEX idx_bookings_vehicle_status (vehicle_id, status),
    INDEX idx_bookings_start (start_datetime),
    INDEX idx_bookings_status (status)
) ENGINE=InnoDB;

CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    method VARCHAR(30) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reference VARCHAR(80) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at DATETIME NULL,
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inspections (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    inspection_type VARCHAR(20) NOT NULL,
    conducted_by_user_id BIGINT UNSIGNED NULL,
    condition_report TEXT NULL,
    notes TEXT NULL,
    photos JSON NULL,
    damage_notes TEXT NULL,
    additional_charges DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    handover_confirmed TINYINT(1) NOT NULL DEFAULT 0,
    returned_confirmed TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inspections_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_inspections_user FOREIGN KEY (conducted_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE cancellation_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    initiated_by VARCHAR(20) NOT NULL,
    reason VARCHAR(500) NULL,
    charge_applied DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    refund_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cancel_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE refunds (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'processing',
    reason VARCHAR(500) NULL,
    processed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refunds_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- DISPUTES
-- -------------------------------------------------------------
CREATE TABLE disputes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    raised_by_user_id BIGINT UNSIGNED NOT NULL,
    role VARCHAR(20) NOT NULL,
    category VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    admin_notes TEXT NULL,
    requested_info TEXT NULL,
    decision VARCHAR(20) NULL,
    settlement DECIMAL(10,2) NULL,
    resolution_summary TEXT NULL,
    resolved_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_disputes_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_disputes_user FOREIGN KEY (raised_by_user_id) REFERENCES users(id),
    INDEX idx_disputes_status (status)
) ENGINE=InnoDB;

CREATE TABLE dispute_evidence (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dispute_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(500) NOT NULL,
    caption VARCHAR(200) NULL,
    uploaded_by_user_id BIGINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evidence_dispute FOREIGN KEY (dispute_id) REFERENCES disputes(id) ON DELETE CASCADE,
    CONSTRAINT fk_evidence_user FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- REVIEWS
-- -------------------------------------------------------------
CREATE TABLE reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL UNIQUE,
    user_id BIGINT UNSIGNED NOT NULL,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    rating INT NOT NULL,
    comment TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_reviews_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    INDEX idx_reviews_vehicle (vehicle_id)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- NOTIFICATIONS
-- -------------------------------------------------------------
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NULL,
    ntype VARCHAR(40) NULL,
    link VARCHAR(300) NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notifications_user (user_id, is_read)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- PLATFORM SETTINGS
-- -------------------------------------------------------------
CREATE TABLE settings (
    `key` VARCHAR(60) PRIMARY KEY,
    value JSON NULL,
    updated_at DATETIME NULL
) ENGINE=InnoDB;
