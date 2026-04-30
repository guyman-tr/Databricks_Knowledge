# History.IndexDividends

> SQL Server temporal history table storing prior row versions of Trade.IndexDividends, capturing every status change in the index and stock dividend processing pipeline since January 2023.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.IndexDividends is the SQL Server system-versioning history table for Trade.IndexDividends, declared as `HISTORY_TABLE = [History].[IndexDividends]` in the Trade.IndexDividends DDL. Whenever a row in Trade.IndexDividends is updated or deleted, the prior version is written here automatically by SQL Server's temporal versioning engine with the exact validity window (SysStartTime to SysEndTime).

Trade.IndexDividends tracks dividend events for both index instruments (ETF/CFD-style) and real stock positions. Each dividend event produces TWO records in the live table - one for CFD positions (PositionType=0) and one for real positions (PositionType=1). As the dividend is processed through the pipeline (snapshot taken, positions credited, payment completed), the Status column advances through states, and each state change cuts a new version row into this history table.

This history table enables full time-travel audit of the dividend processing lifecycle. Given the financial significance of dividend payments (direct customer account credits), the temporal history provides a precise record of when each status change occurred, which process made it, and from which host - critical for dispute resolution and financial audit.

The table receives very active writes - the latest row is from today (2026-03-19). The trigger `TRG_T_IndexDividends` on the live table fires on INSERT and performs a no-op self-UPDATE, producing an immediate history row where SysStartTime = SysEndTime for every newly inserted dividend record.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server automatically writes superseded row versions from Trade.IndexDividends into this table whenever a dividend record is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `Status`

**Rules**:
- On each UPDATE to Trade.IndexDividends: the old version is written here with SysEndTime = the update timestamp
- The CLUSTERED INDEX on (SysEndTime ASC, SysStartTime ASC) optimizes FOR SYSTEM_TIME AS OF range scans
- Multiple history rows per DividendID are expected - one for each status transition

**Diagram**:
```
Trade.IndexDividends lifecycle per DividendID:
  INSERT (Status=0 or 4) -> TRG_T_IndexDividends -> immediate version (SysStart=SysEnd)
  Status -> 1 (snapshot started) -> history row cut
  Status -> 2 (snapshot complete) -> history row cut
  Status -> 3 (payment/processing) -> history row cut
  ... -> history table captures each state transition
```

### 2.2 Dividend Status Pipeline

**What**: The Status column tracks the dividend through its processing lifecycle in Trade.IndexDividends. Each status change generates a version row here.

**Columns/Parameters Involved**: `Status`, `PositionsSnapshotStarted`, `PositionsSnapshotCompleted`, `PositionsSnapshotMarketClose`, `DividendID`

**Rules**:
- Status=0: New dividend record just inserted via Trade.InsertIndexDividend. Initial state for regular dividends.
- Status=1: Snapshot processing started - PositionsSnapshotStarted timestamp is set
- Status=2: Positions snapshot completed - all qualifying positions have been captured
- Status=3: Payment processing in progress or complete
- Status=4: Correction dividend - set when CorrectionDividendID is not NULL, indicating this row supersedes a prior incorrect dividend
- Status=79: Unusual status observed in 7 history rows; likely a cancelled or error-state dividend

### 2.3 Dual Record Pattern (CFD + Real Positions)

**What**: Every dividend event produces two Trade.IndexDividends records - one for CFD (derivative) positions and one for real stock positions. The BuyTax/SellTax and BuyPaymentInDollars/SellPaymentInDollars differ between the two.

**Columns/Parameters Involved**: `PositionType`, `BuyTax`, `SellTax`, `BuyPaymentInDollars`, `SellPaymentInDollars`

**Rules**:
- PositionType=0: CFD positions (IsSettled=0) - contract for difference, no real share ownership
- PositionType=1: Real positions (IsSettled=1) - customer owns actual shares via exchange
- The same InstrumentID/ExDate/PaymentDate/DividendValueInCurrency appears on both, but BuyTax/SellTax differ (different tax treatment for CFD vs real stock dividends)
- `Convert(BIT, TID.PositionType) AS IsSettled` used in Trade.GetDividendsByStatus confirms PositionType=1 maps directly to IsSettled=1

