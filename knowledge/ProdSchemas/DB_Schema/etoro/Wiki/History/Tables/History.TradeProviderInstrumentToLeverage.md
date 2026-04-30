# History.TradeProviderInstrumentToLeverage

> SQL Server system-versioned temporal history table for Trade.ProviderInstrumentToLeverage - stores superseded leverage tier configurations per provider/instrument, enabling point-in-time auditing of leverage policy changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [MAIN] filegroup with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.TradeProviderInstrumentToLeverage is the temporal history backing table for Trade.ProviderInstrumentToLeverage, which defines the available leverage tiers for each instrument/provider combination. Each row in Trade.ProviderInstrumentToLeverage specifies one leverage option (e.g., 1x, 2x, 5x, 10x) for an instrument on a provider, with its associated margin percentage, default flag, and leverage type.

When leverage configurations are added, changed, or removed (e.g., regulatory changes reducing max leverage from 30x to 5x for retail clients), SQL Server's system-versioning automatically archives the old configuration here. This preserves the complete history of which leverage tiers were available at any point in time - essential for regulatory compliance, dispute resolution, and understanding how historical positions were opened.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Each change to Trade.ProviderInstrumentToLeverage produces a history row with SysStartTime/SysEndTime capturing when that leverage configuration was active.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `LeverageID`, `IsDefault`, `Percentage`, `LeverageType`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = when this leverage configuration became active
- SysEndTime = when it was superseded (update or delete)
- Multiple history rows with the same ProviderID/InstrumentID show the evolution of leverage options
- Regulatory events (e.g., ESMA leverage limits) would create a burst of history rows as configurations are updated
- DbLoginName and AppLoginName captured at DML time for change attribution

---

## 3. Data Overview

Table is typically empty in non-production environments. Production accumulates rows with each leverage policy change.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider identifier. Part of the composite key in Trade.ProviderInstrumentToLeverage. Identifies which provider's leverage configuration changed. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. Identifies which instrument's leverage tiers changed. |
| 3 | LeverageID | INT | NO | - | CODE-BACKED | Leverage tier identifier (e.g., 1=1x, 2=2x, 5=5x). Part of the composite key. Identifies the specific leverage option that was changed. |
| 4 | IsDefault | BIT | NO | - | CODE-BACKED | Whether this leverage tier was the default for the provider/instrument: 1 = default tier (pre-selected when opening a position), 0 = optional tier. |
| 5 | Percentage | INT | NO | - | CODE-BACKED | Margin percentage required for this leverage tier (e.g., for 10x leverage, Percentage = 10 meaning 10% margin). Inverse of leverage multiplier. |
| 6 | LeverageType | INT | NO | - | CODE-BACKED | Category/type of leverage rule applied. Determines how the leverage is calculated or validated. Application-defined values. |
| 7 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login name of the session that made the change, captured via suser_name() at DML time. Preserved for change attribution. |
| 8 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login name from context_info() at DML time. Identifies the calling service or admin tool. |
| 9 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this leverage configuration became active. Set automatically by SQL Server. |
| 10 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration was superseded. Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Temporal (inherited) | Historical snapshot of the provider/instrument combination whose leverage changed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderInstrumentToLeverage | SYSTEM_VERSIONING | Temporal parent | Writes superseded leverage configurations here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradeProviderInstrumentToLeverage (table)
  (leaf - temporal history table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | Temporal parent - writes superseded rows automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradeProviderInstrumentToLeverage | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View leverage configurations as of a specific date
```sql
SELECT pil.ProviderID, pil.InstrumentID, pil.LeverageID, pil.IsDefault, pil.Percentage, pil.LeverageType
FROM Trade.ProviderInstrumentToLeverage
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00'
WHERE pil.InstrumentID = 7
ORDER BY pil.LeverageID;
```

### 8.2 Audit leverage history for a specific instrument
```sql
SELECT h.ProviderID, h.InstrumentID, h.LeverageID, h.IsDefault, h.Percentage,
       h.SysStartTime, h.SysEndTime, h.DbLoginName
FROM History.TradeProviderInstrumentToLeverage h WITH (NOLOCK)
WHERE h.InstrumentID = 7
ORDER BY h.SysStartTime;
```

### 8.3 Compare leverage before and after a known policy change date
```sql
SELECT 'Before' AS Period, h.InstrumentID, h.LeverageID, h.Percentage
FROM History.TradeProviderInstrumentToLeverage h WITH (NOLOCK)
WHERE h.SysEndTime BETWEEN '2022-01-01' AND '2022-02-01'
UNION ALL
SELECT 'Current', pil.InstrumentID, pil.LeverageID, pil.Percentage
FROM Trade.ProviderInstrumentToLeverage pil WITH (NOLOCK)
ORDER BY InstrumentID, LeverageID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradeProviderInstrumentToLeverage | Type: Table | Source: etoro/etoro/History/Tables/History.TradeProviderInstrumentToLeverage.sql*
