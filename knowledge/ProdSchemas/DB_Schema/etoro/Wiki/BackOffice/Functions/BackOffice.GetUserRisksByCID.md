# BackOffice.GetUserRisksByCID

> Inline table-valued function returning a customer's CID, GCID, and a comma-separated string of their active risk status names - the original XML PATH concatenation version for BackOffice risk display.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(CID, GCID, RiskStatusesNames) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUserRisksByCID` returns the customer's identifiers (CID and GCID) together with a comma-separated string listing all active risk status names currently flagged against that customer's group. The result directly answers the BackOffice question: "What risk alerts does this customer have right now?"

The function joins `Customer.CustomerStatic` (for CID/GCID) to `BackOffice.CustomerRisk` (the risk flag registry) to `Dictionary.RiskStatus` (the risk status labels) and `Dictionary.RiskEventStatus` (for active/inactive filtering). Only risk statuses that are both `RiskStatusID > 1` (i.e., not the "no risk" baseline status) AND have `RiskEventStatus.IsActive = 1` are included in the output string.

This function is used via `OUTER APPLY` across multiple BackOffice procedures to append the customer's risk status summary to query results. The risk string drives visual highlighting in the BackOffice UI - a customer with "FraudSuspicion,HighRiskCountry" in their risk column gets flagged for agent review.

**Variants**: Three versions exist for this same logic:
- `GetUserRisksByCID` (this): Original STUFF+FOR XML PATH concatenation (pre-SQL Server 2017)
- `GetUserRisksByCID_AGG`: STRING_AGG version (SQL Server 2017+, created Nov 2021 OPSE-236)
- `GetUserRisksByCID_V2`: STRING_AGG with ORDER BY + LEFT JOIN instead of INNER JOIN

---

## 2. Business Logic

### 2.1 Active Risk Status Aggregation with GCID Scope

**What**: Collects all active risk flags for the customer's group (GCID), not just the individual CID.

**Columns/Parameters Involved**: `@CID`, `GCID`, `RiskStatusID`, `RiskEventStatusID`, `RiskStatusesNames`

**Rules**:
- Scope is GCID (Global Customer ID), not CID. A customer group (GCID) includes all linked accounts. Risk flags at the GCID level apply to all accounts in the group.
- Filter 1: `DRE.IsActive = 1` - only currently active risk event statuses (RiskEventStatusID active)
- Filter 2: `BCR.RiskStatusID > 1` - excludes status ID=1 which represents "no risk" or baseline state
- Both filters must be true for a risk status to appear in the output string.
- Concatenation uses STUFF + FOR XML PATH to build comma-separated list with no leading comma.
- Returns one row per CID with all risk names collapsed into a single string.

**Diagram**:
```
@CID
  |
  v
Customer.CustomerStatic WHERE CID=@CID
  |
  CID + GCID
  |
  v
INNER JOIN BackOffice.CustomerRisk ON BCR.GCID = CS.GCID
  |
  +-- INNER JOIN Dictionary.RiskStatus ON RiskStatusID (get Name)
  +-- INNER JOIN Dictionary.RiskEventStatus ON RiskEventStatusID
  |
  WHERE DRE.IsActive=1 AND BCR.RiskStatusID > 1
  |
  v
STUFF(FOR XML PATH) -> "FraudSuspicion,HighRiskCountry,"
  |
  v
Returns: CID | GCID | RiskStatusesNames
```

### 2.2 FOR XML PATH Concatenation Pattern

**What**: String aggregation using SQL Server's FOR XML PATH trick for pre-2017 compatibility.

**Columns/Parameters Involved**: `RiskStatusesNames`

