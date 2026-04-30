# BackOffice.GetFundingSummaryForCashout

> Returns deposit and cashout aggregates (last date, total amount) for a set of funding methods for a specific customer - used in the cashout flow to display payment method history and enforce cashout-to-deposit rules.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@CID, @FundingIDs TVP) - returns one row per FundingID in the TVP with deposit and cashout aggregates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetFundingSummaryForCashout provides the deposit and cashout history summary for a customer's payment methods, powering the cashout (withdrawal) flow. Given a customer and a list of their FundingIDs, it returns for each funding method: the date of the last deposit, the date of the last cashout, the total amount deposited, and the total amount already cashed out.

This data supports cashout eligibility rules (e.g., "you can only cash out as much as you have deposited via this method"), the customer-facing cashout UI showing payment method history, and BackOffice operations staff reviewing a customer's funding activity before processing a withdrawal.

Created November 2019 by Ran Ovadia with a CID filter to ensure the aggregates are scoped per customer.

---

## 2. Business Logic

### 2.1 TVP-Driven Left Outer Join Aggregation

**What**: The TVP is the driving table; LEFT JOINs ensure every input FundingID appears in the result even if the customer has no deposits or cashouts with it.

**Columns/Parameters Involved**: `@FundingIDs`, `Billing.Deposit`, `Billing.Withdraw`, `Billing.WithdrawToFunding`

**Rules**:
- Every FundingID in `@FundingIDs` appears exactly once in the result (due to GROUP BY Funding.ID from the TVP)
- `Billing.Deposit` LEFT JOIN: `Funding.ID = Deposit.FundingID AND Deposit.CID = @CID AND Deposit.PaymentStatusID = 2`. Only successful (approved) deposits are counted. If no deposits: LastDepositDate=NULL, TotalDepositAmount=NULL.
- `Billing.Withdraw` LEFT JOIN: `Funding.ID = Withdraw.FundingID AND Withdraw.CID = @CID AND Withdraw.Approved = 1`. Only approved withdrawals are counted. If no withdrawals: LastCashoutDate=NULL, TotalCashoutAmount=NULL (or 0 if SUM includes NULL rows).
- `Billing.WithdrawToFunding` LEFT JOIN: `WTF.WithdrawID = Withdraw.WithdrawID AND WTF.CashoutStatusID = 3`. CashoutStatusID=3 = "Processed" (money sent successfully). Only the processed payment leg is included in TotalCashoutAmount. If no processed WTF row: ExchangeRate=NULL -> `Withdraw.Amount / NULL = NULL` -> excluded from SUM.

### 2.2 Cashout Amount Currency Normalization

**What**: Withdrawal amounts are divided by the exchange rate from Billing.WithdrawToFunding to convert to a base currency.

**Columns/Parameters Involved**: `Withdraw.Amount`, `WTF.ExchangeRate`

