# Trade.IndexDividends

> Stores scheduled dividend events for index/stock instruments, tracking ex-date, payment date, tax rates, and lifecycle status for both CFD and REAL position types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DividendID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active (PK + IX_DividendCurrencyID, IX_InstrumentID, IX_TradeIndexDividendsStatusPositionType, Ix_Status) |

---

## 1. Business Meaning

Trade.IndexDividends is the central table for dividend event scheduling and tracking on eToro. It stores one row per dividend declaration for an instrument and position type (CFD or REAL), capturing the ex-date (when a holder qualifies), payment date, dividend value, tax rates, and processing status. The table supports both standard dividends and correction/retake workflows via CorrectionDividendID and RetakeDividendID.

This table exists because eToro must pay or adjust dividends to users holding positions on ex-date. Without it, the system could not schedule dividend events, trigger snapshot jobs to identify eligible positions, convert amounts to USD, or mark dividends as paid. Trade.GetCIDsForIndexDividends, Trade.DividendsSetPaymentStatus, and email reports all depend on this table.

Data flows: Rows are created by Trade.InsertIndexDividend, Trade.InsertDividend, Trade.InsertMultipleIndexDividends, and merged from dry-run via Trade.Merge_IndexDividends_DryRun. Status progression: 0 (pending) -> 1 (ready for payment) -> 2 (completed). Trade.GetCIDsForIndexDividends advances Status from 0 to 1 when PaymentDate passes, then 1 to 2 when processing completes. Trade.DeleteDividend and Trade.DeleteIndexDividends remove rows (only when Status=0). System versioning records all changes to History.IndexDividends. Trigger TRG_T_IndexDividends forces temporal history on INSERT.

---

## 2. Business Logic

### 2.1 Dividend Status Lifecycle

**What**: The Status column drives the dividend processing pipeline from pending to paid.

**Columns/Parameters Involved**: `Status`, `PaymentDate`, `CorrectionDividendID`

**Rules**:
- Status=0 (Pending): New dividend, default. Can be deleted. Trade.DeleteDividend only deletes when Status=0.
- Status=4 (Correction Pending): Correction dividend (CorrectionDividendID is not NULL). Treated like 0 for active listing - Trade.GetActiveIndexDividends returns Status 0 or 4.
- Status=1 (In Progress): PaymentDate has passed. Trade.GetCIDsForIndexDividends sets Status=1 when Status=0 and PaymentDate < today. Ready for snapshot and payment processing.
- Status=2 (Completed): Dividend has been paid. Trade.GetCIDsForIndexDividends sets Status=2 after processing. Trade.IndexDividends24HoursEmailReport uses Status=2 for completed dividends.

**Diagram**:
```
INSERT (Trade.InsertIndexDividend)
     |
     +-> CorrectionDividendID IS NULL? -> Status=0 (Pending)
     +-> CorrectionDividendID IS NOT NULL? -> Status=4 (Correction Pending)
     |
PaymentDate < today (GetCIDsForIndexDividends) -> Status=1 (In Progress)
     |
Processing complete -> Status=2 (Completed)
```

### 2.2 Position Type Split (CFD vs REAL)

**What**: Each dividend row applies to either CFD positions (PositionType=0) or REAL positions (PositionType=1). Same instrument can have separate dividend rows per type.

**Columns/Parameters Involved**: `PositionType`, `InstrumentID`

**Rules**:
- PositionType=0 (CFD): Dividend applies to CFD holders. FK to Dictionary.PositionType.
- PositionType=1 (REAL): Dividend applies to REAL stock holders. Different tax treatment.
- PositionType=255 (ILLEGAL): Excluded from active dividends - Trade.GetActiveIndexDividends filters (PositionType <> 255).
- Trade.InsertIndexDividend and Trade.GetDividendsForSnapshot filter by InstrumentID + PositionType when matching positions.

### 2.3 Correction and Retake Chain

**What**: CorrectionDividendID links a correction to an original dividend; RetakeDividendID groups dividends that share a retake/correction flow.

**Columns/Parameters Involved**: `CorrectionDividendID`, `RetakeDividendID`

