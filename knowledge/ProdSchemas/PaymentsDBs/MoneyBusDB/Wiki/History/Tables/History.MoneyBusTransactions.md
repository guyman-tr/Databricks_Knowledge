# History.MoneyBusTransactions

> System-versioned temporal history table that preserves every prior state of money transfer transactions, automatically maintained by SQL Server when rows in MoneyBus.Transactions are updated.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | ID (bigint) - matches MoneyBus.Transactions.ID; not unique here as each transaction ID can have many historical versions |
| **Partition** | Yes - PS_MonthYear on ValidFrom |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.MoneyBusTransactions is the temporal history archive for the MoneyBus money transfer system. Every time a transaction in `MoneyBus.Transactions` is updated (e.g., status changes from InProcess to Success, or exchange rates are populated), SQL Server automatically copies the old row version into this table before applying the update. Each row represents a prior state of a transaction at a specific point in time, bounded by the ValidFrom/ValidTo window.

This table exists because the money transfer pipeline involves multiple state transitions per transaction - a single deposit or withdrawal passes through Created, HoldInitiated, Held, DebitInitiated, Debited, CreditInitiated, Credited, and finally Success. Without temporal history, only the final state would be preserved, losing the full audit trail of when each step occurred and what values existed at each stage. This is critical for financial reconciliation, dispute resolution, and regulatory compliance.

Data flows into this table automatically via SQL Server's `SYSTEM_VERSIONING` mechanism on `MoneyBus.Transactions`. When `MoneyBus.TransactionAdd` creates a new transaction or `MoneyBus.TransactionUpdate` modifies status, exchange rates, or other fields, the system captures the pre-update state here. No stored procedure or application code writes to this table directly. The table is partitioned by month/year on ValidFrom to manage the large volume of historical versions (~54M rows).

---

## 2. Business Logic

### 2.1 Transaction State Lifecycle Audit Trail

**What**: Each transaction accumulates multiple historical rows as it progresses through the hold-debit-credit pipeline, creating a complete audit trail of every state transition.

**Columns/Parameters Involved**: `ID`, `StatusID`, `StatusReasonID`, `ValidFrom`, `ValidTo`

**Rules**:
- A single transaction ID appears multiple times - once for each state transition. The number of history rows reflects how many times the live transaction was updated.
- The StatusReasonID progression reveals the pipeline path: 1 (Created) -> 12 (HoldInitiated) -> 3 (Held) -> 11 (DebitInitiated) -> 5 (Debited) -> 13 (CreditInitiated) -> 4 (Credited) -> 2 (Success)
- Decline paths terminate early: 9 (ValidateDecline) or 6 (HoldDecline) skip remaining steps
- The ValidFrom/ValidTo window for each row shows exactly when the transaction was in that state

**Diagram**:
```
Transaction ID 4093 - Historical State Progression:
[Created]        ValidFrom=10:45:01 -> ValidTo=10:45:06  (5 sec)
    |
[Held]           ValidFrom=10:45:06 -> ValidTo=10:45:12  (6 sec)
    |
[Debited]        ValidFrom=10:45:12 -> ValidTo=10:45:12  (<1 sec)
    |
[CreditDecline]  ValidFrom=10:45:12 -> ValidTo=10:45:13  (1 sec)
    |
[CreditDecline]  ValidFrom=10:45:13 -> ValidTo=10:45:13  (<1 sec)
    v
(Final state in MoneyBus.Transactions - Decline)
```

### 2.2 Two-Sided Ledger Pattern

**What**: Every transaction represents a fund movement between a creditor (receiving) account and a debitor (sending) account, each with its own account type, reference, and exchange rate set.

**Columns/Parameters Involved**: `CreditorTypeID`, `DebitorTypeID`, `CreditorAccountID`, `DebitorAccountID`, `CreditorReferenceID`, `DebitorReferenceID`, `CreditorBaseExchangeRate`, `CreditorExchangeFee`, `CreditorExchangeRate`, `DebitorBaseExchangeRate`, `DebitorExchangeFee`, `DebitorExchangeRate`

**Rules**:
- Deposits: DebitorTypeID=3 (IBAN, external bank) -> CreditorTypeID=1 (Trading account)
- Withdrawals: DebitorTypeID=1 (Trading account) -> CreditorTypeID=3 (IBAN, external bank)
- Each side has independent exchange rate tracking: base rate, fee, and effective rate
- HoldReferenceID is populated only when the creditor side is IBAN (deposits require hold operations on the external bank side)

### 2.3 Multi-Currency Exchange Rate Tracking

**What**: Exchange rate columns were added in February 2024 to track currency conversion details for cross-currency transactions. Historical rows before this date have NULL exchange rate columns.

**Columns/Parameters Involved**: `CurrencyID`, `CreditorBaseExchangeRate`, `CreditorExchangeFee`, `CreditorExchangeRate`, `DebitorBaseExchangeRate`, `DebitorExchangeFee`, `DebitorExchangeRate`

**Rules**:
- CurrencyID identifies the transaction's denomination currency (application-defined enum, not a DB dictionary table)
- Each side (creditor/debitor) has three exchange rate components: base rate (market rate), fee (conversion spread), and effective rate (rate applied after fees)
- Exchange rates are set by the application during TransactionUpdate, not at creation time
- Pre-February-2024 historical rows have all exchange rate columns as NULL

---

## 3. Data Overview

