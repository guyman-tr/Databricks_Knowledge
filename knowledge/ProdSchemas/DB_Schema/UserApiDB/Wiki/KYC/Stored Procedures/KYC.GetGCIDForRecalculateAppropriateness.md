# KYC.GetGCIDForRecalculateAppropriateness

> Returns all verified CySEC/FCA users with their KYC answers for appropriateness recalculation, optionally filtered to a single GCID.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (optional input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetGCIDForRecalculateAppropriateness is the non-paginated version of GetBulkGCIDForRecalculateAppropriateness. Returns all verified users under CySEC/FCA regulation (DesignatedRegulationID IN (1,2)) with their KYC answers. When @gcid is provided, returns data for that single user only. Includes FirstUpdated from History.

---

## 2. Business Logic

No complex beyond filtering to CySEC/FCA + VerificationLevel >= 2.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | YES | NULL | CODE-BACKED | Optional: specific GCID. NULL = all matching users. |

Output: CID, GCID, VerificationLevelID, DesignatedRegulationID, QuestionId, Registered, CountryID, AnswerId, OccurredAt, FirstUpdated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | SELECT FROM | Answer data |
| - | dbo.Real_Customer | JOIN | User data |
| - | dbo.Real_BackOfficeCustomer | JOIN | Regulation/verification data |
| - | History.CustomerAnswers | Subquery | FirstUpdated |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetGCIDForRecalculateAppropriateness (procedure)
  +-- KYC.CustomerAnswers (table) [done]
  +-- dbo.Real_Customer (synonym)
  +-- dbo.Real_BackOfficeCustomer (synonym)
  +-- History.CustomerAnswers (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | SELECT FROM |
| dbo.Real_Customer | Synonym | JOIN |
| dbo.Real_BackOfficeCustomer | Synonym | JOIN |
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

### 8.1 Single user
```sql
EXEC KYC.GetGCIDForRecalculateAppropriateness @gcid = 12345
```

### 8.2 All CySEC/FCA users
```sql
EXEC KYC.GetGCIDForRecalculateAppropriateness
```

### 8.3 Compare with bulk version
```sql
-- Single user (this SP):
EXEC KYC.GetGCIDForRecalculateAppropriateness @gcid = 12345
-- Bulk version:
EXEC KYC.GetBulkGCIDForRecalculateAppropriateness @GCIDToStart = 12344, @BulkCount = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetGCIDForRecalculateAppropriateness | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetGCIDForRecalculateAppropriateness.sql*