**Rules**:
- CorrectionDividendID: Points to DividendID of the dividend being corrected. Validation in Trade.ValidateCorrectionDividendId requires ExDate and DividendCurrencyID match the original.
- RetakeDividendID: Points to a parent dividend when this row is part of a retake batch. Multiple dividends can share the same RetakeDividendID.
- Trade.GetInvalidDividendsByCorrection finds invalid corrections.

---

## 3. Data Overview

| DividendID | InstrumentID | Symbol | Status | PositionType | ExDate | PaymentDate | DividendValueInCurrency | DivCurrency | CorrectionDividendID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 149 | 2213 | DNB.OL | 0 | 0 | 2025-02-05 | 2026-03-12 | 0.68 | NOK | - | Pending dividend for DNB (Norwegian stock) in CFD, payment in NOK. Awaiting PaymentDate to trigger processing. |
| 138 | 1017 | GE | 0 | 0 | 2025-03-14 | 2026-03-11 | 2.69 | USD | - | Pending GE dividend, CFD, USD. Will transition to Status=1 when PaymentDate passes. |
| 129 | 2050 | LLOY.L | 0 | 0 | 2026-03-03 | 2026-03-11 | 2.65 | GBX | - | LLOY dividend in British pence (GBX). Illustrates non-USD dividend currency. |
| 158 | 1137 | - | 2 | 0 | 2025-02-05 | 2026-03-12 | 0.69 | USD | - | Completed dividend (Status=2). Processed and paid. BuyTax=0.61, SellTax=0.29 applied. |
| 81 | 25 | - | 2 | 0 | - | - | - | - | - | Completed dividend with RetakeDividendID=80. Part of a retake batch; shares parent with DividendID 82, 83. |

