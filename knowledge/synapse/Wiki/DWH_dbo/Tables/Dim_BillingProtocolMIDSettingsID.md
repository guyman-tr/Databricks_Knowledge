# DWH_dbo.Dim_BillingProtocolMIDSettingsID

> Payment routing MID (Merchant ID) configuration dimension. Each row defines a protocol parameter value for a (depot + mode + regulation + currency) combination, driving payment gateway selection for deposits and withdrawals. Sourced daily from etoro.Billing.ProtocolMIDSettings via SP_Dictionaries_DL_To_Synapse. ~1,851 rows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.ProtocolMIDSettings |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingProtocolMIDSettingsID is the DWH version of etoro.Billing.ProtocolMIDSettings -- the payment routing configuration table. It maps every combination of payment parameter + depot + trading mode + regulatory jurisdiction + currency to a specific Value (the MID, Merchant ID, or protocol identifier string) used to route transactions through a specific payment processor endpoint.

When a deposit is processed, the system looks up this table to determine which MID to use for the given depot, regulation, and currency. The ProtocolMIDSettingsID foreign key in deposit and withdrawal transaction tables references this table to record which routing configuration was used for each payment.

Source: etoro.Billing.ProtocolMIDSettings on etoroDB-REAL. Exported daily to Bronze/etoro/Billing/ProtocolMIDSettings/ and staged into DWH_staging.etoro_Billing_ProtocolMIDSettings. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern. The production ID column is renamed to ProtocolMIDSettingsID in DWH. UpdateDate is set to GETDATE() at load time.

Row composition (approximate, based on production wiki at 1,470 rows; DWH has 1,851 as of 2026-03-11):
- DepotModeID: ~60% Demo (2), ~37% Live (1), ~3% General (0)
- SubTypeID: ~94% default (0), ~6% alternate (3)
- MerchantAccountID: ~25% have a specific merchant account override; ~75% NULL

**SENSITIVE DATA**: The Value column contains MID strings, API keys, and merchant credentials. Do not include in unmasked reports or logs.

---

## 2. Business Logic

### 2.1 MID Routing Lookup

**What**: Given a depot + regulation + currency + mode, retrieve the MID/protocol string (Value) to use for payment processing.

**Columns Involved**: `ProtocolMIDSettingsID`, `ParameterID`, `DepotID`, `DepotModeID`, `RegulationID`, `CurrencyID`, `Value`, `SubTypeID`, `MerchantAccountID`

**Rules**:
- Primary lookup key: (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID) -- the logical PK from production
- CurrencyID=0 means "any currency" -- applies regardless of transaction currency
- SubTypeID=0 is the default routing path; SubTypeID=3 is an alternate routing path
- MerchantAccountID (when set) provides finer-grained routing to a specific acquiring account within a depot

**Primary reader**: Billing.GetProtocolMIDSettings(@RegulationID, @DepotID, @CurrencyID, @MerchantAccountID)

### 2.2 Depot Mode Segmentation (Live vs Demo)

**What**: Live and Demo accounts use separate MID entries to route to different processing environments.

**Columns Involved**: `DepotModeID`

| DepotModeID | Meaning | Approx Count |
|-------------|---------|-------------|
| 0 | General (applies to both modes) | ~3% |
| 1 | Live trading accounts | ~37% |
| 2 | Demo accounts | ~60% |

**Rules**:
- High Demo count (60%) reflects that demo deposits use the same routing infrastructure with sandbox MIDs
- When routing a payment, the system selects the matching DepotModeID based on whether the customer has a live or demo account

### 2.3 Regulatory Segmentation

**What**: Each regulatory entity (CySEC, FCA, ASIC, etc.) has its own set of MIDs reflecting eToro's multi-jurisdiction legal structure.

**Columns Involved**: `RegulationID`

**Rules**:
- RegulationID=0: applies to all regulations (general fallback)
- RegulationID=1: CySEC (eToro EU)
- RegulationID=2: FCA (eToro UK)
- Additional values for ASIC, FINRA, and other regulatory entities
- Ensures transactions route through the correct legal entity's acquiring relationship