| ID | StatusID | StatusReasonID | CreditorTypeID | DebitorTypeID | Amount | CurrencyID | Meaning |
|----|----------|----------------|----------------|---------------|--------|------------|---------|
| 4093 | 1 | 1 | 2 | 1 | 50 | 1 | Initial creation of a 50-unit transfer from Trading (1) to Options (2) account - snapshot at Created state before any processing began |
| 4093 | 1 | 5 | 2 | 1 | 50 | 1 | Same transaction after debit step completed - StatusReasonID advanced from Created(1) to Debited(5) while StatusID remained InProcess(1) |
| 4093 | 3 | 7 | 2 | 1 | 50 | 1 | Same transaction after credit step failed - StatusID changed to Decline(3) with CreditDecline(7) reason, ending the pipeline |
| 600 | 3 | 8 | 1 | 2 | 100 | 0 | Early test transaction that was declined at the debit step (DebitDecline=8) - CurrencyID=0 indicates test/default currency |
| 800 | 3 | 9 | 1 | 2 | 100 | 1 | Transaction declined at pre-execution validation (ValidateDecline=9) - never progressed past initial validation checks |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Transaction identifier, matching the IDENTITY PK of MoneyBus.Transactions. Not unique in this history table - each update to the live transaction creates an additional history row with the same ID. |
| 2 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID - identifies the customer who owns or initiated the transaction. Passed as a required parameter to MoneyBus.TransactionAdd and MoneyBus.TransactionsAndGroupAdd. |
| 3 | Created | datetime | NO | - | CODE-BACKED | Timestamp when the transaction was originally created. Defaults to GETUTCDATE() in TransactionAdd if not explicitly provided. Immutable after creation - does not change across state transitions. |
| 4 | CreditorTypeID | int | NO | - | VERIFIED | Account type of the receiving (credit) side: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type) for full definitions. (Dictionary.AccountTypes) |
| 5 | DebitorTypeID | int | NO | - | VERIFIED | Account type of the sending (debit) side: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. Paired with CreditorTypeID to define the transfer direction. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes) |
| 6 | StatusID | int | NO | - | VERIFIED | Top-level transaction lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. In history rows, captures what the status WAS during the ValidFrom-ValidTo window. See [Transaction Status](../../_glossary.md#transaction-status). (Dictionary.TransactionStatuses) |
| 7 | GroupID | bigint | YES | - | CODE-BACKED | FK to MoneyBus.TransactionsGroup. Groups related transactions that were created together as a batch via TransactionsAndGroupAdd. NULL for standalone transactions created via TransactionAdd. |
| 8 | ReferenceID | nvarchar(500) | YES | - | CODE-BACKED | External reference identifier provided by the calling application. Used to correlate the transaction with external systems. Immutable after creation. |
| 9 | Amount | money | NO | - | CODE-BACKED | Transaction amount in the currency specified by CurrencyID. Represents the face value of the fund transfer. Immutable after creation - does not change during state transitions. |
| 10 | CurrencyID | int | NO | - | CODE-BACKED | Application-defined currency identifier for the transaction denomination. No database-side dictionary table exists. Observed values: 0 (test/default), 1, 2, 3, 5. Currency mapping is maintained in the application layer. |
| 11 | Modified | datetime | NO | - | CODE-BACKED | Timestamp of the last modification to the live transaction row. Updated to GETUTCDATE() on every TransactionUpdate call. In history rows, this reflects the modification time at the moment this version was superseded. |
| 12 | CreditorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Account identifier for the receiving (credit) side. Format varies by account type - may be a platform account number (Trading/Options) or an external IBAN/bank reference. |
| 13 | DebitorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Account identifier for the sending (debit) side. Format varies by account type - may be a platform account number or external bank reference. |
| 14 | StatusReasonID | int | YES | - | VERIFIED | Granular sub-state within the transaction lifecycle: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason). (Dictionary.TransactionStatusReasons) |
| 15 | PartitionCol | bigint | NO | - | CODE-BACKED | Partition routing column. In the live table, this is a persisted computed column (ID % 100) used for partition alignment on PS_Transactions. In this history table it is stored as a plain bigint preserving the value at time of versioning. |
| 16 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Execution context captured as JSON at the time of the INSERT/UPDATE on the live table. Contains HostName, AppName, SUserName (SQL login), SPID, DBName, and ObjectName (calling procedure). In the live table this is a computed column using host_name(), app_name(), suser_name(), etc. In history it is stored as the materialized string. |
| 17 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Start of the temporal validity window for this row version. For the initial version of a transaction, this is set to 1900-01-01 (sentinel) or the actual row creation time. For subsequent versions, this is the timestamp when this version became the active row in MoneyBus.Transactions. Partition column for PS_MonthYear. |
| 18 | ValidTo | datetime2(7) | NO | - | VERIFIED | End of the temporal validity window for this row version. This is the timestamp when this version was superseded by a newer version (i.e., when the next UPDATE occurred on MoneyBus.Transactions). The clustered index on (ValidTo, ValidFrom) optimizes temporal range queries. |
| 19 | CreditorReferenceID | varchar(100) | YES | - | CODE-BACKED | Reference identifier on the creditor (receiving) side. Added February 2024. Set or updated via TransactionUpdate. Used to track provider-side reference numbers for the credit leg. |
| 20 | DebitorReferenceID | varchar(100) | YES | - | CODE-BACKED | Reference identifier on the debitor (sending) side. Added February 2024. Set or updated via TransactionUpdate. Used to track provider-side reference numbers for the debit leg. |
| 21 | FlowID | int | YES | - | CODE-BACKED | Application-defined flow type identifier. Added February 2024. No database dictionary table exists. Observed values: 0, 1, 2, 3. Also used in MoneyBus.TransferLimits to define per-flow transfer limits by country, account type, and currency. |
| 22 | ExtraData | nvarchar(4000) | YES | - | CODE-BACKED | Free-form JSON payload for extensible transaction metadata. Added February 2024. Allows the application to attach additional context (e.g., payment provider details, routing information) without schema changes. |
| 23 | CreditorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Market exchange rate for the creditor side's currency conversion. Added February 2024. Part of the creditor exchange rate triplet (base, fee, effective). NULL for same-currency transactions or pre-February-2024 history rows. |
| 24 | CreditorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Conversion fee/spread applied to the creditor side's currency exchange. Represents the markup over the base rate charged for the conversion. |
| 25 | CreditorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Effective exchange rate applied to the creditor side after fees. This is the actual rate used for converting the transaction amount on the credit leg. |
| 26 | DebitorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Market exchange rate for the debitor side's currency conversion. Part of the debitor exchange rate triplet (base, fee, effective). |
| 27 | DebitorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Conversion fee/spread applied to the debitor side's currency exchange. |
| 28 | DebitorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Effective exchange rate applied to the debitor side after fees. This is the actual rate used for converting the transaction amount on the debit leg. |
| 29 | HoldReferenceID | varchar(100) | YES | - | CODE-BACKED | Reference identifier for the hold operation on external funds. Set via TransactionUpdate only (not at creation). Populated when the transaction requires a hold on the external (IBAN) side before proceeding with the debit-credit pipeline. Typically present when CreditorTypeID=3 (IBAN deposits). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | MoneyBus.Transactions | Temporal History | Each row is a prior version of a transaction in the live table. The ID matches MoneyBus.Transactions.ID but is not enforced by FK. |
| CreditorTypeID | Dictionary.AccountTypes | Implicit Lookup | Maps to account type name (Trading, Options, IBAN, MoneyFarm) |
| DebitorTypeID | Dictionary.AccountTypes | Implicit Lookup | Maps to account type name for the sending side |
| StatusID | Dictionary.TransactionStatuses | Implicit Lookup | Maps to top-level status name (InProcess, Success, Decline, Technical, Canceled) |
| StatusReasonID | Dictionary.TransactionStatusReasons | Implicit Lookup | Maps to granular sub-state name and its parent status |
| GroupID | MoneyBus.TransactionsGroup | Implicit FK | Links to the transaction group when batch-created via TransactionsAndGroupAdd |

