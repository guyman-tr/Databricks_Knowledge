# BackOffice.GetCryptoTransactions

> Returns crypto transfer (redeem) transactions within a date range with full customer context, instrument metadata, withdrawal linkage, and approval status - the primary crypto withdrawal management grid in BackOffice.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate (request date window); optional @Statuses, @Instruments, @ShowOnlyApproved filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCryptoTransactions` returns the crypto transfer (Redeem) management grid in BackOffice. A "Redeem" in eToro represents a customer's request to withdraw cryptocurrency from their eToro wallet to an external blockchain address - what the UI calls a "transfer". This procedure shows all such transfers in a date range, joined with the associated withdrawal processing record (Billing.Withdraw via WithdrawToFunding) and enriched with instrument, customer, and status details.

**Approved logic**: A transfer is "Approved" (returned as 'Yes') when its RedeemStatusID is between 3 and 8 (inclusive) OR equals 20 (Terminated). These statuses represent states where the transfer has been approved and is in some stage of processing: 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated.

**Cancelled By logic**: Only when RedeemReasonID=10 (the specific "Manager Cancellation" reason) is the cancelling manager's name shown. Other cancellation reasons show NULL.

Created March 2019 by Avraham Lahmi; Customer Level column added April 2019.

---

## 2. Business Logic

### 2.1 STRING_SPLIT Filters

**What**: @Statuses and @Instruments are comma-separated strings parsed at runtime.

**Columns/Parameters Involved**: `@Statuses`, `@Instruments`, `STRING_SPLIT`

**Rules**:
- `@Statuses IS NULL OR RE.RedeemStatusID IN (SELECT * FROM STRING_SPLIT(@Statuses, ','))` - NULL=all statuses.
- `@Instruments IS NULL OR RE.InstrumentID IN (SELECT * FROM STRING_SPLIT(@Instruments, ','))` - NULL=all instruments.
- Requires SQL Server 2016+ for STRING_SPLIT. Results may be unordered within the split.

### 2.2 Approved Status Range

**What**: The "Approved" column classifies whether the transfer has been authorized.

**Columns/Parameters Involved**: `Dictionary.RedeemStatus.RedeemStatusID`

**Rules**:
- WHEN RedeemStatusID IS NULL -> NULL (no status record found - data quality case).
- WHEN RedeemStatusID BETWEEN 3 AND 8 OR = 20 -> 'Yes': Approved(3), ReadyToRedeem(4), PositionClosing(5), PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20).
- All others (1=Pending, 2=Rejected, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New) -> 'No'.
- @ShowOnlyApproved=1 applies the same filter as the WHERE clause using this logic.

### 2.3 Cancelled By (RedeemReasonID=10 Only)

**What**: Manager cancellation name is shown only for manager-initiated cancellations.

**Columns/Parameters Involved**: `Dictionary.RedeemReason.RedeemReasonID`, `BackOffice.Manager.ManagerID` (via RE.ManagerOpsID)

**Rules**:
- `CASE WHEN DRR.RedeemReasonID = 10 THEN CONCAT(BMR.FirstName, ' ', BMR.LastName) ELSE NULL END`.
- RedeemReasonID=10 = Manager cancellation (ops team).
- Other reason IDs (customer cancellation, automatic cancellation, etc.) show NULL.
- Uses RE.ManagerOpsID for the manager lookup (the ops manager who actioned the cancellation).

### 2.4 Net Units Calculation

**What**: Units after eToro fees are deducted.

**Columns/Parameters Involved**: `RE.Units`, `RE.RedeemFee`

**Rules**:
- `(RE.Units - RE.RedeemFee)` AS [Net Units].
- RE.Units = total crypto units in the transfer.
- RE.RedeemFee = eToro's platform fee in units.
- Net Units = what the customer actually receives.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of request date window (inclusive). Filters Billing.Redeem.RequestDate >= @StartDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of request date window (inclusive). Filters RequestDate <= @EndDate. |
| 3 | @Statuses | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated RedeemStatusIDs. NULL=all statuses. STRING_SPLIT parsed. |
| 4 | @Instruments | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated InstrumentIDs. NULL=all crypto instruments. STRING_SPLIT parsed. |
| 5 | @ShowOnlyApproved | BIT | YES | NULL | CODE-BACKED | When 1, filters to approved transfers (RedeemStatusID BETWEEN 3-8 OR =20). NULL or 0=all. |
| 6 | Transfer ID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID - primary key of the crypto transfer record. |
| 7 | Position ID | INT | YES | - | CODE-BACKED | Trading position ID associated with this crypto transfer. From Billing.Redeem.PositionID. |
| 8 | CID | INT | NO | - | CODE-BACKED | Customer Identifier. |
| 9 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Player level name (Dictionary.PlayerLevel.Name via Customer.Customer.PlayerLevelID). |
| 10 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). |
| 11 | Country by Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Registration country (Dictionary.Country.Name via Customer.Customer.CountryID). |
| 12 | Request Time | DATETIME | NO | - | CODE-BACKED | Date/time the crypto transfer was requested. From Billing.Redeem.RequestDate. |
| 13 | Instrument | NVARCHAR | YES | - | CODE-BACKED | Crypto instrument display name (Trade.InstrumentMetaData.InstrumentDisplayName). e.g., "Bitcoin", "Ethereum". |
| 14 | Units | DECIMAL | NO | - | CODE-BACKED | Total crypto units in the transfer (gross, before fees). From Billing.Redeem.Units. |
| 15 | eToro Fees | DECIMAL | YES | - | CODE-BACKED | eToro platform fee in crypto units. From Billing.Redeem.RedeemFee. |
| 16 | $ Invested Amount | DECIMAL | YES | - | CODE-BACKED | USD amount invested/value at time of request. From Billing.Redeem.AmountOnRequest. |
| 17 | Transfer Status | NVARCHAR | YES | - | CODE-BACKED | Redeem status display name. 12 values: Pending(1), Rejected(2), Approved(3), ReadyToRedeem(4), PositionClosing(5), PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20), FailedToCancel(21), TransferNegativeBalance(25), New(100). |
| 18 | Status Reason | NVARCHAR | YES | - | CODE-BACKED | Redeem reason display name (Dictionary.RedeemReason.DisplayName). Why the transfer reached its current status. |
| 19 | Cancelled By | NVARCHAR | YES | - | CODE-BACKED | Manager name who cancelled the transfer (only for RedeemReasonID=10). NULL for all other cancellation reasons. |
| 20 | Approved | VARCHAR | YES | - | CODE-BACKED | 'Yes' if RedeemStatusID BETWEEN 3-8 OR =20; 'No' for other statuses; NULL if status record missing. |
| 21 | Withdraw ID | INT | YES | - | CODE-BACKED | Associated withdrawal ID from Billing.Withdraw (via WithdrawToFunding.WithdrawID). NULL if no withdrawal linked yet. |
| 22 | Withdraw $ amount | MONEY | YES | - | CODE-BACKED | Withdrawal amount in USD. From Billing.Withdraw.Amount. NULL if no linked withdrawal. |
| 23 | Withdraw Status | NVARCHAR | YES | - | CODE-BACKED | Withdrawal cashout status name (Dictionary.CashoutStatus.Name). 17 values. NULL if no linked withdrawal. |
| 24 | Last Modification Time | DATETIME | YES | - | CODE-BACKED | Last modification date of the redeem record. From Billing.Redeem.LastModificationDate. |
| 25 | Blockchain fees | DECIMAL | YES | - | CODE-BACKED | Blockchain network fee charged for the transfer. From Billing.Redeem.BlockchainFee. |
| 26 | Net Units | DECIMAL | YES | - | CODE-BACKED | Units customer receives: RE.Units - RE.RedeemFee (gross units minus eToro platform fee). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | Billing.Redeem | Primary source | Crypto transfer records in request date window. |
| CID | BackOffice.Customer | INNER JOIN | Regulation, for LEFT JOIN to Dictionary.Regulation. |
| CID | Customer.Customer | INNER JOIN | Player level, country. |
| WithdrawToFundingID | Billing.WithdrawToFunding | LEFT JOIN | Links redeem to withdrawal processing. |
| WithdrawID | Billing.Withdraw | LEFT JOIN (via WTF) | Withdrawal amount and status. |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name. |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Crypto instrument display name. |
| RedeemStatusID | Dictionary.RedeemStatus | LEFT JOIN | Transfer status display name. |
| RedeemReasonID | Dictionary.RedeemReason | LEFT JOIN | Status reason display name. |
| CashoutStatusID | Dictionary.CashoutStatus | LEFT JOIN | Withdraw cashout status name. |
| PlayerLevelID | Dictionary.PlayerLevel | LEFT JOIN | Customer level. |
| ManagerOpsID | BackOffice.Manager | LEFT JOIN | Cancelled By manager name. |
| CountryID | Dictionary.Country | LEFT JOIN | Registration country. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice crypto transfer management screen. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransactions (procedure)
├── Billing.Redeem (table) [cross-schema]
├── BackOffice.Customer (table)
├── Customer.Customer (table) [cross-schema]
├── Billing.WithdrawToFunding (table) [cross-schema]
├── Billing.Withdraw (table) [cross-schema]
├── Dictionary.Regulation (table) [cross-schema]
├── Trade.InstrumentMetaData (table) [cross-schema]
├── Dictionary.RedeemStatus (table) [cross-schema]
├── Dictionary.RedeemReason (table) [cross-schema]
├── Dictionary.CashoutStatus (table) [cross-schema]
├── Dictionary.PlayerLevel (table) [cross-schema]
├── BackOffice.Manager (table)
└── Dictionary.Country (table) [cross-schema]
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice crypto transfer management screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. STRING_SPLIT on comma-separated parameters requires SQL Server 2016+ compatibility level 130.

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on all tables. STRING_SPLIT for @Statuses and @Instruments. No explicit ORDER BY - result order depends on query optimizer. The procedure is encapsulated in BEGIN/END but lacks SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Get all crypto transfers for last 7 days
```sql
EXEC BackOffice.GetCryptoTransactions
    @StartDate = DATEADD(DAY,-7,GETUTCDATE()),
    @EndDate = GETUTCDATE();
```

### 8.2 Get only approved Bitcoin and Ethereum transfers
```sql
EXEC BackOffice.GetCryptoTransactions
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-17',
    @Instruments = '100,101',  -- Bitcoin=100, Ethereum=101 (example IDs)
    @ShowOnlyApproved = 1;
```

### 8.3 Get transfers in specific statuses
```sql
EXEC BackOffice.GetCryptoTransactions
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-17',
    @Statuses = '1,2';  -- Pending and Rejected only
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransactions | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransactions.sql*
