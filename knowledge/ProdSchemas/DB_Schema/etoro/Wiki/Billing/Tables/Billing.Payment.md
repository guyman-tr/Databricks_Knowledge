# Billing.Payment

> Legacy deposit transaction ledger (2007-2011); the predecessor to `Billing.Deposit`. All 388,522 records have PaymentStatusID=27 (MigratedToDepositTable) and the last write was January 2011. Retained as a frozen historical archive for pre-migration deposit lookup.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PaymentID (PRIMARY KEY NONCLUSTERED, IDENTITY(1,1), NOT FOR REPLICATION) |
| **Row Count** | ~388,522 rows (frozen - no new rows since 2011-01-16) |
| **Partition** | No - filegroup MAIN; heap table (NONCLUSTERED PK) |
| **Indexes** | 1 NONCLUSTERED PK; 9 NC; total 10 |

---

## 1. Business Meaning

`Billing.Payment` was eToro's original deposit transaction ledger, active from approximately August 2007 through January 2011. It recorded every deposit attempt (credit card, PayPal, wire transfer, Western Union, Neteller, MoneyBookers) during the early history of the platform. The table is structurally similar to `Billing.Deposit` but simpler: no XML PaymentData column, no IsFTD flag, no regulatory routing fields, and no depot-level routing - it used the earlier `Billing.Terminal` configuration model instead.

Around 2010-2011, all data was migrated from this table into `Billing.Deposit` (PaymentStatusID=27 = MigratedToDepositTable). After migration, the table was frozen - no new rows were written. The table exists today purely as a historical archive. All payment-specific child records (CreditCardToPayment, NetellerToPayment, PayPalToPayment, RiskManagementCheck) that reference Payment records also correspond to this pre-2011 era.

Current procedures such as `CheckFundingTypeLimit`, `CheckMemberLimit`, and `GetCustomerPaymentHistory` still UNION against this table alongside `Billing.Deposit` to ensure complete transaction history for customers whose first deposits predate the migration. Without this table, historical deposit counts and fraud velocity checks for pre-2011 customers would be incomplete.

---

## 2. Business Logic

### 2.1 Migration Status - All Records Fully Migrated

**What**: Every record in this table was migrated to `Billing.Deposit` during the 2010-2011 payment system consolidation.

**Columns Involved**: `PaymentStatusID`, `PaymentID`

**Rules**:
- All 388,522 rows have `PaymentStatusID=27` (MigratedToDepositTable) - this is the only status value present
- No new rows have been written since 2011-01-16 (table is effectively read-only)
- Migration mapped each `PaymentID` to a new `DepositID` in `Billing.Deposit`
- Legacy queries checking deposit history must UNION `Billing.Payment` with `Billing.Deposit` to cover the full customer history
- The `OldPaymentID` column in `Billing.Deposit` retains the reference back to this table for migrated records

### 2.2 Amount Storage in Cents (Integer)

**What**: Unlike `Billing.Deposit` (MONEY type), amounts in this table are stored as integers in the smallest currency unit (cents, pence, etc.).

**Columns Involved**: `Amount`, `TotalFee`, `DirectAcceptFee`

**Rules**:
- `Amount` in INT: value of 100000 = $1,000.00 USD; 26000 GBP = £260.00; 5000 = $50.00
- `TotalFee` and `DirectAcceptFee` follow the same cent-integer convention; both default to 0 and are 0 for all migrated records
- This is consistent with `Billing.Terminal.ProcessedAmount` which also stores in smallest unit integers
- `ExchangeRate` is a dtPrice (decimal) - same as Billing.Deposit

### 2.3 Terminal-Based Routing vs. Depot-Based Routing

**What**: This table uses `TerminalID` for routing, while the modern `Billing.Deposit` uses `DepotID`. The Terminal model included the currency dimension inline, while the Depot model separates currency via `Billing.DepotToCurrency`.

**Columns Involved**: `TerminalID`, `FundingTypeID`, `PaymentTypeID`