**Selection criteria for the 5 rows:**
- Mix of Status 0 (pending) and 2 (completed).
- PositionType=0 (CFD) - most common.
- Variety of currencies: USD, NOK, GBX.
- One row showing RetakeDividendID chain.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate ID for the dividend event. NOT FOR REPLICATION. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument (stock/index) for which this dividend is declared. See [Trade.Instrument](Trade.Instrument.md). |
| 3 | DividendDate | date | YES | - | CODE-BACKED | Legacy field. CHECK (DividendDate>=getutcdate()) when set - NOCHECK in place. May predate ExDate/PaymentDate. |
| 4 | BuyPaymentInDollars | money | YES | - | CODE-BACKED | Legacy. Pre-calculated buy-side payment in USD. Populated by Trade.InsertDividend; newer flow uses GetRateInDollarsForDividends. |
| 5 | SellPaymentInDollars | money | YES | - | CODE-BACKED | Legacy. Pre-calculated sell-side payment in USD. Same pattern as BuyPaymentInDollars. |
| 6 | Status | tinyint | NO | 0 | CODE-BACKED | Lifecycle: 0=Pending, 4=Correction Pending, 1=In Progress, 2=Completed. See Section 2.1. Default 0. |
| 7 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the dividend row was created. Audit field. |
| 8 | ProcName | varchar(60) | YES | object_name(@@procid) | CODE-BACKED | Stored procedure that created the row. Default from @@procid. Audit. |
| 9 | UserName | varchar(40) | YES | suser_sname() | CODE-BACKED | SQL login of the user who created the row. Default suser_sname(). Audit. |
| 10 | PositionType | tinyint | NO | - | CODE-BACKED | FK to Dictionary.PositionType. 0=CFD, 1=REAL, 255=ILLEGAL. Dividends split by position ownership model. See [Dictionary.PositionType](../../Dictionary/Tables/Dictionary.PositionType.md). |
| 11 | TaxCode | varchar(40) | NO | - | CODE-BACKED | Tax code/label for withholding. Passed from InsertIndexDividend; may map to jurisdiction. |
| 12 | EventType | varchar(40) | NO | - | CODE-BACKED | Type of corporate action (e.g., dividend, special dividend). Passed from InsertIndexDividend. |
| 13 | ExDate | date | NO | - | CODE-BACKED | Ex-dividend date. Holder must own position on this date to receive dividend. CHECK: PaymentDate >= ExDate. |
| 14 | PaymentDate | date | NO | - | CODE-BACKED | Date when dividend is paid. Trade.GetCIDsForIndexDividends uses PaymentDate < today to advance Status 0 -> 1. |
| 15 | DividendValueInCurrency | money | NO | - | CODE-BACKED | Dividend amount per share/unit in DividendCurrencyID. |
| 16 | DividendCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Currency of DividendValueInCurrency (USD, EUR, GBX, NOK, etc.). See [Dictionary.Currency](../../Dictionary/Tables/Dictionary.Currency.md). |
| 17 | BuyTax | decimal(6,4) | NO | - | CODE-BACKED | Tax rate for buy-side (long) positions. CHECK: 0 to 1. Fraction, e.g., 0.15 = 15%. |
| 18 | SellTax | decimal(6,4) | NO | - | CODE-BACKED | Tax rate for sell-side (short) positions. CHECK: 0 to 1. Same format as BuyTax. |
| 19 | PositionsSnapshotStarted | datetime | YES | - | CODE-BACKED | When the position snapshot for this dividend started. Set by Trade.DividendsSetSnapshotIsReady flow. |
| 20 | PositionsSnapshotCompleted | datetime | YES | - | CODE-BACKED | When the position snapshot completed. Part of dividend processing pipeline. |
| 21 | PositionsSnapshotMarketClose | datetime | YES | - | CODE-BACKED | Market close timestamp used for snapshot. |
| 22 | DbLoginName | (computed) | - | suser_name() | CODE-BACKED | Computed: suser_name(). Current DB login for audit. |
| 23 | AppLoginName | (computed) | - | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context. |
| 24 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. GENERATED ALWAYS AS ROW START. |
| 25 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System-versioning end. GENERATED ALWAYS AS ROW END. History in History.IndexDividends. |
| 26 | HostName | (computed) | - | host_name() | CODE-BACKED | Computed: host_name(). Server where row was created. |
| 27 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | 1 = negative (special) dividend allowed. Passed from InsertIndexDividend. NULL = default no. |
| 28 | CorrectionDividendID | int | YES | - | CODE-BACKED | FK to self. DividendID of the dividend being corrected. When set, Status defaults to 4. Trade.ValidateCorrectionDividendId validates. |
| 29 | RetakeDividendID | int | YES | - | CODE-BACKED | FK to self. Parent dividend when this row is part of a retake batch. Multiple rows can share same RetakeDividendID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Instrument (stock/index) for this dividend. |
| PositionType | Dictionary.PositionType | FK | CFD (0), REAL (1), or ILLEGAL (255). |
| DividendCurrencyID | Dictionary.Currency | FK | Currency of dividend amount. |
| CorrectionDividendID | Trade.IndexDividends | Self-Reference | Original dividend being corrected. |
| RetakeDividendID | Trade.IndexDividends | Self-Reference | Parent dividend in retake chain. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetActiveIndexDividends | - | View | Filters Status 0 or 4, PositionType <> 255. |
| Trade.InsertIndexDividend | INSERT | Writer | Primary insert path. |
| Trade.GetCIDsForIndexDividends | UPDATE | Modifier | Advances Status 0->1, 1->2. |
| Trade.DeleteDividend | DELETE | Deleter | Deletes when Status=0. |
| Trade.DividendsSetPaymentStatus | UPDATE | Modifier | Updates payment status. |
| Trade.DividendsSetSnapshotIsReady | UPDATE | Modifier | Sets PositionsSnapshotStarted/Completed. |
| Trade.GetDividendsForSnapshot | SELECT | Reader | Feeds snapshot pipeline. |
| Trade.IndexDividends24HoursEmailReport | SELECT | Reader | Completed dividends (Status=2). |
| Trade.GetRateInDollarsForDividends | JOIN | Reader | Converts dividend amounts to USD. |
| Trade.ValidateCorrectionDividendId | FROM | Reader | Validates correction linkage. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IndexDividends (table)
  (no code-level dependencies - tables are leaf nodes)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID |
