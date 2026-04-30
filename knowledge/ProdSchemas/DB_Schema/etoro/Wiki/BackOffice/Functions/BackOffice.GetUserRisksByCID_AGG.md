# BackOffice.GetUserRisksByCID_AGG

> Inline table-valued function returning a customer's CID, GCID, and active risk status names as a comma-separated STRING_AGG result - the modernized version of GetUserRisksByCID using SQL Server 2017+ syntax.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(CID, GCID, RiskStatusesNames) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUserRisksByCID_AGG` is the modernized replacement for `BackOffice.GetUserRisksByCID`, returning the same active risk status summary for a customer but using SQL Server 2017+'s `STRING_AGG` function instead of the older STUFF+FOR XML PATH pattern. Created by Shay Oren on 14/11/2021 as part of OPSE-236 (DB task under OPSE-164 "OPS1743 - Add PIPS in USD to BO reports").

The output is identical in meaning: a single row per CID containing CID, GCID, and a comma-separated list of active risk status names. Risk flags where `RiskStatusID > 1` AND `RiskEventStatus.IsActive = 1` are included. The `_AGG` suffix reflects the STRING_AGG aggregation approach.

This version is used in the billing deposit reports (`BillingDepositsPCIVersion`) and is called via `OUTER APPLY` - the same pattern as the original version. The STRING_AGG version is more readable and avoids the XML type casting overhead.

---

## 2. Business Logic

### 2.1 STRING_AGG Risk Status Aggregation

**What**: Uses SQL Server STRING_AGG to produce a comma-separated list of active risk status names in a single aggregation step.

**Columns/Parameters Involved**: `@CID`, `CID`, `GCID`, `RiskStatusesNames`

**Rules**:
- `STRING_AGG(DRS.Name, ',') AS RiskStatusesNames` - comma-separated concatenation without trailing comma
- All four tables are INNER JOINed (unlike GetUserRisksByCID_V2 which uses LEFT JOIN for CustomerStatic)
- Filter 1: `DRE.IsActive = 1` - active risk event statuses only
- Filter 2: `BCR.RiskStatusID > 1` - exclude baseline/no-risk status
- GROUP BY CS.CID, CS.GCID (required for STRING_AGG aggregation)
- Returns one row per CID/GCID combination; NULL if no active risk flags exist for the customer group

**Diagram**:
```
@CID
  |
  v
Customer.CustomerStatic WHERE CID=@CID (INNER JOIN)
  |
  INNER JOIN BackOffice.CustomerRisk ON GCID
  INNER JOIN Dictionary.RiskStatus ON RiskStatusID
  INNER JOIN Dictionary.RiskEventStatus ON RiskEventStatusID
  WHERE DRE.IsActive=1 AND BCR.RiskStatusID > 1
  GROUP BY CS.CID, CS.GCID
  |
  v
STRING_AGG(DRS.Name, ',') -> "FraudSuspicion,HighRiskCountry"
  |
  v
Returns: CID | GCID | RiskStatusesNames
```

### 2.2 Behavioral Difference vs. GetUserRisksByCID

**What**: STRING_AGG vs. FOR XML PATH - same result, different implementation.

**Columns/Parameters Involved**: `RiskStatusesNames`

