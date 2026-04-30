# Dictionary.CashoutType

> Lookup table defining the 3 cashout (withdrawal) classifications — NewMoneyCashout, CashoutRefund, and RiskRefund — determining whether a withdrawal is a standard payout, a deposit refund, or a risk-driven return.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutTypeID (TINYINT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CashoutType classifies the financial nature of a withdrawal — specifically whether the outgoing funds represent new money being returned to the customer, a refund of a prior deposit, or a risk-driven return. This distinction is critical for accounting, regulatory reporting, and PSP routing because each type has different financial treatment.

CashoutTypeID is stored on Billing.WithdrawToFunding (the main withdrawal tracking table) and flows through to History.WithdrawToFundingAction, views (Billing.vWithdrawToFunding, Billing.FundingDataForWithdraw), and extensive BackOffice reporting. The type drives CASE logic throughout the codebase — procedures like BackOffice.GetCashOutRequests and BackOffice.GetWithdrawRequestsDetails use `WHEN CashoutTypeID = 1` (new money) vs `WHEN CashoutTypeID = 2` (refund) to apply different display and routing logic, and `IN (2, 3)` to group refund types together.

---

## 2. Business Logic

### 2.1 Cashout Type Classification

**What**: The three fundamental types of withdrawal and their financial treatment.

**Columns/Parameters Involved**: `CashoutTypeID`, `CashoutTypeName`

**Rules**:
- **NewMoneyCashout (1)**: Standard withdrawal — customer is withdrawing profits or deposited funds as a new outgoing payment. Processed through normal cashout channels. The most common type.
- **CashoutRefund (2)**: Refund of a prior deposit — funds are being returned to the original payment method. May be triggered by chargeback, customer complaint, or operational decision. Treated differently for accounting (reversal vs new payment). Often filtered together with RiskRefund as `IN (2, 3)`.
- **RiskRefund (3)**: Risk-driven refund — funds returned due to risk/compliance decision (fraud detection, AML investigation, account foreclosure). Special approval and processing flows. Often grouped with CashoutRefund in BackOffice reporting.

**Diagram**:
```
Withdrawal Classification:

  Withdrawal Request
       │
       ├── New funds out ──► NewMoneyCashout (1)
       │     Standard payout to customer
       │
       ├── Deposit reversal ──► CashoutRefund (2)
       │     Refund to original payment method
       │
       └── Risk return ──► RiskRefund (3)
              Compliance-driven fund return

  BackOffice grouping: CashoutTypeID IN (2, 3) = "Refund types"
```

### 2.2 Display and Routing Logic

**What**: How CashoutTypeID drives different display and processing paths.

**Columns/Parameters Involved**: `CashoutTypeID`

**Rules**:
- **Billing.FundingDataForWithdraw**: Uses `CASE WHEN CashoutTypeID IN (1, 2)` for conditional display
- **BackOffice.GetCashOutRequests**: Branches on `WHEN CashoutTypeID = 1` vs `WHEN CashoutTypeID = 2` and filters `IN (2, 3)` for refund views
- **BackOffice.GetDepositRefundedCashoutsPCIVersion**: Filters `WHERE CashoutTypeID = 2` specifically for deposit refund reporting
- **BackOffice.WithdrawToFundingAdd**: Validates CashoutTypeID with EXISTS check before inserting
- **BackOffice.GetProcessedWithdrawPCIVersion**: LEFT JOINs to resolve CashoutTypeName for display

---

## 3. Data Overview

| CashoutTypeID | CashoutTypeName | Meaning |
|---|---|---|
| 1 | NewMoneyCashout | Standard withdrawal — new outgoing payment from customer's eToro balance. Customer profits, trading capital, or deposited funds being withdrawn through normal channels. Most common cashout type. Processed as a new payment to the customer's chosen withdrawal method. |
| 2 | CashoutRefund | Deposit refund — reversal of a prior deposit back to the original payment method. Triggered by chargebacks, disputes, compliance decisions, or customer complaints. Treated as a reversal in accounting (not a new payment). Grouped with RiskRefund in BackOffice reporting. |
| 3 | RiskRefund | Risk-driven refund — funds returned as a result of risk or compliance investigation. Account may be flagged, blocked, or foreclosed. Special approval required. Grouped with CashoutRefund as `IN (2, 3)` in BackOffice queries. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the withdrawal classification. 1=NewMoneyCashout (standard), 2=CashoutRefund (deposit reversal), 3=RiskRefund (compliance return). Stored in Billing.WithdrawToFunding and History.WithdrawToFundingAction. Drives CASE branching in 15+ BackOffice/Billing procedures. Types 2 and 3 are often grouped as refund types. |
| 2 | CashoutTypeName | varchar(50) | YES | - | VERIFIED | Human-readable type label. Nullable. Note: column named CashoutTypeName (not Name) — matches table naming convention. Joined in BackOffice reports and payout processing for display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFunding | CashoutTypeID | Implicit | Main withdrawal table stores cashout type |
| History.WithdrawToFundingAction | CashoutTypeID | Implicit | Withdrawal action history stores type |
| Billing.TBL_Withdraw2Funding | CashoutTypeID | UDT column | TVP for batch operations |
| Billing.vWithdrawToFunding | CashoutTypeID | View SELECT | Withdrawal view exposes type |
| Billing.FundingDataForWithdraw | CashoutTypeID | View CASE | Conditional logic on type |
| BackOffice.GetCashOutRequests | CashoutTypeID | WHEN 1/2, IN (2,3) | Cashout screen branches by type |
| BackOffice.GetWithdrawRequestsDetails | CashoutTypeID | WHEN 1/2, IN (2,3) | Withdrawal details branches by type |
| BackOffice.GetProcessedWithdrawPCIVersion | CashoutTypeID | LEFT JOIN, CASE | Processed report resolves type name |
| BackOffice.InProcessPaymentsToSendPCIVersion | CashoutTypeID | LEFT JOIN, CASE | In-process report resolves type name |
| BackOffice.GetDepositRefundedCashoutsPCIVersion | CashoutTypeID | WHERE = 2 | Deposit refund report |
| BackOffice.WithdrawToFundingAdd | @CashoutTypeID | Parameter, EXISTS check | Validates type before insert |
| Billing.WithdrawToFundingAdd | @CashoutTypeID | Parameter, EXISTS check | Validates type before insert |
| Billing.WithdrawToFundingProcess | CashoutTypeID | SELECT/INSERT | Processing stores type |
| Billing.GetPayoutProcessData | CashoutTypeID | JOIN, CashoutTypeName | Payout processing shows type |
| Billing.PayoutMetricDataGet | CashoutTypeID | LEFT JOIN | Payout metrics by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutType (table)
  └── stored in Billing.WithdrawToFunding
  └── stored in History.WithdrawToFundingAction
  └── joined by 18+ BackOffice/Billing procedures
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Stores CashoutTypeID per withdrawal |
| History.WithdrawToFundingAction | Table | Action history stores type |
| Billing.vWithdrawToFunding | View | Exposes CashoutTypeID |
| Billing.FundingDataForWithdraw | View | CASE logic on type |
| BackOffice.GetCashOutRequests | Stored Procedure | Branches by type |
| BackOffice.GetDepositRefundedCashoutsPCIVersion | Stored Procedure | Filters type=2 |
| Billing.GetPayoutProcessData | Stored Procedure | JOINs for type name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.CashoutType | CLUSTERED PK | CashoutTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.CashoutType | PRIMARY KEY | Unique cashout type identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all cashout types
```sql
SELECT  CashoutTypeID,
        CashoutTypeName
FROM    Dictionary.CashoutType WITH (NOLOCK)
ORDER BY CashoutTypeID;
```

### 8.2 Count withdrawals by cashout type
```sql
SELECT  dct.CashoutTypeName     AS Type,
        COUNT(*)                AS WithdrawalCount
FROM    Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN    Dictionary.CashoutType dct WITH (NOLOCK)
        ON wtf.CashoutTypeID = dct.CashoutTypeID
GROUP BY dct.CashoutTypeName
ORDER BY WithdrawalCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 18+ BackOffice and Billing procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 18 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutType.sql*
