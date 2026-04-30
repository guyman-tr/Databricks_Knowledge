# BackOffice.GetCryptoTransactionsWithdrawProcessing

> Returns the withdraw processing (WithdrawToFunding) records associated with crypto transfers, showing the payment depot, processing manager, cashout status, and processed value dates - the crypto withdrawal processing audit trail in BackOffice.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate (redeem request date window); optional @Instruments, @ShowOnlyApproved filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCryptoTransactionsWithdrawProcessing` shows the payment processing side of crypto transfers. While `GetCryptoTransactions` shows the redeem records (customer's transfer request and approval status), this procedure shows the `WithdrawToFunding` records - the actual disbursement processing records that track how the withdrawal was routed to a payment depot, at what rate, by which manager, and with what value date.

In eToro's payment architecture: a customer's crypto transfer (Redeem) generates a withdrawal (Withdraw) which is then processed through one or more `WithdrawToFunding` records - each representing a specific payment processing attempt. This procedure bridges Billing.Redeem to Billing.WithdrawToFunding via Billing.Withdraw, enriching the result with depot name and processing manager.

**Note on Depot JOIN**: `LEFT JOIN Billing.Depot BD ON BD.DepotID = BWTF.DepositID` - this joins Depot on the BWTF.DepositID column, which may appear unusual (joining Depot on DepositID rather than DepotID). This is the as-coded SQL and likely reflects a specific data model relationship where BWTF.DepositID refers to a Depot record in this context.

Created March 2019 by Avraham Lahmi.

---

## 2. Business Logic

### 2.1 Redeem -> WTF Chain

**What**: Navigates from crypto transfer to its payment processing record.

**Columns/Parameters Involved**: `Billing.Redeem.WithdrawToFundingID`, `Billing.WithdrawToFunding.ID`, `Billing.WithdrawToFunding.WithdrawID`

**Rules**:
- INNER JOIN Billing.WithdrawToFunding ON BWTF.ID = RE.WithdrawToFundingID - each redeem is linked to exactly one WTF record.
- INNER JOIN Billing.Withdraw ON BW.WithdrawID = BWTF.WithdrawID - the WTF links to the parent withdrawal.
- BackOffice.Customer INNER JOIN ensures only customers with a BackOffice record are included.

### 2.2 @ShowOnlyApproved Filter (on Withdraw.Approved)

**What**: Filters to only approved withdrawals when requested.

**Columns/Parameters Involved**: `@ShowOnlyApproved`, `Billing.Withdraw.Approved`

**Rules**:
- `@ShowOnlyApproved IS NULL OR @ShowOnlyApproved = 0 OR BW.Approved = 1`.
- Note: Unlike GetCryptoTransactions (which filters on RedeemStatus), this procedure filters on Billing.Withdraw.Approved BIT.

### 2.3 STRING_SPLIT Instrument Filter

**What**: Same comma-separated instrument filter pattern as sibling procedures.

**Columns/Parameters Involved**: `@Instruments`, `Billing.Redeem.InstrumentID`

**Rules**:
- `@Instruments IS NULL OR RE.InstrumentID IN (SELECT * FROM STRING_SPLIT(@Instruments, ','))`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of redeem request date window. Filters Billing.Redeem.RequestDate >= @StartDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of redeem request date window. Filters RequestDate <= @EndDate. |
| 3 | @Instruments | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated InstrumentIDs. NULL=all instruments. STRING_SPLIT parsed. |
| 4 | @ShowOnlyApproved | BIT | YES | NULL | CODE-BACKED | When 1, filters to withdrawals where Billing.Withdraw.Approved=1. NULL or 0=all. |
| 5 | Transfer ID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID - crypto transfer identifier. Links back to GetCryptoTransactions. |
| 6 | Net Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Payment processing amount from Billing.WithdrawToFunding.Amount. Represents the USD value being processed through the depot. |
| 7 | Status | NVARCHAR | YES | - | CODE-BACKED | Withdrawal cashout status (Dictionary.CashoutStatus.Name). 17 values from the Billing.Withdraw.CashoutStatusID. |
| 8 | Request Time | DATETIME | NO | - | CODE-BACKED | Date/time the parent withdrawal was requested. From Billing.Withdraw.RequestDate. |
| 9 | Depot | NVARCHAR | YES | - | CODE-BACKED | Payment depot/processor name. From Billing.Depot.Name via LEFT JOIN on BWTF.DepositID. NULL if no depot record. |
| 10 | Status Modification Date | DATETIME | NO | - | CODE-BACKED | Last modification date of the withdrawal (Billing.Withdraw.ModificationDate). |
| 11 | Processed Value Date | DATETIME | YES | - | CODE-BACKED | The value date when the payment was processed through the depot. From Billing.WithdrawToFunding.ProcessorValueDate. NULL if not yet processed. |
| 12 | Withdraw Processing ID | INT | NO | - | CODE-BACKED | Primary key of the WithdrawToFunding record (BWTF.ID). Unique identifier for this processing attempt. |
| 13 | Processed By | NVARCHAR | YES | - | CODE-BACKED | Full name of the manager who processed this WTF record (BackOffice.Manager.FirstName + ' ' + LastName via BWTF.ManagerID). NULL if processed automatically. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | Billing.Redeem | Primary source (date filter) | Crypto transfer records in request date window. |
| CID | BackOffice.Customer | INNER JOIN | Ensures customer has a BackOffice record. |
| WithdrawToFundingID | Billing.WithdrawToFunding | INNER JOIN | Payment processing record for the redeem. |
| WithdrawID | Billing.Withdraw | INNER JOIN | Parent withdrawal for status and request time. |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name (present in JOIN but not in SELECT). |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Instrument metadata (present in JOIN but not in SELECT). |
| CashoutStatusID | Dictionary.CashoutStatus | LEFT JOIN | Withdrawal status name. |
| DepositID (as DepotID) | Billing.Depot | LEFT JOIN | Depot name via BWTF.DepositID. |
| ManagerID | BackOffice.Manager | LEFT JOIN | Processed By manager name. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice crypto withdraw processing screen. No SQL procedure callers found in repository. Sister procedures: GetCryptoTransactions (customer view) and GetCryptoTransactionsApprovals (approval view).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransactionsWithdrawProcessing (procedure)
├── Billing.Redeem (table) [cross-schema]
├── BackOffice.Customer (table)
├── Billing.WithdrawToFunding (table) [cross-schema]
├── Billing.Withdraw (table) [cross-schema]
├── Dictionary.Regulation (table) [cross-schema - joined, not in SELECT]
├── Trade.InstrumentMetaData (table) [cross-schema - joined, not in SELECT]
├── Dictionary.CashoutStatus (table) [cross-schema]
├── Billing.Depot (table) [cross-schema]
└── BackOffice.Manager (table)
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice crypto withdraw processing screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on all tables. STRING_SPLIT for @Instruments. No ORDER BY. Encapsulated in BEGIN/END. Dictionary.Regulation (DR) and Trade.InstrumentMetaData (IMD) are LEFT JOINed but neither's columns appear in the final SELECT - they may have been used in an earlier version or are present for potential future filtering.

---

## 8. Sample Queries

### 8.1 Get crypto transfer processing records for last 7 days
```sql
EXEC BackOffice.GetCryptoTransactionsWithdrawProcessing
    @StartDate = DATEADD(DAY,-7,GETUTCDATE()),
    @EndDate = GETUTCDATE();
```

### 8.2 Get only approved processing records for specific instruments
```sql
EXEC BackOffice.GetCryptoTransactionsWithdrawProcessing
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-17',
    @Instruments = '100,101',
    @ShowOnlyApproved = 1;
```

### 8.3 Cross-reference with GetCryptoTransactions
```sql
-- Get the transfer overview first:
EXEC BackOffice.GetCryptoTransactions @StartDate='2026-03-01', @EndDate='2026-03-17';
-- Then get processing details for a specific transfer:
SELECT * FROM Billing.WithdrawToFunding BWTF
INNER JOIN Billing.Redeem RE ON RE.WithdrawToFundingID = BWTF.ID
WHERE RE.RedeemID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransactionsWithdrawProcessing | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransactionsWithdrawProcessing.sql*
