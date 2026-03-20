# DWH_dbo.Dim_CompensationReason

> Hierarchical lookup of 133 compensation reason codes used when BackOffice applies manual account adjustments - from marketing promotions and dividend corporate actions to accounting corrections and regulatory decisions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.BackOffice.CompensationReason` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CompensationReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CompensationReason` defines the full taxonomy of reasons BackOffice uses when making manual compensation entries to customer accounts. Each row maps a reason code to its label and parent category. As of 2026-03-19 the table has 133 rows (IDs 0-134, with IDs 5 and 130 absent). The two-level hierarchy groups specific reasons under nine root categories: Custom(1), Marketing(4), Accounting/Ops(9), R&D(10), ACT(16), Obsolete(23), MT4(35), Dividend(45), and Inactivity Fee For Non Depositor(48). ID=0 is the ETL-inserted N/A placeholder.

Data flows from `etoro.BackOffice.CompensationReason` via `DWH_staging.etoro_BackOffice_CompensationReason` and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL renames `CompensationReasonID` to `DWHCompensationID` (same value), hardcodes `StatusID=1`, and sets `UpdateDate`/`InsertDate` to `GETDATE()`. The production columns `DisplayName`, `IsShownInHistory`, `IsCashflowForGain`, `IsTaxable`, and `IsActive` are **not loaded into DWH**. See upstream wiki: `DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md`.

Compensation entries that join this dimension appear in `Fact_BillingCompensation` and the production `Accounting.BalanceHistory` table. The reason code classifies the compensation for accounting, P&L attribution, regulatory reporting, and financial reconciliation.

---

## 2. Business Logic

### 2.1 Root Category Hierarchy

**What**: Each reason belongs to one of nine root categories (ParentID = NULL) or is itself a root. Leaf nodes hold a non-null ParentID pointing to a root.

**Columns Involved**: `CompensationReasonID`, `ParentID`, `Name`

**Rules**:
- **Root categories** (ParentID = NULL): 0(N/A placeholder), 1(Custom), 4(Marketing), 9(Accounting/Ops), 10(R&D), 16(ACT), 23(Obsolete), 35(MT4), 45(Dividend), 48(Inactivity Fee For Non Depositor)
- **Hierarchy depth**: Exactly 2 levels - roots have no parent; all leaves point to a root. No deeper nesting.
- **Largest subtrees**: Accounting/Ops (ID=9) has 40+ children covering chargebacks, adjustments, fees, closures, and transfers. Dividend (ID=45) has 30+ children covering all corporate action event types.
- **Obsolete category**: ID=23 subtree (e.g., ID=2 "Position lost" under ID=23) contains deprecated reasons retained for historical position records.

**Diagram**:
```
Compensation Reason Hierarchy (selected examples):
  ID=4  Marketing
    -> 20  Special Promotion
    -> 41  Guru cash with CO
    -> 51  Affiliate payment with CO
    -> 53  RAF Inviting Friend
    -> 58  Position Airdrop
  ID=9  Accounting / Ops
    -> 6   Chargeback (Negative compensation)
    -> 11  Refill - Negative Balance
    -> 26  Satisfaction Bonus
    -> 30  Dormant Fee
    -> 32  Foreclosure (taking all money)
    -> 55  Credit Line Fee
    -> 108 Transferred Out
    -> 119 Stocks Lending
  ID=45 Dividend
    -> 60  Cash in Lieu
    -> 61  Cash Dividend
    -> 64  Dividend Reinvestments (DRS)
    -> 75  Spinoff
    -> 77  Stock Split
    -> 89  Merger
  ID=10 R&D
    -> 3   Technical Problems
    -> 14  Test - Internal
    -> 22  P&L Adjustment
    -> 56  ReopenOperation
```

### 2.2 DWH Column Mapping vs. Production

**What**: The ETL renames `CompensationReasonID` to `DWHCompensationID` while keeping the original `CompensationReasonID` column, creating a redundant pair with identical values.

**Columns Involved**: `CompensationReasonID`, `DWHCompensationID`

**Rules**:
- `DWHCompensationID` = `CompensationReasonID` (exact same value, just a renamed copy)
- Both columns are available for JOINs; `CompensationReasonID` is the standard FK target
- Production columns dropped by DWH: `DisplayName` (alternative label), `IsShownInHistory` (controls BO history display), `IsCashflowForGain` (tax flag), `IsTaxable` (tax flag), `IsActive` (active/retired flag)