### 2.4 SubTypeID and MerchantAccountID Routing

**What**: Fine-grained routing controls within a (depot, mode, regulation, currency) combination.

**Columns Involved**: `SubTypeID`, `MerchantAccountID`

**Rules**:
- SubTypeID=0: default routing (94% of rows)
- SubTypeID=3: alternate sub-routing for specific processor subsets (6% of rows)
- MerchantAccountID (when set): links to a specific merchant account in Billing.MerchantAccountValues for finer routing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. With ~1,851 rows, REPLICATE is acceptable -- every node holds a full copy, enabling zero-movement JOINs when filtering by DepotID. The clustered index on DepotID optimizes lookups from deposit/cashout fact tables.

**Note**: Unlike the production table (clustered on ID), the DWH clusters on DepotID. Queries by ProtocolMIDSettingsID range scans will not benefit from the clustered index; use DepotID-based lookups for best performance.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, partitioning is optional at this row count. If partitioned, partition by RegulationID or DepotID for routing lookups. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| MID config for a specific depot | WHERE DepotID = N AND DepotModeID IN (0,1) |
| All Live mode entries for a regulation | WHERE DepotModeID = 1 AND RegulationID = N |
| Entries with merchant account overrides | WHERE MerchantAccountID IS NOT NULL |
| Row count by mode | GROUP BY DepotModeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingDepot | ON Dim_BillingDepot.DepotID = Dim_BillingProtocolMIDSettingsID.DepotID | Resolve depot name and payment method |
| Fact deposit/cashout tables | ON ProtocolMIDSettingsID | Identify which MID config was used per transaction |

### 3.4 Gotchas

