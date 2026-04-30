# Hedge.GetExposuresForAllHedgeServers

> Combines current LP hedge positions (Trade.Hedge + Hedge.Netting) with in-flight hedge requests (Trade.HedgeRequest) to produce a complete exposure picture per (ProviderID, InstrumentID, HedgeServerID). 731 rows. Used by Hedge.GetCESQuery for the CES exposure polling cycle.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 731 |

---

## 1. Business Meaning

Hedge.GetExposuresForAllHedgeServers is the primary exposure snapshot view used by the CES (Centralized Execution Server) to determine the current hedge state before making execution decisions.

The view answers: "For each (ProviderID, InstrumentID, HedgeServerID), how much am I currently hedged AND how much is in-flight as pending requests?" This combination prevents over-hedging - if a request is already in flight, it should not be double-counted when deciding whether to send more.

**Two components combined via FULL OUTER JOIN:**

1. **Hedged** (left side - THDG): The sum of actual hedge positions from two sources:
   - `Trade.Hedge`: LP-side direct trade positions
   - `Hedge.Netting`: netting positions mapped to HedgeServerID via HedgeServerToLiquidityAccount
   - Combined via FULL JOIN, then net direction applied (IsBuy=1 -> +1, IsBuy=0 -> -1)

2. **Requested** (right side - THDR): In-flight hedge requests that haven't been filled yet:
   - `Trade.HedgeRequest` filtered to recent requests: `Occurred >= DATEADD(ss, 0-ConsiderOpenRequestsSec, GETDATE())`
   - `ConsiderOpenRequestsSec` is a per-server setting from `Trade.HedgeServer`
   - Net direction applied (IsBuy=1 -> +1, IsBuy=0 -> -1)

Both are expressed as signed net values: positive = net long, negative = net short.

**Primary consumer**: `Hedge.GetCESQuery` reads this view filtered by ProviderID and simultaneously generates a new ExposureID in `Trade.ExposureIDs` for the query cycle.

---

## 2. Business Logic

### 2.1 Hedged Position Calculation (THDG subquery)

**What**: Aggregates the actual hedge position across LP trades and netting positions for each server/instrument combination.

**Columns/Parameters Involved**: Hedged (output)

**Rules**:
- FULL JOIN between Trade.Hedge (TH) and Hedge.Netting via HedgeServerToLiquidityAccount (HNET)
- Net formula: `SUM(direction_TH * AmountInUnitsDecimal + direction_HNET * Units)` where direction = IsBuy ? 1 : -1
- ISNULL(TH.ProviderID, 1): when Trade.Hedge has no ProviderID, defaults to 1
- The FULL JOIN means servers/instruments present in only one source still appear (as NULL in the missing columns, handled by ISNULL)

### 2.2 Requested Position Calculation (THDR subquery)

**What**: Sums in-flight hedge requests within the server's `ConsiderOpenRequestsSec` window.

**Rules**:
- `WHERE Occurred >= DATEADD(ss, 0-ConsiderOpenRequestsSec, GETDATE())` - time window from Trade.HedgeServer.ConsiderOpenRequestsSec
- Net formula: `SUM(direction * AmountInUnitsDecimal)` where direction = IsBuy ? 1 : -1
- INNER JOIN to Trade.HedgeServer ensures ConsiderOpenRequestsSec is available
- If no pending requests: ISNULL(THDR.Requested, 0) = 0

### 2.3 FULL OUTER JOIN Key Resolution

**What**: The outer FULL OUTER JOIN on (ProviderID, InstrumentID, HedgeServerID) combines hedged and requested. Key columns are resolved from whichever side is non-NULL.

**Code note**: The outer column resolution contains a redundant double-ISNULL pattern:
```sql
ISNULL(ISNULL(THDG.ProviderID, THDG.ProviderID), THDR.ProviderID)
-- Equivalent to: ISNULL(THDG.ProviderID, THDR.ProviderID)
```
The inner ISNULL(x,x) always evaluates to x - this is a code quality artifact that does not affect results.

The FULL OUTER JOIN condition also contains a duplicate OR clause:
```sql
ON (THDG.ProviderID = THDR.ProviderID AND THDG.InstrumentID = THDR.InstrumentID AND THDG.HedgeServerID = THDR.HedgeServerID)
OR (THDG.ProviderID = THDR.ProviderID AND THDG.InstrumentID = THDR.InstrumentID AND THDG.HedgeServerID = THDR.HedgeServerID)
```
Both OR branches are identical - this is a copy-paste artifact with no functional impact.

### 2.4 GetCESQuery Usage Pattern

