# Dictionary.CashoutReason

> Lookup table defining the 19 reasons for initiating a cashout (withdrawal) — from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 19 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CashoutReason explains *why* a withdrawal was initiated. Every withdrawal recorded in Billing.Withdraw carries a CashoutReasonID that classifies the business context: was it a standard user request (16), a Popular Investor payment (14), an affiliate payment (15), a risk refund (3), an account closure (12, 19), or something else?

This classification is critical for financial reporting, compliance auditing, and operational analytics. Different reasons trigger different processing logic — for example, Billing.WithdrawToFundingProcess filters by `CashoutReasonID IN (12, 14, 15)` to identify forced account closures and partner/PI payments that require special handling. The default for user-initiated withdrawals is CashoutReasonID=16 ("Requested by User"), explicitly set in Billing.WithdrawRequestAdd and Billing.WithdrawalService_WithdrawRequestAdd.

The table is joined extensively in BackOffice withdrawal screens (GetWithdrawRequests, GetCashOutRequests_Main, InProcessPaymentsToSendPCIVersion) to display the reason alongside withdrawal details, and in Trade.TAPI procedures for customer-facing credit history.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The major categories of withdrawal reasons.

**Columns/Parameters Involved**: `CashoutReasonID`, `Name`

**Rules**:
- **User-Initiated (16)**: Standard withdrawal requested by the customer. Default value in WithdrawRequestAdd.
- **Partner Payments (14, 15)**: Automated payments to Popular Investors (PI Payment) and Affiliates (Affiliate Payment). Special processing in WithdrawToFundingProcess.
- **Risk/Compliance (3, 7, 8)**: Risk refunds, 3rd party payment returns, bonus abuse adjustments. Driven by compliance/risk teams.
- **Account Closures (6, 12, 17, 19)**: Forced withdrawals when accounts are blocked, foreclosed, or failed verification. CashoutReasonID=12 ("Foreclose account") and 19 ("ForClose(GAP)") trigger special handling in processing.
- **Adjustments (1, 4, 5)**: Financial corrections — general adjustments, negative balance fixes, withdrawal fee adjustments.
- **Technical/Operational (9, 10, 11, 13)**: Returned withdrawals, technical issues, underage account closures, test transactions.
- **Crypto (18)**: Withdrawal via crypto wallet transfer — dedicated reason for blockchain-based fund movements.

**Diagram**:
```
Cashout Reason Categories:

  User-Initiated ──► Requested by User (16)
  Partner Payments ──► PI Payment (14), Affiliate Payment (15)
  Risk/Compliance ──► Risk Refund (3), 3rd Party (7), Bonus Abuse (8)
  Account Closure ──► Foreclose (12, 19), Block (6), Failed Verification (17)
  Adjustments ──► Adjustment (1), Negative Balance (4), Fee Adj (5)
  Special ──► Crypto Transfer (18), Returned (9), Test (13)
```

### 2.2 Special Processing by Reason

**What**: How specific CashoutReasonIDs trigger different processing logic.

**Columns/Parameters Involved**: `CashoutReasonID`

**Rules**:
- **Billing.WithdrawToFundingProcess**: Checks `CashoutReasonID IN (12, 14, 15)` — foreclose, PI payment, and affiliate payment get special routing
- **Billing.WithdrawalService_EstimateBonusDeduction**: Uses CashoutReasonID to determine bonus deduction eligibility
- **Billing.WithdrawAndWithdrawToFundingAdd**: Defaults @CashoutReasonID=18 for crypto wallet transfers
- **Trade.TAPI_GetCreditHistoryByCID**: Uses `ISNULL(bw.CashoutReasonID, 0)` — defaults to 0 when no reason set

---

## 3. Data Overview

