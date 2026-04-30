# AffiliateCommission.CustomerAggregatedData_ADF

> Azure Data Factory variant of the customer aggregated data table, providing the same commission summary structure for the ADF pipeline. Currently empty.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

CustomerAggregatedData_ADF is the Azure Data Factory variant of CustomerAggregatedData. It has an identical structure (with CID as bigint instead of int) and serves the same purpose - storing per-customer trading commission aggregates - but is populated via the ADF data pipeline instead of the traditional stored procedure path.

This table exists as part of the migration to Azure Data Factory for data processing. The ADF suffix follows the same pattern as ClosedPositionFromEtoro_ADF. The table is currently empty (0 rows), suggesting the ADF pipeline is not active in this environment or the data has been migrated to the standard table.

The table uses bigint for CID (vs int in CustomerAggregatedData), which aligns with the newer schema convention used throughout the AffiliateCommission schema.

---

## 2. Business Logic

No complex business logic. Same aggregation model as CustomerAggregatedData - see that table's documentation for details.

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer ID. PK. Uses bigint (vs int in CustomerAggregatedData) - newer schema convention. |
| 2 | TotalCommissionOnOpen | money | YES | - | CODE-BACKED | Cumulative commission from position opening events. |
| 3 | TotalCommissionOnClose | money | YES | - | CODE-BACKED | Cumulative commission from position closing events. |
| 4 | LastClosedPosition | datetime | YES | - | CODE-BACKED | Timestamp of most recent position close. |
| 5 | LastOpenedPosition | datetime | YES | - | CODE-BACKED | Timestamp of most recent position open. |
| 6 | OpenedPositionsCommissionOnOpen | money | NO | - | CODE-BACKED | Current total commission on still-open positions. |
| 7 | DateModified | datetime | YES | - | CODE-BACKED | Last aggregate update timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in this schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAggregatedData_ADF | CLUSTERED PK | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerAggregatedData_ADF | PRIMARY KEY | Unique customer identifier |

---

## 8. Sample Queries

### 8.1 Check if ADF pipeline has populated data
```sql
SELECT COUNT(*) AS TotalRows FROM AffiliateCommission.CustomerAggregatedData_ADF WITH (NOLOCK);
```

### 8.2 Compare row counts between standard and ADF tables
```sql
SELECT 'Standard' AS Source, COUNT(*) AS Rows FROM AffiliateCommission.CustomerAggregatedData WITH (NOLOCK)
UNION ALL
SELECT 'ADF', COUNT(*) FROM AffiliateCommission.CustomerAggregatedData_ADF WITH (NOLOCK);
```

### 8.3 Top customers by close commission (if populated)
```sql
SELECT TOP 10 CID, TotalCommissionOnClose, LastClosedPosition
FROM AffiliateCommission.CustomerAggregatedData_ADF WITH (NOLOCK)
ORDER BY ISNULL(TotalCommissionOnClose, 0) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CustomerAggregatedData_ADF | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CustomerAggregatedData_ADF.sql*