**Rules**:
- `TerminalID` FK to `Billing.Terminal` - the (Protocol, PaymentType, Currency, FundingType) routing configuration
- `FundingTypeID` is redundant with what Terminal encodes but stored explicitly for direct query performance
- `PaymentTypeID` is 1=Deposit for all 388,522 records (cashout records were in a separate system)
- Fund type distribution: 1=CreditCard (63%), 3=PayPal (28%), 2=Wire (5%), 5=WesternUnion (2%), 6=Neteller (1%), 7=MoneyBookers (<1%)

---

## 3. Data Overview

| PaymentID | CID | Amount | CurrencyID | FundingTypeID | Meaning |
|-----------|-----|--------|-----------|--------------|---------|
| 389343 | 678138 | 100000 (cents) | 1 (USD) | 1 (CC) | $1,000 credit card deposit, migrated to Billing.Deposit. Status=27. TerminalID=45. |
| 389341 | 1127900 | 26000 (pence) | 3 (GBP) | 3 (PayPal) | GBP 260 PayPal deposit via TerminalID=10 (PayPal Express GBP). ExchangeRate=1.5623 USD/GBP. |
| 389340 | 1130609 | 5000 (cents) | 1 (USD) | 3 (PayPal) | $50 PayPal deposit via TerminalID=2 (PayPal Express Checkout USD). |
| ~246K rows | - | varies | 1 (USD) | 1 (CC) | Credit card deposits 2007-2011; 63% of all historical payment records. All migrated. |
| ~110K rows | - | varies | varies | 3 (PayPal) | PayPal deposits 2007-2011; 28% of historical payment records. All migrated. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. NONCLUSTERED - table is a heap (data pages not sorted by PaymentID). NOT FOR REPLICATION. Range 301 to 389,343. References back to this ID are stored in Billing.Deposit.OldPaymentID for migrated records. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | Deposit currency. FK to Dictionary.Currency (FK_DCUR_BPAY). Indexed (BPAM_CURRENCY). Same meaning as Billing.Deposit.CurrencyID. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.CustomerStatic (FK_CCST_BPAY). Identifies the depositing customer. Indexed (BPAM_CUSTOMER). |
| 4 | PaymentStatusID | int | NO | - | CODE-BACKED | Payment status. FK to Dictionary.PaymentStatus (FK_DPMS_BPAY). Value 27=MigratedToDepositTable for all 388,522 rows - the migration process set this as a "soft delete" marker. No other status values exist in live data. Indexed (BPAM_PAYMENTSTATUS). |
| 5 | PaymentTypeID | int | NO | - | CODE-BACKED | Transaction direction. FK to Dictionary.PaymentType (FK_DPMT_BPAY). Value 1=Deposit for all 388,522 rows. Schema supports 2=Cashout and 3=Refund but these were never populated. Indexed (BPAM_PAYMENTTYPE). |
| 6 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. References Dictionary.FundingType implicitly. Distribution: 1=CreditCard (63%), 3=PayPal (28%), 2=Wire (5%), 5=WesternUnion (2%), 6=Neteller (1%), 7=MoneyBookers (<1%). Redundant with Terminal.FundingTypeID but stored for direct access. Indexed (BPAM_FUNDINGTYPE). |
| 7 | TerminalID | int | NO | - | CODE-BACKED | Payment terminal configuration used. FK to Billing.Terminal (FK_BTER_BPAY). The Terminal encodes Protocol + PaymentType + Currency + FundingType routing. Predecessor to the DepotID routing model used in Billing.Deposit. Indexed (BPAM_TERMINAL). See Billing.Terminal for terminal definitions. |
| 8 | ManagerID | int | YES | NULL | CODE-BACKED | Operations manager who processed the payment. FK to BackOffice.Manager (FK_BMNG_BPAY). NULL for system-processed or automated deposits. Indexed (BPAM_MANAGER). |
| 9 | Amount | int | NO | - | CODE-BACKED | Deposit amount in smallest currency unit (cents, pence, etc.). Unlike Billing.Deposit.Amount (MONEY), this is a raw integer: 100000=USD$1000, 5000=USD$50, 26000=GBP£260. Divide by 100 for human-readable amount. |
| 10 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Exchange rate from deposit currency to USD. Same semantic as Billing.Deposit.ExchangeRate. NULL for USD deposits (ExchangeRate=1.0 implied). |
| 11 | TotalFee | int | NO | 0 | CODE-BACKED | Total fee charged for this payment, in smallest currency unit (cents). Default 0; value is 0 for all migrated records. |
| 12 | DirectAcceptFee | int | NO | 0 | CODE-BACKED | Direct acceptance fee (acquirer fee component) charged to the customer, in smallest currency unit. Default 0; value is 0 for all migrated records. Represents a sub-component of TotalFee. |
| 13 | PaymentDate | datetime | NO | - | CODE-BACKED | UTC timestamp when this payment was submitted. Range: 2007-08-27 to 2011-01-16. |
| 14 | ModificationDate | datetime | NO | getdate() | CODE-BACKED | Timestamp of last modification. Default to current date (local time, note: not UTC unlike Billing.Deposit which uses GETUTCDATE()). |
| 15 | Approved | bit | YES | NULL | CODE-BACKED | Legacy approval flag. NULL for all migrated records - superseded by PaymentStatusID. Same legacy pattern as Billing.Deposit.Approved. |
| 16 | TransactionID | char(6) | YES | NULL | CODE-BACKED | Short internal transaction identifier, unique per customer (UNIQUE index BPAM_TRANSACTION on CID+TransactionID). Same generation pattern as Billing.Deposit.TransactionID (6-char hex from GUID). |
| 17 | IPAddress | numeric(18, 0) | YES | NULL | CODE-BACKED | Customer IP address at deposit time, stored as numeric integer. Same encoding as Billing.Deposit.IPAddress. |
| 18 | Commission | money | NO | 0 | CODE-BACKED | Commission charged on this payment. Default 0; value is 0 for all migrated records. |
| 19 | ClearingHouseEffectiveDate | datetime | YES | NULL | CODE-BACKED | Settlement value date from the clearing house. Relevant for wire/offline deposits. NULL for instant payment methods. Same semantic as Billing.Deposit.ClearingHouseEffectiveDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_BPAY) | Customer who made this payment |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BPAY) | Deposit currency |
| PaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPMS_BPAY) | Payment state (all=27=MigratedToDepositTable) |
| PaymentTypeID | Dictionary.PaymentType | FK (FK_DPMT_BPAY) | Transaction direction (all=1=Deposit) |
| TerminalID | Billing.Terminal | FK (FK_BTER_BPAY) | Routing terminal configuration |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_BPAY) | Processing manager |
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreditCardToPayment | PaymentID | FK | Credit card details for credit card deposits in this legacy table |
| Billing.NetellerToPayment | PaymentID | FK | Neteller account details for Neteller deposits |
| Billing.PayPalToPayment | PaymentID | FK | PayPal details for PayPal deposits |
| Billing.RiskManagementCheck | PaymentID | FK | Risk check results for deposits in this table |
| Billing.Deposit | OldPaymentID | Reference | Migrated deposits reference their source PaymentID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Payment (table)
  - FK targets only (no code-level dependencies):
    Customer.CustomerStatic (table)
    Billing.Terminal (table)
    Dictionary.Currency (table)
    Dictionary.PaymentStatus (table)
    Dictionary.PaymentType (table)
    BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID |
