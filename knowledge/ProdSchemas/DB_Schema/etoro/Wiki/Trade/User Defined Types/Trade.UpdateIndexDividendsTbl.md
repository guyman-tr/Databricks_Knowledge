# Trade.UpdateIndexDividendsTbl

> TVP for bulk update of index dividend records - carries full dividend attributes including ex-date, payment date, tax codes, and correction linkage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DividendID (int), InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateIndexDividendsTbl carries dividend records for bulk update. Each row holds DividendID, InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax, Status, and CorrectionDividendID. Used for syncing or correcting index dividend data.

The type exists because index dividends need bulk updates from external data feeds or corrections. Trade.UpdateIndexDividends receives the TVP, copies to a temp table, and JOINs against Trade.IndexDividends to UPDATE existing rows or handle corrections.

The type flows from dividend feed processors or admin tools into Trade.UpdateIndexDividends. The procedure merges the TVP data into the target dividend tables.

---

## 2. Business Logic

DividendID + InstrumentID identify the record. TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax, Status, CorrectionDividendID form the update payload. CorrectionDividendID links to another dividend for correction scenarios.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend identifier |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier |
| 3 | PositionType | tinyint | YES | - | CODE-BACKED | Position type (long/short) |
| 4 | TaxCode | varchar(40) | YES | - | CODE-BACKED | Tax code for the dividend |
| 5 | EventType | varchar(40) | YES | - | CODE-BACKED | Dividend event type |
| 6 | ExDate | date | YES | - | CODE-BACKED | Ex-dividend date |
| 7 | PaymentDate | date | YES | - | CODE-BACKED | Payment date |
| 8 | DividendValueInCurrency | money | YES | - | CODE-BACKED | Dividend value in currency |
| 9 | DividendCurrencyID | int | YES | - | CODE-BACKED | Currency of the dividend |
| 10 | BuyTax | decimal(6,4) | YES | - | CODE-BACKED | Tax rate for buy side |
| 11 | SellTax | decimal(6,4) | YES | - | CODE-BACKED | Tax rate for sell side |
| 12 | Status | tinyint | YES | - | CODE-BACKED | Dividend status |
| 13 | CorrectionDividendID | int | YES | - | CODE-BACKED | Links to corrected dividend record if this is a correction |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Semantic references to Trade.Instrument, dividend currency, and correction dividend.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateIndexDividends | @UpdateIndexDividendsTbl | Parameter (TVP) | Bulk-updates index dividend records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateIndexDividends | Stored Procedure | READONLY parameter for bulk dividend update |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and update single dividend
```sql
DECLARE @UpdateIndexDividendsTbl Trade.UpdateIndexDividendsTbl;
INSERT INTO @UpdateIndexDividendsTbl (DividendID, InstrumentID, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, Status)
VALUES (100, 12345, '2026-01-15', '2026-01-20', 1.50, 1, 1);
EXEC Trade.UpdateIndexDividends @UpdateIndexDividendsTbl = @UpdateIndexDividendsTbl;
```

### 8.2 Batch update with correction link
```sql
DECLARE @UpdateIndexDividendsTbl Trade.UpdateIndexDividendsTbl;
INSERT INTO @UpdateIndexDividendsTbl (DividendID, InstrumentID, ExDate, DividendValueInCurrency, CorrectionDividendID)
VALUES (100, 12345, '2026-01-15', 1.25, 99), (101, 12346, '2026-01-16', 2.00, NULL);
EXEC Trade.UpdateIndexDividends @UpdateIndexDividendsTbl = @UpdateIndexDividendsTbl;
```

### 8.3 Build from external feed
```sql
DECLARE @UpdateIndexDividendsTbl Trade.UpdateIndexDividendsTbl;
INSERT INTO @UpdateIndexDividendsTbl (DividendID, InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax, Status)
SELECT DividendID, InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax, Status
FROM Staging.IndexDividendsFeed;
EXEC Trade.UpdateIndexDividends @UpdateIndexDividendsTbl = @UpdateIndexDividendsTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 4/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateIndexDividendsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateIndexDividendsTbl.sql*
