# History.RolloverFeeAlertThreshold

> System-versioned temporal history table for Trade.RolloverFeeAlertThreshold, recording all past alert threshold configurations that define the maximum acceptable rollover fee change per instrument type before triggering an alert.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (EndTime, BeginTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on EndTime ASC, BeginTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Trade.RolloverFeeAlertThreshold` (source table declares `HISTORY_TABLE = [History].[RolloverFeeAlertThreshold]`). SQL Server automatically archives superseded rows here when thresholds are updated.

The source table configures alert sensitivity for rollover fee monitoring: for each instrument type (`InstrumentTypeID`), `RolloverFeeThreshold` defines how large a rollover fee change must be before `Trade.RolloverFeesAlertIfNeeded` fires an alert. This procedure compares current vs. previous rollover fees across NonLeveraged/Leveraged Buy/Sell Overnight/EndOfWeek dimensions. When any fee component changes by more than the configured threshold, an alert is triggered.

With 185 history rows and multiple changes per day (intraday changes visible March 2026), this is a frequently-tuned configuration. The `UpdatedByUser` email field confirms changes are made via the eToro ops tooling.

---

## 2. Business Logic

### 2.1 Rollover Fee Alert Triggering

**What**: The threshold controls the sensitivity of the rollover fee monitoring alert.

**Columns/Parameters Involved**: `InstrumentTypeID`, `RolloverFeeThreshold`

**Rules**:
- One row per InstrumentTypeID in the source table (composite PK)
- `Trade.RolloverFeesAlertIfNeeded` compares current vs. previous rollover fee values across 8 fee dimensions (NonLeveraged/Leveraged * Buy/Sell * Overnight/EndOfWeek)
- If any fee component change exceeds `RolloverFeeThreshold`, `@IsAlertTriggered = 1` is output
- Threshold is a decimal(16,8) value representing the fee magnitude threshold (e.g., 6.09 or 6.699)
- `Trade.UpdateRolloverFeeThreshold` updates the source table via a UDT parameter, SQL Server auto-archives the old value here

**Diagram**:
```
Trade.RolloverFeesAlertIfNeeded:
  Current fees (from Trade.InterestRate)
  Previous fees (from History or prior snapshot)
  |
  JOIN Trade.RolloverFeeAlertThreshold ON InstrumentTypeID
  |
  IF ABS(current_fee - prev_fee) > RolloverFeeThreshold
    SET @IsAlertTriggered = 1
    -> Trigger alert notification
```

---

## 3. Data Overview

| InstrumentTypeID | RolloverFeeThreshold | UpdatedByUser | BeginTime | EndTime | Meaning |
|---|---|---|---|---|---|
| 1 | 6.699 | opstest01@etoro.com | 2026-03-20 18:57:05 | 2026-03-20 18:57:12 | InstrumentType 1 had threshold 6.699 for only 7 seconds before being reverted - likely an ops test or accidental change |
| 1 | 6.09 | opstest01@etoro.com | 2026-03-20 10:10:59 | 2026-03-20 18:57:05 | Threshold 6.09 was active for about 9 hours on March 20 - the operational baseline for that day's monitoring window |
| 1 | 6.699 | opstest01@etoro.com | 2026-03-20 10:10:53 | 2026-03-20 10:10:59 | Brief test of 6.699 threshold before being lowered to 6.09 |
| 1 | 6.09 | opstest01@etoro.com | 2026-03-19 18:57:44 | 2026-03-20 10:10:53 | Threshold held from previous evening until next morning - overnight monitoring window |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | CODE-BACKED | The instrument type category for which this rollover fee threshold applies. PK in the source table - one threshold per instrument type. Implicit FK to instrument type lookup (exact table not confirmed in DDL, but the concept maps to InstrumentType categories like equities, commodities, currencies, crypto, etc.). |
| 2 | RolloverFeeThreshold | decimal(16,8) | NO | - | VERIFIED | The alert sensitivity threshold for rollover fee changes for this instrument type. When any of the 8 rollover fee components (NonLeveraged/Leveraged * Buy/Sell * Overnight/EndOfWeek) changes by more than this value, `Trade.RolloverFeesAlertIfNeeded` triggers an alert. Higher values = less sensitive alerting. In practice: oscillates between ~6.09 and ~6.699 for InstrumentTypeID=1. |
| 3 | UpdatedByUser | varchar(50) | NO | - | VERIFIED | Email or username of the person who updated this threshold in the source table. Set by the calling application. Stored as a plain string (no FK). In production, changes come from ops tooling users like "opstest01@etoro.com". Provides operator accountability for threshold changes. |
| 4 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | UTC instant when this threshold configuration became active in `Trade.RolloverFeeAlertThreshold`. Automatically managed by SQL Server temporal system versioning (GENERATED ALWAYS AS ROW START in source). Nanosecond precision. |
| 5 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC instant when this threshold was superseded by an update. Automatically set by SQL Server. Leading key of the clustered index. The intraday changes (seconds apart) confirm real-time tuning of alert sensitivity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Trade.RolloverFeeAlertThreshold | Temporal History | Each row is a past threshold state for the instrument type identified by InstrumentTypeID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RolloverFeeAlertThreshold | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives all superseded rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RolloverFeeAlertThreshold (table)
  (temporal history - no code-level dependencies; populated by SQL Server from Trade.RolloverFeeAlertThreshold)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloverFeeAlertThreshold | Table | Source table; expired rows archived here by SQL Server. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RolloverFeeAlertThreshold | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival audit data. |

---

## 8. Sample Queries

### 8.1 View recent threshold change history
```sql
SELECT
    InstrumentTypeID,
    RolloverFeeThreshold,
    UpdatedByUser,
    BeginTime AS ValidFrom,
    EndTime AS ValidTo,
    DATEDIFF(second, BeginTime, EndTime) AS DurationSeconds
FROM [History].[RolloverFeeAlertThreshold] WITH (NOLOCK)
ORDER BY EndTime DESC
```

### 8.2 Get threshold configuration as of a specific past date
```sql
-- Temporal query on source table (SQL Server reads History automatically)
SELECT InstrumentTypeID, RolloverFeeThreshold, UpdatedByUser
FROM [Trade].[RolloverFeeAlertThreshold]
FOR SYSTEM_TIME AS OF '2026-03-19T00:00:00'
ORDER BY InstrumentTypeID
```

### 8.3 Track all threshold changes for a specific instrument type
```sql
SELECT
    RolloverFeeThreshold,
    UpdatedByUser,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo,
    LAG(RolloverFeeThreshold) OVER (ORDER BY BeginTime) AS PreviousThreshold
FROM [History].[RolloverFeeAlertThreshold] WITH (NOLOCK)
WHERE InstrumentTypeID = @InstrumentTypeID
ORDER BY BeginTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RolloverFeeAlertThreshold | Type: Table | Source: etoro/etoro/History/Tables/History.RolloverFeeAlertThreshold.sql*
