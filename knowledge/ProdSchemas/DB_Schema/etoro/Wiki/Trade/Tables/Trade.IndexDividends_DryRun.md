# Trade.IndexDividends_DryRun

> Dry-run staging table for dividend processing; tests merges and snapshot logic before applying to the real table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DividendID (non-IDENTITY, copied from source) |
| **Partition** | MAIN |
| **Indexes** | IDX_DividendID on DividendID |

---

## 1. Business Meaning

Trade.IndexDividends_DryRun is a dry-run staging table for dividend processing. It holds the full schema of Trade.IndexDividends, including newer columns (CorrectionDividendID, NegativeDividendAllowed, audit columns DbLoginName, AppLoginName, SysStartTime, SysEndTime, HostName). Unlike the parent table, DividendID is not IDENTITY; values are copied from the source so dry runs can target specific dividend rows for testing.

The table is used by Trade.Merge_IndexDividends_DryRun to test dividend merges in isolation. Trade.DividendsSetSnapshotIsReady_DryRun and Trade.DividendsSetPaymentIsComplete_DryRun also reference it to validate snapshot and payment-completion logic without affecting production data. This supports safe rollout of dividend changes and regression testing.

The live database has 0 rows. The table is populated only during dry-run executions and is truncated or cleared afterward.

---

## 2. Business Logic

- Merge logic: Trade.Merge_IndexDividends_DryRun inserts/updates rows from source data into this table instead of Trade.IndexDividends.
- Snapshot readiness: Trade.DividendsSetSnapshotIsReady_DryRun sets PositionsSnapshotCompleted and related timestamps.
- Payment completion: Trade.DividendsSetPaymentIsComplete_DryRun updates Status to Completed and marks payment as done.
- All logic mirrors production procedures but targets this table; no writes go to the real IndexDividends table during a dry run.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 0 |
| Typical use | Populated during dry runs, then cleared |
| Purpose | Pre-production validation of dividend merge and workflow |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NOT NULL | - | High | Copied from source; not IDENTITY |
| 2 | InstrumentID | int | NOT NULL | - | High | FK to Trade.Instrument |
| 3 | DividendDate | date | NULL | - | High | Dividend date |
| 4 | BuyPaymentInDollars | money | NULL | - | High | Buy-side payment amount in USD |
| 5 | SellPaymentInDollars | money | NULL | - | High | Sell-side payment amount in USD |
| 6 | Status | tinyint | NOT NULL | - | High | 0=Pending, 1=InProgress, 2=Completed, 4=CorrectionPending |
| 7 | Occurred | datetime | NULL | - | High | When the event was processed |
| 8 | ProcName | varchar(60) | NULL | - | Medium | Procedure that created/updated the row |
| 9 | UserName | varchar(40) | NULL | - | Medium | User responsible |
| 10 | PositionType | tinyint | NOT NULL | - | High | 0=CFD, 1=REAL, 255=ILLEGAL |
| 11 | TaxCode | varchar(40) | NOT NULL | - | Medium | Tax classification code |
| 12 | EventType | varchar(40) | NOT NULL | - | Medium | Event type classification |
| 13 | ExDate | date | NOT NULL | - | High | Ex-dividend date |
| 14 | PaymentDate | date | NOT NULL | - | High | Payment date |
| 15 | DividendValueInCurrency | money | NOT NULL | - | High | Dividend value in instrument currency |
| 16 | DividendCurrencyID | int | NOT NULL | - | High | Currency of dividend |
| 17 | BuyTax | decimal(6,4) | NOT NULL | - | High | Buy-side tax rate |
| 18 | SellTax | decimal(6,4) | NOT NULL | - | High | Sell-side tax rate |
| 19 | PositionsSnapshotStarted | datetime | NULL | - | High | Snapshot start timestamp |
| 20 | PositionsSnapshotCompleted | datetime | NULL | - | High | Snapshot completion timestamp |
| 21 | PositionsSnapshotMarketClose | datetime | NULL | - | High | Market close timestamp for snapshot |
| 22 | DbLoginName | varchar(128) | NULL | - | High | Database login name (audit) |
| 23 | AppLoginName | varchar(500) | NULL | - | High | Application login name (audit) |
| 24 | SysStartTime | datetime2(7) | NOT NULL | - | High | System-versioning row start |
| 25 | SysEndTime | datetime2(7) | NOT NULL | - | High | System-versioning row end |
| 26 | HostName | nvarchar(120) | NULL | - | Medium | Host that performed the operation |
| 27 | CorrectionDividendID | int | NULL | - | High | Links to correction dividend when Status=4 |
| 28 | NegativeDividendAllowed | bit | NULL | - | Medium | Whether negative dividends are allowed |

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID) - tradable instrument for the dividend

### 5.2 Referenced By
- Trade.Merge_IndexDividends_DryRun - populates/updates rows during dry run
- Trade.DividendsSetSnapshotIsReady_DryRun - sets snapshot readiness flags
- Trade.DividendsSetPaymentIsComplete_DryRun - marks payment complete

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument

### 6.2 Objects That Depend On This
- Trade.Merge_IndexDividends_DryRun
- Trade.DividendsSetSnapshotIsReady_DryRun
- Trade.DividendsSetPaymentIsComplete_DryRun

---

## 7. Technical Details

### 7.1 Indexes
- IDX_DividendID on DividendID

### 7.2 Constraints
None beyond NOT NULL on key columns. No system versioning on this table; SysStartTime/SysEndTime are regular columns for audit, not temporal.

---

*Generated: 2026-03-14 | Quality: 7.5/10*
*Object: Trade.IndexDividends_DryRun | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.IndexDividends_DryRun.sql*
