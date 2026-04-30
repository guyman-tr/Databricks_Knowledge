# Price.SetActiveSkew

> Upserts the active skew values for an instrument+feed in Price.ActiveSkew, then cascades to Trade.InstrumentSpread by setting the effective bid/ask as skew + reference spread - the primary write path for the price skew algorithm's output.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @FeedID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetActiveSkew is the skew algorithm's write procedure. When the pricing engine calculates a new skew level for an instrument (in response to buy/sell client flow imbalances), it calls this procedure to:

1. **Record the active skew** in `Price.ActiveSkew`: stores the current SkewBid and SkewAsk offsets that are being applied to this instrument's prices for this feed
2. **Update the effective spread** in `Trade.InstrumentSpread`: computes the total bid/ask as `skew + reference`, writing the live spread values that the pricing engine distributes to clients

The reference spread (ReferenceBid, ReferenceAsk in Trade.InstrumentSpread) is the baseline spread set by configuration. The skew values are dynamic adjustments on top of it. The formula `Bid = @Bid + ReferenceBid` ensures the effective price always reflects both the configured baseline and the current skew direction.

Price skewing is a risk management technique: when many clients hold long positions (net buy), the pricing engine shifts prices upward (positive skew) to make buying slightly less attractive and reduce the firm's net exposure. SetActiveSkew is called on each skew recalculation cycle.

The @SkewID uniqueidentifier parameter provides a correlation/trace ID for the skew event - allowing the audit history to link this skew update to the underlying skew calculation event that triggered it.

---

## 2. Business Logic

### 2.1 Upsert Price.ActiveSkew (UPDATE then INSERT if new)

**What**: UPDATE-first, INSERT-if-no-row-matched pattern for ActiveSkew.

**Columns/Parameters Involved**: `@InstrumentID`, `@FeedID`, `@Bid`, `@Ask`, `@SkewID`

**Rules**:
- `UPDATE Price.ActiveSkew SET SkewBid=@Bid, SkewAsk=@Ask, SkewID=@SkewID WHERE InstrumentID=@InstrumentID AND FeedID=@FeedID`
- `IF @@ROWCOUNT = 0`: no row was updated (new instrument/feed combination) -> `INSERT INTO Price.ActiveSkew (InstrumentID, FeedID, SkewBid, SkewAsk, SkewID) VALUES (@InstrumentID, @FeedID, @Bid, @Ask, @SkewID)`
- @FeedID defaults to 1 (the standard feed)
- @SkewID defaults to NULL (optional correlation ID)
- Skew values: positive = push prices up (reduces client buy appetite), negative = push prices down. Zero = no skew.

### 2.2 Cascade to Trade.InstrumentSpread

**What**: The effective bid/ask in Trade.InstrumentSpread is updated to reflect the new skew level.

**Columns/Parameters Involved**: `@Bid`, `@Ask`, `Trade.InstrumentSpread.ReferenceBid`, `Trade.InstrumentSpread.ReferenceAsk`

**Rules**:
- `UPDATE Trade.InstrumentSpread SET Bid = @Bid + ReferenceBid, Ask = @Ask + ReferenceAsk WHERE InstrumentID = @InstrumentID AND FeedID = @FeedID`
- `ReferenceBid` and `ReferenceAsk` are the baseline spread values (configured baseline, not including skew)
- `Bid` and `Ask` in InstrumentSpread are the effective/live spread values used by the pricing engine
- This UPDATE does NOT use @@ROWCOUNT - if no InstrumentSpread row exists for this InstrumentID+FeedID, the UPDATE silently does nothing (no INSERT fallback for InstrumentSpread - the row must be pre-created by InsertPricingConfiguration)

### 2.3 No Transaction Wrapping

**What**: Three DML statements are executed without an explicit transaction.

