# Dictionary.DepositFlow

> Lookup table defining the trading flow contexts in which a deposit-related financial operation occurs — distinguishing between open trade execution, close trade execution, and internal transfers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FlowID (PK) |
| **Partition** | No — stored on DICTIONARY filegroup, PAGE compressed |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table classifies deposit-related financial flows by the trading context in which they occur. When money moves through the platform, the system needs to know whether it is associated with opening a trade (Open Trade Execution), closing a trade (Close Trade Execution), or an internal account-to-account transfer (Internal Transfer). This context determines how the financial operation is processed, reported, and reconciled.

Without this table, the platform would have no way to distinguish the operational context of financial flows. This distinction is critical for financial reporting, P&L attribution, and regulatory transaction reporting where the reason for fund movement must be classified.

No procedures or views in the etoro SSDT project reference this table directly, suggesting it is consumed by application-layer services or used in financial reconciliation workflows.

---

## 2. Business Logic

### 2.1 Financial Flow Classification

**What**: Deposit-related money movements are classified by their trading context.

**Columns/Parameters Involved**: `FlowID`, `Description`

**Rules**:
- Open Trade Execution (1) — funds are committed when a customer opens a new position (margin allocation)
- Close Trade Execution (2) — funds are released/adjusted when a customer closes a position (P&L realization)
- Internal Transfer (3) — funds move between internal accounts without a trade context (e.g., bonus allocation, account consolidation)

---

## 3. Data Overview

| FlowID | Description | Meaning |
|---|---|---|
| 1 | Open Trade Execution | Financial flow associated with opening a new trading position — funds are allocated as margin from the customer's available balance to secure the position |
| 2 | Close Trade Execution | Financial flow associated with closing an existing position — realized P&L is calculated and funds are returned to available balance (profit) or deducted (loss) |
| 3 | Internal Transfer | Financial flow for account-to-account movements that are not directly tied to a trade — includes bonus credits, manual adjustments, and inter-entity fund movements |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FlowID | int | NO | - | CODE-BACKED | Primary key identifying the deposit flow type. 1=Open Trade Execution, 2=Close Trade Execution, 3=Internal Transfer. |
| 2 | Description | varchar(50) | NO | - | CODE-BACKED | Human-readable description of the flow context. Used in financial reporting and reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct SQL consumers found in the etoro SSDT project. Likely consumed by application-layer financial processing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositFlow (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DepositFlow | CLUSTERED | FlowID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all deposit flow types
```sql
SELECT  FlowID,
        Description
FROM    Dictionary.DepositFlow WITH (NOLOCK)
ORDER BY FlowID
```

### 8.2 Classify flows by category
```sql
SELECT  FlowID,
        Description,
        CASE WHEN FlowID IN (1, 2) THEN 'Trade-Related' ELSE 'Non-Trade' END AS FlowCategory
FROM    Dictionary.DepositFlow WITH (NOLOCK)
```

### 8.3 Resolve deposit flow context (conceptual join)
```sql
SELECT  d.DepositID,
        d.Amount,
        df.Description AS FlowContext
FROM    Billing.Deposit d WITH (NOLOCK)
        JOIN Dictionary.DepositFlow df WITH (NOLOCK) ON d.FlowID = df.FlowID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositFlow | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositFlow.sql*
