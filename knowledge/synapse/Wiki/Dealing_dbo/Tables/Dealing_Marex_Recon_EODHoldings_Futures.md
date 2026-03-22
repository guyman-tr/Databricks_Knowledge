# Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures

> Daily end-of-day futures holdings reconciliation comparing Marex's custodian position for each futures contract against eToro's aggregated client NOP per CID, with lot-based and USD amounts, ADJ-adjusted FX rates, and tolerance pricing.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Marex futures position feed + etoro_Hedge_ExecutionLog/NettingHistory (client side) |
| **Refresh** | Daily (SB_Daily, Priority 0) |
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

Futures-specific EOD holdings reconciliation for Marex. Added in May 2025 to handle eToro's futures product offering. Each row represents one futures position at CID (client) × Contract × IsBuy × OrderID granularity, comparing Marex's EOD custodian lots against eToro's aggregated client position.

**Key structural difference from base Marex recon**: This table reconciles at **CID level** (individual client) rather than at the eToro hedge book level. There is no `eToro_Units` column — the comparison is Marex position vs Client position (`Clients_Lots` / `ClientUnits`). This reflects the futures model where client positions are passed through to Marex 1:1.

`WA_Marex_Price` is the weighted average price from Marex's position file. `MultiplicationFactor` is the futures contract multiplier (number of underlying units per lot). `LastTradingDay` stores the contract expiry date as an integer DateID. `ForexRate_AfterADJ` and `ADJ_Value` are ADJ (adjustment) FX columns added in July 2025.

Written by `SP_Marex_Recon` (Dealing_dbo). DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Lot-Based Reconciliation

**What**: Futures reconciliation uses lots (contracts) rather than units.

**Columns involved**: `Clients_Lots`, `Marex_Lots`, `Marex-Clients_Lots`, `ClientUnits`, `Marex_Units`

**Rules**:
- `Clients_Lots` and `Marex_Lots` are integer lot counts
- `ClientUnits` and `Marex_Units` are decimal unit amounts (= Lots × MultiplicationFactor)
- `Marex-Clients_Lots` = `Marex_Lots − Clients_Lots`; non-zero = lot-level recon break
- `Marex-Clients_Units` and `Marex-Clients_USDAmount` are the USD-level differences

### 2.2 ADJ (Adjusted) FX Rates

**What**: FX rates may be adjusted for settlement purposes (ADJ columns added Jul 2025).

**Columns involved**: `ForexRate`, `ForexRate_AfterADJ`, `ADJ_Value`, `ConversionRate`

**Rules**:
- `ForexRate` = raw FX rate from Marex
- `ForexRate_AfterADJ` = FX rate after ADJ adjustment; used for final USD amount calculation
- `ADJ_Value` = the adjustment factor applied
- `ConversionRate` = eToro's conversion rate for the currency pair

### 2.3 Contract Direction and Metadata

**What**: Each row is direction-specific and carries futures contract metadata.

**Rules**:
- `IsBuy = 1` → long position; `IsBuy = 0` → short position
- `MultiplicationFactor` = number of underlying units per lot (varies by contract)
- `LastTradingDay` = contract expiry as integer DateID
- `Trader` = Marex trader identifier (informational)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date and `CONTRACT` for efficient access. Note high cardinality due to CID granularity.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` to avoid full scans. CID-level granularity means this table may be large relative to other LP recon tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| EOD lot breaks | `WHERE Date=@d AND [Marex-Clients_Lots]<>0` |
| Expiring contracts | `WHERE LastTradingDay = DateToDateID(@today)` |
| Aggregate to instrument level | `GROUP BY Date, InstrumentID, IsBuy` |
| Client with largest position | `GROUP BY Date, CID, InstrumentID ORDER BY SUM(ClientUnits) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_Marex_Recon_Trades_Futures | Date + PositionID | Trade activity for this position |
| DWH_dbo.Dim_Customer | CID | Client details |

### 3.4 Gotchas

