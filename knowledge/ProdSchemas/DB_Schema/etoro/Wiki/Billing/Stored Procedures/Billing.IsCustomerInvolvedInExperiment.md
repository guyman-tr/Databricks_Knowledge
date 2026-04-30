# Billing.IsCustomerInvolvedInExperiment

> Returns a single row if the specified customer is enrolled in the specified billing A/B experiment, or an empty result set if not enrolled - used as a boolean enrollment check before directing customers into experimental payment flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0 or 1 row from Billing.ABTestsOnCustomersHistory |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.IsCustomerInvolvedInExperiment` is the lookup procedure for the Billing A/B experiment enrollment system. It answers the question: "Is this customer currently enrolled in this billing experiment?" The Billing domain uses controlled experiments to test new payment flows, fee structures, or routing logic on a subset of customers before full rollout.

The procedure is the reader half of a two-SP contract: `Billing.MarkCustomerAsExperimentSubject` WRITES enrollment records; `Billing.IsCustomerInvolvedInExperiment` READS them. Callers check the returned row count (or row presence) to decide which treatment path to apply: if a row is returned, the customer is in the experiment; if the result is empty, they are not and the default path is used. The "History" table name reflects that enrollment is permanent - once added, a customer stays in the experiment record indefinitely.

Data flows: the calling service (DepositSetupUser role has EXECUTE permission) checks enrollment status at the start of a billing flow, then routes the customer to the experimental or control path accordingly. The current live experiment is ExperimentID=1 with ~56K enrolled customers.

---

## 2. Business Logic

### 2.1 Enrollment Check Pattern

**What**: Callers use the presence/absence of a returned row as a boolean - row found = enrolled, no row = not enrolled.

**Columns/Parameters Involved**: `@CID`, `@ExperimentID`, `CID`, `ExperimentID`

**Rules**:
- SELECT TOP 1 ensures at most one row is returned even if duplicates exist (though the composite PK prevents duplicates)
- Returns both CID and ExperimentID to allow the caller to confirm the correct record was found (not just a count)
- Empty result set = customer not enrolled in this experiment - applies standard/default payment flow
- One-row result = customer IS enrolled - applies experimental payment flow
- Must be called BEFORE `Billing.MarkCustomerAsExperimentSubject` if upsert semantics are needed; the writer does not check for existing rows

**Diagram**:
```
Deposit/payment flow starts for CID=X
        |
        v
EXEC IsCustomerInvolvedInExperiment @ExperimentID=1, @CID=X
        |
        +-- Returns row: CID=X IS enrolled in experiment 1
        |         -> Apply experimental payment treatment
        |
        +-- Returns empty: CID=X NOT enrolled
                  -> Apply standard payment treatment
                  -> Optionally: MarkCustomerAsExperimentSubject(@CID=X, @ExperimentID=1)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExperimentID | INT | NO | - | CODE-BACKED | Identifies which billing A/B experiment to check enrollment for. Currently ExperimentID=1 is the only active experiment in the system (~56K enrolled customers). |
| 2 | @CID | INT | NO | - | CODE-BACKED | The eToro customer ID to check. Matched against Billing.ABTestsOnCustomersHistory.CID. |

### Output Columns

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | INT | CODE-BACKED | The customer ID from the enrollment record. Present only if enrolled. |
| 2 | ExperimentID | INT | CODE-BACKED | The experiment ID from the enrollment record. Confirms which experiment the customer is enrolled in. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.ABTestsOnCustomersHistory | READ | Queries the enrollment log table using (CID, ExperimentID) composite key lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | GRANT EXECUTE | Permission | The DepositSetupUser role is authorized to call this procedure - it is invoked during deposit setup flows where experiment routing decisions are made |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.IsCustomerInvolvedInExperiment (procedure)
└── Billing.ABTestsOnCustomersHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ABTestsOnCustomersHistory | Table | SELECT source; queries by (CID, ExperimentID) composite PK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.MarkCustomerAsExperimentSubject | Stored Procedure | Sibling WRITER - should be called after IsCustomerInvolvedInExperiment returns empty to safely enroll a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- SELECT TOP 1 with no explicit ORDER BY - result order is non-deterministic but determinism is irrelevant since the composite PK guarantees at most one matching row
- No WITH (NOLOCK) hint - reads with shared locks; for a simple composite PK lookup this is negligible
- GRANT EXECUTE TO DepositSetupUser is embedded in the SP DDL file

---

## 8. Sample Queries

### 8.1 Check if customer is in experiment 1
```sql
EXEC Billing.IsCustomerInvolvedInExperiment
    @ExperimentID = 1,
    @CID          = 7890123
-- Returns 1 row (enrolled) or empty (not enrolled)
```

### 8.2 Direct table lookup equivalent
```sql
SELECT TOP 1 CID, ExperimentID
FROM Billing.ABTestsOnCustomersHistory WITH (NOLOCK)
WHERE CID = 7890123
  AND ExperimentID = 1
```

### 8.3 Count enrollments per experiment
```sql
SELECT ExperimentID, COUNT(*) AS EnrolledCustomers
FROM Billing.ABTestsOnCustomersHistory WITH (NOLOCK)
GROUP BY ExperimentID
ORDER BY ExperimentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 sibling analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.IsCustomerInvolvedInExperiment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.IsCustomerInvolvedInExperiment.sql*
