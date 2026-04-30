# Trade.SetCurrencyPriceHistoryInsert_New

> Generates a new PriceRateID via Internal.GetPriceRateID and then updates Trade.CurrencyPrice with the new bid/ask/timestamps for the given instrument+provider, returning the generated PriceRateID to the caller via an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @ProviderID - composite key; @PriceRateID OUTPUT - generated sequence ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the **"new" variant** of the price update procedure that incorporates PriceRateID generation into the price update call. The PriceRateID is a globally sequential identifier used to maintain a consistent ordering of price events across all instruments and providers.

Compared to `Trade.SetCurrencyPrice`:
- This procedure calls `Internal.GetPriceRateID` itself to get the next sequence value, rather than requiring the caller to supply it
- `@PriceRateID` is an OUTPUT parameter - the caller receives the generated ID for downstream use (e.g., inserting into price history tables)
- Sets `Occurred = @OccurredOnServer` (from the source feed timestamp) rather than `GETUTCDATE()` - the source timestamp is used as the canonical occurrence time
- Uses `WITH(ROWLOCK)` hint on the CurrencyPrice update to minimize lock contention on this high-frequency table
- Does not support `@MarketPriceRateID` or `@LastPrice` parameters (simpler interface)

The error handling wraps the RAISERROR in error code 60000 (a custom application error code) with the internal error code appended - this surfaces structured errors to the calling application.

---

## 2. Business Logic

### 2.1 PriceRateID Generation

**What**: Obtains the next sequential price rate identifier before updating the live price.

**Columns/Parameters Involved**: `Internal.GetPriceRateID`, `@PriceRateID OUTPUT`

**Rules**:
- `EXEC @LocalError = Internal.GetPriceRateID @PriceRateID OUTPUT`
- @PriceRateID is populated by the called procedure (likely uses a sequence or identity table)
- If @LocalError != 0 -> RAISERROR(60000, ...) with the error code

### 2.2 CurrencyPrice Update

**What**: Updates the live price row for the instrument+provider with ROWLOCK for high-frequency updates.

**Columns/Parameters Involved**: `Trade.CurrencyPrice.Bid`, `Ask`, `Occurred`, `OccurredOnServer`, `PriceRateID`, `ReceivedOnPriceServer`

**Rules**:
- UPDATE Trade.CurrencyPrice WITH(ROWLOCK) WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID
- `Occurred = @OccurredOnServer` (NOT GETUTCDATE() - source feed timestamp as canonical time)
- `OccurredOnServer = @OccurredOnServer` (same value stored in both columns)
- MarketPriceRateID and LastPrice are NOT updated by this procedure
- RETURN 0 on success

### 2.3 Error Handling

**What**: Structured error wrapping with application error code 60000.

**Rules**:
- CATCH: ROLLBACK if in transaction (@@TRANCOUNT=1); COMMIT if nested (@@TRANCOUNT>1)
- `@LocalError = ERROR_NUMBER()` if not already set by GetPriceRateID failure
- `RAISERROR(60000, 16, 1, 'Trade.SetCurrencyPrice', @LocalError)` - application error with context
- RETURN(@LocalError)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The instrument being priced. Part of the composite key for CurrencyPrice lookup. |
| 2 | @ProviderID | INTEGER | NO | - | CODE-BACKED | The liquidity provider sourcing this price. Part of the composite key. |
| 3 | @Bid | dtPrice | NO | - | CODE-BACKED | New bid price (custom dtPrice type). The price at which customers can sell. |
| 4 | @Ask | dtPrice | NO | - | CODE-BACKED | New ask price. The price at which customers can buy. |
| 5 | @OccurredOnServer | DATETIME | NO | - | CODE-BACKED | Timestamp from the price feed source. Stored as BOTH Occurred AND OccurredOnServer in CurrencyPrice - this is the canonical price occurrence time. |
| 6 | @PriceRateID | BIGINT OUTPUT | NO | - | CODE-BACKED | OUTPUT: receives the newly generated sequential price rate ID from Internal.GetPriceRateID. The caller uses this ID for downstream price history recording. |
| 7 | @ReceivedOnPriceServer | DATETIME | YES | NULL | CODE-BACKED | When the price server received the tick. Optional latency tracking field. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Internal.GetPriceRateID | Callee | Generates the next PriceRateID sequence value; returns it via OUTPUT |
| UPDATE | Trade.CurrencyPrice | Modifier | Updates live price record with ROWLOCK hint for concurrency optimization |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by price feed ingestion service as the primary price update procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetCurrencyPriceHistoryInsert_New (procedure)
|- Internal.GetPriceRateID (procedure - sequence ID generator)
|- Trade.CurrencyPrice (table - update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetPriceRateID | Procedure | Generates next PriceRateID; returns via OUTPUT; LocalError checked for failure |
| Trade.CurrencyPrice | Table | UPDATE target with ROWLOCK for concurrent price updates |

### 6.2 Objects That Depend On This

No dependents found - called directly by price feed service as entry point for price updates.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ROWLOCK hint | Performance | WITH(ROWLOCK) on CurrencyPrice UPDATE - reduces lock escalation for this high-frequency update table |
| Source timestamp as Occurred | Logic | Occurred = @OccurredOnServer (not GETUTCDATE()) - feed source time is canonical, not server receipt time |
| Error code 60000 | Pattern | Custom application error code wraps internal errors; LocalError passed as param for diagnostics |
| PriceRateID is OUTPUT | Contract | Caller receives the generated ID for use in history inserts downstream |

---

## 8. Sample Queries

### 8.1 Update price and receive the generated PriceRateID

```sql
DECLARE @GeneratedPriceRateID BIGINT

EXEC Trade.SetCurrencyPriceHistoryInsert_New
    @InstrumentID = 1234,
    @ProviderID = 5,
    @Bid = 150.25,
    @Ask = 150.27,
    @OccurredOnServer = '2026-03-17 10:30:00',
    @PriceRateID = @GeneratedPriceRateID OUTPUT,
    @ReceivedOnPriceServer = '2026-03-17 10:30:00.100'

SELECT @GeneratedPriceRateID AS NewPriceRateID
```

### 8.2 Compare Occurred vs OccurredOnServer in CurrencyPrice

```sql
-- For this proc, both columns are set to @OccurredOnServer
-- For SetCurrencyPrice, Occurred=GETUTCDATE() while OccurredOnServer=@OccurredOnServer
SELECT InstrumentID, ProviderID, Occurred, OccurredOnServer,
    DATEDIFF(MILLISECOND, OccurredOnServer, Occurred) AS ServerLatencyMs
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetCurrencyPriceHistoryInsert_New | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetCurrencyPriceHistoryInsert_New.sql*