```
Hedge.GetCESQuery(@ProviderID INT = 1)
  1. SELECT HedgeServerID, InstrumentID, Hedged, Requested FROM this view WHERE ProviderID = @ProviderID
  2. INSERT INTO Trade.ExposureIDs DEFAULT VALUES -> generate new ExposureID
  3. RETURN SCOPE_IDENTITY() -> return the new ExposureID to caller
```

The CES uses this pattern to atomically read current exposures AND record that it did so (via ExposureID), enabling replay and audit of exposure reads.

---

## 3. Data Overview

731 rows. Sample (all ProviderID=1, HedgeServerID=1, Requested=0):

| ProviderID | InstrumentID | HedgeServerID | Hedged | Requested |
|---|---|---|---|---|
| 1 | 1 | 1 | 28,828,254.79 | 0 |
| 1 | 2 | 1 | -25,706.22 | 0 |
| 1 | 3 | 1 | 27,900.50 | 0 |
| 1 | 4 | 1 | 999,321.67 | 0 |
| 1 | 5 | 1 | 224,924,151.49 | 0 |

InstrumentID=2 shows Hedged=-25,706.22 (net short). InstrumentID=5 shows 224,924,151.49 units (matches the Hedge.Netting live data for this instrument). All Requested=0 (no in-flight requests currently).

---

## 4. Output Columns

| Column | Description |
|--------|-------------|
| ProviderID | LP provider identifier. Sourced from Trade.Hedge.ProviderID (defaulting to 1 when NULL via ISNULL) or Trade.HedgeRequest.ProviderID |
| InstrumentID | The financial instrument. From Trade.Hedge, Hedge.Netting, or Trade.HedgeRequest |
| HedgeServerID | The hedge server. From Trade.Hedge, HedgeServerToLiquidityAccount mapping, or Trade.HedgeRequest |
| Hedged | Signed net of actual hedge positions: positive=net long, negative=net short. Combines Trade.Hedge and Hedge.Netting. 0 if no positions. |
| Requested | Signed net of in-flight hedge requests within ConsiderOpenRequestsSec window. 0 if no pending requests. |

---

## 5. Relationships

### 5.1 Source Tables

| Table | Alias | Join Type | Contribution |
|-------|-------|-----------|--------------|
| Trade.Hedge | TH | FULL JOIN (left of inner) | Actual LP trade positions |
| Hedge.Netting | NETT | via INNER JOIN HNET | Netting positions mapped to HedgeServerID |
| Hedge.HedgeServerToLiquidityAccount | HSLA | via INNER JOIN HNET | Maps LiquidityAccountID to HedgeServerID |
| Trade.HedgeRequest | THR | FULL OUTER JOIN (right) | In-flight hedge requests |
| Trade.HedgeServer | THS | INNER JOIN (right subquery) | Provides ConsiderOpenRequestsSec threshold |

### 5.2 Consumed By

| Consumer | How Used |
|----------|----------|
| Hedge.GetCESQuery | Reads this view filtered by ProviderID; simultaneously creates Trade.ExposureIDs record |

---

## 6. Dependencies

```
Hedge.GetExposuresForAllHedgeServers (view)
+-- Trade.Hedge (table) [cross-schema - LP trade positions]
+-- Hedge.Netting (table) [see Hedge.Netting.md - netting positions]
+-- Hedge.HedgeServerToLiquidityAccount (table) [maps accounts to servers]
+-- Trade.HedgeRequest (table) [cross-schema - in-flight hedge requests]
+-- Trade.HedgeServer (table) [cross-schema - ConsiderOpenRequestsSec]
```

---

## 7. Sample Queries

### 7.1 Total exposure by instrument across all servers
```sql
SELECT  InstrumentID,
        SUM(Hedged)    AS TotalHedged,
        SUM(Requested) AS TotalRequested,
        SUM(Hedged + Requested) AS TotalExposure
FROM    [Hedge].[GetExposuresForAllHedgeServers] WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY ABS(SUM(Hedged + Requested)) DESC;
```

### 7.2 Find instruments with in-flight requests (non-zero Requested)
```sql
SELECT  ProviderID, InstrumentID, HedgeServerID, Hedged, Requested
FROM    [Hedge].[GetExposuresForAllHedgeServers] WITH (NOLOCK)
WHERE   Requested <> 0
ORDER BY HedgeServerID, InstrumentID;
```

### 7.3 Find net short positions
```sql
SELECT  ProviderID, InstrumentID, HedgeServerID, Hedged
FROM    [Hedge].[GetExposuresForAllHedgeServers] WITH (NOLOCK)
WHERE   Hedged < 0
ORDER BY Hedged ASC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found directly for this view.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | Corrections: 0 applied*
*Object: Hedge.GetExposuresForAllHedgeServers | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetExposuresForAllHedgeServers.sql*
