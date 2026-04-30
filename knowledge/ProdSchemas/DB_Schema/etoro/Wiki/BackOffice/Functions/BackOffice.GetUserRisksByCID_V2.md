# BackOffice.GetUserRisksByCID_V2

> Inline table-valued function returning a customer's CID, GCID, and alphabetically-sorted active risk status names - the most robust variant using STRING_AGG with ORDER BY and LEFT JOIN semantics that returns a row even for customers with no risk flags.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(CID, GCID, RiskStatusesNames) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUserRisksByCID_V2` is the most refined version of the risk status retrieval function family. It returns CID, GCID, and a comma-separated list of active risk status names in alphabetical order. The key behavioral difference from `GetUserRisksByCID_AGG` is:

1. **LEFT JOIN instead of INNER JOIN** for `Customer.CustomerStatic` to `BackOffice.CustomerRisk`: customers with NO risk flags still get a row returned (with `RiskStatusesNames = NULL`), rather than returning no rows.
2. **WITHIN GROUP (ORDER BY Name)**: Risk status names are returned in alphabetical order for consistency.
3. **Risk filter moved to subquery**: The `RiskStatusID > 1` and `IsActive = 1` filters are in a derived subquery (RES), not in the main WHERE clause, enabling the LEFT JOIN semantics.

This version is used in `BackOffice.GetBlockedCustomers`, where it's critical to return ALL customers including those with no current risk flags. A customer may be "blocked" for reasons other than risk status, so the function must return a row even when `RiskStatusesNames` is NULL.

---

## 2. Business Logic

### 2.1 LEFT JOIN with Derived Risk Subquery

**What**: Separates risk aggregation into a subquery (RES), LEFT JOINed to CustomerStatic, so customers with zero qualifying risk flags still appear in output.

**Columns/Parameters Involved**: `@CID`, `CID`, `GCID`, `RiskStatusesNames`

**Rules**:
- Outer query: `FROM Customer.CustomerStatic CS` WHERE CID=@CID
- LEFT JOIN to derived subquery RES: `(SELECT DRS.Name, BCR.GCID FROM BackOffice.CustomerRisk BCR INNER JOIN Dictionary.RiskStatus DRS ... INNER JOIN Dictionary.RiskEventStatus DRE ... WHERE BCR.RiskStatusID > 1 AND DRE.IsActive = 1) RES ON CS.GCID = RES.GCID`
- `STRING_AGG(RES.Name, ',') WITHIN GROUP (ORDER BY RES.Name)` - alphabetical ordering
- GROUP BY CS.CID, CS.GCID
- Returns NULL for RiskStatusesNames when no active risk flags exist (vs. _AGG which may return no rows)

**Diagram**:
```
@CID
  |
  v
Customer.CustomerStatic WHERE CID=@CID
  |
  LEFT JOIN (subquery RES)
    BackOffice.CustomerRisk
    INNER JOIN Dictionary.RiskStatus
    INNER JOIN Dictionary.RiskEventStatus
    WHERE RiskStatusID > 1 AND IsActive = 1
  ON CS.GCID = RES.GCID
  |
  GROUP BY CS.CID, CS.GCID
  STRING_AGG(RES.Name, ',') WITHIN GROUP (ORDER BY RES.Name)
  |
  v
Returns: CID | GCID | RiskStatusesNames (NULL if no active flags)
Always returns 1 row per @CID if @CID exists in CustomerStatic
```

### 2.2 Behavioral Comparison Across Variants

**What**: The three variants differ in JOIN type, concatenation method, and output ordering.

**Columns/Parameters Involved**: `RiskStatusesNames`