### 2.3 ID=0 N/A Placeholder

**What**: ID=0 is inserted by the ETL as a catch-all for unclassified or missing compensation reason references.

**Columns Involved**: `CompensationReasonID`, `Name`

**Rules**:
- ID=0 ("N/A") is ETL-computed, not from production `BackOffice.CompensationReason`
- `InsertDate` and `UpdateDate` for ID=0 use `CAST(GETDATE() AS DATE)` (date-only) vs `GETDATE()` (datetime) for all other rows
- Facts with CompensationReasonID=0 mean the original reason was absent or not mapped

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed with CLUSTERED INDEX on `CompensationReasonID`. 133 rows - zero-cost broadcast JOIN on every node.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Parquet at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason`. 133 rows, daily Override. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode a compensation reason ID | `JOIN Dim_CompensationReason ON CompensationReasonID` |
| Find root category for a reason | `JOIN Dim_CompensationReason child ON ... JOIN Dim_CompensationReason parent ON child.ParentID = parent.CompensationReasonID` |
| Find all marketing compensations | `WHERE CompensationReasonID IN (4, 20, 41, 51, 52, 53, 54, 58, 121)` |
| Find all dividend corporate actions | `WHERE CompensationReasonID = 45 OR ParentID = 45` |
| Find all accounting/ops adjustments | `WHERE CompensationReasonID = 9 OR ParentID = 9` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingCompensation (planned) | ON CompensationReasonID | Decode reason for each compensation entry |
| Production: Accounting.BalanceHistory | ON CompensationReasonID | Classifies manual account adjustments |

### 3.4 Gotchas

- **DWHCompensationID is redundant**: `DWHCompensationID` = `CompensationReasonID`. Always JOIN on `CompensationReasonID`; do not use `DWHCompensationID` as a FK target.
- **Two-level hierarchy only**: Self-join for category lookup is simple - child.ParentID always points directly to a root (no recursive CTE needed).
- **IDs 5 and 130 are absent**: These IDs do not exist in the DWH table. Fact rows referencing these IDs will return NULL on JOIN.
- **IsActive not available in DWH**: Production has an `IsActive` flag distinguishing current from retired reasons. DWH does not carry this - all 133 rows are present regardless of active status. Historical fact data may reference retired reasons.
- **IsCashflowForGain and IsTaxable dropped**: These tax-relevant flags from production are absent. Do not use this dimension for tax classification without joining back to production.
- **ID=0 InsertDate/UpdateDate type**: Date-only (DATE cast) vs datetime for all other rows - minor inconsistency if comparing timestamps.
- **Obsolete category still in use**: ID=23 "Obsolete" and its children (e.g., ID=2 "Position lost") appear on historical records. Do not filter these out by name.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|------------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CompensationReasonID | int | YES | Primary key. Unique reason identifier, 0-134 (IDs 5 and 130 absent). ID=0 is ETL-inserted N/A placeholder. Used as FK in Accounting.BalanceHistory and Fact_BillingCompensation. (Tier 1 - upstream wiki, BackOffice.CompensationReason) |
| 2 | ParentID | int | YES | Parent reason ID for 2-level hierarchy. NULL for root categories. Non-null values point directly to a root category row. Roots: 1=Custom, 4=Marketing, 9=Accounting/Ops, 10=R&D, 16=ACT, 23=Obsolete, 35=MT4, 45=Dividend, 48=Inactivity Fee For Non Depositor. (Tier 1 - upstream wiki, BackOffice.CompensationReason) |
| 3 | Name | varchar(100) | YES | Human-readable reason label used in BackOffice UI and reports. E.g., "Satisfaction Bonus", "Cash Dividend", "Dormant Fee". Passed through unchanged from production. (Tier 1 - upstream wiki, BackOffice.CompensationReason) |
| 4 | DWHCompensationID | int | YES | DWH rename of CompensationReasonID. DWHCompensationID = CompensationReasonID (identical values). Redundant column - use CompensationReasonID for all JOINs. Added by SP_Dictionaries_DL_To_Synapse ETL mapping. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | StatusID | int | YES | Active record flag hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from production BackOffice.CompensationReason. No filtering value - all rows have StatusID=1. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() on each daily reload for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | InsertDate | datetime | YES | ETL insert timestamp set to GETDATE() on each daily reload for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder. Not the date the reason was originally created in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CompensationReasonID | etoro.BackOffice.CompensationReason | CompensationReasonID | Passthrough |
| ParentID | etoro.BackOffice.CompensationReason | ParentID | Passthrough |
| Name | etoro.BackOffice.CompensationReason | Name | Passthrough |
| DWHCompensationID | etoro.BackOffice.CompensationReason | CompensationReasonID | Rename (CompensationReasonID -> DWHCompensationID) |
| StatusID | (ETL-computed) | - | Hardcoded to 1 |
| UpdateDate | (ETL-computed) | - | GETDATE() at load (DATE cast for ID=0) |
| InsertDate | (ETL-computed) | - | GETDATE() at load (DATE cast for ID=0) |

Dropped production columns not loaded into DWH: `DisplayName`, `IsShownInHistory`, `IsCashflowForGain`, `IsTaxable`, `IsActive`.

### 5.2 ETL Pipeline

```
etoro.BackOffice.CompensationReason (production, 130+ rows)
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_backoffice_compensationreason)
  -> DWH_staging.etoro_BackOffice_CompensationReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, CompensationReasonID->DWHCompensationID, StatusID=1)
  -> SP_Dictionaries_DL_To_Synapse (INSERT ID=0 placeholder, @ddate)
  -> DWH_dbo.Dim_CompensationReason (133 rows)
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.BackOffice.CompensationReason | Production compensation taxonomy |
| Lake | Bronze/etoro/BackOffice/CompensationReason/ | Daily Override export |
| Staging | DWH_staging.etoro_BackOffice_CompensationReason | Raw import from lake |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 1305-1328) | TRUNCATE + INSERT; CompensationReasonID->DWHCompensationID, StatusID=1 |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 1635-1678) | INSERT ID=0 N/A placeholder with @ddate |
| Target | DWH_dbo.Dim_CompensationReason | 133 rows (IDs 0-134, IDs 5+130 absent) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Target Element | Description |
|--------------|----------------|-------------|
| DWH_dbo.Dim_CompensationReason | CompensationReasonID | Self-reference: ParentID -> CompensationReasonID (2-level hierarchy) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingCompensation (planned) | CompensationReasonID | Each compensation entry records the reason |
| Production: Accounting.BalanceHistory | CompensationReasonID | Classifies every manual account adjustment |
| Production: BackOffice compensation procs | CompensationReasonID | BO tools pass reason code on every adjustment |

