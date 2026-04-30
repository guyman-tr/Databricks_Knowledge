# Trade.CashPaymentStatus

> Tracks the status of individual cash payment operations (dividends, airdrops, corporate actions) per customer per instrument per payment date, linked to a CashingOperationMonitor run.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID |
| **Partition** | No (on DICTIONARY filegroup) |
| **Indexes** | 5 |

---

## 1. Business Meaning

**WHAT:** Trade.CashPaymentStatus is a status-tracking table for cash payment operations such as cash dividends, airdrops, and other corporate actions. Each row represents one payment obligation (one customer, one instrument, one payment date) within a monitor run. The table stores the executable command (CMD), status (UnPaid/Success/Failed/Duplicate/MissingData), and error details for auditing and retry.

**WHY:** Corporate actions from external providers (e.g., APEX EXT922 dividend reports) must be applied to customer balances atomically and reliably. CashPaymentStatus acts as a queue: rows are inserted with StatusID=0 (UnPaid), processed by Trade.ExecuteCashPayment (which runs CMD and updates status), and retried on failure. StatusID=1 (Success) and StatusID=-1 (Failed) drive monitoring and notifications via Trade.UpdateCashingOperationMonitorAndMailing.

**HOW:** Trade.PayCashDividendByPayDate and Trade.PayCashAirdropByPayDateAndTerminalID insert rows from APEX data into CashPaymentStatus, joining Cusip to Trade.InstrumentMetaData and ApexID to Customer.CustomerStatic to resolve InstrumentID and CID. ExecuteCashPayment batches by Sharding, executes CMD (Customer.SetBalanceClameFee), and updates StatusID. Duplicate payments are detected via ApexID+PaymentDate+InstrumentID+Amount and inserted with StatusID=2 (Duplicate).

---

## 2. Business Logic

### 2.1 Status Lifecycle

StatusID flows: 0=UnPaid (default), 1=Success (after CMD executes), -1=Failed (on error), 2=Duplicate (detected at insert). StatusDescription mirrors: 'UnPaid', 'Success', 'Failed', 'Duplicate', 'MissingData'. MissingData when CID or InstrumentID cannot be resolved from ApexID/Cusip.

### 2.2 Monitor Linkage

MonitorID links to Trade.CashingOperationMonitor. Each monitor run (one PaymentDate, one DataSource, optional TerminalID) has many CashPaymentStatus rows. ExecuteCashPayment filters by Sharding and StatusID=0. UpdateCashingOperationMonitorAndMailing checks for unpaid rows (StatusID=0) to drive completion status and mailing.

### 2.3 CMD Execution

CMD holds the literal SQL to run: `EXEC Customer.SetBalanceClameFee @CID=..., @FeeInDollars=..., @Description='CA Type=3:Cash Dividend; Instrument=...; Units=...; MonitorId=...'`. ExecuteCashPayment uses EXEC(@Cmd) and updates StatusID on success or failure.

### 2.4 Sharding and Parallel Processing

Sharding (NTILE over rows) allows ExecuteCashPayment to be run per shard (e.g., @ShardID) for parallel execution. IX_Sharding_StatusID supports efficient selection of unpaid rows per shard.

---

## 3. Data Overview

| ID | ApexID | CID | InstrumentID | Amount | StatusID | StatusDescription | PaymentDate | MonitorID |
|----|--------|-----|--------------|--------|----------|-------------------|-------------|-----------|
| 1 | Account | CID | InstrumentID | -X.XX | 0 | UnPaid | PayDate | MonitorID |
| 2 | Account | CID | InstrumentID | -X.XX | 1 | Success | PayDate | MonitorID |
| 3 | Account | CID | InstrumentID | -X.XX | -1 | Failed | PayDate | MonitorID |
| 4 | Account | CID | InstrumentID | -X.XX | 2 | Duplicate | PayDate | MonitorID |
| 5 | Account | NULL | NULL | -X.XX | -1 | MissingData | PayDate | MonitorID |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY | CODE-BACKED | Primary key; unique row identifier |
| 2 | ApexID | varchar(255) | YES | - | VERIFIED | APEX account number; maps to Customer.CustomerStatic.ApexID for CID |
| 3 | CID | bigint | YES | - | CODE-BACKED | Customer ID; resolved from ApexID; NULL when MissingData |
| 4 | Cusip | varchar(255) | YES | - | CODE-BACKED | CUSIP identifier; maps to Trade.InstrumentMetaData for InstrumentID |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument; resolved from Cusip; NULL when MissingData |
| 6 | Amount | money | YES | - | CODE-BACKED | Payment amount; typically negative for dividend credit |
| 7 | StatusID | int | YES | 0 | VERIFIED | 0=UnPaid, 1=Success, -1=Failed, 2=Duplicate |
| 8 | StatusDescription | varchar(50) | YES | 'UnPaid' | CODE-BACKED | Human-readable status |
| 9 | PaymentDate | date | YES | - | CODE-BACKED | Pay date from corporate action |
| 10 | Occourred | datetime | YES | getdate() | CODE-BACKED | When row created (note: typo Occourred) |
| 11 | EligibleUnits | varchar(30) | YES | - | CODE-BACKED | Position/units eligible for payment |
| 12 | TerminalID | varchar(30) | YES | - | CODE-BACKED | Terminal for airdrop-by-terminal flows |
| 13 | Sharding | int | YES | - | CODE-BACKED | Shard number for parallel ExecuteCashPayment |
| 14 | ErrorMessage | varchar(3000) | YES | - | CODE-BACKED | Error details when StatusID=-1 |
| 15 | CMD | varchar(2000) | YES | - | CODE-BACKED | Executable SQL (SetBalanceClameFee) |
| 16 | MonitorID | int | YES | - | CODE-BACKED | FK to Trade.CashingOperationMonitor.ID |