**Rules**:
- GetUserRisksByCID: STUFF+FOR XML PATH, INNER JOINs, no order guarantee, VARCHAR(1000) limit, may return no rows if no risk
- GetUserRisksByCID_AGG: STRING_AGG, INNER JOINs (all 4 tables), no order guarantee, may return no rows if no risk
- GetUserRisksByCID_V2 (this): STRING_AGG WITHIN GROUP ORDER BY Name, LEFT JOIN for CustomerStatic-to-Risk, alphabetical output, ALWAYS returns 1 row (NULL names if no risk)

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve risk statuses for. Filters Customer.CustomerStatic by CID. Returns a row even if the customer has no active risk flags. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID from Customer.CustomerStatic, matching @CID. |
| 2 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID (group identifier) from Customer.CustomerStatic. |
| 3 | RiskStatusesNames | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated string of active risk status names in alphabetical order (STRING_AGG WITHIN GROUP ORDER BY Name). Only includes RiskStatusID > 1 AND RiskEventStatus.IsActive=1. Returns NULL if the customer has no qualifying risk flags. A NULL result does NOT mean no row - the function always returns 1 row if @CID exists in CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Table read | WHERE CID=@CID - outer table in LEFT JOIN. Always returns 1 row if CID exists. |
| GCID | BackOffice.CustomerRisk | Table join | INNER JOIN in subquery RES; LEFT JOINed result to CustomerStatic. Risk records at GCID scope. |
| RiskStatusID | Dictionary.RiskStatus | Lookup | INNER JOIN in subquery to get Name. Filtered to RiskStatusID > 1. |
| RiskEventStatusID | Dictionary.RiskEventStatus | Lookup | INNER JOIN in subquery; filtered to IsActive=1. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetBlockedCustomers | DRSK.RiskStatusesNames | OUTER APPLY | Blocked customers report - risk flags shown for ALL blocked customers including those with no current risk flags. V2 chosen specifically for the LEFT JOIN behavior. |
| BackOffice.GetBlockedCustomers_Test_JUNKYulia0325 | DRSK.RiskStatusesNames | OUTER APPLY | Test/JUNK version of the blocked customers report. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserRisksByCID_V2 (function)
├── Customer.CustomerStatic (table) [cross-schema]
├── BackOffice.CustomerRisk (table)
├── Dictionary.RiskStatus (table) [cross-schema]
└── Dictionary.RiskEventStatus (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Outer left-hand side WHERE CID=@CID. Guarantees at least one row is returned. |
| BackOffice.CustomerRisk | Table | INNER JOIN in derived subquery RES; filtered to RiskStatusID > 1. |
| Dictionary.RiskStatus | Table | INNER JOIN in subquery to get Name for aggregation. |
| Dictionary.RiskEventStatus | Table | INNER JOIN in subquery; IsActive=1 filter. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetBlockedCustomers | Stored Procedure | OUTER APPLY - risk flags in blocked customers report. V2 chosen for guaranteed row return even when no active risk. |
| BackOffice.GetBlockedCustomers_Test_JUNKYulia0325 | Stored Procedure | OUTER APPLY - test version of blocked customers report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. Requires SQL Server 2017+ for STRING_AGG WITHIN GROUP.

---

## 8. Sample Queries

### 8.1 Get active risk statuses (alphabetically sorted)

```sql
SELECT CID, GCID, RiskStatusesNames
FROM BackOffice.GetUserRisksByCID_V2(12345) WITH (NOLOCK);
-- Always returns 1 row; RiskStatusesNames is NULL if no active flags
```

### 8.2 Use with OUTER APPLY on blocked customers list (primary usage pattern)

```sql
SELECT
    c.CID,
    c.UserName,
    r.RiskStatusesNames
FROM BackOffice.CustomerBlackList bc WITH (NOLOCK)
JOIN BackOffice.Customer c WITH (NOLOCK) ON c.CID = bc.CID
OUTER APPLY BackOffice.GetUserRisksByCID_V2(c.CID) r;
```

### 8.3 Identify customers with multiple simultaneous risk flags

```sql
SELECT CID, GCID, RiskStatusesNames,
    LEN(RiskStatusesNames) - LEN(REPLACE(RiskStatusesNames, ',', '')) + 1 AS RiskFlagCount
FROM BackOffice.GetUserRisksByCID_V2(12345) WITH (NOLOCK)
WHERE RiskStatusesNames IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific version.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserRisksByCID_V2 | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUserRisksByCID_V2.sql*
