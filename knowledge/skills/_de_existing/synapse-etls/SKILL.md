%md
# Synapse ETL Skill

## When to Use
Load this skill when the user asks about:
- DWH or BI_DB tables and how they're populated
- Stored procedures, ETL logic, or data transformations
- Table lineage or data flow in the data warehouse
- Synapse-specific patterns or architecture

## Repository Location
/Users/guyman@etoro.com/DataPlatform/SynapseSQLPool1/sql_dp_prod_we/

## Key Schemas

### DWH_dbo (Data Warehouse)
- **Purpose**: Core dimensional model (Kimball style)
- **Pattern**: Dimensions (Dim_*) and Facts (Fact_*)
- **Stored Procedures**: 128+ ETL procedures
- **Key Tables**: Dim_Customer, Dim_Position, Dim_Instrument, Fact_CustomerAction

### BI_DB_dbo (BI Database)
- **Purpose**: Analytics, reporting, compliance, regulatory
- **Pattern**: Aggregated tables, reports, specialized analytics
- **Stored Procedures**: 700+ procedures (compliance, finance, risk, CMR)
- **Key Tables**: Various BI_DB_* tables for specific business needs

## How to Find Information

### Finding Stored Procedures
Use readAssetById with folder IDs:
- DWH_dbo Stored Procedures: folder ID 1353348094093755
- BI_DB_dbo Stored Procedures: folder ID 1353348094093479

### Reading Stored Procedure Code
Use readAssetById with file type and the file ID from search results

### Translating Synapse Tables to Unity Catalog

**Mapping Table**: `main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`

This table provides the complete mapping of Synapse tables to Unity Catalog tables. Key columns:
- `DatabaseName`: Synapse database (e.g., 'sql_dp_prod_we')
- `SchemaName`: Synapse schema (e.g., 'DWH_dbo', 'BI_DB_dbo')
- `TableName`: Synapse table name (e.g., 'Dim_Customer', 'Fact_CustomerAction')
- `BusinessGroup`: Target Unity Catalog schema (e.g., 'dwh', 'pii_data', 'bi_db')
- `UnityCatalogTableName`: Full Unity Catalog path (e.g., 'dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer')

**Naming Pattern**:
```
Synapse: sql_dp_prod_we.DWH_dbo.Dim_Customer
Unity Catalog: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer

Synapse: sql_dp_prod_we.DWH_dbo.Fact_CustomerAction  
Unity Catalog: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction

Synapse: sql_dp_prod_we.BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
Unity Catalog: main.bi_db.bronze_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform
```

**Translation Rules**:
1. Catalog is always `main`
2. Schema maps via `BusinessGroup` column (dwh, bi_db, pii_data, etc.)
3. Table name format: `gold_{database}_{schema}_{table}` (all lowercase)
4. For BI_DB tables: prefix is `bronze_` instead of `gold_`
5. For masked/PII tables: use `pii_data` schema

**Query to Find Mapping**:
```sql
SELECT 
  DatabaseName,
  SchemaName, 
  TableName,
  BusinessGroup,
  UnityCatalogTableName
FROM main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables
WHERE DatabaseName = 'sql_dp_prod_we'
  AND SchemaName = 'DWH_dbo'
  AND TableName = 'Dim_Customer';
```

