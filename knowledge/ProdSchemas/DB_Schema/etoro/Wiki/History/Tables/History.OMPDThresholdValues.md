# History.OMPDThresholdValues

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of Price.OMPDThresholdValues - the Order Market Price Deviation (OMPD) threshold configuration that defines acceptable price deviation limits for order execution per instrument.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.OMPDThresholdValues is the temporal history backing table for Price.OMPDThresholdValues. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever OMPD threshold configurations are changed.

Price.OMPDThresholdValues defines the Order Market Price Deviation thresholds per instrument: the maximum allowable difference between the price at which an order was placed and the current market price when the order is executed. This controls slippage protection - if the market moves too far from the order price before execution, the order is rejected rather than filled at an unfavorable rate.

Each instrument has two threshold types:
- **Type 1 (Pips)**: Maximum deviation in pips
- **Type 2 (Percentage)**: Maximum deviation as a percentage

With 246,500 history rows and very recent changes (UserName="DevTradingSTG" on 2026-03-20), this table sees active management - threshold values are adjusted as market volatility changes or new instruments are onboarded. The `UserName` computed column (suser_name()) identifies who made each change.

---

## 2. Business Logic

### 2.1 Dual Threshold Types - Pips and Percentage

**What**: Each instrument's OMPD tolerance is configured with two thresholds, one in absolute pips and one as a percentage of the price, giving the pricing engine flexibility in how it evaluates acceptable deviation.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`, `Value`

**Rules**:
- ThresholdType=1 (Pips): the maximum acceptable deviation expressed in pips. Value=55 means up to 55 pips slippage is acceptable.
- ThresholdType=2 (Percentage): the maximum acceptable deviation as a percentage of the instrument price. Value=35 means up to 35% deviation is acceptable.
- FK on live table: ThresholdType -> Dictionary.OMPDThresholdType (1=Pips, 2=Percentage)
- Composite PK on live table: (InstrumentID, ThresholdType) - one row per instrument per threshold type
- If either threshold is breached, the order may be rejected or re-priced

### 2.2 UserName - Operator Accountability

**What**: Price.OMPDThresholdValues uses a computed column (UserName = suser_name()) to capture the database login identity for each change. The value is captured at change time and preserved in the temporal history.

**Rules**:
- UserName = suser_name() at the time of the INSERT/UPDATE
- Stored in history when the row is archived by temporal versioning
- Data shows "DevTradingSTG" - a trading/pricing team service account
- Unlike DbLoginName/AppLoginName patterns (which also capture context_info), UserName here is only the DB login - no application-level identity

### 2.3 Temporal History Frequency

**What**: 246,500 history rows with active daily changes indicates frequent threshold management. This may be driven by automated processes (e.g., volatility-based threshold adjustments) rather than purely manual changes.

**Rules**:
- ThresholdType 1 (Pips): 130,689 history rows (53%) - more frequently adjusted than percentage
- ThresholdType 2 (Percentage): 115,811 history rows (47%)
- Price management procedures: Price.CreateActiveOMPDThresholdByInstrumentId, Price.UpdateInstrumentOMPDThresholdByInstrumentId, Price.UpdateInstrumentThresholdsWithActiveThreshold are the writers

---

## 3. Data Overview

246,500 rows. Active recent changes observed.

| InstrumentID | ThresholdType | Value | UserName | SysStartTime | SysEndTime |
|---|---|---|---|---|---|
| 1 | 2 | 35.00 | DevTradingSTG | 2026-03-20 18:42:21 | 2026-03-20 18:43:16 | Percentage threshold for InstrumentID=1 was 35% for ~55 seconds before being updated to a new value. |
| 1 | 1 | 55.00 | DevTradingSTG | 2026-03-20 18:42:21 | 2026-03-20 18:43:16 | Pips threshold for same instrument, same batch update time. Both types updated together. |
| 2 | 2 | 20.00 | DevTradingSTG | 2026-03-20 18:42:07 | 2026-03-20 18:42:21 | InstrumentID=2 Percentage threshold was 20% for 14 seconds. Short-lived state suggests automated recalibration. |

