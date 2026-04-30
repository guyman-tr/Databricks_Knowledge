# KYC.GetBulkGCIDForRecalculateAppropriateness

> Returns batches of verified users with their KYC answers for bulk appropriateness recalculation, paginated by GCID with regulation filtering.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDToStart + @RegulationID + @BulkCount (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetBulkGCIDForRecalculateAppropriateness retrieves batches of verified users (VerificationLevelID >= 2) with their KYC questionnaire answers for bulk appropriateness/suitability recalculation. Supports pagination via @GCIDToStart and batch size via @BulkCount. Filters to specific regulations (CySEC, FCA, ASIC, ASIC+GAML by default). Used by the KYC Analyzer service for periodic suitability reassessment.

---

## 2. Business Logic

### 2.1 Paginated Bulk Retrieval

**What**: Batched user+answer retrieval with pagination and regulation filtering.

**Columns/Parameters Involved**: `@GCIDToStart`, `@RegulationID`, `@BulkCount`

**Rules**:
- CTE selects TOP(@BulkCount) distinct users where GCID > @GCIDToStart
- Default regulation filter: DesignatedRegulationID IN (1=CySEC, 2=FCA, 4=ASIC, 10=ASIC+GAML)
- If @RegulationID is provided, filters to that single regulation
- Only verified users (VerificationLevelID >= 2)
- Joins with KYC.CustomerAnswers for answer data
- Includes FirstUpdated calculation from History.CustomerAnswers

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDToStart | int (IN) | NO | - | CODE-BACKED | Pagination cursor - return users with GCID > this value. Start with 0 for first batch. |
| 2 | @RegulationID | int (IN) | YES | NULL | CODE-BACKED | Optional regulation filter. NULL = default set (1,2,4,10). |
| 3 | @BulkCount | int (IN) | NO | - | CODE-BACKED | Maximum number of distinct users to return per batch. |

Output: CID, GCID, VerificationLevelID, DesignatedRegulationID, QuestionId, Registered, CountryID, AnswerId, OccurredAt, FirstUpdated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_Customer | SELECT FROM | User data with GCID filter |
| - | dbo.Real_BackOfficeCustomer | JOIN | Verification and regulation data |
| - | KYC.CustomerAnswers | JOIN | Answer data |
| - | History.CustomerAnswers | Subquery | FirstUpdated calculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetBulkGCIDForRecalculateAppropriateness (procedure)
  +-- dbo.Real_Customer (synonym)
  +-- dbo.Real_BackOfficeCustomer (synonym)
  +-- KYC.CustomerAnswers (table) [done]
  +-- History.CustomerAnswers (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Synonym | SELECT FROM |
| dbo.Real_BackOfficeCustomer | Synonym | JOIN |
| KYC.CustomerAnswers | Table | JOIN |
| History.CustomerAnswers | Table | Subquery |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 First batch of 1000
```sql
EXEC KYC.GetBulkGCIDForRecalculateAppropriateness @GCIDToStart = 0, @BulkCount = 1000
```

### 8.2 Next batch (pagination)
```sql
EXEC KYC.GetBulkGCIDForRecalculateAppropriateness @GCIDToStart = 50000, @BulkCount = 1000
```

### 8.3 Specific regulation
```sql
EXEC KYC.GetBulkGCIDForRecalculateAppropriateness @GCIDToStart = 0, @RegulationID = 2, @BulkCount = 500
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetBulkGCIDForRecalculateAppropriateness | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetBulkGCIDForRecalculateAppropriateness.sql*
