# Trade.IndexDividends_20210509_after

> Point-in-time snapshot of Trade.IndexDividends taken after a 2021-05-09 migration; used for before/after comparison.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DividendID (IDENTITY) |
| **Partition** | DICTIONARY |
| **Indexes** | None defined |

---

## 1. Business Meaning

This table is a second point-in-time snapshot of Trade.IndexDividends from 2021-05-09. Its structure is identical to Trade.IndexDividends_20210509. The "_after" suffix indicates it was captured after a migration or schema change, with the "_20210509" table serving as the "before" snapshot.

Together, these two snapshots support before/after comparisons of schema or data changes performed on that date. They are useful for migration validation, rollback planning, and post-migration verification.

The table is empty in the live database (0 rows). It is a historical archive only; no procedures or application code reference it.

---

## 2. Business Logic

None. Read-only archive for comparison purposes.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 0 |
| Last known activity | Snapshot date 2021-05-09 |
| Purpose | Post-migration comparison archive |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NOT NULL | IDENTITY(1,1) | High | Surrogate key for dividend event |
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

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID) - tradable instrument for the dividend

### 5.2 Referenced By
None. Archive table; not used by other objects.

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument

### 6.2 Objects That Depend On This
None.

---

## 7. Technical Details

### 7.1 Indexes
None defined.

### 7.2 Constraints
None defined beyond implicit NOT NULL. Structure matches IndexDividends_20210509 (older schema, no system versioning or correction workflow columns).

---

*Generated: 2026-03-14 | Quality: 7.0/10*
*Object: Trade.IndexDividends_20210509_after | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.IndexDividends_20210509_after.sql*