---

## 5. Relationships

### 5.1 References To

- MonitorID -> Trade.CashingOperationMonitor (logical; no explicit FK)
- CID -> Customer.CustomerStatic (logical; resolved from ApexID)
- InstrumentID -> Trade.Instrument (logical; resolved from Cusip via InstrumentMetaData)
- Cusip -> Trade.InstrumentMetaData (logical; for InstrumentID resolution)

### 5.2 Referenced By

- Trade.ExecuteCashPayment (SELECT/UPDATE)
- Trade.PayCashDividendByPayDate (INSERT/SELECT)
- Trade.PayCashAirdropByPayDateAndTerminalID (INSERT/SELECT)
- Trade.PayCashTerminalIdByManualData (INSERT)
- Trade.UpdateCashingOperationMonitorAndMailing (SELECT for unpaid check)

---

## 6. Dependencies

### 6.0 Dependency Chain

CashPaymentStatus -> CashingOperationMonitor; PayCash* procs read APEX/ApexSYN data and InstrumentMetaData; ExecuteCashPayment invokes Customer.SetBalanceClameFee and Trade.EnqueuePaymentToSvcPayment.

### 6.1 Objects This Depends On

- Trade.CashingOperationMonitor
- Trade.InstrumentMetaData (Cusip -> InstrumentID)
- Customer.CustomerStatic (ApexID -> CID)
- Customer.SetBalanceClameFee (via CMD)
- Trade.ApexSYN_EXT922_DividendReport, Trade.ApexSYN_SodFiles (dividend flow)

### 6.2 Objects That Depend On This

- Trade.ExecuteCashPayment
- Trade.PayCashDividendByPayDate
- Trade.PayCashAirdropByPayDateAndTerminalID
- Trade.UpdateCashingOperationMonitorAndMailing

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Include | Purpose |
|------------|------|-------------|---------|---------|
| CIX_ID | CLUSTERED | ID ASC | - | Primary access |
| IX | NONCLUSTERED | ApexID, PaymentDate, InstrumentID | - | Duplicate check, lookup |
| IX_Cusip_ApexID_MonitorID_StatusID | NONCLUSTERED | Cusip, ApexID, MonitorID, StatusID | - | Monitor + status queries |
| IX_MonitorID_StatusID | NONCLUSTERED | MonitorID, StatusID | - | Monitor completion check |
| IX_Sharding_StatusID | NONCLUSTERED | Sharding, StatusID | CMD | ExecuteCashPayment batch |

### 7.2 Constraints

- df_Status: DEFAULT (0) FOR StatusID
- df_StatusDescription: DEFAULT ('UnPaid') FOR StatusDescription
- df_Occourred: DEFAULT (getdate()) FOR Occourred

---

## 8. Sample Queries

```sql
-- Unpaid payments for a monitor
SELECT TOP 5 ID, ApexID, CID, InstrumentID, Amount, StatusID, StatusDescription, PaymentDate
FROM   Trade.CashPaymentStatus WITH (NOLOCK)
WHERE  MonitorID = @MonitorID
   AND StatusID = 0;

-- Status distribution for a monitor
SELECT StatusID, StatusDescription, COUNT(*) AS Cnt
FROM   Trade.CashPaymentStatus WITH (NOLOCK)
WHERE  MonitorID = @MonitorID
GROUP BY StatusID, StatusDescription;

-- Failed payments with error details
SELECT ID, ApexID, Cusip, Amount, ErrorMessage
FROM   Trade.CashPaymentStatus WITH (NOLOCK)
WHERE  StatusID = -1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 | Sources: DDL, ExecuteCashPayment, PayCashDividendByPayDate, PayCashAirdropByPayDateAndTerminalID, UpdateCashingOperationMonitorAndMailing*
