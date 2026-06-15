# BI_DB_dbo.BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation

> 263K-row daily equity and cash breakdown table for **United Kingdom** customers across three regulations (CySEC/BVI/NFA), segmented by player status, account type, club, and MiFID category. Covers Jan 2021–Apr 2026. Each row aggregates balance sheet components for a unique dimension combination: available cash, in-copy cash, negative liabilities, NWA, and equity split by asset class (real crypto, real stocks, CFD). Written by `SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation` as a UK-scoped GROUP BY aggregation of `BI_DB_Client_Balance_Aggregate_Level_New`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` — UK slice (Country='United Kingdom', Regulation IN ('CySEC','BVI','NFA'), TransferDirection=1) |
| **Refresh** | Daily — DELETE WHERE DateID=@DateID + INSERT (via `SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation`) |
| **OpsDB Priority** | 20 (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation` is a **UK-only regulatory equity dashboard feed** that slices the daily client balance aggregate into its component equity types (real crypto, real stocks, CFD), available cash pools, and structural liabilities. Each row represents one unique combination of `DateID × Country × Regulation × PlayerStatus × AccountType × Club × MifidCategory × IsGermanBaFin × IsCreditReportValidCB` for United Kingdom customers.

**What it answers**: On a given date, how much total equity do UK customers hold in each asset class (crypto, stocks, CFD) and cash component, broken down by regulation, customer segment, and MiFID category?

Key behavioral notes:
- **Country is always 'United Kingdom'** — the SP applies a hard `Country='United Kingdom'` filter before aggregating
- **IsGermanBaFin is always 0** — the UK filter inherently excludes German BaFin customers
- **Regulation is one of CySEC, BVI, or NFA** — the three regulations applicable to UK-registered customers
- **263,369 rows spanning Jan 2021 – Apr 2026** (5.3 years) at ~135–160 rows/day (reflecting the dimension cross-product of 3 regulations × 9 player statuses × 9 account types × 7 clubs × 6 MiFID categories, filtered to non-empty combinations)
- The ETL writes daily: `DELETE FROM ... WHERE DateID = @DateID` then `INSERT` from the aggregation temp table `#Equity_Real_Crypto_Stocks_Total_Cash`

---

## 2. Business Logic

### 2.1 Source Aggregation — Single-Table GROUP BY

**What**: All 20 columns derive from `BI_DB_Client_Balance_Aggregate_Level_New` via a single aggregation query.

**Columns Involved**: All columns

**Rules**:
- Pre-filter applied before GROUP BY: `Country = 'United Kingdom'`, `Regulation IN ('CySEC', 'BVI', 'NFA')`, `TransferDirection = 1`
- GROUP BY keys: DateID, Country, Regulation, IsGermanBaFin, PlayerStatus, IsCreditReportValidCB, AccountType, Club, MifidCategory
- All nine metric columns are `SUM(ISNULL(source_col, 0))`

### 2.2 Equity Type Decomposition

**What**: The SP splits total equity into three mutually exclusive asset-class buckets.

**Columns Involved**: EquityRealCrypto, EquityRealStocks, EquityCFD

**Rules**:
- `EquityRealCrypto = SUM(TotalRealCrypto + PositionPNLCryptoReal)` — market value + unrealised P&L for real (blockchain-settled) crypto positions
- `EquityRealStocks = SUM(TotalRealStocks + PositionPNLStocksReal)` — market value + unrealised P&L for real (CREST/DTC-settled) stock positions
- `EquityCFD = SUM((PositionAmount + PositionPNL) − (TotalRealCrypto + PositionPNLCryptoReal + TotalRealStocks + PositionPNLStocksReal))` — total equity minus real crypto and real stocks; represents CFD and derivative positions
- The three buckets are additive: `EquityRealCrypto + EquityRealStocks + EquityCFD ≈ total position equity` (before cash)

### 2.3 Cash Decomposition Formula

**What**: `TotalCash_Calc` aggregates all cash and equity components into a single net balance figure.

**Columns Involved**: TotalCash_Calc, AvailableCash, CashInCopy, InProcessCashout, EquityCFD, TotalNegativeLiability, ActualNWA

**Rules**:
- `TotalCash_Calc = SUM(AvailableCash + CashInCopy + InProcessCashout + EquityCFD − TotalNegativeLiability − ActualNWA)`
- Note: real crypto and real stocks equity are **excluded** from TotalCash_Calc — only CFD equity contributes
- TotalNegativeLiability is subtracted (already negative in source; net negative liability)
- ActualNWA is subtracted (non-withdrawable bonus principal does not contribute to cash)

### 2.4 TransferDirection Filter

**What**: The SP pre-filters `TransferDirection = 1` before aggregating, excluding transferred-customer rows.

**Columns Involved**: (TransferDirection not in output — filter-only)

**Rules**:
- `TransferDirection = 1` in the source table means "current regulation row" (not a regulation-transfer record)
- This ensures only active customer balance rows are summed, avoiding double-counting from regulation-transfer paths in the parent table

---

## 3. Query Advisory

### 3.1 Distribution and Index

- **ROUND_ROBIN**: No hash key; queries are full scans unless filtered on DateID
- **Clustered index on DateID**: Always filter with `WHERE DateID = @d` or bounded ranges for date-specific reports

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total UK equity by regulation on a given date | `WHERE DateID=@d GROUP BY Regulation SUM(EquityCFD+EquityRealCrypto+EquityRealStocks)` |
| Cash balance by club tier and MiFID category | `WHERE DateID=@d GROUP BY Club, MifidCategory SUM(AvailableCash)` |
| Net cash at aggregate level | `WHERE DateID=@d SUM(TotalCash_Calc)` |
| Trend of real crypto equity by regulation | `WHERE DateID BETWEEN @start AND @end GROUP BY DateID, Regulation SUM(EquityRealCrypto)` |
| Available cash for CB-valid customers only | `WHERE DateID=@d AND IsCreditReportValidCB=1 SUM(AvailableCash)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Client_Balance_Aggregate_Level_New | DateID, Country, Regulation, IsCreditReportValidCB, Club, PlayerStatus, AccountType, MifidCategory | Drill back to full aggregate grain or compare metrics |
| Dim_Date | DateID = DateID | Enrich with calendar attributes (YearMonth, quarter) |

### 3.4 Gotchas

- **Country is always 'United Kingdom'** — filtering on other countries returns zero rows
- **IsGermanBaFin is always 0** — the column exists but carries no information in this table
- **Regulation is always one of CySEC, BVI, NFA** — other regulations (e.g., ASIC, FCA) are excluded by the SP filter
- **TotalCash_Calc excludes real crypto and real stocks** — use `TotalCash_Calc + EquityRealCrypto + EquityRealStocks` for total wealth view
- **TransferDirection pre-filtered to 1** — transfer-in-progress rows from the parent table are excluded; this table represents current-regulation balances only
- **Not a full platform view** — this table covers UK customers only; use `BI_DB_Client_Balance_Aggregate_Level_New` for global segments

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream production wiki verbatim |
| Tier 2 | From SP code (`SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation`) and parent table lineage (`BI_DB_Client_Balance_Aggregate_Level_New`) |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — unverified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date dimension key (YYYYMMDD integer, e.g. 20210101). Clustered index key. Range: 20210101–20260412. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 2 | Country | varchar(100) | YES | Customer's registered country. Always 'United Kingdom' in this table — the SP applies a hard Country='United Kingdom' filter before aggregating. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 3 | Regulation | varchar(100) | YES | Regulatory jurisdiction governing the customer's account. Values: CySEC (66%), BVI (31%), NFA (3%). Restricted by SP filter (Regulation IN ('CySEC','BVI','NFA')). (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 4 | IsGermanBaFin | int | YES | Flag for German BaFin-regulated customers. Always 0 in this table — UK customers are not subject to BaFin. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 5 | PlayerStatus | varchar(100) | YES | Customer account status at the time of the ETL run. Values observed: Normal, Trade & MIMO Blocked, Blocked, Deposit Blocked, Blocked Upon Request, Block Deposit & Trading, Warning, Copy Block, Pending Verification. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 6 | IsCreditReportValidCB | int | YES | Flag indicating whether the customer has a valid credit bureau report (used for K-CMH capital adequacy calculations). 1=valid (81.5%), 0=not valid (18.5%). (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 7 | AccountType | varchar(100) | YES | Customer account classification. Values: Private, Affiliate Private Account, Affiliate Corporate Account, Joint Account, Fund, Corporate, Employee Account, Analyst, White Label. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 8 | Club | varchar(100) | YES | Customer loyalty tier. Values: Bronze, Internal, Silver, Gold, Platinum Plus, Platinum, Diamond. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 9 | MifidCategory | varchar(100) | YES | MiFID II investor categorisation. Values: Retail, Retail Pending, Pending, Elective professional, Professional, None. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 10 | AvailableCash | decimal(18,6) | YES | SUM of available cash (free balance not allocated to positions). Sourced from BI_DB_Client_Balance_Aggregate_Level_New.AvailableCash. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 11 | CashInCopy | decimal(18,6) | YES | SUM of cash currently allocated to copy-trading relationships. Sourced from BI_DB_Client_Balance_Aggregate_Level_New.CashInCopy. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 12 | TotalNegativeLiability | decimal(18,6) | YES | SUM of total negative liability (net negative balance / margin shortfall). Sourced from BI_DB_Client_Balance_Aggregate_Level_New.TotalNegativeLiability. Typically negative values; subtracted in TotalCash_Calc. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 13 | InProcessCashout | decimal(18,6) | YES | SUM of withdrawal amounts in processing (approved but not yet settled). Sourced from BI_DB_Client_Balance_Aggregate_Level_New.InProcessCashout. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 14 | ActualNWA | decimal(18,6) | YES | SUM of non-withdrawable amount (bonus principal). Subtracted in TotalCash_Calc because bonuses are not cashable. Sourced from BI_DB_Client_Balance_Aggregate_Level_New.actualNWA. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 15 | EquityRealCrypto | decimal(18,6) | YES | SUM of market value plus unrealised P&L for blockchain-settled (real) crypto positions. Formula: SUM(TotalRealCrypto + PositionPNLCryptoReal). (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 16 | EquityRealStocks | decimal(18,6) | YES | SUM of market value plus unrealised P&L for CREST/DTC-settled (real) stock positions. Formula: SUM(TotalRealStocks + PositionPNLStocksReal). (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 17 | EquityCFD | decimal(18,6) | YES | SUM of net equity in CFD and derivative positions. Formula: SUM((PositionAmount+PositionPNL) − (TotalRealCrypto+PositionPNLCryptoReal+TotalRealStocks+PositionPNLStocksReal)). Total position equity minus real asset classes. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 18 | TotalCash_Calc | decimal(18,6) | YES | SUM of the net cash balance incorporating all cash and CFD equity components. Formula: SUM(AvailableCash + CashInCopy + InProcessCashout + EquityCFD − TotalNegativeLiability − ActualNWA). Note: real crypto and real stocks equity are excluded. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |
| 19 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT time. Range: 2022-06-09 to 2026-04-13, reflecting 1,397 daily ETL runs. (Tier 2 — SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID–MifidCategory (9 cols) | BI_DB_Client_Balance_Aggregate_Level_New | same names | GROUP BY passthrough; filtered to Country='United Kingdom', Regulation IN ('CySEC','BVI','NFA'), TransferDirection=1 |
| AvailableCash | BI_DB_Client_Balance_Aggregate_Level_New | AvailableCash | SUM(ISNULL(.,0)) |
| CashInCopy | BI_DB_Client_Balance_Aggregate_Level_New | CashInCopy | SUM(ISNULL(.,0)) |
| TotalNegativeLiability | BI_DB_Client_Balance_Aggregate_Level_New | TotalNegativeLiability | SUM(ISNULL(.,0)) |
| InProcessCashout | BI_DB_Client_Balance_Aggregate_Level_New | InProcessCashout | SUM(ISNULL(.,0)) |
| ActualNWA | BI_DB_Client_Balance_Aggregate_Level_New | actualNWA | SUM(ISNULL(.,0)) |
| EquityRealCrypto | BI_DB_Client_Balance_Aggregate_Level_New | TotalRealCrypto + PositionPNLCryptoReal | SUM(TotalRealCrypto + PositionPNLCryptoReal) |
| EquityRealStocks | BI_DB_Client_Balance_Aggregate_Level_New | TotalRealStocks + PositionPNLStocksReal | SUM(TotalRealStocks + PositionPNLStocksReal) |
| EquityCFD | BI_DB_Client_Balance_Aggregate_Level_New | PositionAmount, PositionPNL, TotalRealCrypto, PositionPNLCryptoReal, TotalRealStocks, PositionPNLStocksReal | SUM((PositionAmount+PositionPNL)−real assets) |
| TotalCash_Calc | BI_DB_Client_Balance_Aggregate_Level_New | multi-column formula | SUM(cash+CFD−liabilities−NWA) |
| UpdateDate | ETL | GETDATE() | Set at INSERT |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New  (P99 parent — daily aggregate)
  |-- SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation @Date
  |   Pre-filter: Country='United Kingdom', Regulation IN ('CySEC','BVI','NFA'), TransferDirection=1
  |   Temp table: #Equity_Real_Crypto_Stocks_Total_Cash (HEAP, ROUND_ROBIN)
  |   GROUP BY: 9 dimension keys, SUM: 9 metric columns
  |-- DELETE WHERE DateID=@DateID
  |-- INSERT
  v
BI_DB_dbo.BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation
  (263,369 rows | Jan 2021 – Apr 2026 | ROUND_ROBIN, CLUSTERED(DateID))
  UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| DateID | Dim_Date | Date dimension for calendar enrichment |
| (source) | BI_DB_Client_Balance_Aggregate_Level_New | Primary source table — this table is a UK-filtered, asset-class-split slice |

### 6.2 Referenced By

No downstream objects found referencing this table in the SSDT repo.

---

## 7. Sample Queries

### UK equity breakdown by regulation on a specific date

```sql
SELECT Regulation,
       SUM(EquityRealCrypto)   AS TotalRealCryptoEquity,
       SUM(EquityRealStocks)   AS TotalRealStocksEquity,
       SUM(EquityCFD)          AS TotalCFDEquity,
       SUM(AvailableCash)      AS TotalAvailableCash,
       SUM(TotalCash_Calc)     AS TotalNetCash