- **No eToro hedge column**: Unlike base Marex recon, there is no `eToro_Units` — reconciliation is Marex vs Clients only (futures are passed through 1:1)
- **CID granularity**: Table is at client level — aggregate to InstrumentID/HedgeServerID for book-level analysis
- **ADJ columns added Jul 2025**: `ForexRate_AfterADJ` and `ADJ_Value` are NULL for rows before July 2025
- **Column naming inconsistency**: `Marex_USDAmount` (not `Marex_AmountUSD`) — different from base Marex recon tables
- **SellCurrency and Currency**: Two currency columns — `SellCurrency` is the settlement currency; `Currency` is the underlying instrument currency

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Marex_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. SP parameter; DELETE-INSERT by Date. (Tier 2 — SP_Marex_Recon) |
| 2 | PositionID | bigint | YES | Marex position identifier. Unique identifier for the futures position in Marex's system. (Tier 2 — SP_Marex_Recon) |
| 3 | CID | int | YES | eToro client identifier. Granularity key — each client's position is recorded separately. FK → DWH_dbo.Dim_Customer. (Tier 2 — SP_Marex_Recon) |
| 4 | HedgeServerID | int | YES | eToro hedge server. From eToro netting/history tables. NULL for Marex-only rows. (Tier 2 — SP_Marex_Recon) |
| 5 | CONTRACT | varchar(25) | YES | Marex futures contract code. Uppercase column name; maps to InstrumentID via SP logic. (Tier 2 — SP_Marex_Recon) |
| 6 | ContractName | varchar(150) | YES | Human-readable futures contract name from Marex. (Tier 2 — SP_Marex_Recon) |
| 7 | InstrumentID | int | YES | eToro instrument identifier. Resolved from CONTRACT via mapping logic. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 8 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. (Tier 2 — SP_Marex_Recon) |
| 9 | Exchange | varchar(50) | YES | Futures exchange venue. (Tier 2 — SP_Marex_Recon) |
| 10 | Symbol | varchar(50) | YES | Ticker symbol. (Tier 2 — SP_Marex_Recon) |
| 11 | SellCurrency | varchar(10) | YES | Settlement currency for the contract (P&L currency). (Tier 2 — SP_Marex_Recon) |
| 12 | IsBuy | bit | YES | Position direction: 1=Long, 0=Short. (Tier 2 — SP_Marex_Recon) |
| 13 | ConversionRate | decimal(16,6) | YES | eToro's FX conversion rate for this instrument's currency pair. (Tier 2 — SP_Marex_Recon) |
| 14 | Clients_Lots | int | YES | Client's position in lots (integer lot count). From eToro client netting data. (Tier 2 — SP_Marex_Recon) |
| 15 | Marex_Lots | int | YES | Marex's EOD position in lots. From Marex futures position file. (Tier 2 — SP_Marex_Recon) |
| 16 | WA_Marex_Price | decimal(16,6) | YES | Weighted average Marex price for the position. From Marex position file. (Tier 2 — SP_Marex_Recon) |
| 17 | ForexRate | decimal(16,6) | YES | Raw FX rate from Marex (local → USD) before ADJ adjustment. (Tier 2 — SP_Marex_Recon) |
| 18 | Trader | varchar(100) | YES | Marex trader identifier. Informational; identifies who manages this position at Marex. (Tier 2 — SP_Marex_Recon) |
| 19 | ACCOUNT | varchar(25) | YES | Marex LP account code. Uppercase column name. (Tier 2 — SP_Marex_Recon) |
| 20 | Currency | varchar(10) | YES | Underlying instrument currency (not settlement currency — see SellCurrency). (Tier 2 — SP_Marex_Recon) |
| 21 | MultiplicationFactor | int | YES | Futures contract multiplier: number of underlying units per lot. (Tier 2 — SP_Marex_Recon) |
| 22 | LastTradingDay | int | YES | Contract expiry date as integer DateID. (Tier 2 — SP_Marex_Recon) |
| 23 | ClientUnits | decimal(16,6) | YES | Client's position in units (= Clients_Lots × MultiplicationFactor). From eToro client netting. (Tier 2 — SP_Marex_Recon) |
| 24 | Marex_Units | decimal(16,6) | YES | Marex's position in units (= Marex_Lots × MultiplicationFactor). From Marex position file. (Tier 2 — SP_Marex_Recon) |
| 25 | ClientsLocalAmount | money | YES | Client NOP in local currency. From eToro client netting. (Tier 2 — SP_Marex_Recon) |
| 26 | Marex_LocalAmount | money | YES | Marex position value in local currency. (Tier 2 — SP_Marex_Recon) |
| 27 | ClientsUSDAmount | money | YES | Client NOP in USD. From eToro client netting. (Tier 2 — SP_Marex_Recon) |
| 28 | Marex_USDAmount | money | YES | Marex position value in USD. Note: named `Marex_USDAmount` here (vs `Marex_AmountUSD` in base tables). (Tier 2 — SP_Marex_Recon) |
| 29 | Marex-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0)`. Unit-level break. (Tier 2 — SP_Marex_Recon) |
| 30 | Marex-Clients_USDAmount | money | YES | **Recon diff**: `ISNULL(Marex_USDAmount,0) − ISNULL(ClientsUSDAmount,0)`. USD break. (Tier 2 — SP_Marex_Recon) |
| 31 | Marex-Clients_Lots | decimal(16,6) | YES | **Recon diff**: `Marex_Lots − Clients_Lots`. Lot-level break. (Tier 2 — SP_Marex_Recon) |
| 32 | Marex-Clients_Price | decimal(16,6) | YES | **Recon diff**: Marex price vs client price. Price discrepancy between Marex and client entry. (Tier 2 — SP_Marex_Recon) |
| 33 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Marex_Recon) |
| 34 | ForexRate_AfterADJ | decimal(16,6) | YES | FX rate after ADJ adjustment (added Jul 2025). NULL for rows before July 2025. (Tier 2 — SP_Marex_Recon) |
| 35 | ADJ_Value | decimal(16,6) | YES | ADJ adjustment factor applied to FX rate (added Jul 2025). NULL for rows before July 2025. (Tier 2 — SP_Marex_Recon) |
| 36 | OrderID | int | YES | Marex order identifier. Links to specific order in Marex system. (Tier 2 — SP_Marex_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| PositionID, CONTRACT, ContractName | Marex futures position feed | Direct from Marex LP file |
| Marex_Lots, WA_Marex_Price | Marex futures position feed | EOD position lots and price |
| Marex_Units, Marex_LocalAmount, Marex_USDAmount | Marex futures position feed | Lots × MultiplicationFactor |
| ForexRate, ForexRate_AfterADJ, ADJ_Value | Marex futures position feed | FX metadata |
| CID, Clients_Lots, ClientUnits | etoro_Hedge client netting data | Client-level position |
| ClientsLocalAmount, ClientsUSDAmount | etoro_Hedge client netting data | Local and USD amounts |
| InstrumentID | Contract mapping or Dim_Instrument | CONTRACT → InstrumentID |
| Diff columns | Computed | Marex − Clients |

### 5.2 ETL Pipeline

```
Marex Futures Position File (LP feed)
  +
