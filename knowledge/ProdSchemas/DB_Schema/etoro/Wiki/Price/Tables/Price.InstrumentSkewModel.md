# Price.InstrumentSkewModel

> Per-instrument skew model assignment table that maps each instrument to the skew algorithm used to compute its price skew, with FeedID support for multi-feed instrument configurations.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, FeedID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

InstrumentSkewModel assigns a skew algorithm model to each instrument (or instrument+feed combination). The composite PK `(InstrumentID, FeedID)` allows the same instrument to use different skew models for different feed sources. FeedID defaults to 1.

The critical consumer is `Price.GetSpreadConfigurationFeed` (view), which uses this table to build the per-instrument spread configuration with skew applied:
- **First union branch**: instruments with `FeedID != 1` - reads InstrumentSkewModel with `ISM.FeedID != 1`, then LEFT JOINs `Price.ActiveSkew` on `(InstrumentID, FeedID)` to get the current skew bid/ask for that feed
- **Second union branch**: all instruments for FeedID=1 - LEFT JOINs ActiveSkew with FeedID=1

This means: InstrumentSkewModel's FeedID value determines which feed's skew output from Price.ActiveSkew is applied to the instrument's spread calculation. For most instruments (FeedID=1), skew comes from the primary ActiveSkew feed. Instruments with `FeedID != 1` get skew from a different feed source.

The table is currently empty (0 rows). It was provisioned with temporal versioning, FK constraints to both Trade.Instrument and Price.SkewModels, and the standard ASM no-op trigger.

---

## 2. Business Logic

### 2.1 Per-Instrument Skew Model and Feed Assignment

**What**: Assigns a skew algorithm and feed source to each instrument, controlling which skew model's output adjusts the spread.

**Columns/Parameters Involved**: `InstrumentID`, `ModelID`, `FeedID`

**Rules**:
- PK: (InstrumentID, FeedID) - one model per (instrument, feed source) combination
- ModelID FK -> Price.SkewModels: 1=BuyRatio, 2=PriceAlgo
- FeedID defaults to 1; FeedID != 1 means using an alternate feed's skew values
- Price.GetSpreadConfigurationFeed uses `ISM.FeedID != 1` in the first union - instruments assigned to non-primary feeds here get skew from those alternate feeds' ActiveSkew rows

### 2.2 Role in GetSpreadConfigurationFeed

**What**: The view computes bid/ask prices with skew applied; InstrumentSkewModel provides the FeedID needed to look up the correct ActiveSkew row.

**Rules**:
- INNER JOIN on `TI.InstrumentID = ISM.InstrumentID AND ISM.FeedID != 1` in the first union
- Then `LEFT JOIN Price.ActiveSkew PAS ON ISM.InstrumentID = PAS.InstrumentID AND PAS.FeedID = ISM.FeedID AND PAS.FeedID != 1`
- Output: `ReferenceBid + ISNULL(PAS.SkewBid, 0) AS Bid`, `ReferenceAsk + ISNULL(PAS.SkewAsk, 0) AS Ask`

---

## 3. Data Overview

The table is currently empty (0 rows). No instrument-to-skew-model assignments are configured.

*When populated, rows would appear as:*

| InstrumentID | ModelID | FeedID | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 1 (BuyRatio) | 1 | EUR/USD uses BuyRatio skew on the primary feed |
| 5 | 2 (PriceAlgo) | 2 | Instrument 5 uses PriceAlgo skew from feed 2 (alternate feed) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. FK to Trade.Instrument. The instrument being assigned a skew model. (Trade.Instrument) |
| 2 | ModelID | int | NOT NULL | - | VERIFIED | FK to Price.SkewModels. The skew algorithm assigned to this instrument (1=BuyRatio, 2=PriceAlgo). Note: ModelID is NOT part of the PK - an instrument has one model per FeedID regardless of which model is selected. (Price.SkewModels) |
| 3 | FeedID | smallint | NOT NULL | 1 | VERIFIED | Part 2 of composite PK. The feed source identifier. Default=1 (primary feed). When FeedID != 1, the instrument's skew comes from an alternate feed's Price.ActiveSkew row (FeedID matching). Used by GetSpreadConfigurationFeed to route skew lookup. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical versions in History.InstrumentSkewModel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_InstrumentModel_Instrument) | The instrument assigned a skew model |
| ModelID | Price.SkewModels | FK (FK_InstrumentModel_PriceSkewModels) | The skew algorithm used for this instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetSpreadConfigurationFeed | InstrumentID, FeedID | JOIN | Retrieves FeedID to route skew lookup in Price.ActiveSkew for spread computation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentSkewModel (table)
|- Trade.Instrument (table, FK target - leaf)
|- Price.SkewModels (table, FK target: ModelID=1 BuyRatio, ModelID=2 PriceAlgo)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Price.SkewModels | Table | FK target - ModelID must reference a registered skew algorithm |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetSpreadConfigurationFeed | View | INNER JOIN on (InstrumentID, FeedID != 1) to route skew lookup per feed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentModel | CLUSTERED PK | InstrumentID ASC, FeedID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentModel | PRIMARY KEY | One model per (instrument, feed) combination |
| FK_InstrumentModel_Instrument | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_InstrumentModel_PriceSkewModels | FK | ModelID -> Price.SkewModels(ModelID) |
| DF_TradeInstrumentModel_FeedID | DEFAULT | FeedID = 1 |
| DF_InstrumentSkewModel_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentSkewModel_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.InstrumentSkewModel |
| TRG_T_InstrumentSkewModel | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all instrument-skew-model assignments with model names

```sql
SELECT
    ISM.InstrumentID,
    ISM.ModelID,
    SM.Name AS ModelName,
    ISM.FeedID,
    ISM.SysStartTime AS AssignedSince
FROM Price.InstrumentSkewModel ISM WITH (NOLOCK)
JOIN Price.SkewModels SM WITH (NOLOCK)
    ON SM.ModelID = ISM.ModelID
ORDER BY ISM.InstrumentID, ISM.FeedID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 6, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentSkewModel | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentSkewModel.sql*
