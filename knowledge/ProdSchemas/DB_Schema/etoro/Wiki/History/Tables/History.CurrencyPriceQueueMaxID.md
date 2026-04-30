# History.CurrencyPriceQueueMaxID

> Singleton checkpoint table holding the maximum ID processed from History.CurrencyPriceQueue - one row, currently MaxID=133,739,690.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK, no index - singleton table |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | None |

---

## 1. Business Meaning

History.CurrencyPriceQueueMaxID is a singleton checkpoint table with exactly 1 row. It stores the maximum ID that History.CurrencyPriceQueue_Process has successfully processed from History.CurrencyPriceQueue.

Current value: MaxID = 133,739,690 (meaning 133.7M price ticks have been processed through the queue over the system's lifetime).

This pattern (a single-row table storing a watermark ID) enables the processing stored procedure to resume from where it left off without scanning the entire queue. The SP reads `MaxID`, processes all rows in CurrencyPriceQueue with `ID > MaxID`, then updates `MaxID` to the last processed ID.

---

## 2. Business Logic

### 2.1 Queue Processing Watermark

**What**: Tracks the last processed queue entry ID for the price queue processor.

**Usage by History.CurrencyPriceQueue_Process**:
1. Read MaxID from this table
2. SELECT from History.CurrencyPriceQueue WHERE ID > MaxID
3. Process the new price ticks
4. UPDATE this table SET MaxID = (highest processed ID)

This pattern ensures idempotent processing (can restart without reprocessing) and avoids full table scans on CurrencyPriceQueue.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 1 (singleton) |
| **MaxID** | 133,739,690 |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MaxID | bigint | YES | The ID of the last successfully processed row in History.CurrencyPriceQueue. Singleton value. Currently 133,739,690. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MaxID | History.CurrencyPriceQueue.ID | Logical watermark | Tracks the processing frontier in the price queue. |

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CurrencyPriceQueueMaxID | Type: Table | Source: etoro/etoro/History/Tables/History.CurrencyPriceQueueMaxID.sql*
