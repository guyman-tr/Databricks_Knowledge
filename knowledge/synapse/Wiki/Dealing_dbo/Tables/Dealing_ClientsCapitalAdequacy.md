# Dealing_dbo.Dealing_ClientsCapitalAdequacy

> Daily regulatory capital adequacy report showing aggregate client open position values (long and short) segmented by regulation, instrument type, and Real vs CFD settlement mode.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — aggregation of BI_DB_PositionPnL with customer/regulation dimensions |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_ClientsCapitalAdequacy is a daily regulatory reporting table that tracks the aggregate notional value of client open positions, split by long and short directions, across 15 regulatory jurisdictions (CySEC, FCA, ASIC, FinCEN, etc.), 6 instrument types (Stocks, ETF, Crypto, Indices, Commodities, Forex), and 2 settlement modes (Real and CFD). This data supports eToro's capital adequacy calculations under IFR (Investment Firms Regulation) for KPMG audit reporting.

The data is computed by `SP_Capital_Adequacy_IFR_KPMG`, which reads from `BI_DB_dbo.BI_DB_PositionPnL` (the position-level P&L fact table) and enriches it with customer validation from `DWH_dbo.Fact_SnapshotCustomer`, filtering to verified depositing customers only (VerificationLevelID IN 2,3 — verified or fully verified; PlayerStatusID NOT IN 2,4,14 — excludes suspended, closed, and demo accounts).

Refreshed daily as part of the Dealing_dbo ETL process (Priority 21 in OpsDB). The SP deletes and reloads for the target date.

---

## 2. Business Logic

### 2.1 Capital Adequacy Position Aggregation

**What**: Aggregates the Net Open Position (NOP) value from individual position-level data into regulatory reporting buckets.

**Columns Involved**: `Clients_Long_OP`, `Clients_Short_OP`, `Real/CFD`, `InstrumentType`, `Regulation`

**Rules**:
- Long = `SUM(NOP)` where `IsBuy=1` — total notional value of long positions
- Short = `SUM(ABS(NOP))` where `IsBuy=0` — total notional value of short positions (absolute)
- Grouped by InstrumentType + Real/CFD + Regulation
- Only includes validated depositing customers: `IsValidCustomer=1`, `IsDepositor=1`, `VerificationLevelID IN (2,3)`, `PlayerStatusID NOT IN (2,4,14)`
- Real/CFD derived from `IsSettled`: 1=Real (settled), 0=CFD (unsettled)

### 2.2 Regulatory Jurisdiction Mapping

**What**: Maps each customer to their regulatory entity via Dim_Regulation.

**Columns Involved**: `Regulation`

**Rules**:
- Regulation name from `DWH_dbo.Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`
- 15 distinct regulations: CySEC, FCA, ASIC, FSRA, FSA Seychelles, FinCEN, BVI, MAS, NFA, eToroUS, FINRAONLY, FinCEN+FINRA, NYDFS+FINRA, ASIC & GAML, None
- Some composite regulations (e.g., "FinCEN+FINRA") represent US dual-registered entities

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Always filter by `Date` for optimal performance. With ~125K rows total, scans are fast.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Capital adequacy by regulation for a date | `WHERE Date = @Date GROUP BY Regulation` and `SUM(Clients_Long_OP)` |
| Compare Real vs CFD exposure | `WHERE Date = @Date GROUP BY [Real/CFD]` |
| Track exposure trend over time | `WHERE Date BETWEEN @Start AND @End AND Regulation = 'CySEC'` |
| Total platform exposure on a date | `WHERE Date = @Date` then `SUM(Clients_Long_OP + Clients_Short_OP)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_dbo.Dealing_LP_StocksNOP | ON Date AND InstrumentType AND [Real/CFD] | Compare client exposure vs LP hedged volume |
| Dealing_dbo.Dealing_NOP_LPandClients | ON Date | Correlate with overall NOP metrics |
| DWH_dbo.Dim_Regulation | ON Regulation = Name | Get regulation details and entity information |

### 3.4 Gotchas

- The `Real/CFD` column uses a slash character — always quote it in queries: `[Real/CFD]`
- Regulation "None" exists for customers with no assigned regulation — these may be pre-migration or test accounts
- Values are in monetary units (money type) — these are NOP notional values in the position's currency, not USD-converted
- The customer filter (VerificationLevelID, PlayerStatusID) means unverified and suspended accounts are excluded — actual platform exposure may be higher

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_Capital_Adequacy_IFR_KPMG)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for this capital adequacy snapshot. Set from SP `@Date` parameter. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 2 | Real/CFD | varchar(50) | YES | Position settlement mode. `CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD' END` from BI_DB_PositionPnL.IsSettled. Real = actual asset ownership; CFD = contract for difference. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 3 | InstrumentType | varchar(100) | YES | Asset class of the instruments in this aggregation bucket. Values: Stocks, ETF, Crypto Currencies, Indices, Commodities, Forex/Currencies. From `DWH_dbo.Dim_Instrument.InstrumentType` via InstrumentID JOIN. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 4 | Clients_Long_OP | money | YES | Total client long open positions NOP value. `SUM(CASE WHEN IsBuy=1 THEN NOP ELSE 0 END)` from BI_DB_PositionPnL grouped by InstrumentType, Real/CFD, Regulation. Filtered to valid depositing verified customers only. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 5 | Clients_Short_OP | money | YES | Total client short open positions NOP value (absolute). `SUM(CASE WHEN IsBuy=0 THEN ABS(NOP) ELSE 0 END)` from BI_DB_PositionPnL. Always positive. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 6 | UpdateDate | datetime | NO | ETL load timestamp — `GETDATE()` at SP execution time. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 7 | Regulation | varchar(40) | YES | Regulatory jurisdiction name. From `DWH_dbo.Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`. Values include: CySEC, FCA, ASIC, FSRA, FSA Seychelles, FinCEN, BVI, MAS, NFA, eToroUS, FINRAONLY, FinCEN+FINRA, NYDFS+FINRA, ASIC & GAML, None. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |

