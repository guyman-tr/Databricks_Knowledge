# History.Spread

> Trigger-managed application history table for Trade.Spread, recording all past bid/ask spread adjustments applied per provider-instrument combination, with each version bounded by a ValidFrom/ValidTo time window.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | SpreadVersionID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (CLUSTERED PK on SpreadVersionID; NONCLUSTERED on ProviderID+InstrumentID; NONCLUSTERED on SpreadID) |

---

## 1. Business Meaning

This table is the **trigger-managed application history table** for `Trade.Spread`. It is NOT a SQL Server temporal table - history is maintained by triggers on `Trade.Spread`:
- `SpreadInsert` trigger (INSERT): inserts a new row into History.Spread with ValidFrom=GETDATE(), ValidTo='3000-01-01'
- `SpreadUpdate` trigger (UPDATE): closes the previous row (ValidTo=GETDATE()), inserts new row
- `TSpreadDelete` trigger (DELETE): closes the active row (ValidTo=GETDATE())

`Trade.Spread` defines the bid/ask spread adjustments for each provider-instrument combination. Each row represents the spread override in integer pip/tick units applied to the price feed from a specific provider for a specific instrument. `Bid=-1, Ask=1` is the dominant pattern: the bid is lowered by 1 pip and the ask is raised by 1 pip, creating a symmetric 2-pip spread around the mid-price.

`SpreadID` identifies the current active spread configuration in Trade.Spread; multiple history rows share the same SpreadID representing different versions over time. `SpreadVersionID` is the unique identifier for each historical version.

The table has 15,769 rows spanning March 2009 through February 2026. Active spreads have ValidTo='3000-01-01' (sentinel for "currently active").

**Dual audit**: In addition to trigger history (this table), Trade.Spread has ASM-generated audit triggers (AuditInsert, AuditUpdate, AuditDelete) that write Bid/Ask change details to `History.AuditHistory`.

---

## 2. Business Logic

### 2.1 Spread Versioning Pattern

**What**: Each change to Trade.Spread creates a new history version.

**Columns/Parameters Involved**: `SpreadID`, `SpreadVersionID`, `ValidFrom`, `ValidTo`

**Rules**:
- `ValidTo='3000-01-01'` = currently active version (sentinel)
- `ValidTo < '3000-01-01'` = superseded version (historical)
- On INSERT to Trade.Spread: one row added to History.Spread with ValidFrom=NOW, ValidTo='3000-01-01'
- On UPDATE to Trade.Spread: active row's ValidTo updated to NOW; new row inserted with ValidFrom=NOW, ValidTo='3000-01-01'
- On DELETE from Trade.Spread: active row's ValidTo updated to NOW
- There can be at most one active row per SpreadID (ValidTo='3000-01-01')

### 2.2 Spread Values in Integer Pip Units

**What**: Bid and Ask are integer adjustments applied to the raw price feed, not actual prices.

**Columns/Parameters Involved**: `Bid`, `Ask`, `ProviderID`, `InstrumentID`

**Rules**:
- FK on source: (ProviderID, InstrumentID) -> Trade.ProviderToInstrument
- Bid and Ask values are integer offsets in pip/tick units: positive = increase the price side, negative = decrease
- `Bid=-1, Ask=1`: bid lowered 1 pip (wider spread on buy), ask raised 1 pip -> 2-pip total spread
- `Bid=0, Ask=0`: pass-through - no spread adjustment (tight market spread)
- A spread configuration is indexed on (ProviderID, InstrumentID) for fast lookup by the pricing engine

---

## 3. Data Overview

| SpreadVersionID | SpreadID | ProviderID | InstrumentID | Bid | Ask | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 18456 | 11676 | 1 | 797 | -1 | 1 | 2026-02-05 07:09 | 3000-01-01 (active) | Standard 2-pip spread for instrument 797 from provider 1 |
| 18455 | 11675 | 1 | 794 | -1 | 1 | 2026-02-05 07:09 | 3000-01-01 (active) | Standard 2-pip spread for instrument 794 |

