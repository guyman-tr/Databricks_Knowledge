# Compliance.GetQuestionsExpirationPopulation

> Returns a paginated population of customers whose KYC questionnaire answers have expired (older than the configured period), excluding those already in an active reconfirmation workflow, used to drive the KYC reconfirmation notification flow.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BasePeriodSec, @Page, @PageSize, @RegulationID (inputs); GCID (output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies customers who need to re-answer their KYC (Know Your Customer) questionnaires because their answers have expired. Under regulatory requirements (particularly MiFID II appropriateness assessments), customers must periodically re-confirm their trading knowledge, experience, and financial situation. The `@BasePeriodSec` parameter defines the "time to live" of questionnaire answers - once a customer's answers are older than this period, they enter the reconfirmation population.

The SP is the primary data feed for eToro's KYC reconfirmation flow. It was created in October-November 2017 (tickets 49148, 49385) with multiple iterations, and updated in January 2019 (RD-458, 2192) for the "gaps mechanism" 6-month reminder. It is called by the SQL_Compliance service, PROD_SQL_Compliance, and PROD_BIadmins, confirming active production use.

The procedure excludes customers who are already in an active reconfirmation workflow (WorkFlowID=5, not yet in terminal state 5), preventing duplicate notifications. Customers who have completed their reconfirmation (StateTypeID=5) are eligible again once their new answers age past @BasePeriodSec. Results are paginated via @Page and @PageSize to allow batch processing of large populations.

WITH RECOMPILE is used to avoid parameter sniffing issues given the highly variable filter conditions.

---

## 2. Business Logic

### 2.1 KYC Answer Expiry Calculation

**What**: Determines when a customer's questionnaire answers expire by adding @BasePeriodSec to the oldest relevant answer timestamp.

**Columns/Parameters Involved**: `@BasePeriodSec`, `ca.OccurredAt`, `CA1.OccurredAt`, `Occurred`

**Rules**:
- For each customer, finds their earliest answer to the specified questions (@questions) or to question 100 (the reconfirmation reference question)
- `Occurred = ISNULL(DATEADD(Second, @BasePeriodSec, MIN(CA1.OccurredAt)), DATEADD(Second, @BasePeriodSec, MIN(ca.OccurredAt)))`
  - If the customer has answered question 100 (a special reconfirmation anchor): expiry based on question-100 answer time
  - Otherwise: expiry based on earliest answer to the @questions list
- Answer must be older than @BasePeriodSec: `DATEADD(Second, @BasePeriodSec, ca.OccurredAt) < GETUTCDATE()`
- HAVING clause confirms the computed Occurred is before now (double-check the expiry window)
- `@DateBegin` provides an optional lower bound: `ca.Occurred >= ISNULL(@DateBegin, ca.Occurred)` (no filter if NULL)

**Diagram**:
```
Customer's earliest KYC answer (OccurredAt)
        +
@BasePeriodSec seconds
        =
Occurred (expiry timestamp)

Is Occurred < GETUTCDATE()?
  YES -> answers have expired, customer is in the population
  NO  -> answers are still current, customer excluded
```

### 2.2 Reconfirmation vs Initial Assessment Detection

**What**: Identifies whether a customer's questionnaire completion was an initial assessment or a reconfirmation.

**Columns/Parameters Involved**: `IsReconfirmation`, `CA1.OccurredAt` (question 100), `ca.OccurredAt` (regular questions)

**Rules**:
- Question 100 is a special "reconfirmation anchor" question in the KYC system
- OUTER APPLY fetches the earliest answer to question 100 per GCID
- `IsReconfirmation = CASE WHEN MIN(CA1.OccurredAt) = MIN(ca.OccurredAt) THEN 1 ELSE 0 END`
  - If the earliest answer to question 100 equals the earliest answer to regular questions: customer answered both simultaneously = initial assessment (IsReconfirmation=1 per this logic)
  - If they differ (question 100 answered at a different time): = this is a reconfirmation pass (IsReconfirmation=0)
- Note: The flag naming is counterintuitive - `IsReconfirmation=1` means initial/simultaneous answers

### 2.3 Active Workflow Exclusion

**What**: Prevents duplicate notifications for customers already in an active reconfirmation workflow.

**Columns/Parameters Involved**: `WorkFlowID`, `StateTypeID`, `GCID`

**Rules**:
- Pre-built temp table `#Compliance_WorkFlowDocumentState` contains GCIDs of customers in WorkFlowID=5 (KYC reconfirmation workflow) where `StateTypeID <> 5` (not yet in terminal state)
- These customers are excluded: `ca.GCID NOT IN (SELECT GCID FROM #Compliance_WorkFlowDocumentState)`
- A clustered PK is added dynamically to the temp table for query performance: `CONSTRAINT PK_{@@SPID}_#...` (uses session ID to avoid name conflicts with concurrent executions)
- Source: `Compliance_WorkFlowDocumentState` synonym -> `[ComplianceStateDBStg].[Compliance].[WorkFlowDocumentState]`

### 2.4 Pagination

**What**: Returns a specific page of results ordered by Occurred DESC (most recently expired first).

**Columns/Parameters Involved**: `@Page`, `@PageSize`, `RowNumber`

**Rules**:
- Results ordered by `ca.Occurred DESC` (most recently expired answers first)
- `WHERE t.RowNumber-1 >= @Page*@PageSize AND t.RowNumber-1 < (@Page+1)*@PageSize`
- Zero-based paging: @Page=0 returns rows 1 to @PageSize, @Page=1 returns rows @PageSize+1 to 2*@PageSize
- Callers iterate pages until an empty result is returned

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BasePeriodSec | INT | NO | - | CODE-BACKED | The time-to-live of KYC answers in seconds. Answers older than this period are considered expired. E.g., 15552000 = 180 days (6 months). Determines the reconfirmation frequency. |
| 2 | @PageSize | INT | NO | - | CODE-BACKED | Number of customers to return per page. Used with @Page for paginated processing. |
| 3 | @Page | INT | NO | - | CODE-BACKED | Zero-based page number. Page 0 returns the first @PageSize results, page 1 returns the next @PageSize, etc. Caller increments until empty result. |
| 4 | @DateBegin | DATETIME | NO | - | CODE-BACKED | Optional lower bound for Occurred (expiry timestamp). When NULL, no lower date filter is applied. Used to limit results to customers whose answers expired after a certain date. |
| 5 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external/regular customers (all where PlayerLevelID != 4); 1 = restrict to eToro internal employees (PlayerLevelID=4). |
| 6 | @GCID | INT | YES | NULL | CODE-BACKED | Optional filter to check a single specific customer by GCID. When NULL, all eligible customers are evaluated. Used for ad-hoc investigation or single-customer reconfirmation checks. |
| 7 | @questions | dbo.IdList (table type) | NO (READONLY) | - | CODE-BACKED | Table-valued parameter containing the KYC question IDs to check expiry for. A customer is included only if they have answers to these questions (or to question 100). Source: UserApiDB.KYC.Questions. |
| 8 | @RegulationID | INT | NO | - | CODE-BACKED | Regulation filter. Only customers whose `ISNULL(DesignatedRegulationID, RegulationID)` matches this value are returned. Scopes results to a specific regulatory population (e.g., CySEC=1, FCA=2). See [Regulation](_glossary.md#regulation). |

**Return Result Set**:

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| R1 | RowNumber | INT | NO | CODE-BACKED | Sequential rank ordered by Occurred DESC within the full result set. Used for pagination calculation. |
| R2 | GCID | INT/BIGINT | NO | CODE-BACKED | Global Customer ID of the customer whose questionnaire answers have expired and who needs reconfirmation. |
| R3 | IsReconfirmation | BIT | NO | CODE-BACKED | 1 if the customer's initial answers and question-100 answers were submitted simultaneously (initial assessment batch); 0 if they differ (prior reconfirmation). Note: naming is counterintuitive - value 1 indicates simultaneous/initial answers. |
| R4 | Occurred | DATETIME | NO | CODE-BACKED | The computed expiry timestamp: DATEADD(Second, @BasePeriodSec, earliest relevant answer OccurredAt). The point in time when the customer's answers crossed the expiry threshold. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| QuestionId | KYC_Questions (synonym -> UserApiDB.KYC.Questions) | JOIN | Source of question definitions - filters IsActive=1 and QuestionId<1000 |
| GCID / QuestionId | KYC_CustomerAnswers (synonym -> UserApiDB.KYC.CustomerAnswers) | JOIN | Source of customer answer timestamps (OccurredAt) - drives expiry calculation |
| GCID | Customer.Customer | JOIN | Filters by PlayerLevelID for internal/external split |
| CID | BackOffice.Customer | JOIN | Filters by VerificationLevelID=3 and RegulationID |
| GCID | Compliance_WorkFlowDocumentState (synonym -> ComplianceStateDBStg.Compliance.WorkFlowDocumentState) | Exclusion (NOT IN) | Customers already in active reconfirmation workflow are excluded |
| ID | @questions (dbo.IdList) | Parameter filter | The specific question IDs whose answers are being checked for expiry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance.GetQuestionsExpirationPopulationNew | (see that SP) | Logical predecessor | GetQuestionsExpirationPopulationNew is the "New" version, presumably faster/optimized; both serve the same purpose |
| SQL_Compliance (service account) | - | EXECUTE permission | Compliance notification service calls for reconfirmation campaigns |
| PROD_SQL_Compliance | - | EXECUTE permission | Production compliance service |
| PROD_BIadmins | - | EXECUTE permission | BI reporting access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetQuestionsExpirationPopulation (procedure)
├── Compliance_WorkFlowDocumentState (synonym)
│     └── [ComplianceStateDBStg].[Compliance].[WorkFlowDocumentState] (cross-DB table)
├── KYC_Questions (synonym)
│     └── [UserApiDB].[KYC].[Questions] (cross-DB table)
├── KYC_CustomerAnswers (synonym)
│     └── [UserApiDB].[KYC].[CustomerAnswers] (cross-DB table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
└── dbo.IdList (UDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Compliance_WorkFlowDocumentState | Synonym | Pre-built temp table for active workflow exclusion (SELECT DISTINCT GCID WHERE WorkFlowID=5 AND StateTypeID<>5) |
| KYC_Questions | Synonym | JOINed to filter active questions (IsActive=1) and QuestionId<1000 |
| KYC_CustomerAnswers | Synonym | Primary answer source - OccurredAt drives expiry calculation |
| Customer.Customer | Table | JOINed for PlayerLevelID internal/external filter |
| BackOffice.Customer | Table | JOINed for VerificationLevelID=3 and RegulationID filter |
| dbo.IdList | User Defined Type | Table-valued parameter type for @questions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Compliance.GetQuestionsExpirationPopulationNew | Stored Procedure | Newer optimized variant serving the same purpose |
| SQL_Compliance / PROD_SQL_Compliance service | External | Called for KYC reconfirmation notification campaigns |
| PROD_BIadmins | External reporting | BI analytics access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces new execution plan on each call to prevent parameter sniffing issues from variable filter conditions |
| Dynamic PK creation | Performance | `ALTER TABLE #Compliance_WorkFlowDocumentState ADD CONSTRAINT PK_{@@SPID}...` - adds clustered index on GCID temp table using session ID to avoid naming conflicts with concurrent executions |
| QuestionId < 1000 | Application logic | Filters out test/system questions (IDs >= 1000) from KYC_CustomerAnswers |
| VerificationLevelID = 3 | Application logic | Only fully verified customers are eligible for reconfirmation |

---

## 8. Sample Queries

### 8.1 Get first page of expired customers for CySEC regulation (6-month TTL)

```sql
DECLARE @questions dbo.IdList;
INSERT INTO @questions VALUES (1), (2), (3);  -- question IDs

EXEC [Compliance].[GetQuestionsExpirationPopulation]
    @BasePeriodSec = 15552000,  -- 180 days in seconds
    @PageSize = 100,
    @Page = 0,
    @DateBegin = '2024-01-01',
    @IsInternal = 0,
    @GCID = NULL,
    @questions = @questions,
    @RegulationID = 1;  -- CySEC
```

### 8.2 Check a single customer's reconfirmation status

```sql
DECLARE @questions dbo.IdList;
INSERT INTO @questions VALUES (1), (2);

EXEC [Compliance].[GetQuestionsExpirationPopulation]
    @BasePeriodSec = 15552000,
    @PageSize = 1,
    @Page = 0,
    @DateBegin = NULL,
    @IsInternal = 0,
    @GCID = 12345678,  -- specific GCID
    @questions = @questions,
    @RegulationID = 2;  -- FCA
```

### 8.3 Check active workflows to understand exclusion logic

```sql
SELECT DISTINCT GCID, WorkFlowID, StateTypeID
FROM Compliance_WorkFlowDocumentState WITH (NOLOCK)
WHERE WorkFlowID = 5
  AND StateTypeID <> 5
ORDER BY GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in TRAD space. DDL comments identify rich change history:
- Ticket 49148 (2017-10-08): Original creation
- Ticket 49385 (2017-11-08): OPS0153 - Reconfirmation flow change
- Ticket 49775 (2017-12-11): Performance improvement
- Tickets RD-458, 2192 (2019-01-08): Gaps mechanism - 6-month reminder adjustment

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetQuestionsExpirationPopulation | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetQuestionsExpirationPopulation.sql*
