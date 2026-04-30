# Compliance.GetUkClassificationGapPopulation

> Returns GCIDs of UK-resident customers whose UK Classification KYC answers (questions 172/175) have expired and who do not already have an open UK Classification requirement, used to trigger creation of new UK Classification gap workflows.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BasePeriodSec (input); GCID (output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure feeds the UK Classification gap workflow. Under FCA regulation (COBS rules), eToro must periodically re-confirm UK customers' investor classification status - specifically whether they qualify as Retail Clients or Elective Professional Clients. KYC questions 172 and 175 capture this classification. When a customer's answers age past the `@BasePeriodSec` threshold, they are due for reclassification and a "gap" workflow must be opened.

The SP was created on 2023-12-11 by Serhii Poltava. It is more targeted than the general-purpose `GetQuestionsExpirationPopulation` SP: it is hardcoded to UK customers only (CountryID=218), hardcoded to questions 172 and 175, has no pagination, and filters using the Compliance requirement tracking system (RequirementID=23) rather than a workflow state table. This reflects a newer architectural pattern where UK Classification is tracked via the `Compliance.CustomerRequirementsOverviewStatus` table in ComplianceStateDB.

**Exclusion logic**: Customers already in an **open** UK Classification requirement (RequirementID=23, OverviewStatusID=1) are excluded - their gap is already being processed. Only customers without an open requirement and whose latest answers to questions 172 or 175 predate the cutoff are returned. This prevents duplicate gap creation.

**RequirementID=23 = UK Classification** (confirmed via Confluence "Compliance SQL Toolkit" page).
**OverviewStatusID=1 = Open**, **OverviewStatusID=6 = Completed** (Confluence-confirmed).

---

## 2. Business Logic

### 2.1 Answer Expiry Calculation

**What**: Determines whether a customer's UK Classification KYC answers have expired.

**Columns/Parameters Involved**: `@BasePeriodSec`, `ca.OccurredAt`, `@dt`

**Rules**:
- `@dt = DATEADD(Second, -@BasePeriodSec, GETUTCDATE())` - the cutoff datetime; answers from before this point are expired
- A customer is included if `MAX(ca.OccurredAt) < @dt` for questions 172 or 175 - their MOST RECENT answer to either question is older than the threshold
- If a customer has answered BOTH questions, the MAX (latest) of both is used - only if their most recent answer of either question is expired are they returned
- Note: unlike `GetQuestionsExpirationPopulation`, there is no `IsReconfirmation` flag and no `Occurred` expiry timestamp in the output - only the raw GCID list

**Diagram**:
```
@dt = GETUTCDATE() - @BasePeriodSec
              |
Is MAX(OccurredAt) for questions 172/175 < @dt?
  YES -> answers expired, GCID returned
  NO  -> answers still current, GCID excluded
```

### 2.2 Active Requirement Exclusion

**What**: Prevents duplicate gap creation for customers already in an open UK Classification workflow.

**Columns/Parameters Involved**: `RequirementID`, `OverviewStatusID`, `GCID`

**Rules**:
- Pre-builds `#user_requirements` temp table from `dbo.Compliance_CustomerRequirementsOverviewStatus` WHERE `RequirementID = 23 AND OverviewStatusID = 1`
- RequirementID=23 = UK Classification; OverviewStatusID=1 = Open (not yet completed)
- These GCIDs are excluded via LEFT JOIN + `u.GCID IS NULL` in the `UkUsers` CTE
- Live data: 2481 customers currently have an open UK Classification requirement; 10 have a Completed (OverviewStatusID=6) status
- A clustered PK is added dynamically using @@SPID to avoid constraint name conflicts in concurrent executions: `CONSTRAINT PK_{@@SPID}_#user_requirements`
- Source: `Compliance_CustomerRequirementsOverviewStatus` synonym -> `[ComplianceStateDBStg].[ComplianceStateDBStg].[Compliance].[CustomerRequirementsOverviewStatus]`

### 2.3 UK Residency Filter

**What**: Restricts population to UK-resident customers only.

**Columns/Parameters Involved**: `c.CountryID`, constant `218`

**Rules**:
- `Customer.CustomerStatic` is joined and filtered to `c.CountryID = 218` (United Kingdom - ISO code GB/GBR, IsoCode=826)
- No regulation filter (implicit: UK = FCA regulation)
- No `@IsInternal` filter, no `VerificationLevelID` filter - all UK customers with expired answers are eligible regardless of internal/external status or verification level

### 2.4 UK Classification Questions

**What**: Identifies the specific KYC question IDs that define UK investor classification.

**Rules**:
- Questions 172 and 175 are hardcoded as the UK Classification question set
- These questions are sourced from `KYC_CustomerAnswers` (synonym -> `[UserApiDB].[KYC].[CustomerAnswers]`)
- Unlike `GetQuestionsExpirationPopulation`, there is no join to `KYC_Questions` for IsActive filtering - question validity is assumed for these hardcoded IDs
- The SP groups by `ca.GCID` and applies the HAVING clause across all answers to either question - if a customer has answered both, the cutoff check is against whichever they answered most recently

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BasePeriodSec | INT | NO | - | CODE-BACKED | Time-to-live of UK Classification KYC answers in seconds. Customers whose most recent answer to questions 172 or 175 is older than this threshold are included in the output. E.g., 15552000 = 180 days (6 months). Controls the re-classification frequency. |

**Return Result Set**:

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| R1 | GCID | INT | NO | CODE-BACKED | Global Customer ID of a UK-resident customer whose UK Classification answers have expired and who does not already have an open UK Classification requirement (RequirementID=23, OverviewStatusID=1). Callers use this list to create new UK Classification gap workflows in ComplianceStateDB. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequirementID / OverviewStatusID | Compliance_CustomerRequirementsOverviewStatus (synonym) | Pre-filter | Builds #user_requirements exclusion list - GCIDs with active open UK Classification requirement |
| CountryID | Customer.CustomerStatic | JOIN | UK residency filter (CountryID=218) |
| GCID / QuestionId | KYC_CustomerAnswers (synonym) | JOIN | Source of UK Classification answer timestamps (OccurredAt) for expiry check |
| - | dbo.Compliance_CustomerRequirementsOverviewStatus | Synonym | -> [ComplianceStateDBStg].[ComplianceStateDBStg].[Compliance].[CustomerRequirementsOverviewStatus] |
| - | KYC_CustomerAnswers | Synonym | -> [UserApiDB].[KYC].[CustomerAnswers] |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_Compliance (inferred) | - | EXECUTE (inferred) | Likely called by Compliance notification/workflow service to identify customers needing UK Classification gaps - consistent with usage pattern of all other Compliance SPs in this schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetUkClassificationGapPopulation (procedure)
|-- Compliance_CustomerRequirementsOverviewStatus (synonym)
|     +-- [ComplianceStateDBStg].[ComplianceStateDBStg].[Compliance].[CustomerRequirementsOverviewStatus] (cross-DB)
|-- Customer.CustomerStatic (table)
+-- KYC_CustomerAnswers (synonym)
      +-- [UserApiDB].[KYC].[CustomerAnswers] (cross-DB)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Compliance_CustomerRequirementsOverviewStatus | Synonym | Pre-filter source: RequirementID=23, OverviewStatusID=1 exclusion set |
| Customer.CustomerStatic | Table | UK residency filter (CountryID=218) |
| KYC_CustomerAnswers | Synonym | Answer timestamps (OccurredAt) for UK Classification questions 172, 175 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_Compliance (inferred) | External service | Called for UK Classification gap workflow creation campaigns |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic PK with @@SPID | Concurrency safety | `CONSTRAINT PK_{@@SPID}_#user_requirements` - session-unique name prevents conflicts with concurrent executions |
| CountryID = 218 | Hardcoded filter | UK only (United Kingdom, ISO GB) |
| QuestionId IN (172, 175) | Hardcoded filter | UK Classification questions only - no TVP, unlike GetQuestionsExpirationPopulation |
| RequirementID = 23 | Hardcoded filter | UK Classification requirement type only |
| OverviewStatusID = 1 | Hardcoded filter | Open requirements only (1=Open per Confluence Compliance SQL Toolkit) |
| No WITH RECOMPILE | Design note | Unlike the GetQuestionsExpirationPopulation SPs, no RECOMPILE hint - parameter set is fixed and predictable |
| No pagination | Design note | Returns all matching GCIDs in a single result set - callers process the full population at once |

---

## 8. Sample Queries

### 8.1 Run UK Classification gap population check (6-month TTL)

```sql
EXEC [Compliance].[GetUkClassificationGapPopulation]
    @BasePeriodSec = 15552000;  -- 180 days in seconds
```

### 8.2 Verify active UK Classification requirements (exclusion set)

```sql
-- Customers already in open UK Classification gap workflow (will be excluded by the SP):
SELECT RequirementID, OverviewStatusID, COUNT(*) AS cnt
FROM [dbo].[Compliance_CustomerRequirementsOverviewStatus]
WHERE RequirementID = 23
GROUP BY RequirementID, OverviewStatusID;
-- Returns: 1 (Open) = ~2481 records, 6 (Completed) = ~10 records (as of 2026-03-17)
```

### 8.3 Manually identify the UK Classification population

```sql
-- Equivalent logic to the SP (illustrative):
DECLARE @dt DATETIME = DATEADD(Second, -15552000, GETUTCDATE());

SELECT ca.GCID
FROM [Customer].[CustomerStatic] c
JOIN [KYC_CustomerAnswers] ca ON ca.GCID = c.GCID
WHERE c.CountryID = 218
  AND ca.QuestionId IN (172, 175)
  AND NOT EXISTS (
    SELECT 1 FROM [dbo].[Compliance_CustomerRequirementsOverviewStatus] r
    WHERE r.GCID = c.GCID AND r.RequirementID = 23 AND r.OverviewStatusID = 1
  )
GROUP BY ca.GCID
HAVING MAX(ca.OccurredAt) < @dt;
```

---

## 9. Atlassian Knowledge Sources

Confluence search (TRAD space) returned no results for "GetUkClassificationGapPopulation". Broader search for "UK classification gap" yielded relevant context:

**Compliance SQL Toolkit** (Confluence, personal space `~935552433`, page id 14068318218, last updated 2026-03-09):
- Confirms RequirementID=23 = UK Classification
- Confirms OverviewStatusID=1 = Open, OverviewStatusID=6 = Completed
- Documents the `CustomerRequirementsOverviewStatus` snapshot table and `CustomerRequirmentsHistoryView` lifecycle view as the standard tools for investigating UK Classification status
- This SP is the automated feed that identifies candidates for the workflow documented in that toolkit

DDL comment: "Load users for whom we should create UK Classification gap" - Author: Serhii Poltava, Create date: 2023-12-11.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 2 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 1 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetUkClassificationGapPopulation | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetUkClassificationGapPopulation.sql*
