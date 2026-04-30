# KYC.GetUserDataForRestrictions

> Returns a single user's KYC answers with verification and regulation data for restriction evaluation.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetUserDataForRestrictions retrieves a single user's KYC data for evaluating whether trading restrictions should be applied. Same data shape as GetGCIDForRecalculateAppropriateness but for a mandatory single GCID. Used when a user's regulation changes and restrictions need re-evaluation.

---

## 2. Business Logic

Same pattern as GetGCIDForRecalculateAppropriateness, but @gcid is mandatory (not optional).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID to evaluate. |

Output: CID, GCID, VerificationLevelID, DesignatedRegulationID, QuestionId, Registered, CountryID, AnswerId, OccurredAt, FirstUpdated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | SELECT FROM | Answer data |
| - | dbo.Real_Customer | JOIN | User data |
| - | dbo.Real_BackOfficeCustomer | JOIN | Verification/regulation |
| - | History.CustomerAnswers | Subquery | FirstUpdated |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetUserDataForRestrictions (procedure)
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

### 8.1 Get restriction data
```sql
EXEC KYC.GetUserDataForRestrictions @gcid = 12345
```

### 8.2 Check if user has answers
```sql
DECLARE @R TABLE (CID INT, GCID INT, VerificationLevelID INT, DesignatedRegulationID INT, QuestionId INT, Registered DATETIME, CountryID INT, AnswerId INT, OccurredAt DATETIME, FirstUpdated DATETIME)
INSERT INTO @R EXEC KYC.GetUserDataForRestrictions @gcid = 12345
SELECT COUNT(*) FROM @R
```

### 8.3 Direct equivalent
```sql
SELECT cc.CID, ca.GCID, bc.VerificationLevelID, bc.DesignatedRegulationID, ca.QuestionId, cc.Registered, cc.CountryID, ca.AnswerId, ca.OccurredAt
FROM KYC.CustomerAnswers ca WITH (NOLOCK)
JOIN dbo.Real_Customer cc WITH (NOLOCK) ON ca.GCID = cc.GCID
JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE cc.GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetUserDataForRestrictions | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetUserDataForRestrictions.sql*