etoro_Hedge client netting data (CID-level client positions, Marex futures HS filter)
  → SP_Marex_Recon (JOIN on PositionID/Contract + CID + IsBuy)
  → Dealing_Marex_Recon_EODHoldings_Futures (DELETE-INSERT by Date)
```

*Futures functionality added May 2025. ADJ columns added Jul 2025.*

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| CID | DWH_dbo.Dim_Customer | Client details |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_Marex_Recon_Trades_Futures | Same SP | Trade activity companion |

---

## 7. Sample Queries

### 7.1 EOD futures position breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, CONTRACT, CID, IsBuy,
  Marex_Lots, Clients_Lots, [Marex-Clients_Lots], [Marex-Clients_USDAmount]
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures)
  AND ABS([Marex-Clients_Lots]) > 0
ORDER BY ABS([Marex-Clients_USDAmount]) DESC
```

### 7.2 Expiring contracts (next 7 days)
```sql
SELECT DISTINCT CONTRACT, ContractName, InstrumentID, LastTradingDay,
  SUM(Marex_Lots) AS Total_Marex_Lots
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures)
  AND LastTradingDay BETWEEN CONVERT(int, CONVERT(varchar, DATEADD(DAY,0,GETDATE()),112))
                         AND CONVERT(int, CONVERT(varchar, DATEADD(DAY,7,GETDATE()),112))
GROUP BY CONTRACT, ContractName, InstrumentID, LastTradingDay
```

### 7.3 Aggregate to instrument level (book view)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, IsBuy,
  SUM(Marex_Lots) AS Total_Marex_Lots,
  SUM(Clients_Lots) AS Total_Client_Lots,
  SUM([Marex-Clients_Lots]) AS Total_Break_Lots,
  SUM([Marex-Clients_USDAmount]) AS Total_Break_USD
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures)
GROUP BY Date, InstrumentID, InstrumentDisplayName, IsBuy
ORDER BY ABS(SUM([Marex-Clients_USDAmount])) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.0/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
