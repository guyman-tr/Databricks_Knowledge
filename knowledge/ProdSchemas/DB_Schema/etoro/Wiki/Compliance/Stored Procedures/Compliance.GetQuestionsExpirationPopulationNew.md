# Compliance.GetQuestionsExpirationPopulationNew

> Optimized version of `Compliance.GetQuestionsExpirationPopulation` that pre-materializes user/question/answer subsets into temp tables before the main query to reduce cross-database join overhead. Identical business logic, improved performance architecture. Note: contains a potential column-name bug (`CID` vs `ID` in @questions references).

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BasePeriodSec, @Page, @PageSize, @RegulationID (inputs); GCID (output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the performance-optimized variant of `Compliance.GetQuestionsExpirationPopulation`. It serves the identical business purpose - identifying customers whose KYC questionnaire answers have expired (older than @BasePeriodSec seconds) and who are not already in an active reconfirmation workflow - but restructures the execution plan for better performance with large populations.

The optimization strategy: instead of executing a complex nested query against three large cross-database tables simultaneously, the "New" version pre-materializes three intermediate temp tables (`#Compliance_WorkFlowDocumentState`, `#users`, `#questions`, `#CustomerAnswers`) that are filtered to the specific population and question set before the main aggregation runs. This converts large cross-DB joins into smaller, local-table joins.

**Known issue**: The SP references `CID` column from the `@questions` TVP parameter in three places, but `dbo.IdList` defines the column as `ID` (not `CID`). This would cause a runtime error "Invalid column name 'CID'". The original SP correctly uses `Select * From @questions`. This suggests the "New" SP may have been created with a bug and not fully validated before deployment.

The same parameter signature and pagination logic applies as the original. See `Compliance.GetQuestionsExpirationPopulation` for complete business logic documentation.

---

## 2. Business Logic

### 2.1 Performance Optimization via Temp Table Materialization

**What**: Reduces cross-DB join overhead by pre-filtering data into local temp tables.

**Columns/Parameters Involved**: `#users`, `#questions`, `#CustomerAnswers`

**Rules**:
- **Step 1** - `#Compliance_WorkFlowDocumentState`: Same as original - active KYC workflow GCIDs (WorkFlowID=5, StateTypeID<>5). Fixed constraint name (not dynamic with @@SPID) - risk of conflict with concurrent executions.
- **Step 2** - `#users`: Pre-filters eligible customers (VerificationLevelID=3, regulation match, not in workflow, optional GCID filter) BEFORE joining with answers. This reduces the cross-DB KYC_CustomerAnswers query to only relevant users.
- **Step 3** - `#questions`: Pre-resolves @questions TVP against KYC_Questions for IsActive=1. **BUG**: uses `q1.CID` but IdList column is `ID` - would fail at runtime.
- **Step 4** - `#CustomerAnswers`: Pre-fetches answers for only the #users population. Greatly reduces the working set for the main aggregation query.
- **Main query**: Joins #questions + #CustomerAnswers + KYC_CustomerAnswers (for question-100 OUTER APPLY only) - much smaller than the original's full cross-DB joins.
- **Step 5** - Same pagination as original: `RowNumber-1 >= @Page*@PageSize AND RowNumber-1 < (@Page+1)*@PageSize`

**Diagram**:
```
Original SP approach:
  KYC_CustomerAnswers (full) x Customer.Customer (full) x BackOffice.Customer (full)
  -> complex nested aggregation
  -> SLOW for large populations

New SP approach:
  1. #users = eligible GCIDs only (local temp table, fast)
  2. #questions = active question IDs only (local temp table, fast)
  3. #CustomerAnswers = answers for #users only (local temp table, medium size)
  4. Main query joins local temp tables + small OUTER APPLY to KYC_CustomerAnswers
  -> FAST for large populations
```

### 2.2 Potential Bug: @questions Column Reference

**What**: Three references to `CID` column of @questions TVP where the IdList type defines column as `ID`.

**Rules**:
- `dbo.IdList` DDL: `CREATE TYPE [dbo].[IdList] AS TABLE ([ID] [int] NULL)`
- New SP line 53: `join KYC_Questions q on q.QuestionId = q1.CID` - should be `q1.ID`
- New SP line 59: `ca.QuestionId In (Select CID From @questions)` - should be `Select ID From @questions`
- New SP line 77: `ca.QuestionId In (Select CID From @questions)` - same issue
- Original SP correctly uses: `ca.QuestionId In (Select * From @questions)` (single-column SELECT * works)
- Impact: If executed as-is, this SP would fail with "Invalid column name 'CID'" at the #questions step

### 2.3 Fixed vs Dynamic Constraint Name

**What**: Unlike the original SP, uses a fixed PK constraint name on the temp table.

**Rules**:
- Original: `CONSTRAINT PK_{@@SPID}_#Compliance_WorkFlowDocumentState` - unique per session, safe for concurrency
- New: `CONSTRAINT PK_Compliance_WorkFlowDocumentState` - fixed name - potential name conflict if two sessions execute simultaneously (the second would fail with duplicate constraint name error)

For all other business logic (expiry calculation, IsReconfirmation, pagination, filters), see `Compliance.GetQuestionsExpirationPopulation` - the logic is identical.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

Same parameters as `Compliance.GetQuestionsExpirationPopulation`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BasePeriodSec | INT | NO | - | CODE-BACKED | Time-to-live of KYC answers in seconds. Same as original SP. |
| 2 | @PageSize | INT | NO | - | CODE-BACKED | Number of results per page. Same as original SP. |
| 3 | @Page | INT | NO | - | CODE-BACKED | Zero-based page number. Same as original SP. |
| 4 | @DateBegin | DATETIME | NO | - | CODE-BACKED | Optional lower bound for Occurred. Same as original SP. |
| 5 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external customers; 1 = internal employees. Same as original SP. |
| 6 | @GCID | INT | YES | NULL | CODE-BACKED | Optional single-customer filter. Same as original SP. |
| 7 | @questions | dbo.IdList (READONLY) | NO | - | CODE-BACKED | Question IDs to check. **BUG**: SP references `CID` column but IdList defines column as `ID` - runtime error expected. |
| 8 | @RegulationID | INT | NO | - | CODE-BACKED | Regulation filter. Same as original SP. See [Regulation](_glossary.md#regulation). |

**Return Result Set** - same columns as `Compliance.GetQuestionsExpirationPopulation`: RowNumber, GCID, IsReconfirmation, Occurred.

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `Compliance.GetQuestionsExpirationPopulation`:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Compliance_WorkFlowDocumentState (synonym) | Pre-filter | Active workflow exclusion list |
| GCID | Customer.Customer | Pre-filter (#users) | Eligible customer population |
| CID | BackOffice.Customer | Pre-filter (#users) | VerificationLevelID + RegulationID filter |
| QuestionId | KYC_Questions (synonym) | Pre-filter (#questions) | Active question IDs |
| GCID | KYC_CustomerAnswers (synonym) | Pre-filter (#CustomerAnswers) | Customer answers for eligible users |
| GCID | KYC_CustomerAnswers (synonym) | OUTER APPLY | Question-100 reconfirmation anchor |
| - | dbo.IdList (UDT) | Parameter type | @questions TVP |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance.GetQuestionsExpirationPopulation | - | Logical predecessor | This SP is the performance-optimized variant of GetQuestionsExpirationPopulation. The original SP is the stable production-safe version with correct @questions TVP handling. See that SP for full business logic documentation. |
| SQL_Compliance / PROD_SQL_Compliance | - | EXECUTE permission | Compliance notification service |
| PROD_BIadmins | - | EXECUTE permission | BI reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetQuestionsExpirationPopulationNew (procedure)
├── Compliance_WorkFlowDocumentState (synonym)
│     └── [ComplianceStateDBStg].[Compliance].[WorkFlowDocumentState] (cross-DB)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── KYC_Questions (synonym)
│     └── [UserApiDB].[KYC].[Questions] (cross-DB)
├── KYC_CustomerAnswers (synonym)
│     └── [UserApiDB].[KYC].[CustomerAnswers] (cross-DB)
└── dbo.IdList (UDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Compliance_WorkFlowDocumentState | Synonym | Active workflow exclusion temp table source |
| Customer.Customer | Table | #users pre-filter source |
| BackOffice.Customer | Table | #users pre-filter (VerificationLevelID, RegulationID) |
| KYC_Questions | Synonym | #questions pre-filter (IsActive=1) |
| KYC_CustomerAnswers | Synonym | #CustomerAnswers source + OUTER APPLY for question-100 |
| dbo.IdList | User Defined Type | @questions parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_Compliance / PROD_SQL_Compliance | External | KYC reconfirmation campaigns |
| PROD_BIadmins | External reporting | Analytics access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces fresh execution plan on each call |
| Fixed PK constraint name | Design risk | `PK_Compliance_WorkFlowDocumentState` - unlike original's dynamic @@SPID-based name. Risk of concurrent execution failures. |
| @questions.CID bug | Runtime error | References non-existent column `CID` on dbo.IdList (column is `ID`) - would fail at runtime |

---

## 8. Sample Queries

### 8.1 Note on execution

```sql
-- WARNING: This SP may fail with "Invalid column name 'CID'"
-- due to the @questions TVP bug (should reference ID not CID).
-- Use the original SP instead:
DECLARE @questions dbo.IdList;
INSERT INTO @questions VALUES (1), (2), (3);

EXEC [Compliance].[GetQuestionsExpirationPopulation]
    @BasePeriodSec = 15552000,
    @PageSize = 100,
    @Page = 0,
    @DateBegin = '2024-01-01',
    @IsInternal = 0,
    @GCID = NULL,
    @questions = @questions,
    @RegulationID = 1;
```

### 8.2 Verify the bug

```sql
-- Check IdList column name
SELECT column_name FROM INFORMATION_SCHEMA.ROUTINE_COLUMNS
WHERE TABLE_NAME = 'IdList';

-- Or check via system catalog
SELECT c.name FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
WHERE tt.name = 'IdList';
-- Returns 'ID' not 'CID'
```

### 8.3 Corrected call (if bug is fixed)

```sql
-- If the SP is fixed to use ID instead of CID:
DECLARE @questions dbo.IdList;
INSERT INTO @questions VALUES (1), (2);

EXEC [Compliance].[GetQuestionsExpirationPopulationNew]
    @BasePeriodSec = 15552000,
    @PageSize = 100,
    @Page = 0,
    @DateBegin = NULL,
    @IsInternal = 0,
    @GCID = NULL,
    @questions = @questions,
    @RegulationID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Same change history as original SP. See `Compliance.GetQuestionsExpirationPopulation` for ticket references.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetQuestionsExpirationPopulationNew | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetQuestionsExpirationPopulationNew.sql*
