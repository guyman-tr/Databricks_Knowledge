# Dictionary.CopyPositionStatusID

> Lookup table defining the status of copy trading position creation steps - registration and fund allocation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table tracks the status of copy trading position creation, which is a two-step process: first registering the copy relationship with the parent trader's portfolio, then allocating funds to the copy position. Each step can succeed or fail independently, and this table provides the four possible outcomes.

Without this table, the system could not distinguish between registration-phase failures and fund-allocation-phase failures in copy trading, which is essential for retry logic and troubleshooting. A failed registration requires different remediation than a failed fund allocation.

Values are written to PlanInstances.CopyPositionStatusID by the recurring investment backend service when processing copy-type plans (PlanType=2, CopyType=1 PI or CopyType=4 SmartPortfolio). The Deposit Message Handler and Order Execution Job update this status as copy positions are processed.

---

## 2. Business Logic

### 2.1 Two-Step Copy Position Creation

**What**: Copy position creation follows a sequential two-step process where each step is tracked independently.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Step 1 (Register): The system registers a copy relationship with the parent trader (PI or SmartPortfolio)
- Step 2 (AddFunds): After successful registration, funds are allocated to the copy position
- Each step has independent success/failure tracking
- A RegisterFailed (3) means AddFunds was never attempted
- An AddFundFailed (4) means registration succeeded but fund allocation failed

**Diagram**:
```
Register Copy Relationship
    |
    +-- RegisterSuccess (1) --> Add Funds to Copy Position
    |                              |
    |                              +-- AddFundsSuccess (2) --> DONE
    |                              |
    |                              +-- AddFundFailed (4) --> RETRY/FAIL
    |
    +-- RegisterFailed (3) --> RETRY/FAIL
```

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | RegisterSuccess | Copy relationship was successfully registered with the parent trader's portfolio. This is the first step - funds have not yet been allocated. |
| 2 | AddFundsSuccess | Funds were successfully allocated to the copy position after registration. This is the terminal success state - the copy position is fully established. |
| 3 | RegisterFailed | Attempt to register the copy relationship with the parent trader failed. Fund allocation was never attempted. May trigger retry or plan cancellation. |
| 4 | AddFundFailed | Fund allocation to the copy position failed after successful registration. The copy relationship exists but has no funds - requires separate remediation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the copy position status. 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the copy position status step and outcome. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | CopyPositionStatusID | Implicit Lookup | Tracks the copy position creation status for copy-type plan instances |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | CopyPositionStatusID column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CopyPositionStatusID | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all copy position statuses
```sql
SELECT ID, Name
FROM [Dictionary].[CopyPositionStatusID] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find plan instances by copy position status
```sql
SELECT pi.InstanceID, pi.PlanID, pi.CopyPositionStatusID, cps.Name AS StatusName
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[CopyPositionStatusID] cps WITH (NOLOCK) ON pi.CopyPositionStatusID = cps.ID
```

### 8.3 Count copy position outcomes
```sql
SELECT cps.ID, cps.Name, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[CopyPositionStatusID] cps WITH (NOLOCK) ON pi.CopyPositionStatusID = cps.ID
GROUP BY cps.ID, cps.Name
ORDER BY cps.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Confirms copy position status tracking in PlanInstances table |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CopyPositionStatusID | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.CopyPositionStatusID.sql*
