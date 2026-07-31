# CoffeeClub Post-Migration Optimization & Analytics

# Project Overview

This project focuses on enhancing a restored PostgreSQL database by enforcing relational integrity, performing data cleaning, engineering analytical features, and creating business-ready SQL views.

The source dataset was provided as a PostgreSQL backup file and restored into a database named **coffee_club** using pgAdmin. Once restored, SQL was used to improve the database structure and prepare it for analytical reporting.

---

# Project Objectives

The objectives of this project were to:

- Enforce relational integrity using primary and foreign key constraints.
- Prevent orphaned records through foreign key relationships.
- Improve query performance using B-Tree indexes.
- Transform raw data into meaningful analytical features.
- Clean inconsistent data values.
- Build reusable SQL views for business reporting.
- Prepare customer demographic features for fast reporting.

---

# Workflow

The project followed the workflow below.

## 1. Database Restoration

The source dataset was provided as a PostgreSQL backup (.backup) file.

The backup was restored into PostgreSQL using pgAdmin, creating the **coffee_club** database. This produced the initial relational tables:

- customers
- events
- offers
- offer_channels

The restored database served as the starting point for all subsequent transformations.

---

## 2. Relational Enforcement

Primary key constraints were added to uniquely identify records.

Foreign key constraints were then created to establish relationships between related tables and enforce referential integrity.

Indexes were created on frequently joined foreign-key columns to improve query performance.

---

## 3. Data Cleaning

A data quality audit was performed to identify inconsistent data values.

The placeholder age value **118** was identified as an invalid age and converted to **NULL** to prevent incorrect demographic analysis.

---

## 4. Feature Engineering

New analytical features were created from the existing data.

Examples include:

- day
- hour_of_day
- campaign_duration
- income_bucket
- age_group

These derived attributes make the data easier to analyse and report.

---

## 5. Analytics Layer

SQL Views were created to generate reusable business summaries, including:

- Offer completion statistics
- Offer performance
- Informational offer analysis

These views allow non-technical users to access key business metrics without writing complex SQL.

---


# Referential Integrity Rationale

Relational constraints were implemented to ensure consistency between related tables.

## Primary Keys

Primary keys guarantee uniqueness and prevent duplicate records.

Examples:

- customer_id
- offer_id
- event_id

---

## Foreign Keys

Foreign keys ensure that related records always exist.

For example:

events.customer_id

must reference

customers.customer_id

This prevents orphaned event records.

---

## ON DELETE Behaviour

### RESTRICT

Used for:

- customers → events
- offers → events

Historical customer events should never disappear if a customer or offer is deleted.

---

### CASCADE

Used for:

offer → offer_channels

Offer channels have no meaning without their parent offer, so deleting an offer also removes its associated channels.

---

# Views

The project uses SQL Views to simplify reporting.

Example:

offer_performance_summary

This view calculates:

- offers received
- offers completed
- completion rate

without requiring analysts to repeatedly write aggregation queries.

---

# Technologies Used

- PostgreSQL
- SQL
- pgAdmin

---

# Project Outcomes

The final database now provides:

- relational integrity
- improved query performance
- cleaned customer data
- engineered analytical features
- business-ready reporting views
- demographic segmentation

The resulting database is suitable for reporting, dashboarding, and further analytical processing.