| Billing.Terminal | Table | FK on TerminalID |
| Dictionary.Currency | Table | FK on CurrencyID |
| Dictionary.PaymentStatus | Table | FK on PaymentStatusID |
| Dictionary.PaymentType | Table | FK on PaymentTypeID |
| BackOffice.Manager | Table | FK on ManagerID |
| dbo.dtPrice | User Defined Type | Type for ExchangeRate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardToPayment | Table | FK on PaymentID - CC details for legacy deposits |
| Billing.NetellerToPayment | Table | FK on PaymentID - Neteller details for legacy deposits |
| Billing.PayPalToPayment | Table | FK on PaymentID - PayPal details for legacy deposits |
| Billing.RiskManagementCheck | Table | FK on PaymentID - risk check results |
| Billing.CheckFundingTypeLimit | Procedure | Reader - UNIONs against Payment for historical limit checks |
| Billing.CheckMemberLimit | Procedure | Reader - UNIONs against Payment for historical member limits |
| Billing.GetCustomerPaymentHistory | Procedure | Reader - returns combined Payment + Deposit history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BPAM | NC PK | PaymentID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BPAM_CURRENCY | NC | CurrencyID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_CUSTOMER | NC | CID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_FUNDINGTYPE | NC | FundingTypeID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_MANAGER | NC | ManagerID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_PAYMENTSTATUS | NC | PaymentStatusID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_PAYMENTTYPE | NC | PaymentTypeID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_TERMINAL | NC | TerminalID ASC | - | - | Active; FILLFACTOR=90 |
| BPAM_TRANSACTION | UNIQUE NC | CID ASC, TransactionID ASC | - | - | Active; FILLFACTOR=90 |
| IX_PayStat_PayDate_Incl | NC | PaymentStatusID ASC, PaymentDate ASC | Amount, ExchangeRate, PaymentID | - | Active; FILLFACTOR=90 |
| missing_index_44_43 | NC | PaymentStatusID ASC | CID, Amount, ExchangeRate | - | Active (auto-generated name - DBA optimization suggestion applied directly) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPAM | PRIMARY KEY NONCLUSTERED | One row per PaymentID |
| BPAM_TOTALFEE | DEFAULT (0) | TotalFee defaults to 0 |
| BPAM_DIRECTACCEPTFEE | DEFAULT (0) | DirectAcceptFee defaults to 0 |
| BPAM_MODIFICATIONDATE | DEFAULT (getdate()) | ModificationDate defaults to local time (note: not UTC) |
| BPAM_COMMISSION | DEFAULT (0) | Commission defaults to 0 |
| FK_CCST_BPAY | FK | CID -> Customer.CustomerStatic(CID) |
| FK_BTER_BPAY | FK | TerminalID -> Billing.Terminal(TerminalID) |
| FK_DCUR_BPAY | FK | CurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_DPMS_BPAY | FK | PaymentStatusID -> Dictionary.PaymentStatus(PaymentStatusID) |
| FK_DPMT_BPAY | FK | PaymentTypeID -> Dictionary.PaymentType(PaymentTypeID) |
| FK_BMNG_BPAY | FK | ManagerID -> BackOffice.Manager(ManagerID) |

