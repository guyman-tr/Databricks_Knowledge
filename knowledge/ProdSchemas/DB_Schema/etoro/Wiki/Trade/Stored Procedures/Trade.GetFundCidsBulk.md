# Trade.GetFundCidsBulk

> Returns FundAccountID (as CID) and FundID for a bulk list of CIDs. Used for bulk fund-account lookups via table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | FundAccountID, FundID per CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a bulk lookup of fund account relationships. Given a list of CIDs (via table-valued parameter Trade.CidList), it returns the corresponding FundAccountID (treated as CID in the fund context) and FundID. It supports batch processing when many customers need fund mapping in one call.

The procedure exists to avoid N+1 round-trips when multiple CIDs need fund lookups. Applications can pass hundreds of CIDs in a single call and get all mappings back.

Data flow: caller populates Trade.CidList TVP with CID values, passes it to the procedure. The procedure copies the TVP to a temp table with a clustered index for join performance, then joins to Trade.Fund. Only rows where the CID matches FundAccountID in Trade.Fund are returned.

---

## 2. Business Logic

### 2.1 Temp Table for Bulk Join Performance

**What**: The TVP is copied to a temp table with a clustered index on the CID column before joining to Trade.Fund.

**Columns/Parameters Involved**: `@CIDs`, temp table

**Rules**:
- Trade.CidList TVP is copied to a #temp table
- Clustered index on the CID column improves join performance
- Ensures bulk operations scale well for large input lists

### 2.2 FundAccountID as CID Mapping

**What**: FundAccountID in Trade.Fund corresponds to CID in customer context. The output returns FundAccountID as the CID-equivalent and FundID.

**Columns/Parameters Involved**: `FundAccountID`, `FundID`

**Rules**:
- JOIN condition: input CID = Trade.Fund.FundAccountID
- Only funds where FundAccountID matches an input CID are returned
- CIDs not linked to any fund produce no output row

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | Trade.CidList | NO | - | CODE-BACKED | Table-valued parameter. Bulk list of Customer IDs to look up. READONLY. |
| 2 | FundAccountID | INT | NO | - | CODE-BACKED | Output. Same as CID in fund context. Primary identifier for the fund account. FK to Trade.Fund.FundAccountID. |
| 3 | FundID | INT | NO | - | CODE-BACKED | Output. Fund identifier. FK to Trade.Fund. Identifies the fund entity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | Trade.CidList | TVP | User-defined type for bulk CID input |
| (body) | Trade.Fund | JOIN | FundAccountID and FundID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFundCidsBulk (procedure)
+-- Trade.CidList (user-defined type)
+-- Trade.Fund (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User-Defined Type | TVP parameter type |
| Trade.Fund | Table | JOIN - FundAccountID, FundID lookup |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute with a small CID list

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (1001), (1002), (1003);
EXEC Trade.GetFundCidsBulk @CIDs = @CIDs;
```

### 8.2 Bulk lookup from a table

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID)
SELECT DISTINCT CID FROM SomeTable WITH (NOLOCK) WHERE Processed = 0;
EXEC Trade.GetFundCidsBulk @CIDs = @CIDs;
```

### 8.3 Use results in downstream JOIN

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) SELECT CID FROM #MyCustomers;

CREATE TABLE #Results (FundAccountID INT, FundID INT);
INSERT INTO #Results (FundAccountID, FundID)
EXEC Trade.GetFundCidsBulk @CIDs = @CIDs;

SELECT  r.FundAccountID, r.FundID, c.CustomerName
FROM    #Results r
        INNER JOIN Customer.Customer c WITH (NOLOCK) ON c.CID = r.FundAccountID;
DROP TABLE #Results;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFundCidsBulk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFundCidsBulk.sql*