**ThresholdType distribution**: 1=Pips: 130,689 (53%), 2=Percentage: 115,811 (47%).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument for which this OMPD threshold applies. Part of the composite PK on Price.OMPDThresholdValues (InstrumentID, ThresholdType). References Trade.Instrument (no FK enforced in history). Multiple history rows per InstrumentID from different threshold type rows and different time periods. |
| 2 | ThresholdType | int | NO | - | CODE-BACKED | The type of threshold: 1=Pips (maximum deviation in pips), 2=Percentage (maximum deviation as % of price). FK to Dictionary.OMPDThresholdType on live table (not enforced in history). Part of the composite PK. |
| 3 | Value | decimal(20,2) | NO | - | CODE-BACKED | The threshold value in the units defined by ThresholdType. For Pips (Type 1): number of pips (e.g., 55 = 55 pips max deviation). For Percentage (Type 2): percentage (e.g., 35 = 35% max deviation). decimal(20,2) provides precision for both integer pip values and fractional percentage values. |
| 4 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when this threshold configuration became current in Price.OMPDThresholdValues. Populated automatically by SQL Server SYSTEM_VERSIONING. |
| 5 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC timestamp when this configuration was superseded. For all history rows, always a past timestamp. Short SysEndTime-SysStartTime intervals (seconds) indicate automated batch updates. |
| 6 | UserName | nvarchar(128) | YES | - | CODE-BACKED | The SQL Server login name that changed this threshold configuration. Computed column on Price.OMPDThresholdValues (= suser_name()). Captured at change time and stored in the history row. Identifies the operator or service account responsible for the change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | References the instrument being threshold-configured. No FK in history. |
| ThresholdType | Dictionary.OMPDThresholdType | Implicit | FK enforced on Price.OMPDThresholdValues (1=Pips, 2=Percentage); not enforced in history. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.OMPDThresholdValues | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old states here |

---

## 6. Dependencies

```
History.OMPDThresholdValues (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Price.OMPDThresholdValues (live temporal table)
    - Writers: Price.CreateActiveOMPDThresholdByInstrumentId
               Price.UpdateInstrumentOMPDThresholdByInstrumentId
               Price.UpdateInstrumentThresholdsWithActiveThreshold
               Price.DeleteOMPDThresholdByInstrumentID (generates history on DELETE)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.OMPDThresholdValues | Table | Live temporal table - this is its HISTORY_TABLE |
| Price.GetActiveOMPDThresholdByInstrumentIds | Stored Procedure | Reader of live table |
| Price.GetInstrumentsOMPDThresholdByInstrumentIds | Stored Procedure | Reader of live table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_OMPDThresholdValues | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied.

### 7.2 Constraints

No constraints on history table. Price.OMPDThresholdValues live table: CLUSTERED PK on (InstrumentID, ThresholdType), FK to Dictionary.OMPDThresholdType, FILLFACTOR=90.

---

## 8. Sample Queries

### 8.1 Historical OMPD configuration for an instrument at a specific time

```sql
SELECT InstrumentID, ThresholdType, Value, UserName
FROM [Price].[OMPDThresholdValues]
FOR SYSTEM_TIME AS OF '2026-01-01 00:00:00'
WHERE InstrumentID = @InstrumentID
ORDER BY ThresholdType
```

### 8.2 Track threshold changes for a specific instrument

```sql
SELECT InstrumentID, ThresholdType, Value, UserName, SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS ValidForSec
FROM [History].[OMPDThresholdValues] WITH (NOLOCK)
WHERE InstrumentID = 1
UNION ALL
SELECT InstrumentID, ThresholdType, Value, UserName, SysStartTime, SysEndTime, NULL
FROM [Price].[OMPDThresholdValues] WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY ThresholdType, SysStartTime ASC
```

### 8.3 Most frequently changed instruments (most volatile OMPD configuration)

```sql
SELECT InstrumentID, ThresholdType, COUNT(*) AS ChangeCount,
       MIN(Value) AS MinValue, MAX(Value) AS MaxValue
FROM [History].[OMPDThresholdValues] WITH (NOLOCK)
WHERE SysStartTime >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY InstrumentID, ThresholdType
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Price.UpdateInstrumentOMPDThresholdByInstrumentId, Price.GetActiveOMPDThresholdByInstrumentIds) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.OMPDThresholdValues | Type: Table | Source: etoro/etoro/History/Tables/History.OMPDThresholdValues.sql*
