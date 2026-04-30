# Hedge.Report_Checked_OTW_H1

> Weekend exposure report for HedgeServer 1: returns net lot position (LeftOpen = long lots - short lots) per instrument name for a hardcoded set of forex instruments (IDs 1-19, 27-32) that are configured to remain open through the weekend (CloseOnEndOfWeek=0). Used by the hedge/dealing desk to verify OTW (Open Through Weekend) exposure before market close.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Zero-parameter SELECT; DATA_READER has EXECUTE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_Checked_OTW_H1` is an "Open Through Weekend" (OTW) exposure report for **HedgeServer 1**. Before weekend close, the hedge desk needs to know which instruments will have open positions remaining over the weekend, and what the net exposure is for each.

The procedure computes the net lot position (buy lots minus sell lots = `LeftOpen`) for a hardcoded list of 24 forex instrument IDs on HedgeServer 1, filtering to only positions that are NOT configured to auto-close at end of week (`CloseOnEndOfWeek = 0`). Positions with `CloseOnEndOfWeek = 1` are already scheduled to close automatically and are excluded from the OTW check.

The result (instrument name + net lots) gives the dealing desk visibility into weekend exposure that requires manual management or monitoring.

Note: Both `@HedgeServerID` (hardcoded to 1) and the instrument ID list are hardcoded in the procedure body. A companion procedure `Hedge.Report_Checked_OTW_H21_H22` covers HedgeServers 21 and 22 with a subset of the same instruments. The `DATA_READER` role has EXECUTE permission, making this accessible to BI analysts.

---

## 2. Business Logic

### 2.1 Net Lot Position Calculation (LeftOpen)

**What**: Net position per instrument = total buy lots minus total sell lots among OTW-eligible positions.

**Columns/Parameters Involved**: `IsBuy`, `LotCountDecimal`, `CloseOnEndOfWeek`

**Rules**:
- `SUM(CASE WHEN IsBuy=1 THEN LotCountDecimal ELSE 0 END)` = total buy-side lots for this instrument.
- `SUM(CASE WHEN IsBuy=0 THEN -LotCountDecimal ELSE 0 END)` = total sell-side lots (negative by convention).
- `LeftOpen` = sum of both = net lot exposure (positive = net long, negative = net short, zero = flat).
- `CloseOnEndOfWeek = 0`: only includes positions that will remain open over the weekend. Positions with CloseOnEndOfWeek=1 auto-close and don't require OTW monitoring.
- `HedgeServerID IN (1)`: hardcoded to server 1.

### 2.2 Hardcoded Instrument Scope

**What**: The procedure monitors a fixed list of forex instruments (IDs 1-19, 27-32).

**Rules**:
- InstrumentID IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,27,28,29,30,31,32): these are the major and minor forex pairs on server 1.
- Instruments IDs 1-19 = primary FX majors/minors; 27-32 = additional cross pairs.
- Instruments outside this list (e.g., stocks InstrumentID > 99, crypto InstrumentID ~100000) are excluded.
- Instrument names are resolved by joining to `Trade.GetInstrument` (view or table providing InstrumentID -> Name mapping).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure accepts no parameters. Result set:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Name | VARCHAR | Instrument display name (from Trade.GetInstrument), e.g., "EUR/USD", "GBP/USD" |
| 2 | LeftOpen | DECIMAL | Net lot exposure: buy lots - sell lots. Positive = net long, negative = net short, 0 = flat. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.Position | Reader (NOLOCK) | Source of open positions with IsBuy, LotCountDecimal, CloseOnEndOfWeek, HedgeServerID |
| - | Trade.GetInstrument | Reader (NOLOCK) | Resolves InstrumentID to Name |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Called by dealing desk and BI analysts for weekend OTW exposure review.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_Checked_OTW_H1 (procedure)
|-- Trade.Position (table) [READ - open positions on HedgeServer 1 for OTW instruments]
+-- Trade.GetInstrument (view/table) [READ - instrument name resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Open positions: LotCountDecimal, IsBuy, CloseOnEndOfWeek, HedgeServerID, InstrumentID |
| Trade.GetInstrument | View/Table | InstrumentID -> Name lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DATA_READER (role) | Permission | EXECUTE - BI/analytics access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Hardcoded HedgeServerID IN (1) | Scope limitation | Only covers server 1. Use Report_Checked_OTW_H21_H22 for servers 21/22. |
| Hardcoded InstrumentID IN (...) | Scope limitation | Only the 24 listed forex instruments. Other instruments are not monitored by this procedure. |
| No TRY/CATCH | Error propagation | Exceptions propagate directly to the caller. |
| NOLOCK on both tables | Isolation | Read uncommitted for performance on high-frequency tables. |

---

## 8. Sample Queries

### 8.1 Execute the OTW report for server 1
```sql
EXEC [Hedge].[Report_Checked_OTW_H1]
-- Returns: Name (instrument name) | LeftOpen (net lot exposure)
-- Positive LeftOpen = net long; Negative = net short; 0 = flat
```

### 8.2 Manually replicate for a different server or instrument set
```sql
SELECT TGI.Name,
       SUM(CASE WHEN IsBuy=1 THEN LotCountDecimal ELSE 0 END)
     + SUM(CASE WHEN IsBuy=0 THEN -LotCountDecimal ELSE 0 END) AS LeftOpen
FROM Trade.Position TP WITH (NOLOCK)
JOIN Trade.GetInstrument TGI WITH (NOLOCK) ON TGI.InstrumentID = TP.InstrumentID
WHERE TP.InstrumentID IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,27,28,29,30,31,32)
  AND HedgeServerID IN (2)     -- change server as needed
  AND CloseOnEndOfWeek = 0
GROUP BY TGI.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_Checked_OTW_H1 | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_Checked_OTW_H1.sql*