- **Value column is SENSITIVE**: Contains MID strings, API keys, and merchant credentials. Exclude from unmasked exports, logs, and reports.
- **ProtocolMIDSettingsID = production ID**: The DWH renames the production `ID` column to `ProtocolMIDSettingsID`. These are the same values; use ProtocolMIDSettingsID when joining to fact tables that store the original ID.
- **CurrencyID=0 = any currency**: Most rows use CurrencyID=0 as a wildcard -- they apply to all currencies, not just currency 0. Do not filter `WHERE CurrencyID = 0` expecting only "no-currency" rows.
- **UpdateDate staleness warning**: Live data as of 2026-03-18 shows UpdateDate=2026-03-11, suggesting the ETL may not have run for ~7 days. Monitor UpdateDate for freshness issues.
- **Clustered on DepotID (not ID)**: Production clusters on ID for sequential inserts; DWH clusters on DepotID for JOIN performance. This changes query plan behavior.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 stars | Tier 3 - name-inferred | (Tier 3 - name-inferred) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProtocolMIDSettingsID | int | NOT NULL | Surrogate primary key. Renamed from `ID` in the production Billing.ProtocolMIDSettings table. Referenced by fact deposit and withdrawal tables to record which routing configuration was used per transaction. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 2 | ParameterID | int | NOT NULL | Protocol parameter type. Part of logical routing key. References Billing.Parameter which defines the parameter name/type (e.g., MID, SecretKey, ApiKey). Together with DepotID, DepotModeID, RegulationID, CurrencyID forms the unique routing key. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 3 | DepotID | int | NOT NULL | Payment gateway/depot. Part of logical routing key. References Billing.Depot (DWH: Dim_BillingDepot.DepotID). Identifies the payment processor this MID configuration belongs to. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 4 | DepotModeID | tinyint | NOT NULL | Trading mode. Part of logical routing key. 0=General (applies to both), 1=Live, 2=Demo. Separates Live and Demo payment processing environments. ~60% Demo, ~37% Live. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 5 | Value | nvarchar(250) | YES | The protocol identifier string (MID, merchant ID, API key, etc.) passed to the payment processor for routing. SENSITIVE -- contains payment gateway credentials. Examples: merchant ID numbers, API endpoint identifiers. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 6 | RegulationID | int | NOT NULL | Regulatory entity. Part of logical routing key. Segments MIDs by legal jurisdiction: 0=None, 1=CySEC (EU), 2=FCA (UK), plus additional ASIC/other values. Ensures transactions route through the correct legal entity's acquiring relationship. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 7 | CurrencyID | int | NOT NULL | Currency restriction. Part of logical routing key. 0=any currency (most rows). Non-zero values restrict this MID entry to a specific transaction currency. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 8 | Description | nvarchar(250) | YES | Human-readable description of this MID entry (e.g., processor name, account identifier). Nullable; not all rows have a description. (Tier 3 - name-inferred) |
| 9 | SubTypeID | int | NOT NULL | Sub-routing type. 0=default routing (~94% of rows); 3=alternate sub-routing for specific processor subsets (~6% of rows). Allows multiple routing paths within the same (depot, mode, regulation, currency). (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 10 | MerchantAccountID | int | YES | Optional link to a specific merchant account configuration in Billing.MerchantAccountValues. When set (~25% of rows), enables finer-grained routing to a specific acquiring account within a depot. NULL when not applicable. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 11 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Monitor for freshness -- live data as of 2026-03-18 shows last load was 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProtocolMIDSettingsID | etoro.Billing.ProtocolMIDSettings | ID | Passthrough (renamed: ID -> ProtocolMIDSettingsID) |
| ParameterID | etoro.Billing.ProtocolMIDSettings | ParameterID | Passthrough |
| DepotID | etoro.Billing.ProtocolMIDSettings | DepotID | Passthrough |
| DepotModeID | etoro.Billing.ProtocolMIDSettings | DepotModeID | Passthrough |
| Value | etoro.Billing.ProtocolMIDSettings | Value | Passthrough |
| RegulationID | etoro.Billing.ProtocolMIDSettings | RegulationID | Passthrough |
| CurrencyID | etoro.Billing.ProtocolMIDSettings | CurrencyID | Passthrough |
| Description | etoro.Billing.ProtocolMIDSettings | Description | Passthrough |
| SubTypeID | etoro.Billing.ProtocolMIDSettings | SubTypeID | Passthrough |
| MerchantAccountID | etoro.Billing.ProtocolMIDSettings | MerchantAccountID | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Billing.ProtocolMIDSettings -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/ProtocolMIDSettings/ -> DWH_staging.etoro_Billing_ProtocolMIDSettings -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingProtocolMIDSettingsID
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.ProtocolMIDSettings | ~1,851-row MID routing config (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/ProtocolMIDSettings/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_ProtocolMIDSettings | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; ID renamed to ProtocolMIDSettingsID; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingProtocolMIDSettingsID | ~1,851 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ProtocolMIDSettingsID | etoro.Billing.ProtocolMIDSettings | Production source (upstream reference) |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment depot dimension in DWH |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact deposit tables | ProtocolMIDSettingsID | Records which MID config was used per transaction |
| Fact withdrawal tables | ProtocolMIDSettingsID | Records which MID config was used per withdrawal |

---

## 7. Sample Queries

### 7.1 Row distribution by depot mode

```sql
SELECT
    DepotModeID,
    CASE DepotModeID WHEN 0 THEN 'General' WHEN 1 THEN 'Live' WHEN 2 THEN 'Demo' ELSE 'Unknown' END AS ModeName,
    COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
GROUP BY DepotModeID
ORDER BY DepotModeID
```

### 7.2 MID configs for a specific depot (excluding sensitive Value)

```sql
SELECT
    pms.ProtocolMIDSettingsID,
    pms.ParameterID,
    pms.DepotID,
    bd.Name AS DepotName,
    pms.DepotModeID,
    pms.RegulationID,
    pms.CurrencyID,
    pms.SubTypeID,
    pms.Description
    -- Value intentionally excluded: contains sensitive MID credentials
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID] pms
JOIN [DWH_dbo].[Dim_BillingDepot] bd ON bd.DepotID = pms.DepotID
WHERE pms.DepotID = 7  -- Neteller
ORDER BY pms.RegulationID, pms.DepotModeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 9/14 (P3/P5/P6/P9B/P10 skipped)*
*Tiers: 9 T1, 1 T2, 1 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 9.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingProtocolMIDSettingsID | Type: Table | Production Source: etoro.Billing.ProtocolMIDSettings*
