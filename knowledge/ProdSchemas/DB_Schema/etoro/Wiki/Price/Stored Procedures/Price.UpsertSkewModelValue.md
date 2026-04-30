# Price.UpsertSkewModelValue

> Inserts or updates the computed bid/ask skew values for a specific instrument in Price.SkewModelValue, acting as the write endpoint for the SkewModelService to persist freshly-computed skew output.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT on Price.SkewModelValue WHERE InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpsertSkewModelValue is the write interface for persisting skew algorithm output to the database. The SkewModelService computes bid and ask skew adjustment values for each instrument based on the active skew model (BuyRatio or PriceAlgo), and calls this procedure to record the result. The skew values are additive adjustments applied to reference prices by the spread computation: a positive ask skew widens the ask spread; a negative bid skew narrows the bid from below.

The procedure uses a classic UPSERT pattern: if no row exists for the given InstrumentID in `Price.SkewModelValue`, it inserts a new row; if a row already exists, it updates Bid, Ask, ModelId, and sets Date to the current timestamp. The existence check is by InstrumentID only (not by the composite PK of ModelId+InstrumentID), meaning each instrument has at most one active skew row regardless of which model produced it - the ModelId in the row reflects the most recent computation.

The `Date` column in SkewModelValue acts as a staleness indicator: if a skew value has not been refreshed recently, it may indicate the SkewModelService has stopped running, and the pricing engine should treat the skew as potentially stale.

---

## 2. Business Logic

### 2.1 UPSERT by InstrumentID

**What**: Checks if a skew row exists for the InstrumentID. Inserts if new; updates if existing.

**Columns/Parameters Involved**: `@InstrumentID`, `@Bid`, `@Ask`, `@ModelId`

**Rules**:
- IF NOT EXISTS (SELECT InstrumentID FROM Price.SkewModelValue WHERE InstrumentID=@InstrumentID):
  - INSERT (InstrumentID, Bid, Ask, ModelId) VALUES (@InstrumentID, @Bid, @Ask, @ModelId)
  - Date is set by DEFAULT constraint (getdate()) on the table
- ELSE:
  - UPDATE Price.SkewModelValue SET Bid=@Bid, Ask=@Ask, ModelId=@ModelId, Date=GETDATE() WHERE InstrumentID=@InstrumentID
  - Date is explicitly set to GETDATE() on every update
- Upsert key is InstrumentID only - ModelId changes between runs (algorithm can switch from BuyRatio to PriceAlgo without creating a new row)
- No return value - fire-and-forget write pattern

**Skew value semantics** (inherited from Price.SkewModelValue doc):
- Bid/Ask are DECIMAL(10,4) adjustments added to ReferenceBid/ReferenceAsk in the spread computation
- ISNULL(SkewBid, 0) in consumers means NULL skew = no adjustment (treated as 0)
- Positive Ask skew: raises ask price (widens spread from above)
- Negative Bid skew: lowers bid (widens spread from below)

**Diagram**:
```
First call for InstrumentID=100 (no row exists):
  INSERT: SkewModelValue(InstrumentID=100, Bid=-0.0002, Ask=0.0003, ModelId=1, Date=getdate())

Subsequent call for InstrumentID=100 (row exists):
  UPDATE: SET Bid=-0.0001, Ask=0.0002, ModelId=1, Date=GETDATE()
  (Previous skew value overwritten; no history retained)
```

### 2.2 Staleness Detection via Date Column

**What**: The Date column is updated on every write, enabling detection of skew service outages.

**Columns/Parameters Involved**: `Date`

**Rules**:
- INSERT: Date set by DEFAULT (getdate())
- UPDATE: Date explicitly set to GETDATE()
- If Date is significantly in the past (e.g., > 5 minutes), the SkewModelService may not be running
- No versioning - only the most recent skew value is retained

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument for which the skew value is being written. Used as the upsert existence key (not the composite PK - the procedure checks by InstrumentID only). Each instrument has at most one active row in SkewModelValue. |
| 2 | @Bid | DECIMAL(5,4) | NOT NULL | - | CODE-BACKED | The computed bid skew adjustment. Additive offset applied to the reference bid price in spread computation. Positive raises bid, negative lowers it. DECIMAL(5,4) allows values from -9.9999 to 9.9999. |
| 3 | @Ask | DECIMAL(5,4) | NOT NULL | - | CODE-BACKED | The computed ask skew adjustment. Additive offset applied to the reference ask price. Positive raises ask (widens spread from above). |
| 4 | @ModelId | INT | NOT NULL | - | CODE-BACKED | The skew model that produced this computed value. FK to Price.SkewModels: 1=BuyRatio, 2=PriceAlgo. Written to SkewModelValue.ModelId and updated on every write, tracking which algorithm produced the most recent skew. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.SkewModelValue | WRITER (UPSERT) | Inserts new row or updates Bid, Ask, ModelId, Date for existing InstrumentID row |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the SkewModelService when new skew computations are produced.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpsertSkewModelValue (procedure)
└── Price.SkewModelValue (table - UPSERT target)
      └── Price.SkewModels (table, FK target for ModelId)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.SkewModelValue | Table | UPSERT target - INSERT or UPDATE depending on InstrumentID existence |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by external SkewModelService.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Upsert key mismatch | Design note | Composite PK on SkewModelValue is (ModelId, InstrumentID), but the upsert checks only InstrumentID. This means one skew row per instrument regardless of ModelId - a model switch doesn't create a new row. |
| No return value | Pattern | Fire-and-forget - caller does not receive confirmation of what was written |
| No transaction | Design | No explicit BEGIN TRANSACTION - the single DML statement is inherently atomic |
| Date precision | Note | INSERT uses DEFAULT getdate(); UPDATE uses explicit GETDATE(). Both resolve to the same function. |

---

## 8. Sample Queries

### 8.1 Upsert a skew value for an instrument

```sql
EXEC Price.UpsertSkewModelValue
    @InstrumentID = 1,
    @Bid = -0.0002,
    @Ask = 0.0003,
    @ModelId = 1;  -- 1 = BuyRatio model
```

### 8.2 Verify the written skew value

```sql
SELECT
    SMV.InstrumentID,
    SM.Name AS ModelName,
    SMV.Bid AS SkewBid,
    SMV.Ask AS SkewAsk,
    SMV.Date AS LastComputed,
    DATEDIFF(SECOND, SMV.Date, GETDATE()) AS SecondsSinceUpdate
FROM Price.SkewModelValue SMV WITH (NOLOCK)
JOIN Price.SkewModels SM WITH (NOLOCK)
    ON SM.ModelID = SMV.ModelId
WHERE SMV.InstrumentID = 1;
```

### 8.3 Find stale skew values (service may be down if Date is old)

```sql
SELECT
    SMV.InstrumentID,
    SMV.ModelId,
    SMV.Bid,
    SMV.Ask,
    SMV.Date,
    DATEDIFF(MINUTE, SMV.Date, GETDATE()) AS MinutesSinceUpdate
FROM Price.SkewModelValue SMV WITH (NOLOCK)
WHERE Date < DATEADD(MINUTE, -5, GETDATE())
ORDER BY Date ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpsertSkewModelValue | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpsertSkewModelValue.sql*