### Common Patterns
1. **External Tables** (Ext_*): Source data from Data Lake
2. **Staging Tables** (#temp): Temporary processing tables
3. **SCD Type 2**: Historical tracking with BeginDate/EndDate
4. **DL_To_Synapse**: Procedures that copy from Data Lake to Synapse
5. **Partitioning**: Many tables partitioned by date for performance

## Example: How Dim_Customer is Loaded

**Stored Procedure**: DWH_dbo.SP_Dim_Customer
**Source Tables**:
- DWH_dbo.Ext_Dim_Customer_Customer (from etoro.Customer)
- DWH_dbo.Ext_Dim_Customer_BOCustomer (from etoro.BackOffice.Customer)

**Logic**:
1. Join customer and backoffice customer data
2. Calculate derived fields (IsValidCustomer, IsCreditReportValidCB)
3. Detect changes (SCD Type 2 pattern)
4. Insert new customers
5. Update changed customers with EndDate/BeginDate

**Key Fields Added**:
- IsValidCustomer: Excludes test accounts, employees, specific labels
- IsCreditReportValidCB: Valid for credit reporting
- Multiple status IDs: PlayerStatus, RiskStatus, VerificationLevel, etc.

## Cross-Domain Connections

**Recurring Investments Example**:
- Plan: general.bronze_recurringinvestment_recurringinvestment_plans
- Deposit: billing.bronze_etoro_billing_deposit (via DepositID)
- Order: trading.* (via OrderID)
- Position: DWH_dbo.Dim_Position (via PositionID)

## Spaceship Data

### Currency Warning: All AUD
**CRITICAL**: All Spaceship source tables contain monetary values in **AUD (Australian Dollars)**, not USD.

**Source Tables** (all in `main.spaceship` schema):
- `bronze_spaceship_metabase_super_user_balances` - Super product balances
- `spaceship_metabase_voyager_user_balances` - Voyager product balances
- `bronze_spaceship_metabase_nova_user_balances` - Nova product balances
- `bronze_spaceship_metabase_super_transactions` - Super transactions
- `bronze_spaceship_metabase_voyager_transactions` - Voyager transactions
- `bronze_spaceship_metabase_nova_transactions` - Nova transactions

### Currency Conversion Pattern
When querying Spaceship source tables directly, **always convert AUD to USD**:

```sql
-- Add this CTE to your queries
aud_usd_rates AS (
  SELECT 
    CAST(OccurredDate AS DATE) AS rate_date,
    (Ask + Bid) / 2 AS aud_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 7  -- AUD/USD pair
)

-- Then join and multiply AUD amounts by aud_to_usd_rate
LEFT JOIN aud_usd_rates r ON your_date_field = r.rate_date
SELECT amount_aud * r.aud_to_usd_rate AS amount_usd
```

The `(Ask + Bid) / 2` formula provides the EOD (end-of-day) price used in eToro systems.

### Semantic Views (Conversion Already Done)
The following views in `main.bi_output_stg` **already include USD columns** - no conversion needed:
- `v_semantic_spaceship_aum` - Assets Under Management (balances by product)
- `v_semantic_spaceship_fees` - Total fees across all products
- `v_semantic_spaceship_mimo` - Money In Money Out (deposits/withdrawals)

All monetary fields have `_aud` and `_usd` suffixes (e.g., `total_balance_aud`, `total_balance_usd`).

### Key Fields
- **User ID Mapping**: `main.spaceship.bronze_spaceship_metabase_contact.user_id` maps to `main.bi_db.bronze_sub_accounts_accounts.accountId`
- **GCID**: Integer field from `bronze_sub_accounts_accounts` where `providerName = 'Spaceship'`
- **Products**: Super (uses `member_id`), Voyager (uses `user_id`), Nova (uses `user_id`)

## MoneyFarm Data

### Currency Warning: All GBP
**CRITICAL**: All MoneyFarm source tables contain monetary values in **GBP (British Pounds)**, not USD.

**Source Tables**:
- `main.money_farm.silver_moneyfarm_etoro_mf_aum` - Portfolio balances (Market_Value field)
- `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` - Transaction events (PORTFOLIO_DEPOSIT, PORTFOLIO_WITHDRAW)

### Currency Conversion Pattern
When querying MoneyFarm source tables directly, **always convert GBP to USD**:

```sql
-- Add this CTE to your queries
gbp_usd_rates AS (
  SELECT 
    CAST(OccurredDate AS DATE) AS rate_date,
    (Ask + Bid) / 2 AS gbp_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 2  -- GBP/USD pair
)

-- Then join and multiply GBP amounts by gbp_to_usd_rate
LEFT JOIN gbp_usd_rates r ON your_date_field = r.rate_date
SELECT amount_gbp * r.gbp_to_usd_rate AS amount_usd
```

The `(Ask + Bid) / 2` formula provides the EOD (end-of-day) price used in eToro systems.

### Semantic Views (Conversion Already Done)
The following views in `main.bi_output_stg` **already include USD columns** - no conversion needed:
- `v_semantic_moneyfarm_aum` - Assets Under Management (total balance across portfolios)
- `v_semantic_moneyfarm_fees` - Total fees (placeholder - no data yet)
- `v_semantic_moneyfarm_mimo` - Money In Money Out (deposits/withdrawals from events)

All monetary fields have `_gbp` and `_usd` suffixes (e.g., `total_balance_gbp`, `total_balance_usd`).

### Key Fields
- **GCID**: Directly available in source tables (`EventPayloadRowData.EventMetadata.Gcid` in event streaming)
- **Event Types**: `PORTFOLIO_DEPOSIT` (deposits), `PORTFOLIO_WITHDRAW` (withdrawals)
- **Portfolio ID**: Available in AUM table and parsed from event data JSON

## Tips
- Most DWH tables are loaded from External Tables (Ext_*)
- BI_DB procedures often call DWH tables as sources
- Look for "_DL_To_Synapse" suffix for Data Lake → Synapse ETL
- Check change history comments in stored proc headers for business context

## Common Gotchas

### Duplicate Events
Some event tables have duplicate rows with identical timestamps (e.g., ActionType 19 in Fact_CustomerAction). Always deduplicate subqueries in LEFT JOINs:
```sql
-- Use GROUP BY + MAX/MIN to deduplicate
SELECT PositionID, MAX(Occurred) as Occurred
FROM Fact_CustomerAction WHERE ActionTypeID = 19
GROUP BY PositionID
```

### Hidden IDs in Description Fields
ActionType 36 with CompensationReasonID 117/118 stores PositionID in Description field. Extract using:
```sql
TRY_CAST(REVERSE(SUBSTRING(REVERSE(Description), 1, CHARINDEX(' ', REVERSE(Description)) - 1)) AS BIGINT)
```

### Validation Pattern
Always validate row counts AND amounts when translating stored procs to views:
```sql
SELECT key_field, COUNT(*), SUM(amount) FROM source GROUP BY key_field;
SELECT key_field, COUNT(*), SUM(amount) FROM new_view GROUP BY key_field;
```