| Dictionary.PositionType | Table | FK PositionType |
| Dictionary.Currency | Table | FK DividendCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetActiveIndexDividends | View | Base table |
| History.IndexDividends | Table | System-versioning history |
| Trade.InsertIndexDividend | Procedure | INSERT |
| Trade.GetCIDsForIndexDividends | Procedure | UPDATE, JOIN |
| Trade.DeleteDividend | Procedure | DELETE, SELECT |
| Trade.DividendsSetPaymentStatus | Procedure | UPDATE |
| Trade.DividendsSetSnapshotIsReady | Procedure | SELECT, UPDATE |
| Trade.GetDividendsForSnapshot | Procedure | SELECT |
| Trade.IndexDividends24HoursEmailReport | Procedure | SELECT |
| Trade.GetRateInDollarsForDividends | Procedure | JOIN |
| Trade.ValidateCorrectionDividendId | Function | FROM |
| Trade.IndexDividendsEmail | Procedure | JOIN |
| Trade.GetDividendsByStatus | Procedure | SELECT |
| Trade.UpdateIndexDividends | Procedure | UPDATE |
| Trade.Merge_IndexDividends_DryRun | Procedure | MERGE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeIndexDividends | CLUSTERED | DividendID | - | - | Active |
| IX_DividendCurrencyID | NC | DividendCurrencyID | - | - | Active |
| IX_InstrumentID | NC | InstrumentID | - | - | Active |
| IX_TradeIndexDividendsStatusPositionType | NC | Status, PositionType, PaymentDate | DividendCurrencyID | - | Active |
| Ix_Status | NC | Status | InstrumentID, PositionType, ExDate | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TradeIndexDividendsStatus | DEFAULT | Status = 0 |
| DF_TradeIndexDividends_Occurred | DEFAULT | Occurred = getutcdate() |
| DF_TradeIndexDividends | DEFAULT | ProcName = object_name(@@procid) |
| DF_TradeIndexDividends_ProcName | DEFAULT | UserName = suser_sname() |
| DF_IndexDividends_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_IndexDividends_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| CK_TradeDividend_BuyTax | CHECK | BuyTax between 0 and 1 |
| CK_TradeDividend_SellTax | CHECK | SellTax between 0 and 1 |
| CK_TradeDividend_ExDate | CHECK | PaymentDate >= ExDate (NOCHECK) |
| CK_TradeDividend_DividendDate | CHECK | DividendDate >= getutcdate() (NOCHECK) |
| FK_TradeIndexDividends_DictionaryPositionType | FK | PositionType -> Dictionary.PositionType.ID |
| FK_TradeIndexDividends_DividendCurrencyID | FK | DividendCurrencyID -> Dictionary.Currency.CurrencyID |
| FK_TradeIndexDividends_TradeInstrument | FK | InstrumentID -> Trade.Instrument.InstrumentID |

---

## 8. Sample Queries

### 8.1 Pending dividends for an instrument
```sql
SELECT DividendID, InstrumentID, PositionType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, Status
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE InstrumentID = 1017
  AND Status IN (0, 4)
ORDER BY PaymentDate;
```

### 8.2 Completed dividends with instrument and currency
```sql
SELECT D.DividendID, D.InstrumentID, IMD.Symbol, D.PositionType, D.ExDate, D.PaymentDate,
       D.DividendValueInCurrency, DC.Abbreviation AS DivCurrency, D.BuyTax, D.SellTax
FROM Trade.IndexDividends D WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON D.InstrumentID = IMD.InstrumentID
INNER JOIN Dictionary.Currency DC WITH (NOLOCK) ON D.DividendCurrencyID = DC.CurrencyID
WHERE D.Status = 2
ORDER BY D.PaymentDate DESC;
```

### 8.3 Active dividends (CFD and REAL) with position type label
```sql
SELECT D.DividendID, D.InstrumentID, D.ExDate, D.PaymentDate, PT.Value AS PositionTypeName, D.Status
FROM Trade.IndexDividends D WITH (NOLOCK)
INNER JOIN Dictionary.PositionType PT WITH (NOLOCK) ON D.PositionType = PT.ID
WHERE D.Status IN (0, 4)
  AND D.PositionType <> 255
ORDER BY D.PaymentDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Index Dividend Process (Trading CM) | Confluence | Dividend process and lifecycle context |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IndexDividends | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.IndexDividends.sql*