**Rules**:
- GetUserRisksByCID: STUFF + FOR XML PATH - compatible with SQL Server 2012+, order non-deterministic, VARCHAR(1000) limit
- GetUserRisksByCID_AGG: STRING_AGG(Name, ',') - SQL Server 2017+ required, no length limit, order non-deterministic
- GetUserRisksByCID_V2: STRING_AGG WITHIN GROUP (ORDER BY Name) - ordered output, LEFT JOIN approach
- All three return NULL if no active risk flags exist for the @CID

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve risk statuses for. Filters Customer.CustomerStatic by CID to resolve to GCID, then risk flags are pulled at GCID scope covering all linked accounts. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID from Customer.CustomerStatic, matching the input @CID. |
| 2 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID (group identifier). Risk flags in BackOffice.CustomerRisk are tracked at GCID level. |
| 3 | RiskStatusesNames | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated string of active risk status names for the customer's GCID (STRING_AGG output). Only includes RiskStatusID > 1 AND RiskEventStatus.IsActive=1. No trailing comma (unlike STUFF version). NULL if no qualifying risk flags exist. No length limit (unlike 1000-char limit in GetUserRisksByCID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Table read | INNER JOIN WHERE CID=@CID to get GCID. |
| GCID | BackOffice.CustomerRisk | Table join | INNER JOIN ON BCR.GCID=CS.GCID - source of risk flag records. |
| RiskStatusID | Dictionary.RiskStatus | Lookup | INNER JOIN to get Name for STRING_AGG. |
| RiskEventStatusID | Dictionary.RiskEventStatus | Lookup | INNER JOIN; filtered to IsActive=1. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion | DRSK.RiskStatusesNames | OUTER APPLY | Billing deposits report - risk flags shown alongside each deposit. |
| BackOffice.BillingDepositsPCIVersion_Old | DRSK.RiskStatusesNames | OUTER APPLY | Legacy billing deposits report. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserRisksByCID_AGG (function)
├── Customer.CustomerStatic (table) [cross-schema]
├── BackOffice.CustomerRisk (table)
├── Dictionary.RiskStatus (table) [cross-schema]
└── Dictionary.RiskEventStatus (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INNER JOIN WHERE CID=@CID to resolve CID to GCID. |
| BackOffice.CustomerRisk | Table | INNER JOIN ON BCR.GCID=CS.GCID - risk flag records at GCID scope. |
| Dictionary.RiskStatus | Table | INNER JOIN ON RiskStatusID to get Name for STRING_AGG. |
| Dictionary.RiskEventStatus | Table | INNER JOIN ON RiskEventStatusID; WHERE IsActive=1. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | OUTER APPLY - risk flags in billing deposit PCI report. |
| BackOffice.BillingDepositsPCIVersion_Old | Stored Procedure | OUTER APPLY - legacy billing deposit report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. Requires SQL Server 2017+ for STRING_AGG support.

---

## 8. Sample Queries

### 8.1 Get active risk statuses for a customer

```sql
SELECT CID, GCID, RiskStatusesNames
FROM BackOffice.GetUserRisksByCID_AGG(12345) WITH (NOLOCK);
```

### 8.2 Use with OUTER APPLY on multiple customers (billing report pattern)

```sql
SELECT
    bd.DepositID,
    bd.CID,
    bd.Amount / 100.0 AS AmountUSD,
    risk.RiskStatusesNames
FROM Billing.Deposit bd WITH (NOLOCK)
OUTER APPLY BackOffice.GetUserRisksByCID_AGG(bd.CID) risk
WHERE bd.DepositDate >= DATEADD(DAY, -7, GETDATE());
```

### 8.3 Compare output across all three risk function variants

```sql
SELECT
    v1.RiskStatusesNames AS GetUserRisksByCID,
    v2.RiskStatusesNames AS GetUserRisksByCID_AGG,
    v3.RiskStatusesNames AS GetUserRisksByCID_V2
FROM BackOffice.GetUserRisksByCID(12345) WITH (NOLOCK) v1
CROSS JOIN BackOffice.GetUserRisksByCID_AGG(12345) WITH (NOLOCK) v2
CROSS JOIN BackOffice.GetUserRisksByCID_V2(12345) WITH (NOLOCK) v3;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [OPSE-236: DB Task](https://etoro-jira.atlassian.net/browse/OPSE-236) | Jira Sub-task | DB task under OPSE-164 "OPS1743 - Add PIPS in USD to BO reports". Assigned to Shay Oren, created 14/11/2021. This function was created as part of the PIPS in USD reporting enhancement, likely to improve performance and modern syntax of risk status retrieval. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserRisksByCID_AGG | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUserRisksByCID_AGG.sql*
