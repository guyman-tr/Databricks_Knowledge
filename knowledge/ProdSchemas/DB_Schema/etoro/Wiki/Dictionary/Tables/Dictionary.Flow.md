# Dictionary.Flow

> Lookup table defining the three trading execution flow types — Open Trade, Close Trade, and Internal Transfer — used to classify billing and BackOffice operations by their trade lifecycle stage.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FlowID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Flow defines the three fundamental types of trading execution flows in eToro's system. Every trade-related billing operation falls into one of these categories: opening a new position, closing an existing position, or performing an internal transfer between accounts. This classification drives how BackOffice procedures display, filter, and process trade-related financial records.

This table exists because billing and BackOffice reporting need to segment operations by lifecycle stage. A deposit associated with a trade open needs different handling than one linked to a position close or an internal fund transfer. The FlowID is referenced in multiple BackOffice stored procedures that display deposits, cashouts, and withdrawal history to operations staff.

FlowID is consumed by BackOffice procedures including BillingDepositsPCIVersion, GetProcessedWithdrawPCIVersion, GetCashOutRequests, and billing reporting procedures. It appears as a filter/display column in views that show billing transactions categorized by their trade context.

---

## 2. Business Logic

### 2.1 Trade Lifecycle Flow Classification

**What**: Every trading-related billing operation belongs to one of three lifecycle stages.

**Columns/Parameters Involved**: `FlowID`, `Description`

**Rules**:
- **Open Trade Execution (1)**: Financial operations triggered by opening a new position — initial margin, deposit flows tied to trade entry
- **Close Trade Execution (2)**: Financial operations triggered by closing a position — PnL settlement, funds released from margin
- **Internal Transfer (3)**: Fund movements between accounts that are not directly tied to trade open/close — e.g., transfers between trading and wallet accounts, mirror/copy rebalancing

**Diagram**:
```
Trading Operation Lifecycle:
    ┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
    │  Open Trade (1)  │ ──► │  Position Active  │ ──► │  Close Trade (2) │
    │  Margin allocated │     │  (no flow change) │     │  PnL settled     │
    └─────────────────┘     └──────────────────┘     └──────────────────┘

    ┌───────────────────────┐
    │  Internal Transfer (3) │  ← Independent of position lifecycle
    │  Account-to-account    │
    └───────────────────────┘
```

---

## 3. Data Overview

| FlowID | Description | Meaning |
|---|---|---|
| 1 | Open Trade Execution | Financial operations associated with opening a new trading position. Includes margin allocation, deposit-to-trade flows, and initial fee deductions. Used by BackOffice to filter deposits that were immediately followed by a trade open. |
| 2 | Close Trade Execution | Financial operations associated with closing an existing position. Includes PnL settlement, margin release, and close-related fee calculations. Used to track the financial outcome of position closure events. |
| 3 | Internal Transfer | Fund movements between accounts that are not tied to a specific trade open or close. Covers inter-account transfers (trading ↔ wallet), copy-trading fund rebalancing, and administrative fund adjustments. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FlowID | int | NO | - | VERIFIED | Primary key identifying the execution flow type. 1=Open Trade Execution, 2=Close Trade Execution, 3=Internal Transfer. Referenced by BackOffice and Billing procedures to classify financial operations by their trade lifecycle context. |
| 2 | Description | varchar(50) | NO | - | VERIFIED | Human-readable label for the flow type. Displayed in BackOffice billing screens, cashout request views, and withdrawal reports. Used for filtering and grouping operations by trade lifecycle stage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion | FlowID | Read | Displays flow type in deposit billing reports |
| BackOffice.GetProcessedWithdrawPCIVersion | FlowID | Read | Displays flow type in processed withdrawal reports |
| BackOffice.GetCashOutRequests_Main | FlowID | Read | References flow type in cashout request views |
| BackOffice.GetCashOutRequests | FlowID | Read | References flow type in cashout request views |
| Billing.GetDepositsCustomerCardPCIVersion | FlowID | Read | Displays flow type in customer card deposit reports |
| Billing.GetRejectedWithdrawsByRejectDate | FlowID | Read | References flow in rejected withdrawal reports |
| Billing.GetRejectedWithdrawsByRequestDate | FlowID | Read | References flow in rejected withdrawal reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | Reads flow for billing deposit reports |
| BackOffice.GetProcessedWithdrawPCIVersion | Stored Procedure | Reads flow for processed withdrawal reports |
| BackOffice.GetCashOutRequests_Main | Stored Procedure | Reads flow for cashout request views |
| BackOffice.GetCashOutRequests | Stored Procedure | Reads flow for cashout request views |
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | Reads flow for card deposit reports |
| Billing.GetRejectedWithdrawsByRejectDate | Stored Procedure | Reads flow for rejected withdrawal reports |
| Billing.GetRejectedWithdrawsByRequestDate | Stored Procedure | Reads flow for rejected withdrawal reports |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Flows | CLUSTERED PK | FlowID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Flows | PRIMARY KEY | Unique flow type identifier |

---

## 8. Sample Queries

### 8.1 List all flow types
```sql
SELECT  FlowID,
        Description
FROM    [Dictionary].[Flow] WITH (NOLOCK)
ORDER BY FlowID;
```

### 8.2 Resolve flow description for a billing record
```sql
SELECT  f.Description   AS FlowType
FROM    [Dictionary].[Flow] f WITH (NOLOCK)
WHERE   f.FlowID = @FlowID;
```

### 8.3 Flow label lookup with fallback for NULL
```sql
SELECT  ISNULL(f.Description, 'Unknown')   AS FlowType
FROM    [Dictionary].[Flow] f WITH (NOLOCK)
WHERE   f.FlowID = @FlowID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Flow | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Flow.sql*
