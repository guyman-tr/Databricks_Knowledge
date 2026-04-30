# Customer.AddCloseUserRequest

> Records a user's account closure request with the full closure flow data: category, reason, solution response, and free-text feedback.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.AddCloseUserRequest captures the complete closure flow interaction. When a user goes through the self-service account closure process, this procedure records their category selection, specific reason, whether the retention solution was accepted, and any free-text feedback. Optional parameters allow recording partial flows (user may abandon at any step).

---

## 2. Business Logic

No complex business logic. Single INSERT with optional parameters defaulting to NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @CloseUserCategoryId | int (IN) | NO | - | CODE-BACKED | Mandatory closure category: 1=paymentIssues, 2=accountIssues, 3=notMeetNeeds, 4=personalReasons, 5=other, 6=privacyConcerns. |
| 3 | @CloseUserReasonId | int (IN) | YES | NULL | CODE-BACKED | Specific reason within category. NULL if user did not proceed past category. |
| 4 | @CloseUserSolutionId | int (IN) | YES | NULL | CODE-BACKED | Retention solution presented. NULL if flow abandoned before solution. |
| 5 | @CloseUserSolveProblemId | int (IN) | YES | NULL | CODE-BACKED | User response: 1=yesKeepOpen, 2=yesClose, 3=noClose. NULL if no response. |
| 6 | @FreeText | nvarchar(4000) (IN) | YES | NULL | CODE-BACKED | User's free-text feedback about their closure decision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CloseUserRequest | INSERT INTO | Writes closure flow record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.AddCloseUserRequest (procedure)
  +-- Customer.CloseUserRequest (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CloseUserRequest | Table | INSERT INTO |

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

### 8.1 Full closure flow
```sql
EXEC Customer.AddCloseUserRequest @Gcid = 12345, @CloseUserCategoryId = 1,
  @CloseUserReasonId = 1, @CloseUserSolutionId = 1, @CloseUserSolveProblemId = 3, @FreeText = N'Fees too high'
```

### 8.2 Partial flow (category only)
```sql
EXEC Customer.AddCloseUserRequest @Gcid = 12345, @CloseUserCategoryId = 5
```

### 8.3 Retained user
```sql
EXEC Customer.AddCloseUserRequest @Gcid = 12345, @CloseUserCategoryId = 4,
  @CloseUserReasonId = 15, @CloseUserSolutionId = 15, @CloseUserSolveProblemId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.AddCloseUserRequest | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.AddCloseUserRequest.sql*
