# Monitoring.TransmissionFailureSimplex

> Reads payment pipeline status counts (Initiated, Transmitted, Completed) from the pre-computed dbo.PaymentStatuses table for Simplex payment provider monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment pipeline stage values for Simplex |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.TransmissionFailureSimplex monitors the Simplex fiat-to-crypto payment pipeline by reading pre-computed counts from the dbo.PaymentStatuses table. Simplex is a payment provider that enables customers to buy crypto with credit cards. This procedure returns three pipeline stage values (Initiated, Transmitted, Completed) that, when compared, reveal where failures are occurring.

Without this procedure, diagnosing Simplex payment pipeline issues would require manual queries against the PaymentStatuses summary table.

The procedure uses UNION ALL to return each stage as a separate row with Value and Object columns, using ISNULL with -1 default to flag NULL values (meaning the stage counter doesn't exist).

---

## 2. Business Logic

### 2.1 Pipeline Stage Comparison

**What**: Returns three pipeline stages for comparison.

**Columns/Parameters Involved**: `Initiated`, `Transmited`, `Completed`

**Rules**:
- Each stage returned as a row: (Value, Object)
- Value = -1 indicates the stage counter is NULL (not initialized or missing)
- Normal flow: Initiated >= Transmitted >= Completed
- Gaps between stages indicate failures at that point
- "Transmited" column name has a typo in the source table (single 't')

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Value | INT | NO | - | CODE-BACKED | Count for the pipeline stage. -1 if the stage counter is NULL. |
| 2 | Object | VARCHAR | NO | - | CODE-BACKED | Pipeline stage name: 'Initiated', 'Transmited', or 'Completed'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | dbo.PaymentStatuses | FROM (read) | Pre-computed Simplex payment pipeline counts |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.TransmissionFailureSimplex (procedure)
  └── dbo.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentStatuses | Table | FROM - pre-computed pipeline counts |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the pipeline check
```sql
EXEC Monitoring.TransmissionFailureSimplex;
```

### 8.2 View the raw PaymentStatuses table
```sql
SELECT * FROM dbo.PaymentStatuses WITH (NOLOCK);
```

### 8.3 Calculate failure rate from results
```sql
-- After running the procedure, compare:
-- Failure at initiation: Initiated - Transmited
-- Failure at transmission: Transmited - Completed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.TransmissionFailureSimplex | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.TransmissionFailureSimplex.sql*
