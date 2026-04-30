# History.InstrumentSkewModel

> Temporal history table recording all changes to the per-instrument skew model assignments, capturing which price adjustment model was applied to each instrument on each price feed at every point in time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentSkewModel is the SQL Server system-versioning history table for `Price.InstrumentSkewModel`, which defines which price skew model applies to each instrument on each price feed. A skew model controls how bid/ask spread adjustments (price skewing) are calculated for an instrument - this directly affects the prices shown to customers and the cost of trading. Every change to an instrument's skew model assignment is recorded here automatically for audit and incident investigation.

This table answers questions like "which skew model was assigned to EUR/USD on feed 5 during the February outage?" and "when did instrument 100 switch from model 3 to model 7?". These questions arise during pricing quality reviews, spread anomaly investigations, and regulatory audits of best-execution practices.

Data flows in via SQL Server SYSTEM_VERSIONING from `Price.InstrumentSkewModel`. The live table has a composite PK on (InstrumentID, FeedID), meaning each instrument can have a different skew model per feed. The default FeedID is 1 (primary/simulation feed). The view `Price.GetSpreadConfigurationFeed` specifically filters `FeedID != 1` to work with non-simulation feed configurations, confirming FeedID 1 is the standard/default pricing channel.

---

## 2. Business Logic

### 2.1 Per-Feed Skew Model Assignment

**What**: Each instrument can have different skew models for different price feeds, allowing differentiated spread policies across pricing channels.

**Columns/Parameters Involved**: `InstrumentID`, `ModelID`, `FeedID`

**Rules**:
- PK in live table is (InstrumentID, FeedID) - one skew model per instrument per feed
- FeedID 1 is the default feed (used for primary pricing and simulation); DEFAULT constraint sets FeedID = 1 on insert
- FeedID != 1 feeds are specialized channels (alternative providers, regional feeds, etc.)
- ModelID references Price.SkewModels which contains the actual spread adjustment parameters
- The same InstrumentID can appear in multiple rows with different FeedIDs, each mapped to a potentially different ModelID

**Diagram**:
```
Instrument 100 (EUR/USD) skew model configuration:
  FeedID 1  -> ModelID 5  (primary feed - default spread model)
  FeedID 3  -> ModelID 8  (secondary feed - different spread model)
  FeedID 9  -> ModelID 5  (tertiary feed - same model as primary)

Price.GetSpreadConfigurationFeed queries: WHERE FeedID != 1
-> Returns non-default feed configurations for spread calibration
```

### 2.2 Temporal Change Audit

**What**: Every assignment change creates a history row, enabling point-in-time reconstruction of skew model configurations.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SysStartTime: when this (InstrumentID, FeedID, ModelID) assignment became active
- SysEndTime: when this assignment was superseded
- Note: INSERT trigger TRG_T_InstrumentSkewModel fires a no-op UPDATE after each INSERT, generating an immediate history record with SysStartTime = SysEndTime (zero-duration history row marking the initial state)
- DbLoginName and AppLoginName identify who made each configuration change

---

## 3. Data Overview

No rows found in History.InstrumentSkewModel (table is empty). This indicates the live Price.InstrumentSkewModel configuration has been stable with no changes recorded, or this is a fresh environment where the live table was populated without triggering temporal history entries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this skew model assignment applies to. Part of composite PK (InstrumentID, FeedID) in the live table. FK to Trade.Instrument(InstrumentID). |
| 2 | ModelID | int | NO | - | CODE-BACKED | The skew model assigned to this instrument-feed combination. FK to Price.SkewModels(ModelID) in the live table. Determines how bid/ask spread is adjusted for this instrument on this feed. See Price.SkewModels for available model definitions. |
| 3 | FeedID | smallint | NO | 1 | CODE-BACKED | Identifies which price feed this skew model assignment applies to. DEFAULT 1 = primary/simulation feed. Feed IDs correspond to price source channels. The view Price.GetSpreadConfigurationFeed filters FeedID != 1 to retrieve non-primary feed assignments. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name of the session that made the configuration change. Computed from suser_name() in the live table; stored statically here. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user context when the change was made. Computed from context_info() in the live table; stored statically here for audit. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument-feed-model assignment became active in Price.InstrumentSkewModel. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this assignment was superseded by a change in Price.InstrumentSkewModel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose skew model is recorded. FK enforced on Price.InstrumentSkewModel, not on this history table. |
| ModelID | Price.SkewModels | Implicit (FK in live table) | The skew model assigned - FK to Price.SkewModels(ModelID) in the live table. |
| InstrumentID + FeedID | Price.InstrumentSkewModel | Temporal History | This is the history table for Price.InstrumentSkewModel via SYSTEM_VERSIONING. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentSkewModel | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table - passive receiver of change data.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentSkewModel | Table | Live temporal table whose history is stored here |
| Price.GetSpreadConfigurationFeed | View | Reads live Price.InstrumentSkewModel (filters FeedID != 1) to provide spread configuration data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentSkewModel | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find all historical skew model assignments for a specific instrument
```sql
SELECT
    InstrumentID,
    ModelID,
    FeedID,
    SysStartTime AS AssignedFrom,
    SysEndTime   AS AssignedTo,
    DbLoginName
FROM History.InstrumentSkewModel WITH (NOLOCK)
WHERE InstrumentID = 10
ORDER BY FeedID, SysStartTime
```

### 8.2 Reconstruct skew model config active at a specific point in time
```sql
DECLARE @AsOf datetime2 = '2024-01-01 00:00:00'
SELECT
    InstrumentID,
    ModelID,
    FeedID,
    SysStartTime,
    SysEndTime
FROM History.InstrumentSkewModel WITH (NOLOCK)
WHERE SysStartTime <= @AsOf
  AND SysEndTime > @AsOf
ORDER BY InstrumentID, FeedID
```

### 8.3 Find instruments that had skew model changes in the last 90 days
```sql
SELECT DISTINCT
    InstrumentID,
    COUNT(*) AS ChangeCount,
    MIN(SysStartTime) AS FirstChange,
    MAX(SysEndTime) AS LastChange
FROM History.InstrumentSkewModel WITH (NOLOCK)
WHERE SysEndTime > DATEADD(day, -90, GETUTCDATE())
GROUP BY InstrumentID
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentSkewModel | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentSkewModel.sql*