Total: 15,769 rows | ProviderID=1 dominant | Most recent batch: Feb 5, 2026

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadVersionID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key for history rows. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each version of each spread configuration. |
| 2 | SpreadID | int | NO | - | VERIFIED | References the Trade.Spread row this version belongs to. Multiple SpreadVersionIDs share the same SpreadID across time. Used to look up all historical states of a specific spread. Indexed for fast lookup. |
| 3 | ProviderID | int | NO | - | VERIFIED | The price provider this spread applies to. Part of the (ProviderID, InstrumentID) FK to Trade.ProviderToInstrument. Indexed with InstrumentID for the pricing engine to look up spread by provider+instrument. |
| 4 | InstrumentID | int | NO | - | VERIFIED | The instrument this spread applies to. Part of the (ProviderID, InstrumentID) composite key in the source table. Indexed with ProviderID. |
| 5 | Bid | int | NO | - | VERIFIED | Integer pip/tick adjustment to the bid price. Negative = lower the bid (widen the spread from above). `Bid=-1` is the standard pattern: bid lowered by 1 pip. `Bid=0` = no adjustment. |
| 6 | Ask | int | NO | - | VERIFIED | Integer pip/tick adjustment to the ask price. Positive = raise the ask (widen the spread from below). `Ask=1` is the standard pattern: ask raised by 1 pip. Combined with `Bid=-1` creates a symmetric 2-pip spread. |
| 7 | ValidFrom | datetime | NO | - | CODE-BACKED | UTC timestamp when this spread configuration became effective. Set to GETDATE() by the SpreadInsert or SpreadUpdate trigger at the time of the Trade.Spread change. |
| 8 | ValidTo | datetime | NO | - | CODE-BACKED | UTC timestamp when this spread configuration was superseded. Sentinel value '3000-01-01' = currently active. Set to GETDATE() by the SpreadUpdate or TSpreadDelete trigger when replaced or removed. Filter WHERE ValidTo = '3000-01-01' to get current spreads. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadID | Trade.Spread | Trigger History | Each row is a past state of the source Trade.Spread row identified by SpreadID. |
| (ProviderID, InstrumentID) | Trade.ProviderToInstrument | Implicit (FK on source) | The provider-instrument pair this spread governs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Spread | SpreadInsert / SpreadUpdate / TSpreadDelete triggers | Trigger Writer | All changes to Trade.Spread are reflected here via triggers. |

---

## 6. Dependencies

No dependencies. Application-managed trigger history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HSPR | CLUSTERED PK | SpreadVersionID ASC | - | - | Active |
| HSPR_PROVIDER2INSTRUMENT | NONCLUSTERED | ProviderID ASC, InstrumentID ASC | - | - | Active |
| HSPR_SPREAD | NONCLUSTERED | SpreadID ASC | - | - | Active |

Note: All indexes on [HISTORY] filegroup with FILLFACTOR=90.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HSPR | PRIMARY KEY | Uniqueness on SpreadVersionID. CLUSTERED. FILLFACTOR=90. NOT FOR REPLICATION. |

---

## 8. Sample Queries

### 8.1 Get all currently active spreads
```sql
SELECT SpreadID, ProviderID, InstrumentID, Bid, Ask, ValidFrom
FROM [History].[Spread] WITH (NOLOCK)
WHERE ValidTo = '30000101'
ORDER BY ProviderID, InstrumentID
```

### 8.2 Get spread history for a specific instrument
```sql
SELECT SpreadVersionID, SpreadID, ProviderID, Bid, Ask, ValidFrom, ValidTo
FROM [History].[Spread] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY ValidFrom ASC
```

### 8.3 Find spread at a specific point in time
```sql
SELECT SpreadID, ProviderID, InstrumentID, Bid, Ask
FROM [History].[Spread] WITH (NOLOCK)
WHERE ProviderID = @ProviderID
  AND InstrumentID = @InstrumentID
  AND ValidFrom <= @PointInTime
  AND ValidTo > @PointInTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (trigger-driven) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Spread | Type: Table | Source: etoro/etoro/History/Tables/History.Spread.sql*
