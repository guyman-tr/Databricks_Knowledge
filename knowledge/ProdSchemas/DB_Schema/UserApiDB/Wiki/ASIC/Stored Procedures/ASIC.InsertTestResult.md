# ASIC.InsertTestResult

> Inserts a new ASIC classification test result row and returns the generated TestId via SCOPE_IDENTITY().

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID, @Success, @Score, @OccurredAt (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ASIC.InsertTestResult is the entry point for recording an ASIC classification test session. It inserts the summary row into ASIC.TestResults (pass/fail, score, timestamp) and immediately returns the new TestId using SCOPE_IDENTITY(). The caller uses this TestId to subsequently insert the individual Q&A pairs via ASIC.InsertCustomerAnswer.

This procedure is always the first step in persisting an ASIC test session: the TestId it returns is the foreign key that ties all answer rows together.

---

## 2. Business Logic

### 2.1 Identity Return

**What**: Returns the auto-generated primary key of the newly inserted row.

**How**: Uses SCOPE_IDENTITY() immediately after the INSERT to return the new TestId to the caller.

**Why**: The caller needs the TestId to pass to ASIC.InsertCustomerAnswer for each Q&A pair in the same test session.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. The user who took the test. |
| 2 | @Success | bit (IN) | NO | - | CODE-BACKED | Whether the user passed. 1 = pass, 0 = fail. |
| 3 | @Score | int (IN) | YES | - | CODE-BACKED | Numeric score achieved. May be NULL if not applicable. |
| 4 | @OccurredAt | datetime (IN) | NO | - | CODE-BACKED | When the test was taken. Supplied by the caller. |

Output: Returns a single scalar result set containing the new TestId (int) via SCOPE_IDENTITY().

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | ASIC.TestResults | INSERT INTO | Creates a new test result row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by application code before InsertCustomerAnswer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.InsertTestResult (procedure)
  +-- ASIC.TestResults (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.TestResults | Table | INSERT INTO; returns SCOPE_IDENTITY() as new TestId |

### 6.2 Objects That Depend On This

No database-level dependents found. Application code depends on this procedure to initiate a test session.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a test result and capture the new TestId
```sql
DECLARE @NewTestId INT
EXEC @NewTestId = ASIC.InsertTestResult
    @GCID       = 12345,
    @Success    = 1,
    @Score      = 80,
    @OccurredAt = '2026-04-11 09:00:00'
SELECT @NewTestId AS NewTestId
```

### 8.2 Full test session insert pattern
```sql
-- Insert the test result
DECLARE @TestId INT
EXEC @TestId = ASIC.InsertTestResult @GCID = 12345, @Success = 1, @Score = 80, @OccurredAt = GETUTCDATE()

-- Insert each answer using the returned TestId
EXEC ASIC.InsertCustomerAnswer @TestId = @TestId, @Question = N'Q1', @Answer = N'A1', @OccurredAt = GETUTCDATE()
EXEC ASIC.InsertCustomerAnswer @TestId = @TestId, @Question = N'Q2', @Answer = N'A2', @OccurredAt = GETUTCDATE()
```

### 8.3 Insert with no score
```sql
EXEC ASIC.InsertTestResult @GCID = 12345, @Success = 0, @Score = NULL, @OccurredAt = GETUTCDATE()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: ASIC.InsertTestResult | Type: Stored Procedure | Source: UserApiDB/UserApiDB/ASIC/Stored Procedures/ASIC.InsertTestResult.sql*
