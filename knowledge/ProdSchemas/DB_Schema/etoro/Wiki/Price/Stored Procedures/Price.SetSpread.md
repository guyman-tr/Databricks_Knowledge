# Price.SetSpread

> Writes the current bid and ask spread prices for a specific instrument and feed into Trade.InstrumentSpread, acting as the real-time price update entry point for the pricing engine.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Trade.InstrumentSpread WHERE InstrumentID AND FeedID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetSpread is the direct write interface for updating the live bid/ask spread values on Trade.InstrumentSpread. When the pricing engine or a price feed produces a new price tick for an instrument, this procedure is called to persist that tick to the database. The InstrumentSpread table is the canonical store for the current market-facing bid and ask prices; SetSpread is the sole mechanism that updates it.

Without this procedure, real-time price data from feeds would not reach Trade.InstrumentSpread. Any system reading live instrument prices from that table would see stale data. The procedure is intentionally minimal - just a parameterized UPDATE - for performance reasons: it is expected to be called at high frequency as ticks arrive.

The @FeedID parameter (default=1) allows targeting a specific price feed lane. Feed 1 is the standard production feed. Multiple feeds can coexist per instrument in InstrumentSpread, and SetSpread updates only the specified feed's row, leaving other feeds untouched.

---

## 2. Business Logic

### 2.1 Single-Row Targeted UPDATE

**What**: Updates exactly the row matching (InstrumentID, FeedID) in Trade.InstrumentSpread with new Bid and Ask values.

**Columns/Parameters Involved**: `@InstrumentID`, `@Bid`, `@Ask`, `@FeedID`

**Rules**:
- UPDATE is by exact (InstrumentID, FeedID) match - does not insert if the row is missing (no UPSERT)
- If no matching row exists in InstrumentSpread, the UPDATE silently affects 0 rows (no error raised)
- @FeedID defaults to 1 - callers omitting this parameter always target the primary feed
- Bid/Ask are DECIMAL(10,4) matching the InstrumentSpread column types
- No return value - fire-and-forget update pattern

**Diagram**:
```
Caller (pricing engine / feed handler)
   |
   v
Price.SetSpread(@InstrumentID, @Bid, @Ask, @FeedID=1)
   |
   v
Trade.InstrumentSpread
  UPDATE Bid = @Bid, Ask = @Ask
  WHERE InstrumentID = @InstrumentID AND FeedID = @FeedID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument to update. Must match an existing InstrumentID + FeedID combination in Trade.InstrumentSpread. If no matching row exists, the UPDATE silently does nothing. |
| 2 | @Bid | DECIMAL(10,4) | NOT NULL | - | CODE-BACKED | The new bid (sell) price for this instrument on this feed. Written directly to Trade.InstrumentSpread.Bid. |
| 3 | @Ask | DECIMAL(10,4) | NOT NULL | - | CODE-BACKED | The new ask (buy) price for this instrument on this feed. Written directly to Trade.InstrumentSpread.Ask. |
| 4 | @FeedID | SMALLINT | NOT NULL | 1 | CODE-BACKED | The price feed lane to update. Default=1 (primary production feed). Allows targeting alternative feed rows (e.g., benchmark feeds) without affecting the primary feed row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID + @FeedID | Trade.InstrumentSpread | MODIFIER | Updates Bid and Ask for the matching row |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. This procedure is called externally by the pricing engine or feed processing service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetSpread (procedure)
└── Trade.InstrumentSpread (table - target of UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentSpread | Table | UPDATE target - writes Bid and Ask for (InstrumentID, FeedID) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by external pricing engine services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No error is raised if the target row does not exist (silent no-op UPDATE).

---

## 8. Sample Queries

### 8.1 Set spread for EUR/USD on the primary feed

```sql
EXEC Price.SetSpread
    @InstrumentID = 1,
    @Bid = 1.0851,
    @Ask = 1.0853,
    @FeedID = 1;
```

### 8.2 Set spread on a secondary feed (FeedID=2)

```sql
EXEC Price.SetSpread
    @InstrumentID = 1,
    @Bid = 1.0850,
    @Ask = 1.0854,
    @FeedID = 2;
```

### 8.3 Verify the updated spread in Trade.InstrumentSpread

```sql
SELECT InstrumentID, FeedID, Bid, Ask
FROM Trade.InstrumentSpread WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY FeedID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetSpread | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetSpread.sql*
