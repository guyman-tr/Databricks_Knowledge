# Hedge.Report_Checked_OTW_H21_H22

> Weekend exposure report for HedgeServers 21 and 22: same net lot calculation as Report_Checked_OTW_H1 but covers HedgeServerIDs 21,22 and a narrower instrument subset (IDs 17-19, 27-32). Used by the dealing desk to verify OTW (Open Through Weekend) exposure for the secondary hedge server pair before market close.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Zero-parameter SELECT; DATA_READER has EXECUTE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_Checked_OTW_H21_H22` is the "Open Through Weekend" (OTW) companion to `Hedge.Report_Checked_OTW_H1`, covering **HedgeServers 21 and 22** instead of server 1. It uses identical calculation logic (net lot position per instrument) but with:
- A different server scope: `HedgeServerID IN (22, 21)` (note: 22 listed first)
- A narrower instrument subset: `InstrumentID IN (17,18,19,27,28,29,30,31,32)` - 9 cross/minor FX pairs, a subset of the 24 instruments covered by the H1 version

This implies that HedgeServers 21 and 22 handle a more limited set of instruments than server 1. The overlap with the H1 report on instruments 17-19 and 27-32 allows cross-server comparison for shared instruments.

---

## 2. Business Logic

### 2.1 Net Lot Position Calculation (LeftOpen)

**What**: Identical calculation to Report_Checked_OTW_H1: net lot exposure (buy - sell) per instrument, excluding positions scheduled to auto-close at weekend.

**Columns/Parameters Involved**: `IsBuy`, `LotCountDecimal`, `CloseOnEndOfWeek`

**Rules**:
- Same formula: `SUM(CASE WHEN IsBuy=1 THEN LotCountDecimal ELSE 0 END) + SUM(CASE WHEN IsBuy=0 THEN -LotCountDecimal ELSE 0 END)`.
- `CloseOnEndOfWeek = 0`: excludes auto-close positions (same as H1).
- `HedgeServerID IN (22,21)`: covers both servers in one query. Results aggregated across both servers unless only one has positions.
- `InstrumentID IN (17,18,19,27,28,29,30,31,32)`: minor/cross FX pairs (17-19 are cross pairs; 27-32 are additional crosses).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure accepts no parameters. Result set:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Name | VARCHAR | Instrument display name (from Trade.GetInstrument) |
| 2 | LeftOpen | DECIMAL | Net lot exposure: buy lots - sell lots across both servers (21 and 22). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.Position | Reader (NOLOCK) | Source of open positions for HedgeServers 21,22 |
| - | Trade.GetInstrument | Reader (NOLOCK) | InstrumentID to Name lookup |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Called by dealing desk and BI analysts for weekend OTW review on the H21/H22 server pair.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_Checked_OTW_H21_H22 (procedure)
|-- Trade.Position (table) [READ - open positions on HedgeServers 21,22]
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

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Hardcoded HedgeServerID IN (22,21) | Scope | Only covers servers 21 and 22. Use Report_Checked_OTW_H1 for server 1. |
| Hardcoded InstrumentID IN (...) | Scope | 9 cross/minor FX instruments only. |

---

## 8. Sample Queries

### 8.1 Execute the OTW report for servers 21 and 22
```sql
EXEC [Hedge].[Report_Checked_OTW_H21_H22]
```

### 8.2 Compare H1 vs H21/H22 overlap instruments
```sql
-- Instruments in both reports (overlap set: 17-19, 27-32)
EXEC [Hedge].[Report_Checked_OTW_H1]       -- server 1
EXEC [Hedge].[Report_Checked_OTW_H21_H22]  -- servers 21,22
-- Compare LeftOpen for shared InstrumentIDs
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_Checked_OTW_H21_H22 | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_Checked_OTW_H21_H22.sql*
