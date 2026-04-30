# Trade.GetMostPopularInstrumentsForAPI

> Returns the top N most popular instrument IDs ranked by the number of manually opened positions, used by the trading API to surface trending/popular instruments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumOfInstruments - controls result set size (default 200) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMostPopularInstrumentsForAPI` returns the top N most popular instrument IDs from `Trade.MostPopularInstruments`, ranked by `NumOfManuallPositions` (descending). The default is the top 200 instruments by manual position count.

This procedure exists to power the "Popular Instruments" feature in the eToro trading interface - enabling the platform to surface instruments with the highest user activity to new and existing traders. Popularity is measured by manually opened positions (as opposed to copy-trade positions), representing instruments that users actively choose to trade on their own.

Data flows: Called by the trading API. The `Trade.MostPopularInstruments` table is updated periodically (by a background process) and this procedure reads from it with NOCOUNT.

---

## 2. Business Logic

### 2.1 Popularity Ranking by Manual Positions

**What**: Popularity is ranked by number of manually opened positions, not copy trades.

**Columns/Parameters Involved**: `NumOfManuallPositions`, `@NumOfInstruments`

**Rules**:
- `ORDER BY NumOfManuallPositions DESC`: Most manually-traded instruments appear first.
- `TOP (@NumOfInstruments)`: Returns exactly N instruments (default 200, configurable by caller).
- Manual positions (not copy trade) represent genuine user interest/demand.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumOfInstruments | INT | YES | 200 | CODE-BACKED | Maximum number of instruments to return. Defaults to 200. Controls the TOP N cutoff in the result. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | InstrumentID | Trade.MostPopularInstruments | The instrument identifier for a popular instrument. Top N by manual position count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.MostPopularInstruments | Primary read | Source of instrument popularity rankings. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMostPopularInstrumentsForAPI (procedure)
└── Trade.MostPopularInstruments (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MostPopularInstruments | Table | SELECT TOP N InstrumentID ORDER BY NumOfManuallPositions DESC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get top 200 popular instruments (default)

```sql
EXEC Trade.GetMostPopularInstrumentsForAPI;
```

### 8.2 Get top 50 popular instruments

```sql
EXEC Trade.GetMostPopularInstrumentsForAPI @NumOfInstruments = 50;
```

### 8.3 Get popular instruments with names from Instrument table

```sql
SELECT TOP 50
    mpi.InstrumentID,
    mpi.NumOfManuallPositions,
    i.InstrumentDisplayName
FROM Trade.MostPopularInstruments mpi WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = mpi.InstrumentID
ORDER BY mpi.NumOfManuallPositions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMostPopularInstrumentsForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMostPopularInstrumentsForAPI.sql*
