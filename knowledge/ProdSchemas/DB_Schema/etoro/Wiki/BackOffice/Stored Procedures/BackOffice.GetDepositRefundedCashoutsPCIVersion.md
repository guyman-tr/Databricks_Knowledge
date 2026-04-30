# BackOffice.GetDepositRefundedCashoutsPCIVersion

> Reporting query returning all deposit-refund cashout transactions within a date range, with full payment method details for each refund - used by BackOffice for financial reconciliation and cashout audit.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns rows from Billing.WithdrawToFunding where CashoutTypeID=2 (CashoutRefund) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDepositRefundedCashoutsPCIVersion is a financial reporting query that returns all "CashoutRefund" transactions (CashoutTypeID=2) within a specified date range. A CashoutRefund is when a customer's previously-made deposit is refunded back to them via a cashout - this happens when deposits are reversed, disputed, or subject to regulatory refund requirements. The "PCI Version" designation means payment card details are handled in a PCI-compliant manner: actual card numbers are not exposed, instead payment details are reconstructed from encrypted/tokenized FundingData based on funding type.

The procedure exists as an audit and reconciliation tool for the BackOffice financial team. By querying all deposit refunds in a period, the team can verify that refunds were processed correctly, match processor confirmations, and produce reports for compliance or finance. The optional @CID and @DepositID parameters allow filtering to a single customer or specific deposit when investigating individual cases.

The procedure has been enhanced over time to support additional payment methods: created 2019 (Avraham), refactored 2020 (Adi - payment details moved to a view), POLi added 2021 (MIMOPS-3783), Payoneer added June 2022 (MIMOPSA-6820 / MIMOPSA-5920).

---

## 2. Business Logic

### 2.1 CashoutRefund Scope (CashoutTypeID=2)

**What**: The procedure is specifically scoped to deposit refunds, not all cashouts.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.CashoutTypeID`

**Rules**:
- `CashoutTypeID=1` = NewMoneyCashout (standard withdrawal of trading profits) - NOT included
- `CashoutTypeID=2` = CashoutRefund (refunding a prior deposit) - ONLY this type is returned
- `CashoutTypeID=3` = RiskRefund (risk-initiated refund) - NOT included
- The "refunded cashouts" are linked to their original deposit via `BWTF.DepositID` in `Billing.WithdrawToFunding`

### 2.2 PCI-Compliant Payment Detail Extraction

**What**: Payment details are reconstructed per funding type from stored XML data without exposing raw card numbers.

**Columns/Parameters Involved**: `Billing.FundingPaymentDetailsForDeposit.FundingTypeID`, `PaymentData` (XML), `FundingData`

**Rules**:
- `FundingTypeID=2` (Wire Transfer): Extracts IBAN from deposit PaymentData XML: `PaymentData.value('Deposit[1]/IBANCodeAsString[1]',...)`
- `FundingTypeID=33`: Extracts CardID + FundingDetails + GCID from PaymentData XML
- `FundingTypeID=34`: Extracts FundingDetails + Bank Name + Account Holder Name from PaymentData
- `FundingTypeID=37` (POLi, added MIMOPS-3783): Extracts Account Sort Code, First/Last Name, Account Number, Bank Name
- `FundingTypeID=39` (Payoneer, added MIMOPSA-6820): Extracts PayId, Email, First/Middle/Last Name
- All others: Uses `Billing.FundingPaymentDetailsForDeposit.FundingDetails` as-is
- This pattern ensures the report shows meaningful payment identifiers without exposing PCI-sensitive card numbers

### 2.3 Optional Per-Customer and Per-Deposit Filtering

**What**: The procedure can be scoped to a specific customer or deposit for investigation purposes.

**Columns/Parameters Involved**: `@CID`, `@DepositID`

**Rules**:
- Default `@CID=0` or NULL: no CID filter - returns all cashout refunds in the date range
- Non-zero @CID: `AND BWIT.CID = @CID` - returns only refunds for that customer
- Default `@DepositID=0` or NULL: no deposit filter
- Non-zero @DepositID: `AND BWTF.DepositID = @DepositID` - returns only the refund(s) for that deposit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date range for `Billing.Withdraw.RequestDate`. Inclusive (`BETWEEN`). Filters cashout requests that were initiated on or after this date. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date range for `Billing.Withdraw.RequestDate`. Inclusive (`BETWEEN`). |
| 3 | @CID | INTEGER | NO | 0 | CODE-BACKED | Optional customer filter. Default 0 = no filter (all customers). Non-zero = scopes to one customer. Allows NULL (treated same as 0). |
| 4 | @DepositID | INTEGER | NO | 0 | CODE-BACKED | Optional deposit filter. Default 0 = no filter. Non-zero = returns only refunds related to this specific deposit. Allows NULL (treated same as 0). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | NO | - | CODE-BACKED | Customer account ID of the refund recipient. From Billing.Withdraw.CID. |
| R2 | Status | varchar | YES | - | CODE-BACKED | Human-readable cashout status name. From Dictionary.CashoutStatus.Name via BWTF.CashoutStatusID. |
| R3 | DepositID | int | YES | - | CODE-BACKED | The original deposit that is being refunded. From Billing.WithdrawToFunding.DepositID. Links the refund back to the source deposit. |
| R4 | Process Time | datetime | YES | - | CODE-BACKED | When the cashout refund was processed. From Billing.WithdrawToFunding.ModificationDate. |
| R5 | Request Time | datetime | NO | - | CODE-BACKED | When the customer or system requested the cashout refund. From Billing.Withdraw.RequestDate. Used as the date range filter column. |
| R6 | Net Cashout $ Amount | decimal(16,2) | NO | - | CODE-BACKED | The net amount refunded, cast to 2 decimal places. From Billing.WithdrawToFunding.Amount (ISNULL -> 0 if NULL). |
| R7 | Funding Method | nvarchar | YES | - | CODE-BACKED | Human-readable name of the payment method type. From Dictionary.FundingType.Name via Billing.FundingPaymentDetailsForDeposit.FundingTypeID. E.g., "Credit Card", "Wire Transfer", "PayPal". |
| R8 | Payment Detail | nvarchar | YES | - | CODE-BACKED | PCI-compliant payment identifier. Reconstructed per FundingTypeID from encrypted FundingData/PaymentData XML. Shows IBAN for wire, PayId+name for Payoneer, sort code+account for POLi, or FundingDetails for other types. |
| R9 | Funding ID | int | NO | - | CODE-BACKED | The FundingID of the payment method used for the refund. From Billing.WithdrawToFunding.FundingID. |
| R10 | Withdraw Processing ID | int | NO | - | CODE-BACKED | Internal processing record ID. From Billing.WithdrawToFunding.ID. |
| R11 | WithdrawID | int | NO | - | CODE-BACKED | The withdrawal request ID. From Billing.Withdraw.WithdrawID. Primary key of the withdrawal. |
| R12 | Customer Status | nvarchar | YES | - | CODE-BACKED | Customer's current account status name (e.g., "Real", "Blocked"). From Dictionary.PlayerStatus via Customer.Customer.PlayerStatusID. LTRIM/RTRIM applied. |
| R13 | Customer Level | nvarchar | YES | - | CODE-BACKED | Customer's player/trading level name. From Dictionary.PlayerLevel via Customer.Customer.PlayerLevelID. LTRIM/RTRIM applied. |
| R14 | Processed By | nvarchar | YES | - | CODE-BACKED | Full name of the BackOffice manager who processed the refund. `FirstName + ' ' + LastName` from BackOffice.Manager via BWTF.ManagerID. |
| R15 | Currency | nvarchar | YES | - | CODE-BACKED | Currency abbreviation (e.g., "USD", "EUR") for the refund amount. From Dictionary.Currency.Abbreviation via BWTF.ProcessCurrencyID. |
| R16 | Brand | nvarchar | YES | - | CODE-BACKED | Card brand name (e.g., "Visa", "MasterCard") for credit card refunds. From Dictionary.CardType.Name via FundingData XML CardTypeIDAsInteger. NULL for non-card refunds. |
| R17 | Depot | nvarchar | YES | - | CODE-BACKED | Payment depot/processor name. From Billing.Depot.Name via BWTF.DepotID. NULL if no depot linked. |
| R18 | Verification Code | - | YES | - | CODE-BACKED | Transaction verification code from the payment processor. From Billing.WithdrawToFunding.VerificationCode. |
| R19 | Processor Value Date | datetime | YES | - | CODE-BACKED | The value date assigned by the payment processor. From Billing.WithdrawToFunding.ProcessorValueDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BWTF | Billing.WithdrawToFunding | SELECT (main table) | Deposit-refund cashout records; filtered to CashoutTypeID=2 |
| BWIT | Billing.Withdraw | JOIN | Withdrawal request details including CID and RequestDate |
| BLDP | Billing.Depot | LEFT JOIN | Payment processor/depot name |
| BFUN | Billing.FundingPaymentDetailsForDeposit | JOIN | Funding type and PCI-safe payment details |
| BDEP | Billing.Deposit | LEFT JOIN | Source deposit linked to the refund; used for XML PaymentData extraction |
| BMNG | BackOffice.Manager | JOIN | Agent who processed the refund |
| CCST | Customer.Customer | JOIN | Customer status and player level |
| DCCS | Dictionary.CashoutStatus | LEFT JOIN | Human-readable cashout status |
| DFUT | Dictionary.FundingType | JOIN | Funding method name |
| DCUR | Dictionary.Currency | JOIN | Currency of the refund |
| DPLV | Dictionary.PlayerLevel | JOIN | Customer level name |
| DSTT | Dictionary.PlayerStatus | JOIN | Customer account status name |
| DCTY | Dictionary.CardType | LEFT JOIN | Card brand for credit card refunds |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This is a reporting/audit procedure called from BackOffice UI or reporting tools. No stored procedure callers found within BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDepositRefundedCashoutsPCIVersion (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Depot (table)
├── Billing.FundingPaymentDetailsForDeposit (view - cross-schema)
├── Billing.Deposit (table)
├── BackOffice.Manager (table)
├── Customer.Customer (table - cross-schema)
├── Dictionary.CashoutStatus (table)
├── Dictionary.FundingType (table)
├── Dictionary.Currency (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.PlayerStatus (table)
└── Dictionary.CardType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Main data source - CashoutRefund transactions |
| Billing.Withdraw | Table | Withdrawal request details and CID |
| Billing.Depot | Table | Payment depot name |
| Billing.FundingPaymentDetailsForDeposit | View | PCI-safe funding details and FundingTypeID |
| Billing.Deposit | Table | Source deposit; XML PaymentData for PCI-compliant payment detail extraction |
| BackOffice.Manager | Table | Agent name for Processed By column |
| Customer.Customer | Table | Customer status and level |
| Dictionary.CashoutStatus | Table | Status name lookup |
| Dictionary.FundingType | Table | Funding method name |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.PlayerLevel | Table | Player level name |
| Dictionary.PlayerStatus | Table | Player status name |
| Dictionary.CardType | Table | Card brand name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (cashout refund report) | External | READER - audit and reconciliation of deposit refunds |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: Uses `WITH (NOLOCK)` on all tables for non-blocking reads. Date range filter is on `Billing.Withdraw.RequestDate` (not processing date), so the report period reflects when refunds were requested, not when they were processed.

---

## 8. Sample Queries

### 8.1 Get all deposit refunds for Q1 2026
```sql
EXEC BackOffice.GetDepositRefundedCashoutsPCIVersion
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31'
```

### 8.2 Get all deposit refunds for a specific customer
```sql
EXEC BackOffice.GetDepositRefundedCashoutsPCIVersion
    @StartDate = '2025-01-01',
    @EndDate = '2026-12-31',
    @CID = 12345
```

### 8.3 Investigate refund for a specific deposit
```sql
EXEC BackOffice.GetDepositRefundedCashoutsPCIVersion
    @StartDate = '2020-01-01',
    @EndDate = '2026-12-31',
    @DepositID = 55555
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-6820](https://etoro-jira.atlassian.net/browse/MIMOPSA-6820) | Jira | Added Payoneer (FundingTypeID=39) payment detail extraction in Jun 2022 as part of Payoneer Payout Story (MIMOPSA-5920) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDepositRefundedCashoutsPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDepositRefundedCashoutsPCIVersion.sql*
