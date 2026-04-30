# Trade.MergedDailySchedules

> Synonym pointing to the MergedDailySchedules table in CalendarDB (CalendarAzure linked server), the primary source for market open/close schedules used throughout the trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [CalendarAzure].[CalendarDB].[Market].[MergedDailySchedules] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MergedDailySchedules is one of the most important synonyms in the Trade schema. It provides local access to the MergedDailySchedules table in CalendarDB, which is the authoritative source for daily market open/close schedules across all exchanges and instruments. This data drives critical platform functions including trading hour enforcement, market status determination, and ex-dividend date processing.

Per code comments in GetMarketCloseTimeByExDate_SS: "The basic table for market times is Trade.MergedDailySchedules. It includes a row for each and every day (including days when the market is closed). A date may have several rows - a newer row overrides all previous rows. An additional override may be on instrument level. Use only OpenTimeUTC and CloseTimeUTC (local times have bugs)."

Consumed by Trade.GetMarketTimes (the core market schedule function), which is in turn used by the entire market-hours and dividend-processing function chain.

---

## 2. Business Logic

### 2.1 Schedule Override Hierarchy

**What**: Multi-level override system for market schedules.

**Rules**:
- Each date can have multiple rows; newer rows override earlier rows for the same date
- Exchange-level defaults apply to all instruments on that exchange
- Instrument-level overrides (for indices) take precedence over exchange-level defaults
- Multiple rows per day and instrument may represent different trading slots with breaks
- Only OpenTimeUTC and CloseTimeUTC should be used (local time columns have known bugs)

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [CalendarAzure].[CalendarDB].[Market].[MergedDailySchedules]. The authoritative market schedule table with daily open/close times per exchange/instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [CalendarAzure].[CalendarDB].[Market].[MergedDailySchedules] | Synonym target | Cross-database reference to CalendarDB market schedule table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMarketTimes | FROM clause | Reader | Core consumer - reads merged schedules to build market time windows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MergedDailySchedules (synonym)
  +-- [CalendarAzure].[CalendarDB].[Market].[MergedDailySchedules] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [CalendarAzure].[CalendarDB].[Market].[MergedDailySchedules] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMarketTimes | Function | Reads market schedules for open/close time calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query recent market schedules
```sql
SELECT TOP 10 * FROM Trade.MergedDailySchedules WITH (NOLOCK) ORDER BY 1 DESC
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'MergedDailySchedules' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.MergedDailySchedules WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MergedDailySchedules | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.MergedDailySchedules.sql*