---

## 8. Sample Queries

### 8.1 Find historical deposits for a pre-2011 customer (both legacy and modern)

```sql
-- Combined deposit history across both legacy and modern tables
SELECT 'Payment' AS Source, PaymentID AS TxID, PaymentDate, Amount / 100.0 AS Amount, CurrencyID, FundingTypeID
FROM Billing.Payment WITH (NOLOCK)
WHERE CID = @CID
  AND PaymentStatusID = 2  -- Note: all here are 27, but joined from modern code this filters nothing
UNION ALL
SELECT 'Deposit' AS Source, DepositID AS TxID, PaymentDate, Amount, CurrencyID, FundingID AS FundingTypeID
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = @CID
  AND PaymentStatusID = 2  -- Approved
ORDER BY PaymentDate DESC
```

### 8.2 Summarize legacy deposit volume by funding type

```sql
SELECT
    p.FundingTypeID,
    COUNT(*) AS DepositCount,
    SUM(p.Amount) / 100.0 AS TotalAmountUnits,
    MIN(p.PaymentDate) AS FirstDeposit,
    MAX(p.PaymentDate) AS LastDeposit
FROM Billing.Payment WITH (NOLOCK)
GROUP BY p.FundingTypeID
ORDER BY DepositCount DESC
```

### 8.3 Look up a legacy deposit with its payment method details

```sql
SELECT
    p.PaymentID,
    p.CID,
    p.PaymentDate,
    p.Amount / 100.0 AS Amount,
    c.Abbreviation AS Currency,
    t.TerminalName,
    ps.Name AS PaymentStatus
FROM Billing.Payment p WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = p.CurrencyID
JOIN Billing.Terminal t WITH (NOLOCK) ON t.TerminalID = p.TerminalID
JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = p.PaymentStatusID
WHERE p.PaymentID = @PaymentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,6,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no procedure reads needed - table is fully frozen) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Payment | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Payment.sql*