### 2.4 Computed Columns Materialized in History

**What**: Trade.IndexDividends has DbLoginName, AppLoginName, and HostName as computed (non-persisted) columns. In this history table they are stored as regular nullable columns.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `HostName`, `ProcName`, `UserName`

**Rules**:
- DbLoginName: suser_name() at write time (e.g., "TRAD\gittysa", "TRAD\Alonti")
- AppLoginName: context_info() - typically NULL (dividend service does not set context_info)
- HostName: Server or container hostname (e.g., "qa-trdtrm-we02", "PF5SF7NJ")
- ProcName: Also captured via DEFAULT (object_name(@@procid)) on the source table - "InsertIndexDividend" in all observed rows
- UserName: suser_sname() via source DEFAULT - matches DbLoginName in observed data

---

## 3. Data Overview

634 rows. Range: 2023-01-24 to 2026-03-19. Very active - writes occurring today.

| DividendID | InstrumentID | PositionType | Status | DividendValueInCurrency | SysStartTime | SysEndTime | Meaning |
|-----------|-------------|-------------|--------|------------------------|-------------|-----------|---------|
| 166 | 1014 | 0 | 0 | 3.60 USD | 2026-03-19 10:48:33 | 2026-03-19 10:50:08 | Status=0 version of a CFD dividend for instrument 1014, valid for ~90 seconds before being updated by the pipeline. The next version (SysEnd=SysEnd trigger artifact) captures the insert. |
| 166 | 1014 | 0 | 0 | 3.60 USD | 2026-03-19 10:48:33 | 2026-03-19 10:48:33 | Insert artifact: TRG_T_IndexDividends fired immediately after INSERT, SysStart=SysEnd. Shows the initial state of DividendID 166 at creation. |
| 165 | 2089 | 0 | 0 | 1.35 (currency 666) | 2026-03-19 10:46:29 | 2026-03-19 10:48:04 | CFD dividend for instrument 2089 in a non-USD currency (DividendCurrencyID=666), lasted ~90 seconds before a status update. |
| 164 | 1054 | 0 | 0 | 1.71 USD | 2026-03-19 09:48:03 | 2026-03-19 09:49:35 | Dividend for instrument 1054 inserted by TRAD\Alonti via InsertIndexDividend, superseded after ~90 seconds (likely automatic pipeline trigger). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | VERIFIED | Auto-increment primary key of the Trade.IndexDividends row (IDENTITY NOT FOR REPLICATION in source). Multiple history rows share the same DividendID - each represents a prior state of that dividend record. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The instrument (index or stock) for which the dividend is paid. FK to Trade.Instrument in source. For indexes (InstrumentTypeID=4) and 24/5 stocks (InstrumentTypeID=5) - determined at payment time via Trade.InstrumentMetaData JOIN. |
| 3 | DividendDate | date | YES | - | CODE-BACKED | The dividend announcement or declaration date. NULL in most observed rows - not always populated by the insertion procedures. |
| 4 | BuyPaymentInDollars | money | YES | - | CODE-BACKED | The per-unit dividend payment for long (buy) positions, normalized to USD. Computed during payment processing. NULL in history rows captured before payment calculation runs. |
| 5 | SellPaymentInDollars | money | YES | - | CODE-BACKED | The per-unit dividend payment for short (sell) positions, normalized to USD. Short positions may receive inverted dividend treatment (pay out rather than receive). NULL until payment calculation. |
| 6 | Status | tinyint | NO | 0 | VERIFIED | Dividend processing pipeline state at the time this history version was captured. Values observed in history: 0=new/inserted, 1=snapshot started, 2=snapshot complete, 3=payment processing, 4=correction dividend (CorrectionDividendID not null), 79=cancelled or error. Each status transition generates a new history row. |
| 7 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the dividend record was originally inserted into Trade.IndexDividends. Set once at insert via DEFAULT getutcdate(). Preserved across all history versions (not updated on status changes). |
| 8 | ProcName | varchar(60) | YES | object_name(@@procid) | CODE-BACKED | Name of the stored procedure that performed the INSERT. DEFAULT captures the calling procedure name automatically. Observed value: "InsertIndexDividend". Preserved in history versions as it was set at insert time. |
| 9 | UserName | varchar(40) | YES | suser_sname() | CODE-BACKED | SQL Server username at time of initial insert. DEFAULT suser_sname(). Observed: "TRAD\gittysa", "TRAD\Alonti" - operators using the dividend management interface. |
| 10 | PositionType | tinyint | NO | - | VERIFIED | Whether this dividend record applies to CFD or real positions: 0=CFD positions (IsSettled=0, derivative contracts), 1=real positions (IsSettled=1, actual share ownership). FK to Dictionary.PositionType in source table. Each dividend event has one record per PositionType. |
| 11 | TaxCode | varchar(40) | NO | - | CODE-BACKED | Tax jurisdiction or tax treatment code applied to this dividend. Empty string ('') in observed history rows - may be set programmatically for specific tax regions. Used to determine withholding tax rates. |
| 12 | EventType | varchar(40) | NO | - | CODE-BACKED | Corporate action event type classification for this dividend. Empty string in observed rows. Expected values may include "CASH", "SPECIAL", "INDEX_CASH" or similar event classification codes. |
| 13 | ExDate | date | NO | - | VERIFIED | Ex-dividend date. Positions must be open before this date to qualify. PaymentDate >= ExDate enforced by CK_TradeDividend_ExDate CHECK constraint in source. Primary eligibility cutoff for the payment pipeline. |
| 14 | PaymentDate | date | NO | - | VERIFIED | Date on which the dividend payment is credited to qualifying customer accounts. Payment pipeline checks PaymentDate <= current date before processing. |
| 15 | DividendValueInCurrency | money | NO | - | VERIFIED | The per-share/unit dividend value in the instrument's native currency (DividendCurrencyID). This is the raw dividend amount before any tax deductions or currency conversion to USD. |
| 16 | DividendCurrencyID | int | NO | - | VERIFIED | Currency of DividendValueInCurrency. FK to Dictionary.Currency in source (FK_TradeIndexDividends_DividendCurrencyID). Observed: 1=USD, 666=other currency. |
| 17 | BuyTax | decimal(6,4) | NO | - | VERIFIED | Withholding tax rate applied to long (buy) position dividend payments. Range 0.0000 to 1.0000 (0% to 100%), enforced by CHECK constraint. Example: 0.18 = 18% tax. |
| 18 | SellTax | decimal(6,4) | NO | - | VERIFIED | Withholding tax rate for short (sell) position dividend payments. Range 0.0000 to 1.0000. Example: 0.82 = 82% (short sellers often pay back most of the dividend). |
| 19 | PositionsSnapshotStarted | datetime | YES | - | CODE-BACKED | UTC timestamp when the positions snapshot process began for this dividend. Set by Trade.IndexDividends_SetStatus when status advances to snapshot-in-progress. NULL in early-stage history rows. |
| 20 | PositionsSnapshotCompleted | datetime | YES | - | CODE-BACKED | UTC timestamp when positions snapshot finished - all qualifying positions were captured. Set by Trade.IndexDividends_SetStatus on snapshot completion. NULL until snapshot runs. |
| 21 | PositionsSnapshotMarketClose | datetime | YES | - | CODE-BACKED | UTC timestamp of the market close used to determine position eligibility. Derived from Trade.GetMarketCloseTimeByExDate(ExchangeID, InstrumentID, ExDate). Set by Trade.IndexDividends_SetStatus. NULL until snapshot. |
| 22 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at row version close time. Identifies the DB login that performed the UPDATE/DELETE that closed this version. Examples: "TRAD\gittysa", "TRAD\Alonti". |
| 23 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at version close time. Typically NULL - dividend processing services do not set context_info before writes. |
| 24 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this history version. Set by SQL Server temporal engine. Rows where SysStartTime = SysEndTime are insert artifacts from TRG_T_IndexDividends. |
| 25 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window. Set by SQL Server temporal engine to the timestamp when the live row was updated or deleted. CLUSTERED INDEX ordered by (SysEndTime, SysStartTime) for temporal scan performance. |
| 26 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of host_name() at version close time. Identifies the server that made the change. Observed: "PF5SF7NJ", "qa-trdtrm-we02". |
| 27 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | Whether negative dividend payments are permitted for this record: 0/NULL=not allowed, 1=allowed. Passed as parameter to Trade.InsertIndexDividend. Used for special correction/retake dividend scenarios where the customer may owe money rather than receive a payment. |
| 28 | CorrectionDividendID | int | YES | - | CODE-BACKED | DividendID of the original (incorrect) dividend that this record corrects. NULL for regular dividends. When not NULL, Status is set to 4 (correction) at insert time. Validated by Trade.ValidateCorrectionDividendId to ensure ExDate and DividendCurrencyID match the original. |
| 29 | RetakeDividendID | int | YES | - | CODE-BACKED | DividendID of a retake dividend - used when a dividend is re-issued after being cancelled or reversed. NULL for regular dividends. Similar to CorrectionDividendID but for retake scenarios rather than corrections. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (from source FK) | The instrument whose dividend is being tracked. Source has FK_TradeIndexDividends_TradeInstrument. |
| PositionType | Dictionary.PositionType | Implicit (from source FK) | CFD (0) vs real (1) position type. Source has FK_TradeIndexDividends_DictionaryPositionType. |
| DividendCurrencyID | Dictionary.Currency | Implicit (from source FK) | Currency of the dividend amount. Source has FK_TradeIndexDividends_DividendCurrencyID. |
| CorrectionDividendID | Trade.IndexDividends | Implicit | Points to the original dividend being corrected. NULL for regular dividends. |
| RetakeDividendID | Trade.IndexDividends | Implicit | Points to the dividend being retaken/re-issued. NULL for regular dividends. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.IndexDividends | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | All closed row versions from Trade.IndexDividends are written here automatically by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.IndexDividends (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies. Managed exclusively by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | Declares this as its HISTORY_TABLE. All temporal version rows flow here on UPDATE/DELETE. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_IndexDividends | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression on all data and index pages. |

---

## 8. Sample Queries

### 8.1 Full version history for a specific dividend record
```sql
SELECT DividendID, InstrumentID, PositionType, Status,
       DividendValueInCurrency, DividendCurrencyID,
       BuyTax, SellTax, SysStartTime, SysEndTime,
       DbLoginName, HostName
FROM History.IndexDividends WITH (NOLOCK)
WHERE DividendID = 166
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to see live + history versions for a dividend
```sql
SELECT DividendID, InstrumentID, Status,
       PositionsSnapshotStarted, PositionsSnapshotCompleted,
       SysStartTime, SysEndTime
FROM Trade.IndexDividends WITH (NOLOCK)
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1014
ORDER BY SysStartTime;
```

### 8.3 Find all status transitions for dividends processed on a given date
```sql
SELECT DividendID, InstrumentID, PositionType,
       Status,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS SecondsInStatus,
       SysStartTime, SysEndTime, DbLoginName
FROM History.IndexDividends WITH (NOLOCK)
WHERE CAST(SysEndTime AS date) = '2026-03-19'
  AND SysStartTime != SysEndTime  -- exclude insert artifacts
ORDER BY DividendID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (InsertIndexDividend, IndexDividends_SetStatus, GetDividendsByStatus) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.IndexDividends | Type: Table | Source: etoro/etoro/History/Tables/History.IndexDividends.sql*