**Rules**:
- ActiveSkew UPDATE + ActiveSkew INSERT (conditional) + InstrumentSpread UPDATE run as separate implicit transactions
- A failure in the InstrumentSpread UPDATE would leave ActiveSkew updated but InstrumentSpread stale
- Accepted risk: skew updates are frequent and idempotent; the next skew recalculation will re-apply the correct values. Transactional atomicity is not required for this real-time pricing update path.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument to set skew for. Must exist in Price.ActiveSkew (or will be inserted) and should exist in Trade.InstrumentSpread (InstrumentSpread UPDATE does nothing if missing). |
| 2 | @Bid | DECIMAL(10,4) | NOT NULL | - | CODE-BACKED | Bid skew offset in price units (4 decimal places). Positive = raise bid price; negative = lower bid price; 0 = no skew. Added to ReferenceBid in InstrumentSpread. |
| 3 | @Ask | DECIMAL(10,4) | NOT NULL | - | CODE-BACKED | Ask skew offset in price units (4 decimal places). Positive = raise ask price; negative = lower ask price; 0 = no skew. Added to ReferenceAsk in InstrumentSpread. |
| 4 | @FeedID | SMALLINT | NOT NULL | 1 | CODE-BACKED | Feed identifier. Default 1 = primary/standard feed. Allows different skew values per feed for the same instrument. Matched against both Price.ActiveSkew.FeedID and Trade.InstrumentSpread.FeedID. |
| 5 | @SkewID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation/trace ID for this skew event. Stored in Price.ActiveSkew.SkewID. Links the stored skew value to the skew calculation event that generated it. NULL if not provided. |

**Result set**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID + @FeedID | Price.ActiveSkew | WRITER (UPSERT) | Records current active skew values - UPDATE existing or INSERT new |
| @InstrumentID + @FeedID | Trade.InstrumentSpread | WRITER (UPDATE) | Updates effective bid/ask as skew + reference spread |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (price skew algorithm / pricing engine) | @InstrumentID, @Bid, @Ask | CALLER | Called on each skew recalculation cycle to persist the new skew level |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetActiveSkew (procedure)
+-- Price.ActiveSkew (table) - UPSERT target (active skew store)
+-- Trade.InstrumentSpread (table) - UPDATE target (effective bid/ask)
    +-- (ReferenceBid, ReferenceAsk from InsertPricingConfiguration)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.ActiveSkew | Table | UPSERT: UPDATE existing SkewBid/SkewAsk/SkewID, or INSERT if first time for this InstrumentID+FeedID |
| Trade.InstrumentSpread | Table | UPDATE: sets Bid=@Bid+ReferenceBid, Ask=@Ask+ReferenceAsk for the instrument+feed |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing engine / skew algorithm) | External | Calls on each skew recalculation to persist and propagate new skew values |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON (returns row counts from UPDATE/INSERT). No explicit transaction (three separate implicit transactions). No error handling. No NOLOCK on writes (correct - writes need proper lock acquisition). The InstrumentSpread UPDATE silently no-ops if no row exists for the given InstrumentID+FeedID (no INSERT fallback). InstrumentSpread rows are pre-created by Price.InsertPricingConfiguration (SpreadTypeID=1, FeedID=1, all zeros). @@ROWCOUNT check is performed immediately after the first UPDATE (before any other statement), ensuring it correctly reflects the UPDATE row count. The SkewID correlation ID enables tracing which skew model evaluation triggered this specific ActiveSkew update.

---

## 8. Sample Queries

### 8.1 Set active skew for an instrument

```sql
EXEC Price.SetActiveSkew
    @InstrumentID = 1,
    @Bid = 0.0020,        -- 2 pip bid skew upward
    @Ask = -0.0010,       -- 1 pip ask skew downward
    @FeedID = 1,
    @SkewID = NEWID();
```

### 8.2 Clear skew (zero out)

```sql
EXEC Price.SetActiveSkew
    @InstrumentID = 1,
    @Bid = 0.0000,
    @Ask = 0.0000,
    @FeedID = 1;
-- Resets spread to baseline: Bid=ReferenceBid, Ask=ReferenceAsk
```

### 8.3 Check current active skew and effective spread

```sql
SELECT
    sk.InstrumentID,
    sk.FeedID,
    sk.SkewBid,
    sk.SkewAsk,
    isp.ReferenceBid,
    isp.ReferenceAsk,
    isp.Bid AS EffectiveBid,
    isp.Ask AS EffectiveAsk
FROM Price.ActiveSkew sk WITH (NOLOCK)
JOIN Trade.InstrumentSpread isp WITH (NOLOCK)
    ON sk.InstrumentID = isp.InstrumentID
    AND sk.FeedID = isp.FeedID
WHERE sk.InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetActiveSkew | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetActiveSkew.sql*
