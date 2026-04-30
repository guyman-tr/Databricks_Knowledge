# Billing.MarkCustomerAsExperimentSubject

> Writer procedure that enrolls a customer into a Billing A/B experiment by inserting a (CID, ExperimentID) row into Billing.ABTestsOnCustomersHistory.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @ExperimentID INT - the enrollment pair |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.MarkCustomerAsExperimentSubject records a customer's assignment to a specific Billing A/B experiment. It inserts a (CID, ExperimentID) row into Billing.ABTestsOnCustomersHistory. This is the sole write path to that table.

The procedure is used to implement controlled billing experiments - for example, testing new fee structures, deposit flows, or payment routing logic on a subset of customers before a wider rollout. Once enrolled, a customer's membership is permanent: the composite PK (CID, ExperimentID) prevents duplicate enrollment and there is no corresponding delete procedure.

The typical caller flow is:
1. Call Billing.IsCustomerInvolvedInExperiment(@CID, @ExperimentID) - if the row exists, skip.
2. If not enrolled, call Billing.MarkCustomerAsExperimentSubject(@CID, @ExperimentID) to enroll.

The procedure itself does NOT check for existing enrollment before inserting. A duplicate attempt will raise a primary key violation from Billing.ABTestsOnCustomersHistory - callers must pre-check with IsCustomerInvolvedInExperiment.

---

## 2. Business Logic

### 2.1 Enrollment Insert

**What**: Enrolls a customer in an experiment unconditionally (no pre-check).

**Columns/Parameters Involved**: `@CID`, `@ExperimentID`

**Rules**:
- Inserts a single row: INSERT INTO Billing.ABTestsOnCustomersHistory VALUES(@CID, @ExperimentID).
- No error handling or TRY/CATCH - a duplicate PK raises an unhandled exception to the caller.
- No existence check - callers are responsible for pre-checking via Billing.IsCustomerInvolvedInExperiment.
- Currently only one experiment is active in production: ExperimentID=1 (56K enrolled customers).
- No RETURN value - the procedure is void on success.

**Diagram**:
```
Application checks:
    Billing.IsCustomerInvolvedInExperiment(@CID, @ExperimentID)
    |
    +-- Enrolled -> skip (do NOT call MarkCustomerAsExperimentSubject)
    |
    +-- Not enrolled -> call Billing.MarkCustomerAsExperimentSubject(@CID, @ExperimentID)
                            |
                            v
                INSERT INTO Billing.ABTestsOnCustomersHistory VALUES (@CID, @ExperimentID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier to enroll. Implicit FK to Customer.CustomerStatic.CID. Written as CID to Billing.ABTestsOnCustomersHistory. Only customers not already enrolled should be passed here - duplicates cause a PK violation. |
| 2 | @ExperimentID | INT | NO | - | CODE-BACKED | Experiment identifier. Written as ExperimentID to Billing.ABTestsOnCustomersHistory. Currently only value 1 exists in production. The composite PK (CID, ExperimentID) means a customer can be enrolled in multiple experiments simultaneously but only once per experiment. |
| RETURN | (void) | - | - | CODE-BACKED | No explicit RETURN. Void on success. Unhandled exceptions propagate to the caller (e.g., duplicate PK violation). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Billing.ABTestsOnCustomersHistory | WRITE | Creates a new experiment enrollment record. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing application layer | @CID, @ExperimentID | EXEC | Called after pre-check via IsCustomerInvolvedInExperiment to enroll eligible customers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MarkCustomerAsExperimentSubject (procedure)
└── Billing.ABTestsOnCustomersHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ABTestsOnCustomersHistory | Table | INSERT - creates a new (CID, ExperimentID) enrollment row. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing application layer | Application | EXEC - called to enroll customers in billing experiments. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Enroll a customer in experiment 1
```sql
EXEC Billing.MarkCustomerAsExperimentSubject
    @CID = 12345,
    @ExperimentID = 1;
```

### 8.2 Safe enrollment with pre-check
```sql
-- First check if already enrolled
IF NOT EXISTS (
    SELECT 1 FROM Billing.ABTestsOnCustomersHistory WITH (NOLOCK)
    WHERE CID = 12345 AND ExperimentID = 1
)
BEGIN
    EXEC Billing.MarkCustomerAsExperimentSubject @CID = 12345, @ExperimentID = 1;
END
-- (In production, use Billing.IsCustomerInvolvedInExperiment for the pre-check)
```

### 8.3 Count enrolled customers per experiment after bulk enrollment
```sql
SELECT ExperimentID, COUNT(*) AS EnrolledCount
FROM Billing.ABTestsOnCustomersHistory WITH (NOLOCK)
GROUP BY ExperimentID
ORDER BY ExperimentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.MarkCustomerAsExperimentSubject | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.MarkCustomerAsExperimentSubject.sql*