| CashoutReasonID | Name | Meaning |
|---|---|---|
| 1 | Adjustment | General financial adjustment — manual correction to customer balance. |
| 2 | Partners withdraw | Partner account withdrawal — non-customer partner fund extraction. |
| 3 | Risk Refund | Refund initiated by risk/compliance team — returning funds to flagged customer. |
| 4 | Negative Balance adjustment | Correction for negative account balance — restoring customer to zero. |
| 5 | Withdraw fees adjustment | Adjustment to previously charged withdrawal fees. |
| 6 | Block account – Not communicative | Forced withdrawal when blocking unresponsive account. |
| 7 | 3rd party payment | Return of third-party funds — payment didn't originate from account holder. |
| 8 | Bonus abuse adjustment | Clawback of abused bonus/promotional credits. |
| 9 | Returned withdraw | Previously sent withdrawal was returned by recipient bank/PSP. |
| 10 | Technical issue – Customer side | Withdrawal due to customer-side technical problem requiring resolution. |
| 11 | Underage | Account closure withdrawal — customer found to be under minimum age. |
| 12 | Foreclose account | Forced withdrawal during account foreclosure/liquidation. Special processing in WithdrawToFundingProcess. |
| 13 | Test | Test transaction — internal testing only. |
| 14 | PI Payment | Popular Investor program payment — automated compensation to copy-trading leaders. Special processing in WithdrawToFundingProcess. |
| 15 | Affiliate Payment | Affiliate partner commission payment. Special processing in WithdrawToFundingProcess. |
| 16 | Requested by User | Standard customer-initiated withdrawal. Default reason (set explicitly in WithdrawRequestAdd). Most common cashout reason. |
| 17 | Failed Verification | Withdrawal/return of funds when customer fails identity verification. |
| 18 | Transfered by CryptoWallet | Withdrawal via cryptocurrency wallet transfer. Default for crypto transfers in WithdrawAndWithdrawToFundingAdd. |
| 19 | ForClose(GAP) | Forced withdrawal during account foreclosure with GAP (discrepancy) resolution. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutReasonID | int | NO | - | VERIFIED | Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdraw | CashoutReasonID | Implicit | Main withdrawal table stores reason |
| History.WithdrawAction | CashoutReasonID | Implicit | Withdrawal action history stores reason |
| Billing.TBL_Withdraw | CashoutReasonID | UDT column | TVP for batch withdrawal operations |
| BackOffice.GetWithdrawRequests | CashoutReasonID | LEFT JOIN | Withdrawal screen shows reason name |
| BackOffice.GetCashOutRequests_Main | CashoutReasonID | LEFT JOIN | Main cashout screen shows reason |
| BackOffice.InProcessPaymentsToSendPCIVersion | CashoutReasonID | LEFT JOIN | In-process payment report |
| BackOffice.GetProcessedWithdrawPCIVersion | CashoutReasonID | LEFT JOIN | Processed withdrawal report |
| Billing.WithdrawRequestAdd | @CashoutReasonID | Parameter (default 16) | Sets reason at withdrawal creation |
| Billing.WithdrawToFundingProcess | CashoutReasonID | WHERE IN (12,14,15) | Special processing for closures/payments |
| Billing.WithdrawAndWithdrawToFundingAdd | @CashoutReasonID | Parameter (default 18) | Crypto wallet transfers |
| Customer.SetBalanceCashOut | @CashoutReasonID | Parameter | Balance update with reason |
| Trade.TAPI_GetCreditHistoryByCID | CashoutReasonID | SELECT ISNULL | Customer credit history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutReason (table)
  └── stored in Billing.Withdraw, History.WithdrawAction
  └── joined by 22+ procedures across BackOffice, Billing, Trade, SalesForce
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Stores CashoutReasonID per withdrawal |
| History.WithdrawAction | Table | Action history stores reason |
| BackOffice.GetWithdrawRequests | Stored Procedure | JOINs for reason name |
| Billing.WithdrawRequestAdd | Stored Procedure | Default reason = 16 |
| Billing.WithdrawToFundingProcess | Stored Procedure | Special handling for 12, 14, 15 |
| Trade.TAPI_GetCreditHistoryByCID | Stored Procedure | Customer credit history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.CashoutReason | CLUSTERED PK | CashoutReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.CashoutReason | PRIMARY KEY | Unique reason identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all cashout reasons
```sql
SELECT  CashoutReasonID,
        Name
FROM    Dictionary.CashoutReason WITH (NOLOCK)
ORDER BY CashoutReasonID;
```

### 8.2 Count withdrawals by reason
```sql
SELECT  dcr.Name            AS CashoutReason,
        COUNT(*)            AS WithdrawalCount
FROM    Billing.Withdraw bw WITH (NOLOCK)
JOIN    Dictionary.CashoutReason dcr WITH (NOLOCK)
        ON bw.CashoutReasonID = dcr.CashoutReasonID
GROUP BY dcr.Name
ORDER BY WithdrawalCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 22+ procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 22 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutReason.sql*
