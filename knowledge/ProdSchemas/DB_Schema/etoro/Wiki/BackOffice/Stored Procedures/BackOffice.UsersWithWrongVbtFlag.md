# BackOffice.UsersWithWrongVbtFlag

> Diagnostic report (Nugios alert feed): identifies customers routed to ASIC regulation (DesignatedRegulationID=4) who are from non-ASIC countries, have not reached VerificationLevelID=3, and had a compliance record change in the last 4 hours without a KYC flow started - indicating a potential miscategorization requiring attention.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - diagnostic report |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UsersWithWrongVbtFlag` is a compliance alert feed introduced in January 2020 (Jira RD-19401) for the Nugios monitoring system. It identifies customers who appear to have an incorrectly applied compliance classification - specifically, customers who:

1. Were recently assigned `DesignatedRegulationID=4` (ASIC - Australian regulation) in the last 4 hours
2. Are registered from a country in the monitored non-ASIC country list (primarily EU, CIS, and other international jurisdictions that should not be under Australian regulatory oversight)
3. Have not achieved `VerificationLevelID >= 3` (the "VBT" - Verified Basic Trader - threshold)
4. Were registered after January 21, 2020 (scope fence matching the RD-19401 change date)
5. Have no active KYC flow started in `dbo.Compliance_KYCFlow`

These customers represent a potential regulatory routing error: they are categorized under ASIC but their country of origin suggests they should be regulated differently (e.g., under CySEC/FCA/BVI). The SP surfaces them for compliance team intervention before the window passes.

The result includes the customer's current and historical countries (to show any country-change behavior), their verification history from `History.BackOfficeCustomer`, and the current VBT flag state.

---

## 2. Business Logic

### 2.1 Candidate Detection via History.BackOfficeCustomer

**What**: Identifies CIDs that had DesignatedRegulationID=4 in BackOffice.Customer changes within the last 4 hours (240 minutes).

**Columns/Parameters Involved**: `History.BackOfficeCustomer.DesignatedRegulationID`, `History.BackOfficeCustomer.ValidFrom`, `History.BackOfficeCustomer.VerificationLevelID`

**Rules**:
- `WHERE DesignatedRegulationID=4` - only customers assigned to ASIC regulation.
- `HAVING MAX(ValidFrom) > DATEADD(Minute,-240,GetDate())` - at least one change in the last 4 hours.
- Returns per-CID aggregates: MinValidFrom (registration date proxy), Level1ReachDate (first time VerificationLevelID > 0), MaxValidFrom (most recent change), MaxVerificationLevelID.

### 2.2 Country + Verification Filter

**What**: Filters candidates to only those from the monitored country list with insufficient verification.

**Columns/Parameters Involved**: `Customer.CustomerStatic.CountryID`, `BackOffice.Customer.VerificationLevelID`

**Rules**:
- `Customer.CustomerStatic.CountryID IN (161,96,60,62,24,16,237,12,225,192,132,158,87,2,64,160,103,120,92,234,36,136,91,147,31,111,194,241,17,174,90,8,171,190,97,47,43,155,202,51,28,15,109,179,221,162,9,167,183,217,20,23,53,61,84,140)` - 54 specific country IDs representing non-ASIC jurisdictions
- `BackOffice.Customer.VerificationLevelID < 3` - below the VBT threshold
- `Customer.CustomerStatic.Registered > '20200121 06:00'` - post-feature-release registrations only

### 2.3 KYC Flow Exclusion

**What**: Excludes customers who already have an active KYC flow in progress.

**Rules**:
- `NOT EXISTS (SELECT * FROM dbo.Compliance_KYCFlow WHERE KYCFlowTypeID > 0 AND GCID = ...)` - customers with any active KYC flow are already being processed.

### 2.4 Result Set

**Columns Returned**:
- `CID` - the misrouted customer
- `DesignatedRegulationID` - current ASIC routing
- `VerificationLevelID` - current level (< 3)
- `MaxVerificationLevelID` - highest ever achieved level
- `Level1ReachDate` - when they first got any verification
- `RegDate` (MinValidFrom) - earliest BackOffice.Customer record
- `Countries` - comma-separated list of current + historical country names
- `GCID` - global customer ID
- `LastUpdate` (MaxValidFrom) - timestamp of the most recent BackOffice.Customer change
- `KYCFlowTypeID` - from Compliance_KYCFlow (informational - NULL for all results since KYCFlowTypeID=0 or absent was required)

**Ordering**: By registration date, CID, DesignatedRegulationID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | Diagnostic procedure. All filtering is hardcoded: DesignatedRegulationID=4 (ASIC), 54-country list, VerificationLevelID<3, 4-hour lookback, post-Jan-2020 registration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DesignatedRegulationID=4 | History.BackOfficeCustomer | SELECT source | Change history - detects recent ASIC routing changes |
| CID | Customer.CustomerStatic | JOIN | Country and registration date filter |
| CID | BackOffice.Customer | JOIN | Current VerificationLevelID and DesignatedRegulationID |
| GCID | dbo.Compliance_KYCFlow | NOT EXISTS check | Excludes customers with active KYC flows |
| CountryID | Dictionary.Country | JOIN (subquery) | Country names for current + historical countries |
| CID | History.Customer | JOIN (subquery) | Historical country records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Nugios alerting system | - | Caller | Scheduled execution to feed compliance team alerts for ASIC miscategorization |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UsersWithWrongVbtFlag (procedure)
+-- History.BackOfficeCustomer (table) [SELECT: regulation change history with 4-hour window]
+-- Customer.CustomerStatic (table) [JOIN: CountryID, Registered, GCID]
+-- BackOffice.Customer (table) [JOIN: current VerificationLevelID, DesignatedRegulationID]
+-- dbo.Compliance_KYCFlow (table) [NOT EXISTS: KYC flow exclusion]
+-- Dictionary.Country (table) [JOIN: country name resolution (current)]
+-- History.Customer (table) [JOIN: historical country records]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.BackOfficeCustomer | Table | SELECT compliance change history grouped by CID |
| Customer.CustomerStatic | Table | JOIN for CountryID, Registered date, GCID |
| BackOffice.Customer | Table | JOIN for current VerificationLevelID, DesignatedRegulationID |
| dbo.Compliance_KYCFlow | Table | NOT EXISTS: exclude customers with KYCFlowTypeID>0 |
| Dictionary.Country | Table | JOIN for current country names |
| History.Customer | Table | JOIN for historical country names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Nugios monitoring system | External | Scheduled calls for ASIC miscategorization alerting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON.
- No parameters - all filter values are hardcoded.
- 4-hour lookback is computed from GETDATE() (local time), not GETUTCDATE(). May need timezone consideration.
- Country list of 54 IDs is hardcoded and must be updated manually if jurisdictions change.

---

## 8. Sample Queries

### 8.1 Run the diagnostic report

```sql
EXEC BackOffice.UsersWithWrongVbtFlag;
-- Returns customers requiring compliance team review for ASIC miscategorization
```

### 8.2 Count current candidates

```sql
SELECT COUNT(*) AS CandidateCount
FROM History.BackOfficeCustomer(NOLOCK)
WHERE DesignatedRegulationID = 4
  AND ValidFrom > DATEADD(MINUTE, -240, GETDATE())
GROUP BY CID
HAVING MAX(ValidFrom) > DATEADD(MINUTE, -240, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-19401 | Jira | Initial version for Nugios alerts - January 2020 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UsersWithWrongVbtFlag | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UsersWithWrongVbtFlag.sql*
