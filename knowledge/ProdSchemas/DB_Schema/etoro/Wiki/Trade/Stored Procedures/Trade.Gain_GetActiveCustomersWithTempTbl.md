# Trade.Gain_GetActiveCustomersWithTempTbl

> Filtered version of Gain_GetActiveCustomers that returns only customers from a provided list who had trading activity in the specified date range.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinDate / @MaxDate + @customerIds (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a filtered variant of `Trade.Gain_GetActiveCustomers`. While the base procedure returns ALL active customers for a date range, this version accepts a pre-filtered list of customer IDs and returns only those that had trading activity during the period. This enables the Gain service to check activity for a specific subset of customers (e.g., a batch being processed) rather than scanning the entire customer base.

The activity detection logic is identical to `Gain_GetActiveCustomers` (four-way UNION), but the result is intersected with the provided customer list via an indexed temp table JOIN.

---

## 2. Business Logic

### 2.1 Filtered Four-Way Activity Detection

**What**: Same four-way UNION as Gain_GetActiveCustomers, filtered to a customer subset.

**Columns/Parameters Involved**: `@MinDate`, `@MaxDate`, `@customerIds`

**Rules**:
- Same four query patterns as Gain_GetActiveCustomers (closed in range, open before max, straddling start, straddling end)
- Results JOINed with @customerIds (materialized to #Tbl with NC index on CID)
- Only returns CIDs that appear in BOTH the activity union AND the input list

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinDate | datetime | NO | - | CODE-BACKED | Start of the gain calculation period. |
| 2 | @MaxDate | datetime | NO | - | CODE-BACKED | End of the gain calculation period. |
| 3 | @customerIds | Trade.CidList (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing CIDs to filter. READONLY. Only customers in this list are considered. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.Position | READER | Closed position activity detection |
| SELECT | Trade.Position (view) | READER | Open position activity detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Batch-filtered customer activity check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetActiveCustomersWithTempTbl (procedure)
+-- History.Position (table)
+-- Trade.Position (view)
+-- Trade.CidList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | SELECT - closed position activity |
| Trade.Position | View | SELECT - open position activity |
| Trade.CidList | User Defined Type | TVP type for @customerIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: NC INDEX IX_ID on #Tbl(CID).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check Activity for Specific Customers

```sql
DECLARE @cids Trade.CidList
INSERT INTO @cids VALUES (12345), (67890)
EXEC Trade.Gain_GetActiveCustomersWithTempTbl @MinDate = '2026-03-01', @MaxDate = '2026-03-31', @customerIds = @cids
```

### 8.2 Compare Full vs Filtered Active Customer Count

```sql
SELECT COUNT(DISTINCT CID) AS TotalActive FROM Trade.Position WITH (NOLOCK)
```

### 8.3 View CidList Type Definition

```sql
SELECT * FROM sys.table_types WHERE name = 'CidList' AND schema_id = SCHEMA_ID('Trade')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetActiveCustomersWithTempTbl | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetActiveCustomersWithTempTbl.sql*
