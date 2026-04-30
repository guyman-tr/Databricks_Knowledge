# Trade.GetUserRegulationsByBatch

> Batch regulation lookup - accepts a TVP of CIDs (Trade.CidList) and returns the effective regulation (DesignatedRegulationID ?? RegulationID) for each customer. Uses temp table + clustered index for TVP join performance.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cids TVP - batch of CIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserRegulationsByBatch` is a focused regulation lookup for batch scenarios. Given a set of CIDs, it returns each customer's effective regulation ID using the standard override pattern: `ISNULL(DesignatedRegulationID, RegulationID)`. This is the correct pattern for determining which regulatory framework governs a customer's trading - if a designated override is set it takes precedence, otherwise the base regulation applies.

The procedure materializes the TVP into a temp table (`#Cids`) with a clustered index before joining, which is a SQL Server performance best practice for TVP joins to avoid repeated scans of the table variable.

This is used by services that need to process a cohort of customers under different regulatory rules - e.g., fee calculation, instrument eligibility, or order validation that differs by regulation.

---

## 2. Business Logic

### 2.1 TVP Materialization Pattern

**What**: TVP is materialized into a temp table with a clustered index before joining.

**Rules**:
- `SELECT CID INTO #Cids FROM @Cids` - copies TVP to temp table
- `CREATE CLUSTERED INDEX ix_CID ON #Cids(CID)` - adds clustered index for join performance
- Then `INNER JOIN #Cids cids ON c.CID = cids.CID` in the main query
- This avoids the O(N) scan that would result from joining directly to the TVP

### 2.2 Effective Regulation Resolution

**What**: Returns the regulatory framework that actually governs the customer.

**Rules**:
- `ISNULL(c.DesignatedRegulationID, c.RegulationID) AS RegulationID`
- DesignatedRegulationID: regulatory override (e.g., for customers re-classified by compliance)
- RegulationID: base regulation assigned at registration
- This is the definitive pattern for effective regulation - used consistently across the Trade schema (GetTreeNodesByParentCID_Inner, GetUserRegulationsByBatch both use this)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cids | Trade.CidList READONLY | NO | - | CODE-BACKED | TVP of CIDs to look up. Column name in TVP: CID. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID from BackOffice.Customer. |
| 3 | RegulationID | INT | NO | - | CODE-BACKED | Effective regulation: ISNULL(DesignatedRegulationID, RegulationID). The regulation that governs this customer's trading. FK to Dictionary.Regulation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | Trade.CidList | User Defined Type | Input TVP type |
| FROM | BackOffice.Customer | FROM | Source of DesignatedRegulationID and RegulationID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (batch regulation services) | @Cids TVP | EXEC caller | Bulk regulation lookup for cohort processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserRegulationsByBatch (procedure)
+-- Trade.CidList (UDT - TVP type)
+-- BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User Defined Type | Input TVP for batch CIDs |
| BackOffice.Customer | Table | Source of RegulationID and DesignatedRegulationID |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #Cids clustered index | Performance pattern | TVP materialized to temp table to enable efficient clustered join |
| WITH (NOLOCK) | Isolation | BackOffice.Customer read uses dirty read |
| ISNULL(DesignatedRegulationID, RegulationID) | Business rule | Standard effective-regulation pattern |

---

## 8. Sample Queries

### 8.1 Batch regulation lookup
```sql
DECLARE @cids Trade.CidList;
INSERT INTO @cids VALUES (123456), (234567), (345678);
EXEC Trade.GetUserRegulationsByBatch @Cids = @cids;
```

### 8.2 Equivalent direct query
```sql
SELECT c.CID, ISNULL(c.DesignatedRegulationID, c.RegulationID) AS RegulationID
FROM BackOffice.Customer c WITH (NOLOCK)
WHERE c.CID IN (123456, 234567, 345678)
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Batch regulation utility procedure not separately documented.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserRegulationsByBatch | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserRegulationsByBatch.sql*
