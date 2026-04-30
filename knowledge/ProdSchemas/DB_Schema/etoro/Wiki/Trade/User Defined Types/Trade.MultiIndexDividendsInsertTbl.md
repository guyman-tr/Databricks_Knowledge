# Trade.MultiIndexDividendsInsertTbl

> A table-valued parameter type for bulk insert of dividend events across multiple index instruments, carrying dividend metadata and tax configuration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID + ExDate + EventType (composite) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.MultiIndexDividendsInsertTbl is a TVP that carries dividend event data for bulk insertion into index instrument dividends. Each row represents one dividend event with its instrument, position type, tax codes, event type, dates, currency, value, and buy/sell tax rates.

This type exists to support batch dividend configuration and updates across many index instruments. Index instruments (ETFs, indices) pay dividends on a schedule; this type lets administrators or data feeds push multiple dividend events in a single procedure call.

The calling application or ETL process populates the TVP with dividend rows and passes it to Trade.InsertMultipleIndexDividends. The procedure inserts into the target dividend tables.

---

## 2. Business Logic

InstrumentID + EventType + ExDate + PositionType + TaxCode form a logical grouping for dividend events. BuyTax and SellTax are paired configuration values applied per event. No complex multi-column validation patterns detected beyond the column semantics.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier - the index/ETF that pays the dividend. |
| 2 | PositionType | tinyint | YES | - | NAME-INFERRED | Position type (e.g. long/short) - may affect tax treatment. |
| 3 | TaxCode | varchar(40) | YES | - | NAME-INFERRED | Tax jurisdiction or code for the dividend event. |
| 4 | EventType | varchar(40) | YES | - | NAME-INFERRED | Type of dividend event (e.g. regular, special). |
| 5 | ExDate | date | YES | - | CODE-BACKED | Ex-dividend date - date determining eligibility. |
| 6 | PaymentDate | date | YES | - | CODE-BACKED | Date when dividend is paid. |
| 7 | DividendValueInCurrency | money | YES | - | NAME-INFERRED | Dividend amount in the specified currency. |
| 8 | DividendCurrencyID | int | YES | - | CODE-BACKED | Currency identifier for the dividend amount. |
| 9 | BuyTax | decimal(6,4) | YES | - | NAME-INFERRED | Tax rate applied on buy-side dividend handling. |
| 10 | SellTax | decimal(6,4) | YES | - | NAME-INFERRED | Tax rate applied on sell-side dividend handling. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references instrument tables; DividendCurrencyID references currency. No declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertMultipleIndexDividends | @MultiIndexDividendsInsertTbl | Parameter (TVP) | Bulk inserts dividend events from TVP into dividend tables |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertMultipleIndexDividends | Stored Procedure | READONLY parameter for bulk dividend insert |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk dividend insert

```sql
DECLARE @Dividends Trade.MultiIndexDividendsInsertTbl;
INSERT INTO @Dividends (InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax)
VALUES (1001, 1, 'US', 'Regular', '2025-03-15', '2025-03-22', 1.25, 1, 0.15, 0.15);
EXEC Trade.InsertMultipleIndexDividends @MultiIndexDividendsInsertTbl = @Dividends;
```

### 8.2 Insert multiple dividend events

```sql
DECLARE @Dividends Trade.MultiIndexDividendsInsertTbl;
INSERT INTO @Dividends
SELECT InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax
FROM ExternalDividendFeed;
EXEC Trade.InsertMultipleIndexDividends @MultiIndexDividendsInsertTbl = @Dividends;
```

### 8.3 Single instrument dividend

```sql
DECLARE @Div Trade.MultiIndexDividendsInsertTbl;
INSERT INTO @Div (InstrumentID, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID)
VALUES (5001, 'Regular', '2025-04-01', '2025-04-08', 0.50, 1);
EXEC Trade.InsertMultipleIndexDividends @MultiIndexDividendsInsertTbl = @Div;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 7/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MultiIndexDividendsInsertTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.MultiIndexDividendsInsertTbl.sql*