---

## 5. Lineage

### 5.1 Production Sources

This table aggregates from DWH-layer tables. The ultimate production sources are `etoro.Trade.PositionTbl` (via BI_DB_PositionPnL) and `etoro.Customer.Customer` (via Fact_SnapshotCustomer).

Full lineage: see [Dealing_ClientsCapitalAdequacy.lineage.md](Dealing_ClientsCapitalAdequacy.lineage.md)

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL ─────┐
DWH_dbo.Fact_SnapshotCustomer ───┤
DWH_dbo.Dim_Instrument ──────────┤──► SP_Capital_Adequacy_IFR_KPMG ──► Dealing_ClientsCapitalAdequacy
DWH_dbo.Dim_Range ───────────────┤
DWH_dbo.Dim_Regulation ──────────┘
```

| Step | Object | Description |
|------|--------|-------------|
| Source | BI_DB_dbo.BI_DB_PositionPnL | Daily position-level P&L with NOP values |
| Source | DWH_dbo.Fact_SnapshotCustomer | Customer validation: IsValidCustomer, IsDepositor, VerificationLevel, PlayerStatus |
| Source | DWH_dbo.Dim_Instrument | Instrument type classification |
| Source | DWH_dbo.Dim_Regulation | Regulatory entity names |
| ETL | SP_Capital_Adequacy_IFR_KPMG | Aggregates NOP by regulation/instrument/settlement, filters to verified depositors |
| Target | Dealing_ClientsCapitalAdequacy | Daily capital adequacy snapshot |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation | Regulatory entity lookup |
| InstrumentType | DWH_dbo.Dim_Instrument | Instrument asset class |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (External reports) | Date, Regulation | Used in IFR/KPMG capital adequacy audit reporting |

---

## 7. Sample Queries

### 7.1 Capital adequacy summary by regulation for latest date

```sql
SELECT
    Regulation,
    SUM(Clients_Long_OP) AS Total_Long,
    SUM(Clients_Short_OP) AS Total_Short,
    SUM(Clients_Long_OP) + SUM(Clients_Short_OP) AS Total_Exposure
FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy)
GROUP BY Regulation
ORDER BY Total_Exposure DESC;
```

### 7.2 Real vs CFD exposure trend for CySEC

```sql
SELECT Date, [Real/CFD],
    SUM(Clients_Long_OP) AS Long_OP,
    SUM(Clients_Short_OP) AS Short_OP
FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy
WHERE Regulation = 'CySEC' AND Date >= DATEADD(MONTH, -3, GETDATE())
GROUP BY Date, [Real/CFD]
ORDER BY Date DESC;
```

### 7.3 Crypto exposure across all regulations

```sql
SELECT
    Date,
    Regulation,
    [Real/CFD],
    Clients_Long_OP,
    Clients_Short_OP
FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy
WHERE InstrumentType = 'Crypto Currencies'
    AND Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy)
ORDER BY Clients_Long_OP DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [eToro Entities (Regulation)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137345250/eToro+Entities+Regulation) | Confluence | Mapping of eToro entities to regulatory jurisdictions (CySEC, FCA, ASIC, etc.) |
| [Regulation Metrics](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12020319207/Regulation+Metrics) | Confluence | Regulation-level metrics validation using DWH_dbo.Dim_Regulation |
| [Dealing System Architecture](https://etoro-jira.atlassian.net/wiki/spaces/CTO/pages/11532107859/Dealing+System+Architecture) | Confluence | Overall dealing system architecture context |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_ClientsCapitalAdequacy | Type: Table | Production Source: Derived (DWH-computed)*
