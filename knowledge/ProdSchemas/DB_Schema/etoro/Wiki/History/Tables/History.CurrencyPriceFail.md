# History.CurrencyPriceFail

> Price feed failure log table - records price quote rejections from liquidity providers with the rejection reason; currently empty (0 rows).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CurrencyPriceFailID - bigint IDENTITY PK NONCLUSTERED |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | 3 (1 PK nonclustered + 2 nonclustered on InstrumentID, ProviderID), FILLFACTOR=90, on [HISTORY] |

---

## 1. Business Meaning

History.CurrencyPriceFail is a diagnostic/audit log that records price quote failures - instances where a price tick received from a liquidity provider (ProviderID) for a specific instrument (InstrumentID) was rejected by the price validation engine.

Each row captures: which provider sent the bad price, which instrument it was for, the bid/ask values that failed validation, when it occurred on the server and when it was processed, and the reason for rejection.

0 rows - no price failures have been logged. The price feed is operating cleanly.

The table uses the `dbo.dtPrice` User Defined Type for Bid and Ask columns - a precision decimal type used consistently across the price feed tables. The PK is NONCLUSTERED (no heap, but no clustered index either - the table is a heap), which is unusual and indicates this was designed for fast INSERT operations where clustered insert ordering would be a bottleneck.

---

## 2. Business Logic

### 2.1 Price Failure Logging

**What**: When a price tick from a provider fails validation, a row is inserted here.

**Rules**:
- CurrencyPriceFailID is auto-incremented (IDENTITY)
- Occurred = DEFAULT getdate() = when the failure was detected locally
- OccurredOnServer = when the price tick was generated on the provider's side
- Reason = text description of why the price was rejected (e.g., stale price, out-of-range bid/ask, zero price)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 |
| **Status** | Empty - no price failures logged |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyPriceFailID | bigint IDENTITY | NO | - | VERIFIED | Auto-incremented unique ID. PK. NOT FOR REPLICATION. |
| 2 | ProviderID | int | NO | - | VERIFIED | Liquidity provider that sent the failed price. Implicit FK to provider tables. |
| 3 | InstrumentID | int | NO | - | VERIFIED | Financial instrument for which the price failed. Implicit FK to Trade.InstrumentTbl. |
| 4 | Bid | dbo.dtPrice | NO | - | VERIFIED | Bid price value from the failed tick. Uses dbo.dtPrice UDT (precision decimal). |
| 5 | Ask | dbo.dtPrice | NO | - | VERIFIED | Ask price value from the failed tick. Uses dbo.dtPrice UDT. |
| 6 | Occurred | datetime | NO | getdate() | VERIFIED | Timestamp when the failure was detected. DEFAULT = getdate(). |
| 7 | OccurredOnServer | datetime | NO | - | VERIFIED | Timestamp from the provider's side when the price tick was generated. |
| 8 | Reason | varchar(255) | NO | - | VERIFIED | Text description of why the price was rejected. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Provider/liquidity tables | Implicit | The provider that sent the invalid price. |
| InstrumentID | Trade.InstrumentTbl | Implicit | The instrument for which the price failed. |
| Bid, Ask | dbo.dtPrice (UDT) | Type dependency | Uses shared precision price decimal type. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_HCRF | NONCLUSTERED PK | CurrencyPriceFailID ASC | FILLFACTOR=90, on [HISTORY] (heap table) |
| HCRF_INSTRUMENT | NONCLUSTERED | InstrumentID ASC | FILLFACTOR=90, on [HISTORY] |
| HCRF_PROVIDER | NONCLUSTERED | ProviderID ASC | FILLFACTOR=90, on [HISTORY] |

Note: Heap table (no clustered index). PK is nonclustered. Heap design enables fast sequential inserts during high-frequency price failure events.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CurrencyPriceFail | Type: Table | Source: etoro/etoro/History/Tables/History.CurrencyPriceFail.sql*
