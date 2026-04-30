# Price.SkewModelValue

> Runtime state table that stores the most recently computed bid and ask skew values per instrument from the active skew algorithm, acting as the current skew output cache for the pricing engine.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (ModelId, InstrumentID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

SkewModelValue is the output cache for the skew algorithm computations. After the SkewModelService runs its skew algorithm (BuyRatio or PriceAlgo), it writes the computed bid skew and ask skew values for each instrument into this table. The pricing engine (or `Price.ActiveSkew`) then reads these values to apply the skew to bid and ask prices.

Unlike most Price configuration tables, SkewModelValue is a **runtime state table** - it is continuously written to as skew values change, and the `Date` column tracks when each value was last computed (default: getdate(), updated on each UPSERT).

The write pattern is an UPSERT via `Price.UpsertSkewModelValue`:
- INSERT if InstrumentID not yet present
- UPDATE Bid, Ask, ModelId, and Date if InstrumentID already exists

Key observations:
- The upsert checks existence by InstrumentID only (not by ModelId+InstrumentID which is the PK) - this means each instrument has exactly one row regardless of which model computed it, and the ModelId in the row reflects the most recent computation
- The `Bid` and `Ask` columns are nullable decimal(10,4), allowing NULL for instruments with no active skew
- No temporal versioning - only the latest value is kept here (historical skew values are not retained in the DB)
- ModelId (note: lowercase 'd', unlike ModelID in other tables) FK -> Price.SkewModels

The table currently has 0 rows (consistent with InstrumentSkewModel also being empty - no instruments have been assigned to skew models yet).

---

## 2. Business Logic

### 2.1 Skew Value Upsert

**What**: The SkewModelService writes computed skew values to this table using an UPSERT pattern keyed on InstrumentID.

**Columns/Parameters Involved**: `InstrumentID`, `ModelId`, `Bid`, `Ask`, `Date`

**Rules**:
- `Price.UpsertSkewModelValue(@InstrumentID, @Bid, @Ask, @ModelId)`:
  - IF NOT EXISTS (by InstrumentID): INSERT (InstrumentID, Bid, Ask, ModelId)
  - ELSE: UPDATE SET Bid=@Bid, Ask=@Ask, ModelId=@ModelId, Date=GETDATE()
- The upsert key is InstrumentID alone (not the composite PK) - effectively one value row per instrument
- Date is always updated to the current timestamp on each write via GETDATE()
- Bid/Ask are nullable - NULL means the model did not produce a skew value for this instrument

### 2.2 Skew Values as Additive Price Adjustments

**What**: Bid and Ask skew values are added to the instrument's reference prices in the spread computation.

**Columns/Parameters Involved**: `Bid`, `Ask`

**Rules**:
- In `Price.GetSpreadConfigurationFeed` (for `Price.ActiveSkew`): `ReferenceBid + ISNULL(SkewBid, 0) AS Bid`, `ReferenceAsk + ISNULL(SkewAsk, 0) AS Ask`
- Positive Bid skew: narrows the bid-ask spread from below (raises bid)
- Positive Ask skew: widens the spread from above (raises ask)
- ISNULL(Skew, 0): NULL skew is treated as 0 (no adjustment)

---

## 3. Data Overview

The table is currently empty (0 rows). No skew model values have been computed.

*When populated, rows would appear as:*

| ModelId | InstrumentID | Bid | Ask | Date |
|---|---|---|---|---|
| 1 (BuyRatio) | 1 (EUR/USD) | -0.0002 | 0.0003 | 2026-03-18 12:00:01 |
| 1 (BuyRatio) | 5 | 0.0000 | 0.0001 | 2026-03-18 12:00:01 |
| 2 (PriceAlgo) | 100 | 0.0500 | 0.0500 | 2026-03-18 12:00:01 |

Negative bid skew moves bid down (widens spread from buy side). Positive ask skew moves ask up (widens spread from sell side).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelId | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. FK to Price.SkewModels (note: lowercase 'd' inconsistency vs ModelID elsewhere). The skew algorithm that produced this value: 1=BuyRatio, 2=PriceAlgo. Updated on each UPSERT call. (Price.SkewModels) |
| 2 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. The instrument for which this skew value applies. Despite being PK part 2, the UPSERT logic treats InstrumentID as the sole uniqueness key (checks existence by InstrumentID only). |
| 3 | Bid | decimal(10,4) | YES | - | VERIFIED | The computed bid skew adjustment value. Added to ReferenceBid in the spread computation. NULL means no bid skew (treated as 0 in ISNULL). Negative value narrows bid, positive widens. |
| 4 | Ask | decimal(10,4) | YES | - | VERIFIED | The computed ask skew adjustment value. Added to ReferenceAsk in the spread computation. NULL means no ask skew. Positive value widens ask. |
| 5 | Date | datetime | NOT NULL | getdate() | VERIFIED | Timestamp of when this skew value was last computed and written. Updated to GETDATE() on every UPSERT. Used to detect stale skew values - if Date is significantly in the past, the skew service may not be running. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ModelId | Price.SkewModels | FK (unnamed) | The algorithm that produced this skew value |
| InstrumentID | Trade.Instrument | Logical (no FK) | The instrument this skew value applies to; no DB-level FK constraint |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.UpsertSkewModelValue | InstrumentID, ModelId | WRITER (UPSERT) | Writes computed skew values from SkewModelService |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SkewModelValue (table)
|- Price.SkewModels (table, FK target: ModelId=1 BuyRatio, ModelId=2 PriceAlgo)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.SkewModels | Table | FK target - ModelId must reference a registered skew algorithm |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.UpsertSkewModelValue | Stored Procedure | WRITER - upserts computed skew values by InstrumentID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_SkewModelValue | CLUSTERED PK | ModelId ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Price_SkewModelValue | PRIMARY KEY | Composite PK (ModelId, InstrumentID) |
| FK (unnamed) | FK | ModelId -> Price.SkewModels(ModelID) |
| DF_PriceSkewModelValue_Date | DEFAULT | Date = getdate() |

No temporal versioning, no computed columns, no audit triggers.

---

## 8. Sample Queries

### 8.1 View current skew values with model names

```sql
SELECT
    SMV.ModelId,
    SM.Name AS ModelName,
    SMV.InstrumentID,
    SMV.Bid AS SkewBid,
    SMV.Ask AS SkewAsk,
    SMV.Date AS LastComputed
FROM Price.SkewModelValue SMV WITH (NOLOCK)
JOIN Price.SkewModels SM WITH (NOLOCK)
    ON SM.ModelID = SMV.ModelId
ORDER BY SMV.ModelId, SMV.InstrumentID;
```

### 8.2 Find stale skew values (not updated in last 5 minutes)

```sql
SELECT
    InstrumentID,
    ModelId,
    Bid,
    Ask,
    Date,
    DATEDIFF(MINUTE, Date, GETDATE()) AS MinutesSinceUpdate
FROM Price.SkewModelValue WITH (NOLOCK)
WHERE Date < DATEADD(MINUTE, -5, GETDATE())
ORDER BY Date ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SkewModelValue | Type: Table | Source: etoro/etoro/Price/Tables/Price.SkewModelValue.sql*
