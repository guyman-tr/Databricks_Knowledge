# Customer.CreditExtended_TEMP

> Staging copy of Customer.CreditExtended with identical structure and zero rows - used as a transient work table for bulk credit snapshot operations before promotion to the live CreditExtended table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID + MirrorID (composite PK, clustered) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK only) |

---

## 1. Business Meaning

Customer.CreditExtended_TEMP is a staging/transient table with an identical column structure to Customer.CreditExtended. It holds zero rows in the current environment, indicating it is used as a temporary work surface during batch snapshot operations rather than as a live data store.

The pattern follows a common SQL Server ETL approach: bulk-insert calculated credit snapshots into the _TEMP table first (avoiding locks on the live table), validate the data, then swap or merge into Customer.CreditExtended. The "TEMP" suffix is a naming convention for transient staging tables that parallels the structure of their live counterpart.

No stored procedure consumers were found in the SSDT codebase scan, suggesting either the table is populated by application-layer code or a maintenance job that references it dynamically. It may also be part of the Maintenance.JOB_InsertHistoryCreditExtended pipeline that manages credit snapshot archival.

---

## 2. Business Logic

### 2.1 Staging Pattern (Mirror of Customer.CreditExtended)

**What**: Identical structure to CreditExtended - same columns, same PK, same MirrorID=0 default. Used as intermediate staging before updating live data.

**Columns/Parameters Involved**: All columns (identical to Customer.CreditExtended)

**Rules**:
- MirrorID=0 row: Total* columns hold customer-level aggregates; Mirror* columns are NULL
- MirrorID>0 rows: Mirror* columns hold per-copy-trade amounts; Total* columns are NULL
- On staging use: data is written here first, then promoted to Customer.CreditExtended
- Current state: 0 rows (not in active use or recently cleared after last operation)

### 2.2 Differences from Customer.CreditExtended

**What**: Minor PK constraint naming differs; no DEFAULT constraint on MirrorID.

**Rules**:
- PK name: `PK_CustomerCreditExtended_Temp` (vs `PK_CustomerCreditExtended_TempEtoro` on live table)
- No DEFAULT constraint on MirrorID in TEMP (callers must supply MirrorID explicitly)
- No synonym exists for this table (unlike live table which has dbo.RW_Customer_CreditExtended)

---

## 3. Data Overview

*Customer.CreditExtended_TEMP is currently empty (0 rows). Structure is identical to Customer.CreditExtended.*

For column semantics and data patterns, see [Customer.CreditExtended](Customer.CreditExtended.md).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - part of composite PK. Matches CID semantics in Customer.CreditExtended. |
| 2 | TotalPositionsAmount | money | YES | - | CODE-BACKED | Total value of all open positions. Populated on MirrorID=0 staging rows. See Customer.CreditExtended for full semantics. |
| 3 | TotalCash | money | YES | - | CODE-BACKED | Total cash balance (USD). Populated on MirrorID=0 staging rows. |
| 4 | Credit | money | YES | - | CODE-BACKED | Credit/bonus balance. On MirrorID=0 staging rows. |
| 5 | InProcessCashouts | money | YES | - | CODE-BACKED | Pending withdrawal amount. On MirrorID=0 staging rows. |
| 6 | TotalMirrorPositionsAmount | money | YES | - | CODE-BACKED | Aggregate positions across all copy-trade mirrors. On MirrorID=0 staging rows. |
| 7 | TotalMirrorCash | money | YES | - | CODE-BACKED | Aggregate cash across all copy-trade mirrors. On MirrorID=0 staging rows. |
| 8 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror identifier. 0=account totals row; >0=specific copy-trade relationship. No DEFAULT constraint in TEMP table (unlike live table). |
| 9 | MirrorPositionsAmount | money | YES | - | CODE-BACKED | Positions for a specific mirror. On per-mirror staging rows (MirrorID>0). |
| 10 | MirrorCash | money | YES | - | CODE-BACKED | Cash for a specific mirror. On per-mirror staging rows. |
| 11 | TotalStockOrders | money | YES | - | CODE-BACKED | Total pending stock orders. On MirrorID=0 staging rows. |
| 12 | TotalMirrorStockOrders | money | YES | - | CODE-BACKED | Aggregate pending stock orders across all mirrors. On MirrorID=0 staging rows. |
| 13 | MirrorStockOrders | money | YES | - | CODE-BACKED | Pending stock orders for a specific mirror. On per-mirror staging rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No stored procedure consumers identified in SSDT scan. This table is likely populated by application-layer code or referenced dynamically by a maintenance job outside the SSDT codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No stored procedure consumers found. See business meaning for staging pattern context.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerCreditExtended_Temp | CLUSTERED | CID ASC, MirrorID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerCreditExtended_Temp | PRIMARY KEY | CID + MirrorID must be unique - one row per customer per mirror |

---

## 8. Sample Queries

### 8.1 Check if staging table has data

```sql
SELECT COUNT(*) AS StagingRowCount
FROM Customer.CreditExtended_TEMP WITH (NOLOCK)
-- Returns 0 when not in active use
```

### 8.2 Compare staging to live (when populated)

```sql
SELECT
    t.CID,
    t.MirrorID,
    t.TotalCash AS StagingCash,
    ce.TotalCash AS LiveCash
FROM Customer.CreditExtended_TEMP t WITH (NOLOCK)
FULL OUTER JOIN Customer.CreditExtended ce WITH (NOLOCK)
    ON ce.CID = t.CID AND ce.MirrorID = t.MirrorID
WHERE t.TotalCash <> ce.TotalCash OR t.CID IS NULL OR ce.CID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CreditExtended_TEMP | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CreditExtended_TEMP.sql*
