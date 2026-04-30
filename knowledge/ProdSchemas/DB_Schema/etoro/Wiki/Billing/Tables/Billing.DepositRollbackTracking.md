# Billing.DepositRollbackTracking

> Audit log for deposit rollback operations - records every chargeback, refund, reversal, and cancellation action applied to a deposit, including the amount, currency, exchange rates, manager, reason, and rollback status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RollbackID (BIGINT IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.DepositRollbackTracking` is the authoritative audit log for all deposit rollback operations at eToro. A "deposit rollback" is any action that reverses or modifies the status of a previously processed deposit: chargebacks (payment reversed by card issuer), refunds (eToro returns funds to customer), reversals of those actions, and cancellations of rollbacks.

Each row captures the full financial context of one rollback event: which deposit was affected, what the new status is, how much was rolled back (both in customer currency and USD), the exchange rates used, which back-office manager performed the action, the reason, and whether this rollback was subsequently canceled.

The table was migrated from BackOffice schema to Billing schema in January 2022 (PAYIL-3480). It has 18,037 rows from January 2023 through March 2026 - an active operational table. The `NOT FOR REPLICATION` flag on the IDENTITY column indicates it participates in SQL Server replication.

The two-amount pattern (`TotalRollback*` vs `RollbackAmount*`) distinguishes partial rollbacks (this action's amount) from the cumulative rollback for that deposit across all actions.

---

## 2. Business Logic

### 2.1 Rollback Event Recording

**What**: Each call to `Billing.DepositRollback` records one rollback action against a deposit.

**Columns/Parameters Involved**: All columns

**Rules**:
- `Billing.DepositRollback` is the sole write path. It executes as a transaction:
  1. Validates `@PaymentStatusID IN (2, 11, 12, 26, 37, 38, 39)` - invalid status = error 60025.
  2. Updates `Billing.Deposit.PaymentStatusID` to the new status.
  3. Inserts into `History.DepositAction` (audit trail).
  4. If `@PaymentStatusID = 2` (Cancel Rollback): marks all existing open rollbacks for that deposit as `IsCanceled = 1` BEFORE inserting the new row.
  5. Inserts new row into `Billing.DepositRollbackTracking` with `IsCanceled = 0`.
  6. Calls `Customer.SetBalance` to adjust the customer's account balance.
  7. COMMIT or ROLLBACK as a single transaction.
- `IsCanceled`: set to 0 on insert (active rollback). Set to 1 when a subsequent `PaymentStatusID=2` cancels the rollback.

### 2.2 PaymentStatusID Values in This Table

**What**: The PaymentStatusID records the TYPE of rollback action.

**Columns/Parameters Involved**: `PaymentStatusID`

**Rules**:
| PaymentStatusID | Name | Count | % | Meaning |
|----------------|------|-------|---|---------|
| 12 | Refund | 9,216 | 51% | eToro refunds deposit amount to customer |
| 39 | ReversedDeposit | 2,906 | 16% | Deposit reversed (distinct from standard refund) |
| 2 | Approved | 2,886 | 16% | Cancel Rollback - previous rollback was reversed, deposit restored to Approved |
| 11 | Chargeback | 2,206 | 12% | Card issuer reversed the deposit; eToro records the chargeback |
| 26 | RefundAsChargeback | 819 | 5% | Refund processed using chargeback mechanism |
| 38 | RefundReversal | 3 | <1% | A previous refund was itself reversed |
| 37 | ChargebackReversal | 1 | <1% | A previous chargeback was reversed |

### 2.3 CreditTypeID Mapping for Balance Adjustment

**What**: The DepositRollback procedure maps PaymentStatusID to a CreditTypeID for Customer.SetBalance.

**Columns/Parameters Involved**: `PaymentStatusID`

**Rules**:
```
PaymentStatusID -> CreditTypeID (for Customer.SetBalance)
11 (Chargeback)         -> 11
12 (Refund)             -> 12
26 (RefundAsChargeback) -> 16
37 (ChargebackReversal) -> 11
38 (RefundReversal)     -> 12
39 (ReversedDeposit)    -> 32
2  (CancelRollback)     -> uses OldPaymentStatusID mapping above
```
Amount passed to SetBalance: `CAST(@RollbackAmountInUSD * 100 AS INT)` (converts money to integer cents).

### 2.4 RollbackReasonID

**What**: Categorizes why the rollback was performed.

**Columns/Parameters Involved**: `RollbackReasonID`

**Rules**:
- The lookup table for RollbackReasonID is not in the etoro SSDT repo (external reference, possibly in a BackOffice or admin database).
- Dominant values: 0 (56% - no specific reason or default), 2 (43% - most common tracked reason).
- 18 distinct reason IDs observed; 0 and 2 together account for 99% of rows.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 18,037 |
| IsCanceled = 1 (canceled rollbacks) | 2,909 (16%) |
| IsCanceled = 0 (active rollbacks) | 15,128 (84%) |
| Date range (CreateDate) | 2023-01-04 to 2026-03-16 |
| Most common status | Refund (PaymentStatusID=12, 51%) |
| Most common reason | 0 = no reason / default (56%) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RollbackID | bigint | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. Auto-incremented. NOT FOR REPLICATION prevents identity gaps on replication subscribers. bigint allows for high volume over time. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer whose deposit is being rolled back. Explicit FK to Customer.CustomerStatic(CID). Populated from Billing.Deposit.CID at time of rollback. |
| 3 | DepositID | int | NO | - | CODE-BACKED | The deposit being rolled back. Explicit FK to Billing.Deposit(DepositID). Multiple rollback rows may exist per DepositID (e.g., chargeback then cancel). |
| 4 | PaymentStatusID | int | NO | - | CODE-BACKED | Type of rollback action. Explicit FK to Dictionary.PaymentStatus. Allowed values: 2=Approved(CancelRollback), 11=Chargeback, 12=Refund, 26=RefundAsChargeback, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. Distribution: 12=51%, 39=16%, 2=16%, 11=12%, 26=5%. |
| 5 | TotalRollbackAmountInUSD | money | NO | - | CODE-BACKED | Cumulative total amount rolled back for this deposit across all actions, in USD. Represents the running total at the time of this action. May exceed RollbackAmountInUSD for partial rollbacks. |
| 6 | TotalRollbackAmountInCurrency | money | NO | - | CODE-BACKED | Same as TotalRollbackAmountInUSD but in the deposit's original currency. Populated from @TotalRollbackAmountInCurrency parameter. |
| 7 | RollbackAmountInUSD | money | NO | - | CODE-BACKED | Amount rolled back by this specific action, in USD. Computed if not provided: @RollbackAmountInCurrency * @ExchangeRate. Used in Customer.SetBalance call: CAST(RollbackAmountInUSD * 100 AS INT) = amount in cents. |
| 8 | RollbackAmountInCurrency | money | NO | - | CODE-BACKED | Amount rolled back by this specific action, in the deposit's original currency. The primary input amount from the caller. |
| 9 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the original deposit. Inherited from Billing.Deposit.CurrencyID at time of rollback. Implicit FK to Dictionary.Currency. |
| 10 | ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate used for currency conversion at time of rollback. User-defined type dtPrice (decimal). Defaults to the original deposit ExchangeRate if not explicitly passed. Used to convert RollbackAmountInCurrency to USD. |
| 11 | BaseExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Base exchange rate from the original deposit, carried forward to the rollback record for PIP calculation consistency. Inherited from Billing.Deposit.BaseExchangeRate. |
| 12 | ExchangeFee | int | NO | - | CODE-BACKED | Exchange fee from the original deposit, inherited at rollback time. Used in PIP calculations via Billing.CalculateDepositRollbackPIPsUSD. |
| 13 | ReferenceNumber | varchar(50) | YES | - | CODE-BACKED | External payment processor reference number for this rollback action (e.g., chargeback case ID, refund transaction ID). NULL when not provided by the processor. |
| 14 | RollbackReasonID | int | NO | - | CODE-BACKED | Categorizes why the rollback was performed. Lookup table not in SSDT repo. Dominant values: 0=no specific reason (56%), 2=most common tracked reason (43%). 18 distinct values observed. |
| 15 | Comments | varchar(255) | YES | - | CODE-BACKED | Free-text notes added by the manager performing the rollback. Passed to Customer.SetBalance as @Description. NULL when not provided. |
| 16 | RollbackDate | datetime | NO | - | CODE-BACKED | The effective date of the rollback (e.g., date the chargeback was received from the processor). Distinct from CreateDate - represents when the event occurred in the external system, not when it was recorded in eToro's database. |
| 17 | CreateDate | datetime | NO | - | CODE-BACKED | UTC timestamp when this rollback record was created in eToro's system. Set to GETDATE() at time of procedure execution. |
| 18 | ModificationDate | datetime | NO | - | CODE-BACKED | UTC timestamp of last modification. Initially set to GETDATE() = same as CreateDate. Updated when IsCanceled is set to 1 by a subsequent cancel-rollback action. |
| 19 | ManagerID | int | NO | - | CODE-BACKED | Back-office manager who performed the rollback. Explicit FK to BackOffice.Manager(ManagerID). Passed to Customer.SetBalance for audit trail. |
| 20 | IsCanceled | bit | NO | DEFAULT (0) | CODE-BACKED | Whether this rollback was subsequently canceled. 0=active rollback (default on insert), 1=canceled by a later PaymentStatusID=2 action on the same deposit. 2,909 rows (16%) have IsCanceled=1. When canceling, all IsCanceled=0 rows for the DepositID are set to 1 before the new row is inserted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Explicit FK | Customer whose deposit is being rolled back. |
| DepositID | Billing.Deposit | Explicit FK | The deposit being reversed/refunded. |
| ManagerID | BackOffice.Manager | Explicit FK | Back-office staff member who processed the rollback. |
| PaymentStatusID | Dictionary.PaymentStatus | Explicit FK | Type of rollback action (Chargeback, Refund, etc.). |
| CurrencyID | Dictionary.Currency | Implicit FK | Currency of the rollback amount. |
| RollbackReasonID | (Unknown - not in SSDT repo) | Implicit FK | Categorization of rollback reason. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositRollback | DepositID, all columns | WRITER + UPDATER | Primary write path. Inserts new records; updates IsCanceled on cancel-rollback. |
| Billing.CalculateDepositRollbackPIPsUSD | RollbackID | READER | Calculates PIP values for deposit rollback records. |
| Billing.BI_Deposit_State_Report | DepositID | READER | BI reporting on deposit states including rollbacks. |
| Billing.BI_DepositRollback_PIPS_Report | RollbackID | READER | BI report on rollback PIP calculations. |
| Billing.BI_GetDepositStatus | DepositID | READER | Function to determine deposit status including rollback state. |
| Billing.BI_GetDeposit_TransactionType | DepositID | READER | Function to classify deposit transaction type including rollback context. |
| Billing.GetDepositsCustomerCardPCIVersion | CID | READER | Retrieves deposit rollback info for PCI card management. |
| Billing.PSPMatchToEtoro | DepositID | READER | PSP reconciliation procedure reads rollback records. |
| Billing.PSPMatchToEtoro2 | DepositID | READER | Second version of PSP reconciliation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Billing.Deposit -> Billing.DepositRollbackTracking (DepositID FK)
BackOffice.Manager -> Billing.DepositRollbackTracking (ManagerID FK)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | DepositID FK target - rollback must reference a valid deposit |
| BackOffice.Manager | Table | ManagerID FK target - must be a valid back-office manager |
| Customer.CustomerStatic | Table | CID FK target |
| Dictionary.PaymentStatus | Table | PaymentStatusID FK target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositRollback | Stored Procedure | WRITER - primary write path for all rollback operations |
| Billing.CalculateDepositRollbackPIPsUSD | Function | READER - PIP calculations for rollback records |
| Billing.BI_Deposit_State_Report | Stored Procedure | READER - BI deposit state reporting |
| Billing.BI_DepositRollback_PIPS_Report | Stored Procedure | READER - BI rollback PIP report |
| Billing.BI_GetDepositStatus | Function | READER - deposit status classification |
| Billing.BI_GetDeposit_TransactionType | Function | READER - transaction type classification |
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | READER - PCI card deposit lookup |
| Billing.PSPMatchToEtoro | Stored Procedure | READER - PSP reconciliation |
| Billing.PSPMatchToEtoro2 | Stored Procedure | READER - PSP reconciliation v2 |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOfficeDepositRollbackTracking | CLUSTERED PK | RollbackID ASC | - | - | Active |

No non-clustered indexes on DepositID or CID. Point lookups by DepositID require a full clustered scan (acceptable given access patterns in BI/reporting contexts).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOfficeDepositRollbackTracking | PRIMARY KEY | RollbackID - unique rollback event identifier |
| FK_BackOfficeDepositRollbackTracking_BackOfficeManager | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_BackOfficeDepositRollbackTracking_BillingDeposit | FOREIGN KEY | DepositID -> Billing.Deposit(DepositID) |
| FK_BackOfficeDepositRollbackTracking_CustomerCustomerStatic | FOREIGN KEY | CID -> Customer.CustomerStatic(CID) |
| FK_BackOfficeDepositRollbackTracking_DictionaryPaymentStatus | FOREIGN KEY | PaymentStatusID -> Dictionary.PaymentStatus(PaymentStatusID) |
| DF_BackOfficeDepositRollbackTracking_IsCanceled | DEFAULT | 0 - new rollbacks start as active (not canceled) |

Note: PK name retains "BackOffice" prefix from original schema before the Jan 2022 migration.

---

## 8. Sample Queries

### 8.1 Get all active rollbacks for a deposit

```sql
SELECT rt.RollbackID, ps.Name AS StatusName, rt.RollbackAmountInUSD,
    rt.RollbackAmountInCurrency, rt.CurrencyID, rt.RollbackDate, rt.CreateDate, rt.Comments
FROM [Billing].[DepositRollbackTracking] rt WITH (NOLOCK)
JOIN [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON rt.PaymentStatusID = ps.PaymentStatusID
WHERE rt.DepositID = @DepositID AND rt.IsCanceled = 0
ORDER BY rt.CreateDate DESC;
```

### 8.2 Total rollback amounts by type (last 30 days)

```sql
SELECT ps.Name AS RollbackType, COUNT(*) AS Count,
    SUM(rt.RollbackAmountInUSD) AS TotalUSD
FROM [Billing].[DepositRollbackTracking] rt WITH (NOLOCK)
JOIN [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON rt.PaymentStatusID = ps.PaymentStatusID
WHERE rt.CreateDate >= DATEADD(DAY, -30, GETUTCDATE()) AND rt.IsCanceled = 0
GROUP BY ps.Name
ORDER BY TotalUSD DESC;
```

### 8.3 Rollback history for a customer

```sql
SELECT rt.RollbackID, rt.DepositID, ps.Name AS Action,
    rt.RollbackAmountInUSD, rt.RollbackDate, rt.CreateDate, rt.IsCanceled
FROM [Billing].[DepositRollbackTracking] rt WITH (NOLOCK)
JOIN [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON rt.PaymentStatusID = ps.PaymentStatusID
WHERE rt.CID = @CID
ORDER BY rt.CreateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| PAYIL-3480 | Jira (code comment) | Procedure moved from BackOffice to Billing schema, Jan 2022. Establishes migration history. |
| PAYIL-3976 | Jira (code comment) | @ExchangeRate parameter added to DepositRollback, Apr 2022. |
| PAYIL-4068 | Jira (code comment) | Added support for default calculation of @RollbackAmountInUSD and @ExchangeRate when NULL, Apr 2022. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (tickets archived) | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositRollbackTracking | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DepositRollbackTracking.sql*