**Rules**:
- `TotalCashoutAmount = SUM(Withdraw.Amount / WTF.ExchangeRate)` - the ExchangeRate in WithdrawToFunding is the USD-to-payment-currency rate used when processing the cashout. Dividing normalizes the cashout amount back toward the USD base.
- Only WithdrawToFunding rows with CashoutStatusID=3 (Processed) contribute; pending, canceled, or rejected cashouts are excluded because their WTF LEFT JOIN returns NULL ExchangeRate.
- A single Withdraw can have multiple WithdrawToFunding rows (re-attempts, splits); the CashoutStatusID=3 filter ensures only the final successful leg contributes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID. All aggregates are scoped to this customer only - @CID is applied in both LEFT JOIN conditions. Added Nov 2019 (Ran Ovadia) as a filter. |
| 2 | @FundingIDs | BackOffice.IDs READONLY | NO | - | CODE-BACKED | Table-valued parameter of FundingIDs to summarize. Each row provides a FundingID via the IDs UDT's single INT column (ID). Every FundingID in this TVP will appear in the result, even if the customer has no activity for it. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | int | NO | - | CODE-BACKED | Payment method identifier. Aliased from Funding.ID (the TVP column). One row per distinct FundingID in @FundingIDs. |
| R2 | LastDepositDate | datetime | YES | - | VERIFIED | Date of the most recent successful deposit (PaymentStatusID=2) by this customer via this FundingID. NULL if no successful deposits exist. |
| R3 | LastCashoutDate | datetime | YES | - | VERIFIED | Date of the most recent approved withdrawal request by this customer via this FundingID. NULL if no approved withdrawals exist. From Billing.Withdraw.RequestDate. |
| R4 | TotalDepositAmount | money | YES | - | VERIFIED | Sum of all successful deposit amounts (PaymentStatusID=2) by this customer via this FundingID. In the deposit's currency (typically USD). NULL if no successful deposits exist. |
| R5 | TotalCashoutAmount | money | YES | - | VERIFIED | Sum of (Withdraw.Amount / WTF.ExchangeRate) for approved withdrawals with CashoutStatusID=3 (Processed) by this customer via this FundingID. Normalized by exchange rate. NULL if no processed cashouts exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Funding | @FundingIDs TVP | Driving set | One row per FundingID; LEFT JOINs expand with activity |
| Deposit | Billing.Deposit | LEFT OUTER JOIN | Approved deposits (PaymentStatusID=2) for @CID via each FundingID |
| Withdraw | Billing.Withdraw | LEFT OUTER JOIN | Approved withdrawals (Approved=1) for @CID via each FundingID |
| WTF | Billing.WithdrawToFunding | LEFT JOIN | Processed cashout legs (CashoutStatusID=3) linked to each withdrawal |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the cashout/withdrawal flow to populate payment method history and enforce deposit-based cashout limits.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetFundingSummaryForCashout (procedure)
├── Billing.Deposit (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
└── Billing.WithdrawToFunding (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | LEFT JOIN on FundingID + CID + PaymentStatusID=2 for deposit aggregates |
| Billing.Withdraw | Table | LEFT JOIN on FundingID + CID + Approved=1 for cashout aggregates |
| Billing.WithdrawToFunding | Table | LEFT JOIN on WithdrawID + CashoutStatusID=3 for exchange rate normalization |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cashout/withdrawal service | External | READER - retrieves per-funding deposit/cashout summary for cashout eligibility and display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. SET NOCOUNT ON is present. Billing.Deposit has indexes on CID and FundingID; Billing.Withdraw has indexes on CID; Billing.WithdrawToFunding has `IX_BillingWithdrawToFunding_WithdrawID` on (WithdrawID, CashoutStatusID) and `IX_WithdrawToFunding_FundingID_CashoutStatusID` - both support this query's JOIN and filter patterns.

### 7.2 Constraints

N/A for Stored Procedure. The LEFT JOIN chain means: if Withdraw has no matching WTF row with CashoutStatusID=3, that withdrawal contributes to LastCashoutDate but NOT to TotalCashoutAmount. This intentionally excludes canceled and pending cashouts from the total amount.

---

## 8. Sample Queries

### 8.1 Get funding summary for a customer's payment methods
```sql
DECLARE @ids BackOffice.IDs;
INSERT INTO @ids (ID) VALUES (100001), (100002), (100003);
EXEC BackOffice.GetFundingSummaryForCashout
    @CID = 12345,
    @FundingIDs = @ids
-- Returns: FundingID, LastDepositDate, LastCashoutDate, TotalDepositAmount, TotalCashoutAmount
-- One row per FundingID - NULL for amounts if no activity
```

### 8.2 Ad-hoc equivalent for deposit totals only
```sql
SELECT
    d.FundingID,
    MAX(d.PaymentDate) AS LastDepositDate,
    SUM(d.Amount) AS TotalDepositAmount
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2
  AND d.FundingID IN (100001, 100002, 100003)
GROUP BY d.FundingID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created November 2019 by Ran Ovadia with CID filter.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetFundingSummaryForCashout | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetFundingSummaryForCashout.sql*
