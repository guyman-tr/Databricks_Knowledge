# Billing.ABTestsOnCustomersHistory

> Permanent enrollment log recording which customers have been assigned to which billing A/B experiments.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CID, ExperimentID) - composite clustered PK |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Billing.ABTestsOnCustomersHistory` is the audit log for Billing-domain A/B experiment enrollment. Each row represents a customer-experiment pair, recording that a given customer (CID) was placed into a specific billing experiment (ExperimentID). The composite primary key prevents duplicate enrollment: a customer can only appear once per experiment.

This table exists to support controlled experiments in the Billing domain - for example, testing new fee structures, deposit flows, or payment routing logic on a subset of customers before a wider rollout. Without this table there would be no persistent record of which customers were exposed to which experimental treatments, making it impossible to attribute outcomes or ensure consistency across sessions.

Data enters via `Billing.MarkCustomerAsExperimentSubject` (INSERT) and is queried by `Billing.IsCustomerInvolvedInExperiment` (SELECT). The table currently holds one active experiment (ExperimentID=1) with approximately 56K enrolled customers. The "History" suffix indicates this is a cumulative, append-only log - enrollment records are not removed when an experiment concludes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

### 2.1 Enrollment Uniqueness

**What**: Each customer can be enrolled in each experiment only once.

**Columns/Parameters Involved**: `CID`, `ExperimentID`

**Rules**:
- The composite PK (CID, ExperimentID) enforces that duplicate enrollment attempts will raise a primary key violation.
- `Billing.MarkCustomerAsExperimentSubject` inserts without a prior existence check - callers must invoke `Billing.IsCustomerInvolvedInExperiment` first if upsert semantics are needed.
- The READER procedure (`IsCustomerInvolvedInExperiment`) returns the (CID, ExperimentID) row if found, or an empty resultset if not enrolled - the application checks for a non-empty result.

**Diagram**:
```
Customer eligibility check
        |
        v
Billing.IsCustomerInvolvedInExperiment(@CID, @ExperimentID)
        |
        +-- Row returned: customer ALREADY enrolled -> skip
        |
        +-- Empty result: customer NOT enrolled
                |
                v
        Billing.MarkCustomerAsExperimentSubject(@CID, @ExperimentID)
                |
                v
        INSERT (CID, ExperimentID) -> ABTestsOnCustomersHistory
```

---

## 3. Data Overview

| CID | ExperimentID | Meaning |
|-----|-------------|---------|
| 20653 | 1 | An early-adopter customer (low CID range) enrolled in Experiment 1 - likely from an initial pilot or internal test phase. |
| 692008 | 1 | An established retail customer enrolled in Experiment 1, from an older account cohort. |
| 3635312 | 1 | A mid-range customer enrolled in Experiment 1, representing a later signup cohort. |
| 3739183 | 1 | Customer enrolled in Experiment 1 within a batch of sequential CIDs (3739183-3739198 appear in same block), suggesting bulk enrollment logic. |
| 3739193 | 1 | Another customer from the sequential enrollment block, confirming a bulk assignment pattern for Experiment 1. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier for the enrolled experiment subject. Implicit FK to the Customer schema (Customer.CustomerStatic.CID). Uniquely identifies a registered eToro customer. Part of the composite PK - a customer can appear once per ExperimentID. |
| 2 | ExperimentID | int | NO | - | CODE-BACKED | Numeric identifier for the billing A/B experiment. Defines which experiment the customer was enrolled in. Currently only value 1 exists in production (56,253 rows all with ExperimentID=1). Part of the composite PK - multiple experiments can exist simultaneously. Used as a parameter by both `Billing.IsCustomerInvolvedInExperiment` and `Billing.MarkCustomerAsExperimentSubject`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | CID identifies the customer enrolled in the experiment. No explicit FK constraint - relationship enforced at application level. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.MarkCustomerAsExperimentSubject | @CID, @ExperimentID | WRITER | Inserts a new enrollment record - the only write path to this table. |
| Billing.IsCustomerInvolvedInExperiment | @CID, @ExperimentID | READER | Checks whether a customer is enrolled in a given experiment - returns the row if enrolled, empty if not. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.MarkCustomerAsExperimentSubject | Stored Procedure | WRITER - INSERTs new (CID, ExperimentID) enrollment records |
| Billing.IsCustomerInvolvedInExperiment | Stored Procedure | READER - SELECTs TOP 1 to check enrollment existence |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_ABTestsOnCustomersHistory | CLUSTERED PK | CID ASC, ExperimentID ASC | - | - | Active |

Page compression applied (DATA_COMPRESSION = PAGE). Stored on MAIN filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_ABTestsOnCustomersHistory | PRIMARY KEY | Composite (CID, ExperimentID) - prevents duplicate enrollment of the same customer in the same experiment |

---

## 8. Sample Queries

### 8.1 Check if a customer is enrolled in an experiment

```sql
SELECT CID, ExperimentID
FROM [Billing].[ABTestsOnCustomersHistory] WITH (NOLOCK)
WHERE CID = @CID
  AND ExperimentID = @ExperimentID;
-- Returns 1 row if enrolled, empty if not
```

### 8.2 List all experiments a customer is enrolled in

```sql
SELECT ExperimentID
FROM [Billing].[ABTestsOnCustomersHistory] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY ExperimentID;
```

### 8.3 Count enrolled customers per experiment

```sql
SELECT ExperimentID,
       COUNT(*) AS EnrolledCustomers
FROM [Billing].[ABTestsOnCustomersHistory] WITH (NOLOCK)
GROUP BY ExperimentID
ORDER BY ExperimentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ABTestsOnCustomersHistory | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ABTestsOnCustomersHistory.sql*
