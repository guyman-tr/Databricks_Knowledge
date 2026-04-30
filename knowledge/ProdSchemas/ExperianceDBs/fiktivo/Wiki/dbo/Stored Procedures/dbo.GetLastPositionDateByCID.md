# dbo.GetLastPositionDateByCID

> Accepts a table-valued parameter of customer IDs and returns each customer's last opened position date from the AffiliateCommission.CustomerAggregatedData table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Affiliate managers and automated commission processes need to know when each referred customer last opened a trading position. This date is a key activity signal used in LTV (Lifetime Value) calculations, trader re-engagement campaigns, and activity-based commission eligibility checks.

This procedure accepts a batch of customer IDs via a table-valued parameter of type dbo.IDTableType and returns the LastOpenedPosition timestamp for each matched customer from the pre-aggregated AffiliateCommission.CustomerAggregatedData table. The aggregated table is used rather than querying individual position records directly, providing fast batch lookups without scanning large transactional tables.

---

## 2. Business Logic

### 2.1 Batch Last-Position Date Lookup

**What**: Joins the input CID list to CustomerAggregatedData to return the last opened position date per customer.

**Columns/Parameters Involved**: `@CIDs`, `cust.CID`, `cust.LastOpenedPosition`

**Rules**:
- Only CIDs present in both the input TVP and CustomerAggregatedData are returned (INNER JOIN semantics via the JOIN to @CIDs)
- CIDs in the input that have no row in CustomerAggregatedData are silently dropped
- LastOpenedPosition reflects the most recent position open date as pre-computed in the aggregated data table; it is not recalculated at query time
- The result is aliased as LastPositionDate for consistency with the application's expected column name

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @CIDs | IN | dbo.IDTableType (READONLY) | (required) | Table-valued parameter containing the customer IDs (CIDs) for which to retrieve the last position date. Defined by the dbo.IDTableType user-defined table type. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| AffiliateCommission.CustomerAggregatedData | SELECT (INNER JOIN) | Source of pre-aggregated customer activity data including last opened position date |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| CID | AffiliateCommission.CustomerAggregatedData | Customer identifier |
| LastPositionDate | AffiliateCommission.CustomerAggregatedData (LastOpenedPosition aliased) | The date and time of the customer's most recently opened trading position |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetLastPositionDateByCID (stored procedure)
+-- dbo.IDTableType (user-defined table type) [TVP input]
+-- AffiliateCommission.CustomerAggregatedData (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.IDTableType | User-Defined Table Type | Defines the shape of the CID input TVP |
| AffiliateCommission.CustomerAggregatedData | Table | Source of customer last-position aggregated data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| LTV calculation service | Application | Retrieves last position date for a batch of customers as part of LTV scoring |
| Commission eligibility check | Application | Verifies recent customer activity before applying activity-based commission rules |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON; callers receive rowcount messages
- WITH (NOLOCK) applied to AffiliateCommission.CustomerAggregatedData
- Uses dbo.IDTableType TVP; the ID column in that type is joined to cust.CID
- LastOpenedPosition is aliased as LastPositionDate in the result set
- The JOIN (not LEFT JOIN) means unmatched CIDs are silently excluded from results

---

## 8. Sample Queries

### 8.1 Get last position dates for a batch of customers

```sql
DECLARE @CIDs dbo.IDTableType;
INSERT INTO @CIDs VALUES (111111), (222222), (333333);
EXEC dbo.GetLastPositionDateByCID @CIDs = @CIDs;
```

### 8.2 Get the last position date for a single customer

```sql
DECLARE @CIDs dbo.IDTableType;
INSERT INTO @CIDs VALUES (111111);
EXEC dbo.GetLastPositionDateByCID @CIDs = @CIDs;
```

### 8.3 Find customers with no position in the last 90 days

```sql
DECLARE @CIDs dbo.IDTableType;
INSERT INTO @CIDs SELECT CID FROM dbo.tblaff_CustomersLTV WITH (NOLOCK);

SELECT c.CID, c.LastPositionDate
FROM (
    EXEC dbo.GetLastPositionDateByCID @CIDs = @CIDs
) c
WHERE c.LastPositionDate < DATEADD(DAY, -90, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetLastPositionDateByCID | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetLastPositionDateByCID.sql*