**Rules**:
- `STUFF((SELECT CONCAT(',', DRS.Name) ... FOR XML PATH(''), TYPE).value('.','varchar(1000)'), 1, 1, '')` removes the leading comma.
- TYPE.value() ensures XML special characters (&, <, >) are decoded properly.
- Result is capped at VARCHAR(1000) - very long risk strings (many statuses) are truncated at 1000 chars.
- Superseded by STRING_AGG in GetUserRisksByCID_AGG for simpler syntax and potentially better performance.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve risk statuses for. Used to filter Customer.CustomerStatic by CID, then the GCID is used to join BackOffice.CustomerRisk. Risk flags at the GCID level cover all linked accounts in the customer group. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID passed in via @CID. Returned as an output column for caller convenience when using OUTER APPLY across multiple customers. |
| 2 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID (group identifier). Risk flags in BackOffice.CustomerRisk are tracked at GCID level, covering all linked accounts. From Customer.CustomerStatic. |
| 3 | RiskStatusesNames | VARCHAR(1000) | YES | NULL | CODE-BACKED | Comma-separated string of active risk status names for the customer's GCID. Only includes risk statuses where RiskStatusID > 1 AND RiskEventStatus.IsActive=1. NULL if the customer has no active risk flags meeting these criteria. Maximum 1000 characters. Example: "FraudSuspicion,HighRiskFATFCountry,TooManyCreditCards". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Table read | WHERE CID=@CID to get GCID. Bridge between the input CID and the GCID-scoped risk data. |
| GCID | BackOffice.CustomerRisk | Table join | INNER JOIN ON BCR.GCID = CS.GCID. Source of risk flag records. |
| RiskStatusID | Dictionary.RiskStatus | Lookup | INNER JOIN to get risk status Name string. |
| RiskEventStatusID | Dictionary.RiskEventStatus | Lookup | INNER JOIN to filter to IsActive=1 (active risk event statuses only). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerAcceptance | DRST.RiskStatusesNames | OUTER APPLY | Customer acceptance workflow - shows risk flags during the acceptance decision. |
| BackOffice.GetPepReport | rs.RiskStatusesNames | OUTER APPLY | PEP (Politically Exposed Person) report - risk flags shown alongside PEP screening. |
| BackOffice.GetRedeemDisplayData | RS.RiskStatusesNames | OUTER APPLY | Redeem display data - shows customer risk profile during withdrawal review. |
| BackOffice.GetRiskExposureReportPCIVersion | DRSK.RiskStatusesNames | OUTER APPLY | Risk exposure report - customer risk flags in the risk exposure view. |
| BackOffice.GetRiskExposureReportPCIVersion_Old | DRSK.RiskStatusesNames | OUTER APPLY | Legacy version of the risk exposure report. |
| BackOffice.GetUnapprovedWithdrawRequests | DCRS.RiskStatusesNames | OUTER APPLY | Unapproved withdraw requests - risk flags shown for compliance review. |
| BackOffice.NewRiskAlertsPCIVersion | DRST.RiskStatusesNames | OUTER APPLY | New risk alerts report - current customer risk profile alongside new alerts. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserRisksByCID (function)
├── Customer.CustomerStatic (table) [cross-schema]
├── BackOffice.CustomerRisk (table)
├── Dictionary.RiskStatus (table) [cross-schema]
└── Dictionary.RiskEventStatus (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | WHERE CID=@CID to resolve CID to GCID. Foundation of the query. |
| BackOffice.CustomerRisk | Table | INNER JOIN on GCID - source of all risk flag records for the customer group. |
| Dictionary.RiskStatus | Table | INNER JOIN on RiskStatusID to get risk status Name for the output string. |
| Dictionary.RiskEventStatus | Table | INNER JOIN on RiskEventStatusID; filtered to IsActive=1 to exclude resolved/inactive events. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAcceptance | Stored Procedure | OUTER APPLY - risk status in customer acceptance workflow. |
| BackOffice.GetPepReport | Stored Procedure | OUTER APPLY - risk flags in PEP screening report. |
| BackOffice.GetRedeemDisplayData | Stored Procedure | OUTER APPLY - risk profile in redeem/withdrawal review. |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | OUTER APPLY - risk flags in risk exposure report. |
| BackOffice.GetRiskExposureReportPCIVersion_Old | Stored Procedure | OUTER APPLY - legacy risk exposure report. |
| BackOffice.GetUnapprovedWithdrawRequests | Stored Procedure | OUTER APPLY - risk flags in pending withdrawal review. |
| BackOffice.NewRiskAlertsPCIVersion | Stored Procedure | OUTER APPLY - customer risk profile in new alerts report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Get active risk statuses for a specific customer

```sql
SELECT CID, GCID, RiskStatusesNames
FROM BackOffice.GetUserRisksByCID(12345) WITH (NOLOCK);
-- Returns one row: CID=12345, GCID=..., RiskStatusesNames="FraudSuspicion,HighRiskCountry" or NULL
```

### 8.2 Use with OUTER APPLY on a customer list (primary usage pattern)

```sql
SELECT
    c.CID,
    c.FirstName,
    c.LastName,
    r.RiskStatusesNames
FROM BackOffice.Customer c WITH (NOLOCK)
OUTER APPLY BackOffice.GetUserRisksByCID(c.CID) r
WHERE c.CID IN (12345, 67890);
```

### 8.3 Find customers with specific risk flags

```sql
SELECT CID, GCID, RiskStatusesNames
FROM BackOffice.GetUserRisksByCID(12345) WITH (NOLOCK)
WHERE RiskStatusesNames LIKE '%FraudSuspicion%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this function. See OPSE-236 for GetUserRisksByCID_AGG (the improved STRING_AGG version).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserRisksByCID | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUserRisksByCID.sql*