Note: No DWH_dbo SPs or Views currently JOIN this table (SSDT grep returned no matches).

---

## 7. Sample Queries

### 7.1 List all root categories
```sql
SELECT  CompensationReasonID,
        Name
FROM    [DWH_dbo].[Dim_CompensationReason]
WHERE   ParentID IS NULL
ORDER BY CompensationReasonID;
```

### 7.2 List all reasons with their parent category
```sql
SELECT  child.CompensationReasonID,
        child.Name          AS ReasonName,
        parent.Name         AS CategoryName
FROM    [DWH_dbo].[Dim_CompensationReason] child
LEFT JOIN [DWH_dbo].[Dim_CompensationReason] parent
        ON child.ParentID = parent.CompensationReasonID
ORDER BY parent.CompensationReasonID, child.CompensationReasonID;
```

### 7.3 Count compensations by root category
```sql
SELECT  ISNULL(parent.Name, child.Name) AS Category,
        COUNT(*) AS CompensationCount
FROM    [DWH_dbo].[Fact_BillingCompensation] f
JOIN    [DWH_dbo].[Dim_CompensationReason] child
        ON f.CompensationReasonID = child.CompensationReasonID
LEFT JOIN [DWH_dbo].[Dim_CompensationReason] parent
        ON child.ParentID = parent.CompensationReasonID
GROUP BY ISNULL(parent.Name, child.Name)
ORDER BY CompensationCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (BackOffice.CompensationReason, quality 9.1/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 8.8/10 (****) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 3 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CompensationReason | Type: Table | Production Source: etoro.BackOffice.CompensationReason*
