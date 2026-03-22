# Dealing_dbo.Dealing_CEP_ExecutionMonitoring

> Daily volume and units by instrument, hedge server, and transaction type — the CEP (Complex Event Processing) rule monitoring table for verifying dealing execution correctness.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.Etoro_Hedge_ExecutionLog` (LP), `DWH_dbo.Dim_Position` (Clients) |
| **Refresh** | Daily |
| **Retention** | 720 days (auto-purged by SP) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table tracks daily dealing execution volumes for CEP rule monitoring. It answers: "For each instrument and hedge server, how much volume (USD) and how many units traded today — split by LP (liquidity provider) executions vs client-side positions?"

The purpose is to verify that CEP rules (automated dealing execution rules) are working correctly by comparing LP-side hedge executions against client-side position activity. Discrepancies between LP and client volumes may indicate CEP misfiring.

Two data streams are UNIONed:
1. **LP stream**: Hedge execution log records from `Dealing_staging.Etoro_Hedge_ExecutionLog`. Volume converted to USD using currency rates from `Fact_CurrencyPriceWithSplit`.
2. **Client stream**: Position opens and closes from `DWH_dbo.Dim_Position`. Categorized as 'Clients', 'IsComputeForHedge=0' (positions excluded from hedge computation), or 'LabelID=30' (internal/test).

Author: Jenia Simonovitch, created 2019-06-04. 720-day retention window.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: Rows are labeled by source and category.

**Columns Involved**: `TranType`

**Rules**:
- `'LP'` — Liquidity provider hedge execution records
- `'IsComputeForHedge=0'` — Client positions excluded from hedge computation
- `'LabelID=30'` — Internal/test account positions (LabelID=30)
- `'Clients'` — Regular client positions (everything else)

### 2.2 USD Volume Conversion (LP)

**What**: LP volumes are in instrument units × execution rate, converted to USD.

**Columns Involved**: `Volume`

**Rules**:
- Base: `Units * ExecutionRate`
- Silver fix: If InstrumentID=19 AND ExecutionRate>100, multiply by 0.01
- XNG fix: If InstrumentID=22 AND ExecutionRate>100, multiply by 0.001
- USD conversion: If SellCurrencyID=1 → already USD. If BuyCurrencyID=1 → divide by ExecutionRate. Otherwise → use Bid/Ask from Fact_CurrencyPriceWithSplit
- When ExecutionRate=0 AND BuyCurrencyID=1 → Volume=0 (no division by zero)

### 2.3 Client IsBuy Flip on Close

**What**: For close positions on the client side, IsBuy is inverted.

**Columns Involved**: `IsBuy`

**Rules**: Open: `IsBuy` as-is. Close: `CASE WHEN IsBuy = 1 THEN 0 ELSE 1 END`. This makes the client close direction match what the LP sees (selling = closing a buy).

### 2.4 Retention

**What**: Data older than 720 days is deleted on each run.

**Rules**: `DELETE WHERE DateID < CAST(CONVERT(VARCHAR(8), DATEADD(day,-720,GETDATE()), 112) AS INT)`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Always filter on Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| LP vs Client volume comparison | `WHERE Date = @date GROUP BY InstrumentID, TranType` and compare LP vs Clients totals |
| Failed LP executions | `WHERE Success = 0 AND Date = @date` |
| Volume by hedge server | `GROUP BY HedgeServerID, TranType WHERE Date = @date` |
| Instrument-level CEP check | Compare `SUM(Volume) WHERE TranType='LP'` vs `SUM(Volume) WHERE TranType='Clients'` per InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Full instrument metadata |
| Dealing_dbo.Dealing_HedgeServer (if exists) | ON HedgeServerID | Hedge server name |

### 3.4 Gotchas

- **Success and LiquidityAccountID are NULL for client rows**: These fields only apply to LP executions.
- **IsBuy is flipped for client closes**: A client closing a Buy position appears as IsBuy=0 in this table (to match LP perspective).
- **Volume is USD-converted**: Not raw instrument units. Use Units column for raw instrument quantities.
- **Silver/XNG rate fixes**: Hardcoded corrections for InstrumentID 19 (Silver) and 22 (XNG) when ExecutionRate is abnormally high.
- **720-day retention**: Historical data is purged. Don't expect data older than ~2 years.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HedgeServerID | int | YES | Liquidity provider server ID. Identifies which hedge server executed (LP) or which server the client position was on (Clients). (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 2 | InstrumentID | int | NO | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 3 | Instrument | varchar(50) | NO | Instrument name from Dim_Instrument.Name. E.g., "EOSE/USD", "HOOD/USD". (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 4 | TranType | varchar(50) | NO | Transaction source type. Values: 'LP' (liquidity provider), 'Clients' (regular clients), 'IsComputeForHedge=0' (excluded from hedge), 'LabelID=30' (internal/test). (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 5 | IsBuy | bit | NO | Trade direction. 1=Buy, 0=Sell. For LP: direct from ExecutionLog. For Clients: flipped on close positions (closing a buy shows as 0). (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 6 | Volume | bigint | YES | USD-converted trade volume. LP: `SUM(Units * ExecutionRate * currency_conversion)` with Silver/XNG rate fixes. Clients: `SUM(CAST(Volume/VolumeOnClose AS BIGINT))`. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 7 | Units | decimal(20,6) | NO | Instrument units traded. LP: `SUM(Units)` from ExecutionLog. Clients: `SUM(AmountInUnitsDecimal)` from Dim_Position. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 8 | DateID | int | NO | Date as YYYYMMDD integer. `Dealing_dbo.DateToDateID(@Date)`. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 10 | Date | date | YES | Report date. `@Date` SP parameter. (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 11 | Success | tinyint | YES | LP execution success flag. 1=success, 0=failure. NULL for client rows. Previously filtered to Success=1 only (removed 2020-02-04). (Tier 2 — SP_CEP_ExecutionMonitoring) |
| 12 | LiquidityAccountID | int | YES | Liquidity provider account identifier. LP rows only, NULL for clients. Added SR-281131 (2024-11-18). (Tier 2 — SP_CEP_ExecutionMonitoring) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
Dealing_staging.Etoro_Hedge_ExecutionLog ─┐
DWH_dbo.Dim_Position + Dim_Customer ──────┼──► UNION → #Final → Dealing_CEP_ExecutionMonitoring
DWH_dbo.Fact_CurrencyPriceWithSplit ──────┘
```

### 5.2 Production Sources

| Source | Role |
|--------|------|
| Dealing_staging.Etoro_Hedge_ExecutionLog | LP hedge execution records |
| DWH_dbo.Dim_Position | Client position opens/closes |
| DWH_dbo.Dim_Customer | Client LabelID for categorization |
| DWH_dbo.Dim_Instrument | Instrument metadata + currency IDs |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Currency conversion rates |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument details |
| HedgeServerID | Dealing infrastructure | Liquidity provider server |
| LiquidityAccountID | Dealing LP accounts | LP account identifier |

---

## 7. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Dealing Execution Production Services and Servers](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11873648846) | Confluence | CEP API service locations and dealing infrastructure |
| [HBC Execution Monitoring](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/11858675769) | Confluence | Possible execution failures and monitoring context |
| [Dealing System Architecture](https://etoro-jira.atlassian.net/wiki/spaces/CTO/pages/11532107859) | Confluence | Dealing system architecture and LP allocation flow |
| SR-223828 | Jira | Migration to Synapse |
| SR-281131 | Jira | Added LiquidityAccountID column |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 8/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_CEP_ExecutionMonitoring | Type: Table | Production Source: Derived (multi-source ETL)*