### 5.2 Referenced By (other objects point to this)

This table is not directly referenced by any views, procedures, or other tables. It is maintained exclusively by SQL Server's temporal versioning mechanism and is queried ad-hoc for audit, reconciliation, and point-in-time analysis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MoneyBusTransactions (table)
  (no code-level dependencies - leaf node)
```

This is a system-managed temporal history table. It has no CREATE TABLE dependencies beyond its partition scheme (PS_MonthYear).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| PS_MonthYear | Partition Scheme | Table is partitioned ON PS_MonthYear(ValidFrom) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | This is the HISTORY_TABLE for MoneyBus.Transactions via SYSTEM_VERSIONING. SQL Server writes here automatically on UPDATE. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MoneyBus_Transactions | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression to reduce storage for the large volume of historical rows |

---

## 8. Sample Queries

### 8.1 Retrieve full history of a specific transaction
```sql
SELECT ID, StatusID, StatusReasonID, Modified, ValidFrom, ValidTo
FROM History.MoneyBusTransactions WITH (NOLOCK)
WHERE ID = 4093
ORDER BY ValidFrom ASC
```

### 8.2 Find transactions that were in a specific state at a point in time
```sql
SELECT h.ID, h.GCID, h.StatusID, h.StatusReasonID, h.Amount, h.CurrencyID
FROM History.MoneyBusTransactions h WITH (NOLOCK)
WHERE h.ValidFrom <= '2025-06-15 12:00:00'
  AND h.ValidTo > '2025-06-15 12:00:00'
  AND h.StatusID = 1  -- InProcess at that moment
```

### 8.3 Join with Dictionary tables to see human-readable state transitions
```sql
SELECT h.ID, h.GCID,
       ts.Name AS StatusName,
       tsr.Name AS StatusReasonName,
       h.Amount, h.CurrencyID,
       h.ValidFrom, h.ValidTo
FROM History.MoneyBusTransactions h WITH (NOLOCK)
JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON h.StatusID = ts.ID
JOIN Dictionary.TransactionStatusReasons tsr WITH (NOLOCK) ON h.StatusReasonID = tsr.ID
WHERE h.ID = 4093
ORDER BY h.ValidFrom ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Hold and Release - LLD | Confluence | Confirms the hold/release pattern used in the MoneyBus transaction pipeline for external fund movements |
| STD Internal Transfer Iban <> Trading | Confluence | Confirms the IBAN-to-Trading transfer flow that drives the CreditorTypeID/DebitorTypeID pairing pattern |
| Local Currency HLD | Confluence | Confirms multi-currency support and the need for per-side exchange rate tracking added in 2024 |
| Phase 1.5 PRD: MIMO Two Ways In / Two Ways Out | Confluence | Establishes MoneyBus as the MIMO (Money In / Money Out) system handling bidirectional fund transfers |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 4 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MoneyBusTransactions | Type: Table (Temporal History) | Source: MoneyBusDB/History/Tables/History.MoneyBusTransactions.sql*
