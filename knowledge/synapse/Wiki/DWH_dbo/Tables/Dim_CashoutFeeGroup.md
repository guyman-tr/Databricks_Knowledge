# DWH_dbo.Dim_CashoutFeeGroup

> Lookup dimension defining the 3 withdrawal fee groups -- Default, Exempt, and Discount -- controlling which fee schedule applies to a customer's cashout transactions. Sourced daily from etoro.Dictionary.CashoutFeeGroup via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CashoutFeeGroup |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutFeeGroupID) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_CashoutFeeGroup is the DWH version of etoro.Dictionary.CashoutFeeGroup. It classifies customers into fee tiers for withdrawal processing. Each customer's record carries a CashoutFeeGroupID that determines which withdrawal fee schedule applies when they request a cashout.

The three groups: Default (1) -- standard withdrawal fees apply (most customers); Exempt (2) -- no withdrawal fees (high-tier eToro Club members, active Popular Investors, promotional campaigns); Discount (3) -- reduced withdrawal fees (mid-tier loyalty program members).

Fee amounts per group are defined in Trade.CashoutRange (not in DWH). The fee group is dynamically calculated based on a customer's PlayerLevel and GuruStatus (Popular Investor tier) via mapping tables, and auto-updated by Billing.ProcessCashoutFeeGroupUpdate when tiers change.

Source: etoro.Dictionary.CashoutFeeGroup on etoroDB-REAL. Exported daily to Bronze/etoro/Dictionary/CashoutFeeGroup/ and staged into DWH_staging.etoro_Dictionary_CashoutFeeGroup. SP_Dictionaries_DL_To_Synapse loads using TRUNCATE + INSERT. The production `Name` column is renamed to `CashoutFeeGroupName` in DWH.

3 rows only; no ID=0 placeholder.

---

## 2. Business Logic

### 2.1 Fee Group Assignment

**What**: Determines the withdrawal fee schedule for a customer based on their tier and loyalty status.

**Columns Involved**: `CashoutFeeGroupID`, `CashoutFeeGroupName`

| CashoutFeeGroupID | CashoutFeeGroupName | Meaning |
|---|---|---|
| 1 | Default | Standard withdrawal fee schedule. Applied to most customers by default at registration. |
| 2 | Exempt | Zero withdrawal fees. Granted to premium customers -- high eToro Club tiers, active Popular Investors, or through special promotions. |
| 3 | Discount | Reduced withdrawal fees. Mid-tier benefit; lower than Default but not fully waived. |

**Rules**:
- Fee group is set at registration to Default (1)
- Billing.ProcessCashoutFeeGroupUpdate auto-recalculates based on PlayerLevel (via Billing.PlayerLevelToCashoutFeeGroup) and GuruStatus (via Billing.GuruStatusToCashoutFeeGroup)
- BackOffice operators can manually override via BackOffice.CustomerSetCashoutFeeGroup
- Actual fee amounts per group are in Trade.CashoutRange (not in DWH)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on CashoutFeeGroupID. Correct for a 3-row lookup -- eliminates JOIN data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for 3 rows. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count customers by withdrawal fee group | JOIN Dim_Customer ON CashoutFeeGroupID, GROUP BY |
| Exempt customers (no withdrawal fees) | WHERE CashoutFeeGroupID = 2 |
| Fee group name display | JOIN Dim_CashoutFeeGroup ON CashoutFeeGroupID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH customer tables | ON CashoutFeeGroupID | Resolve fee group for each customer |

### 3.4 Gotchas

- **No ID=0 placeholder**: Unlike most DWH Dim_ tables, there is no ID=0 (N/A) row. Customers not matching any group will produce NULLs on LEFT JOIN.
- **CashoutFeeGroupName renamed from Name**: Production column is `Name` (varchar 50 nullable). DWH renames it to `CashoutFeeGroupName`. Same values.
- **Fee amounts NOT in DWH**: Trade.CashoutRange defines the actual dollar amounts per group. That table is not in DWH -- fee amount analysis requires the production source.
- **All columns nullable in DWH DDL** despite NOT NULL constraints in production.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.CashoutFeeGroup) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutFeeGroupID | int | YES | Primary key identifying the fee group. 1=Default (standard fees), 2=Exempt (no fees), 3=Discount (reduced fees). Stored on customer records; drives withdrawal fee calculation via Trade.CashoutRange. (Tier 1 - upstream wiki, Dictionary.CashoutFeeGroup) |
| 2 | CashoutFeeGroupName | varchar(50) | YES | Human-readable fee group name: 'Default', 'Exempt', 'Discount'. Renamed from production `Name` column. Used in reporting to display fee group. (Tier 1 - upstream wiki, Dictionary.CashoutFeeGroup) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutFeeGroupID | etoro.Dictionary.CashoutFeeGroup | CashoutFeeGroupID | Passthrough |
| CashoutFeeGroupName | etoro.Dictionary.CashoutFeeGroup | Name | Passthrough (renamed: Name -> CashoutFeeGroupName) |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutFeeGroup -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/CashoutFeeGroup/ -> DWH_staging.etoro_Dictionary_CashoutFeeGroup -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_CashoutFeeGroup
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CashoutFeeGroup | 3-row fee group catalog (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/CashoutFeeGroup/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_CashoutFeeGroup | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; Name renamed to CashoutFeeGroupName; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_CashoutFeeGroup | 3 rows (IDs 1-3) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CashoutFeeGroupID | etoro.Dictionary.CashoutFeeGroup | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH customer dimension tables | CashoutFeeGroupID | Customer withdrawal fee group lookup |

---

## 7. Sample Queries

### 7.1 List all fee groups

```sql
SELECT CashoutFeeGroupID, CashoutFeeGroupName
FROM [DWH_dbo].[Dim_CashoutFeeGroup]
ORDER BY CashoutFeeGroupID
-- Returns: 1=Default, 2=Exempt, 3=Discount
```

### 7.2 Customer distribution by fee group (illustrative)

```sql
SELECT
    dcfg.CashoutFeeGroupName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_CashoutFeeGroup] dcfg
    ON dc.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
GROUP BY dcfg.CashoutFeeGroupName
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 9.0/10, Relationships: 6.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_CashoutFeeGroup | Type: Table | Production Source: etoro.Dictionary.CashoutFeeGroup*
