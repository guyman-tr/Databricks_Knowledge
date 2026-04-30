# History.CurrencyPriceQueue

> Price feed processing queue - receives incoming price ticks from liquidity providers and holds them until processed by History.CurrencyPriceQueue_Process; currently empty (all prices processed).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID - bigint IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=90) |

---

## 1. Business Meaning

History.CurrencyPriceQueue is the incoming price tick processing queue. Price ticks arrive from liquidity providers (ProviderID) for specific instruments (InstrumentID) and are inserted here. The stored procedure History.CurrencyPriceQueue_Process reads from this queue, validates prices, applies splits, applies spreads, and writes the result to History.CurrencyPriceMaxDateWithSplitView.

History.CurrencyPriceQueueMaxID (singleton) tracks the maximum ID processed so the processing SP knows where to resume.

0 rows - all queued prices have been processed. The queue operates as a transient staging area.

The table uses `dbo.dtPrice` UDT for Bid and Ask values - a precision decimal type shared across all price tables.

---

## 2. Business Logic

### 2.1 Queue Processing Flow

```
Liquidity Provider -> INSERT into History.CurrencyPriceQueue
                   -> History.CurrencyPriceQueue_Process reads rows WHERE ID > MaxID
                   -> Validates, applies splits, applies spreads
                   -> Updates History.CurrencyPriceMaxDateWithSplitView
                   -> Updates History.CurrencyPriceQueueMaxID
                   -> History.CurrencyPriceQueue_CleanUp deletes processed rows
```

### 2.2 QueueStatus Values

| Value | Meaning |
|-------|---------|
| NULL | Unprocessed - waiting in queue |
| Other | Processing state (values not directly observed - queue is empty) |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 (queue empty - all processed) |
| **Max Processed ID** | 133,739,690 (from History.CurrencyPriceQueueMaxID) |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | bigint IDENTITY | NO | Auto-incremented queue entry ID. PK. Max processed: 133,739,690. |
| 2 | ProviderID | int | YES | Liquidity provider that sent this price tick. |
| 3 | InstrumentID | int | YES | Instrument this price is for. |
| 4 | OccurredOnServer | datetime | YES | Timestamp when the price was generated at the provider. |
| 5 | Bid | dbo.dtPrice | YES | Market bid price. Uses dbo.dtPrice precision decimal UDT. |
| 6 | Ask | dbo.dtPrice | YES | Market ask price. Uses dbo.dtPrice precision decimal UDT. |
| 7 | Occurred | datetime | YES | Timestamp when the tick arrived locally. |
| 8 | PriceRateID | bigint | YES | Price rate record ID for cross-reference with the price feed system. |
| 9 | ReceivedOnPriceServer | datetime | YES | Timestamp when the price server received this tick. |
| 10 | QueueStatus | tinyint | YES | Processing state: NULL=unprocessed; other values indicate processing stages. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Bid, Ask | dbo.dtPrice (UDT) | Type dependency | Shared price decimal type. |

### 5.2 Referenced By

| Source | How Used |
|--------|---------|
| History.CurrencyPriceQueue_Process | Reader/Writer - reads queue, processes prices |
| History.CurrencyPriceQueue_CleanUp | Deletes processed rows |
| History.CurrencyPriceQueueMaxID | Tracks max ID processed from this queue |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_CurrencyPriceQueue | CLUSTERED PK | ID ASC | FILLFACTOR=90 |

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.CurrencyPriceQueue | Type: Table | Source: etoro/etoro/History/Tables/History.CurrencyPriceQueue.sql*
