# wander_analytics — dbt + Databricks Project

A dbt project built on Databricks (Unity Catalog) that models data for **Wander**, a short-term rental platform. It follows the **Medallion Architecture** (Bronze → Silver → Gold) and implements Type-2 Slowly Changing Dimensions (SCD2) via dbt snapshots.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup & Configuration](#setup--configuration)
- [Project Structure](#project-structure)
- [Data Sources](#data-sources)
- [Layers](#layers)
  - [Bronze](#bronze-layer)
  - [Silver](#silver-layer)
  - [Gold](#gold-layer)
- [Snapshots (SCD2)](#snapshots-scd2)
- [Seeds](#seeds)
- [Custom UDFs](#custom-udfs)
- [Macros](#macros)
- [Data Quality & Testing](#data-quality--testing)
- [Running the Project](#running-the-project)

---

## Project Overview

| Property | Value |
|---|---|
| dbt project name | `wander_analytics` |
| Databricks catalog | `wander_analytics` (Unity Catalog) |
| Default schema | `bronze` |
| dbt version | 1.0.0+ |
| Key package | `dbt-labs/dbt_utils` v1.3.3 |

---

## Architecture

```
Source (samples.wanderbricks)
        │
        ▼
┌───────────────┐
│    BRONZE     │  Raw incremental ingestion, surrogate keys, schema contracts
│  (tables)     │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│    SILVER     │  Deduplication, cleansing, SCD2 snapshots, type casting
│  (ephemeral / │
│  incremental) │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     GOLD      │  Business-ready dimensions and fact tables
│ (views/tables)│
└───────────────┘
```

---

## Prerequisites

- Python 3.8+
- dbt-databricks adapter installed
- Access to a Databricks workspace with a SQL warehouse
- Unity Catalog enabled on the workspace
- `DBT_DATABRICKS_TOKEN` environment variable set

---

## Setup & Configuration

1. **Clone the repo** and navigate to the project:
   ```bash
   cd wander_analytics
   ```

2. **Install dependencies:**
   ```bash
   pip install dbt-databricks
   dbt deps
   ```

3. **Set your Databricks token:**
   ```bash
   export DBT_DATABRICKS_TOKEN=<your-token>
   ```

4. **Verify connection:**
   ```bash
   dbt debug
   ```

The `profiles.yml` inside `wander_analytics/` points to:

| Config | Value |
|---|---|
| Host | `dbc-25d9d64d-9c9e.cloud.databricks.com` |
| HTTP Path | `/sql/1.0/warehouses/5da2b8f6fe4099dc` |
| Catalog | `wander_analytics` |
| Threads | 4 |

---

## Project Structure

```
wander_analytics/
├── models/
│   ├── _sources.yml          # Source table definitions & freshness checks
│   ├── bronze/               # Raw ingestion models
│   ├── silver/               # Cleansed & deduplicated models
│   └── gold/                 # Business-ready dimensions & facts
├── snapshots/                # SCD2 snapshot definitions
├── seeds/                    # Static CSV reference data
├── functions/                # Databricks UDFs (SQL)
├── macros/                   # Reusable dbt macros
├── tests/                    # Custom test files
├── analyses/                 # Ad-hoc analysis queries
├── dbt_project.yml           # Main dbt configuration
├── profiles.yml              # Databricks connection config
└── packages.yml              # Package dependencies
```

---

## Data Sources

All sources live in `samples.wanderbricks` on Databricks.

| Source | Table | Event Time Column |
|---|---|---|
| `src_users` | `users` | `created_at` |
| `src_bookings` | `bookings` | `created_at` |
| `src_properties` | `properties` | `created_at` |
| `src_hosts` | `hosts` | — |
| `src_destinations` | `destinations` | `created_at` |

Source freshness is monitored on `src_users` (expects data between 2023-07-01 and 2023-07-08 18:00:00).

---

## Layers

### Bronze Layer

**Purpose:** Ingest raw data from source tables with minimal transformation. Adds surrogate keys and records load timestamps.

**Materialization:** All models are **incremental tables** using `append` strategy, filtered by `created_at` for dev environments (2023-07-01 to 2023-07-08 18:00:00).

| Model | Source | Surrogate Keys |
|---|---|---|
| `bronze_users` | `src_users` | `user_id_sk` |
| `bronze_bookings` | `src_bookings` | `booking_id_sk`, `user_id_sk`, `property_id_sk` |
| `bronze_properties` | `src_properties` | `property_id_sk`, `host_id_sk`, `destination_id_sk` |
| `bronze_hosts` | `src_hosts` | `host_id_sk` |
| `bronze_destinations` | `src_destinations` | `destination_id_sk` |

All surrogate keys are generated via `dbt_utils.generate_surrogate_key()`.

Schema contracts are enforced at the bronze layer via `contract: enforced: true` (controlled by the `enforce_schema_contracts` project variable).

---

### Silver Layer

**Purpose:** Deduplicate records, apply data cleansing, cast types, and prepare clean datasets for snapshots and the gold layer.

**Materialization:** Mix of **ephemeral** (inline CTEs) and **incremental** (merge strategy) models.

| Model | Materialization | Key Logic |
|---|---|---|
| `silver_users` | ephemeral | Deduplicate on `user_id_sk` (latest `created_at`); fill nulls |
| `silver_users_scd1` | incremental (disabled) | SCD1 pattern with `is_active` and `updated_at` tracking |
| `silver_bookings` | ephemeral | Deduplicate on `booking_id_sk` (latest `updated_at`) |
| `silver_properties` | ephemeral | Deduplicate on `property_id_sk` (latest `created_at`) |
| `silver_hosts` | ephemeral | Deduplicate on `host_id_sk`; filter active hosts; format phone numbers |
| `silver_destinations` | incremental | Merge strategy; MD5 checksum detects description changes |

`silver_hosts` applies the custom `phn_number_format()` UDF to standardize phone number formatting.

The `silver_users_scd1` model is currently **disabled** (`enabled: false`) in `dbt_project.yml`.

---

### Gold Layer

**Purpose:** Business-ready data for BI tools and reporting. Joins dimensions and facts into queryable views and tables.

**Materialization:** Views by default; `fct_bookings` is a table.

| Model | Type | Description |
|---|---|---|
| `dim_users` | view | Users dimension from `silver_users_scd2` snapshot; supports SCD1 filter via project variable |
| `dim_properties` | view | Properties dimension from `silver_properties` |
| `dim_hosts` | view | Hosts dimension from `silver_hosts` |
| `dim_destinations` | view | Destinations dimension from `silver_destinations` |
| `fct_bookings` | table | Bookings fact joined to SCD2 snapshots of properties and hosts; active records only |
| `dim_users_py` | table (disabled) | Python dbt model — disabled due to free-tier compute limitations |

**`dim_users` SCD1 toggle:** When `dim_users` is listed in the `gold_scd1_enabled_views` project variable, it filters to `record_end_date is null` to expose only the current state. Remove it from the list to expose full SCD2 history.

**`fct_bookings` joins:**
- `silver_bookings_scd2` (main fact rows)
- `silver_properties_scd2` (property details)
- `silver_hosts_scd2` (host details)
- `silver_destinations` (destination info)

---

## Snapshots (SCD2)

Snapshots track full history of dimension changes using **Type-2 SCD**, storing records in the `silver` schema.

| Snapshot | Source Model | Strategy | Unique Key | Tracked Columns |
|---|---|---|---|---|
| `silver_users_scd2` | `silver_users` | `check` | `user_id_sk` | name, country, user_type, is_business, company_name, email |
| `silver_bookings_scd2` | `silver_bookings` | `timestamp` | `booking_id_sk` | `updated_at` |
| `silver_properties_scd2` | `silver_properties` | `check` | `property_id_sk` | title, description, base_price, property_type, max_guests, bathrooms, bedrooms |
| `silver_hosts_scd2` | `silver_hosts` | `check` | `host_id_sk` | name, email, phone, is_verified, is_active, rating, country |

All snapshots use `invalidate_hard_deletes: true` and expose these metadata columns:

| Column | Description |
|---|---|
| `record_start_date` | When this version became active |
| `record_end_date` | When this version was superseded (NULL = current) |
| `record_scd_id` | Unique ID per snapshot record |
| `record_updated_at` | Last updated timestamp |
| `record_is_deleted` | Whether the source row was hard-deleted |

---

## Seeds

| Seed | Destination Table | Description |
|---|---|---|
| `customers.csv` | `bronze.bronze_customers_ff` | 10 static customer records for reference/testing |

Load seeds with:
```bash
dbt seed
```

---

## Custom UDFs

UDFs are defined as SQL files in `functions/` and deployed to `wander_analytics.udfs` catalog schema.

| UDF | Input | Output | Description |
|---|---|---|---|
| `is_positive_int` | `a_string` (string) | integer | Returns 1 if the string is a positive integer, else 0 |
| `phn_number_format` | `phone_number` (string) | string | Formats a phone number to `(XXX) XXX-XXXX`; returns NULL if invalid |

Both UDFs are marked as **deterministic**.

---

## Macros

| Macro | Description |
|---|---|
| `generate_schema_name` | Overrides dbt's default schema resolution — uses the custom schema if provided, otherwise falls back to the target schema |
| `st_md5_check_cols` | Generates an MD5-based comparison condition across a list of columns, used in merge operations to detect row-level changes |

### `st_md5_check_cols` Usage

```sql
{{ st_md5_check_cols(['email', 'name', 'country'], s_alias='src', t_alias='tgt') }}
```

Returns a SQL condition that evaluates to `TRUE` when any of the listed columns differ between the source and target aliases.

---

## Data Quality & Testing

Tests are defined in `_schema.yml` files alongside models.

| Test | Models Covered |
|---|---|
| `not_null` | `bronze_users.user_id`, `bronze_users.email` |
| `unique` | `bronze_users.user_id` |
| `accepted_values` | `bronze_users.user_type` (warn severity) |

Test failures are stored in the `_data_quality` schema for auditability.

Run all tests:
```bash
dbt test
```

---

## Running the Project

```bash
# Install packages
dbt deps

# Load seed data
dbt seed

# Run all models
dbt run

# Run snapshots
dbt snapshot

# Run tests
dbt test

# Run everything (seeds → run → test)
dbt build

# Run a specific layer
dbt run --select bronze
dbt run --select silver
dbt run --select gold

# Run a specific model
dbt run --select bronze_users
```