FROM [BI_DB_dbo].[BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation]
WHERE DateID = 20260401
GROUP BY Regulation
ORDER BY Regulation
```

### CB-valid vs non-CB-valid cash breakdown by MiFID category

```sql
SELECT MifidCategory,
       IsCreditReportValidCB,
       SUM(AvailableCash)      AS AvailableCash,
       SUM(ActualNWA)          AS NonWithdrawableAmount,
       SUM(TotalCash_Calc)     AS NetCash
FROM [BI_DB_dbo].[BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation]
WHERE DateID = 20260401
GROUP BY MifidCategory, IsCreditReportValidCB
ORDER BY MifidCategory, IsCreditReportValidCB
```

### Real crypto equity trend over time for professional customers

```sql
SELECT DateID,
       SUM(EquityRealCrypto)   AS TotalRealCryptoEquity,
       SUM(EquityRealStocks)   AS TotalRealStocksEquity
FROM [BI_DB_dbo].[BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation]
WHERE DateID BETWEEN 20260101 AND 20260412
  AND MifidCategory IN ('Professional', 'Elective professional')
GROUP BY DateID
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 14/14*
*Tiers: 0 T1, 19 T2, 0 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation | Type: Table | Production Source: BI_DB_Client_Balance_Aggregate_Level_New (UK slice)*
