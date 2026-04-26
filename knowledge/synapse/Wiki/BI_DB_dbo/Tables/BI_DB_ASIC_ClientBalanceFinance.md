# BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance

> Daily ASIC/ASIC+GAML regulatory client-balance finance report — one row per customer per day showing balance decomposition (opening balance, deposits, withdrawals, closed PnL, current day balance, unrealized position delta, equity, margin, real crypto). ~230K rows per day across 2,451 dates from 2019-07-28 to 2026-04-12 (~565M total rows). Loaded by SP_ASIC_ClientBalanceFinance (Katy F, migrated from RegReportDB_Prod 2019-07-30). Regulatory file — ProcessType 4 (FinanceReportSPS), Priority 99.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + V_Liabilities + Fact_CustomerAction via SP_ASIC_ClientBalanceFinance |
| **Refresh** | Daily (ProcessType=4 FinanceReportSPS, Priority 99). DELETE WHERE Date=@StartDate + INSERT. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC); NONCLUSTERED INDEX on Country; NONCLUSTERED INDEX on CurrentLabel |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | Not in Generic Pipeline mapping |

---

## 1. Business Meaning

Daily regulatory client-balance report for all ASIC and ASIC & GAML regulated customers (RegulationID IN(4,10), IsCreditReportValidCB=1). Each row represents one customer's balance ledger for a single day: opening balance (previous day equity), any deposits/withdrawals/closed-PnL activity during the day, resulting current-day balance, live open-position PnL change, closing equity, total margin committed to open positions, and real crypto asset value.

The table is the ASIC regulatory reporting source — used for regulatory submissions, audits, and finance reconciliation. ~230,517 rows on 2026-04-12 (ASIC & GAML: 92.6%, ASIC: 7.4%). The `Customer` column contains the ASIC account identifier (`Dim_Customer.ExternalID`) — a 20-digit numeric string, NOT a customer name.

Key caveats:
- **`PreviuosDayBalance`** — DDL typo (missing 'o' in "Previous") baked into DDL and SP; all queries must use misspelled name.
- **`Deposit`** — composite field: actual deposits PLUS chargeback losses and other negative balance adjustments, not just raw deposit events.
- **`IsGermanBaFin`** — legacy indicator for German customers with real crypto who registered before 2023-07-13 BaFin cut-off. Effectively obsolete as of 2026 (1 row on 2026-04-12).
- **Zero-row exclusion** — rows where all balance/action components are zero are silently excluded from the load (reduces noise, means absence = all zeros, not missing customer).

---

## 2. Business Logic

### 2.1 Population Scope

**What**: ASIC-regulated, valid customers only.
**Columns Involved**: CID, RegulationName
**Rules**:
- `RegulationID IN (4, 10)` at current snapshot date — RegulationID 4 = ASIC, 10 = ASIC & GAML
- `IsCreditReportValidCB = 1` — customer must be credit-report-valid (active regulatory status)
- Population sourced from `DWH_dbo.Fact_SnapshotCustomer` SCD2 join via `V_M2M_Date_DateRange`

### 2.2 Balance Decomposition Formula

**What**: CurrentDayBalance is a full daily reconciliation.
**Columns Involved**: PreviuosDayBalance, Deposit, Withdrawal, ClosedPnL, CurrentDayBalance
**Rules**:
- `PreviuosDayBalance` = previous day's closing equity (V_Liabilities.Liabilities with negative adjustment removed)
- `Deposit` = SUM of ActionTypeIDs 7,11,12,13,35,36 (deposits/credits) minus ActionTypeID 30 (commission) plus ChargebackLoss plus OtherNegative
- `Withdrawal` = -1 × SUM(Amount) WHERE ActionTypeID=8 (cashout)
- `ClosedPnL` = SUM(NetProfit) WHERE ActionTypeID IN(4,5,6,28,40) (position close events)
- `CurrentDayBalance` = PreviuosDayBalance + Deposit + ClosedPnL (note: Withdrawal is stored separately as a component visible in Deposit formula but not double-counted — Deposit includes net of withdrawals via action type routing)
- `Equity` = current day V_Liabilities.Liabilities adjusted for negatives (closing balance)

### 2.3 Label Normalization

**What**: Broker label is simplified for reporting.
**Columns Involved**: CurrentLabel, PrevLabel
**Rules**:
- Any `Dim_Label.Name` LIKE '%eToro%' → stored as 'eToro'
- Observed values 2026-04-12: eToro (99.8%), ICMarkets (0.2%), Royal-CM (<0.1%)
- `CurrentLabel` = current day label; `PrevLabel` = previous day label. Difference signals a label migration event.

### 2.4 Real Crypto vs Standard Equity

**What**: Separate tracking of real crypto asset value.
**Columns Involved**: RealAssetEquity, Equity
**Rules**:
- `RealAssetEquity` = V_Liabilities.TotalRealCrypto + PositionPnLCryptoReal (real crypto holdings plus real crypto PnL)
- `Equity` includes all asset types; `RealAssetEquity` is the crypto-only component
- 30.4% of ASIC customers have non-zero RealAssetEquity as of 2026-04-12

### 2.5 German BaFin Legacy Indicator

**What**: Legacy flag for a historical BaFin regulatory requirement.
**Columns Involved**: IsGermanBaFin
**Rules**:
- 1 if: CountryID=79 (Germany) AND RegisteredReal < 2023-07-13 AND has non-zero LiabilitiesCryptoReal
- Determined via `V_GermanBaFin` JOIN (which references `BI_DB_IsGermanBafin_Freeze_20230712`)
- As of 2026-04-12: 1 row with IsGermanBaFin=1 (essentially obsolete, regulatory cut-off passed)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN — data is evenly distributed across distributions. No data-local JOINs available. The CLUSTERED INDEX on (Date ASC, CID ASC) makes single-date or CID+date range queries efficient. For regulatory reporting across all customers on a specific date, filter `WHERE Date = @date` first to minimize scan range.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily balance for a specific customer | `WHERE CID = @cid ORDER BY Date` — CLUSTERED INDEX on (Date, CID), add Date range |
| All ASIC customers on a specific date | `WHERE Date = '2026-04-12'` — cluster-range scan, ~230K rows |
| Customers with deposit activity today | `WHERE Date = @date AND Deposit > 0` — 270 rows 2026-04-12 |
| Balance trend (rolling lookback) | `WHERE CID = @cid AND Date BETWEEN @from AND @to` |
| German BaFin population | `WHERE IsGermanBaFin = 1` — effectively 1 row as of 2026 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `BI_DB.CID = Dim_Customer.RealCID` | Customer name, GCID, registration date |
| DWH_dbo.Dim_Country | `BI_DB.Country = Dim_Country.Abbreviation` | Full country name, region |
| DWH_dbo.Dim_Regulation | `BI_DB.RegulationName = Dim_Regulation.Name` | Full regulation info |

### 3.4 Gotchas

- **`PreviuosDayBalance` typo** — always use the misspelled column name exactly as in DDL (double-check: `PreviuosDayBalance` not `PreviousDayBalance`)
- **`Deposit` is not just deposits** — it includes chargeback compensation and other negative balance adjustments; cannot be compared directly to Fact_CustomerAction deposit sums
- **`Customer` is not a name** — it's `Dim_Customer.ExternalID` (ASIC account ID, 20-digit numeric string); not human-readable
- **Zero-row exclusion** — customers with all-zero balances are absent; absence means zero balance, not missing from ASIC population
- **Single-date snapshot** — each daily ETL run DELETEs the day first then re-INSERTs; backfill-safe but historical rows for a given date can change if SP re-runs
- **`IsGermanBaFin` obsolete** — do not build new workflows on this flag; 1 row as of 2026-04-12
- **RegulationID vs DWHRegulationID** — the SP uses `RegulationID IN(4,10)` which are DWH internal IDs, not the Synapse Dim_Regulation DimID

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source → DWH dimension wiki) |
| Tier 2 | Derived from SP code analysis (ETL-computed or SP-logic-traced) |
| Tier 3 | Inferred from data patterns / partial code analysis |
| Tier 4 | Best-guess / no source traceable |
| Propagation | ETL metadata column (timestamp, file ref, batch marker) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL date integer key in YYYYMMDD format. Computed as CONVERT(VARCHAR(8), @StartDate, 112). Used for date-range JOIN with DateRange tables. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 2 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: filtered to ASIC/ASIC+GAML regulated, IsCreditReportValidCB=1 population from Fact_SnapshotCustomer. (Tier 1 — Customer.CustomerStatic) |
| 3 | Date | date | YES | Snapshot date for this row. The @StartDate parameter value passed to the SP. One row per CID per date. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 4 | Customer | varchar(50) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. DWH note: passthrough from Dim_Customer.ExternalID, stored as varchar(50); in ASIC context serves as the ASIC account identifier (20-digit numeric string, e.g., "56652263734277170001"). (Tier 1 — Customer.CustomerStatic) |
| 5 | PreviuosDayBalance | money | YES | Previous day's opening balance (closing equity from yesterday). ROUND(V_Liabilities.Liabilities - negative_liability_adjustment, 2) at DateID=@dprev_int. DDL typo: 'PreviuosDayBalance' not 'PreviousDayBalance' — baked into DDL and SP; all queries must use the misspelled name. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 6 | Deposit | money | YES | Net daily inflow. Composite: SUM(Fact_CustomerAction.Amount) for deposit/credit ActionTypeIDs (7,11,12,13,35,36), minus Commission (ActionTypeID=30), plus ChargebackLoss and OtherNegative adjustments from V_Liabilities negative-balance split. Not a pure deposit event count — includes compensations and negative-equity adjustments. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 7 | Withdrawal | money | YES | Daily cashout amount (negative sign). ROUND(SUM(-Amount) WHERE ActionTypeID=8, 2). Stored as negative value representing customer-initiated withdrawals. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 8 | ClosedPnL | money | YES | Realized profit/loss from closed positions on this date. ROUND(SUM(Fact_CustomerAction.NetProfit) WHERE ActionTypeID IN(4,5,6,28,40), 2). (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 9 | CurrentDayBalance | money | YES | Calculated closing balance: PreviuosDayBalance + Deposit + ClosedPnL. Does not include open-position floating PnL (that is captured in OpenPosition and Equity separately). (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 10 | OpenPosition | money | YES | Change in unrealized open-position PnL from yesterday to today. ROUND(today.PositionPnL - yesterday.PositionPnL, 2) from V_Liabilities. Positive = portfolio P&L improved; negative = deteriorated. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 11 | Equity | money | YES | Closing total equity for the day. ROUND(V_Liabilities.Liabilities - negative_liability_adjustment, 2) at DateID=@d_int. Includes all assets (cash + open positions + crypto). (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 12 | TotalOpenMargin | money | YES | Total open-position margin committed (TotalPositionsAmount from V_Liabilities). Sum of all open position notional values. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 13 | RealAssetEquity | money | YES | Real crypto asset value. ISNULL(TotalRealCrypto,0) + ISNULL(PositionPnLCryptoReal,0) from V_Liabilities. Represents the customer's crypto holdings plus crypto unrealized PnL. 30.4% of rows have this non-zero on 2026-04-12. (Tier 2 — SP_ASIC_ClientBalanceFinance) |
| 14 | CurrentLabel | varchar(50) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). DWH note: simplified via CASE WHEN Name LIKE '%eToro%' THEN 'eToro'; current-day snapshot. Values: eToro (99.8%), ICMarkets (0.2%), Royal-CM (<0.1%). (Tier 1 — Dictionary.Label) |
| 15 | PrevLabel | varchar(50) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). DWH note: simplified via CASE WHEN Name LIKE '%eToro%' THEN 'eToro'; previous-day snapshot. Difference from CurrentLabel signals a label migration event. (Tier 1 — Dictionary.Label) |
| 16 | Country | varchar(50) | YES | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). DWH note: passthrough from Dim_Country.Abbreviation; represents customer's registered country at snapshot date. (Tier 1 — Dictionary.Country upstream wiki) |
| 17 | UpdateDate | datetime | NO | ETL batch run timestamp. GETDATE() at SP execution time. All rows in a single SP run share the same UpdateDate. (Propagation) |
| 18 | RegulationName | nvarchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: only ASIC (DWHRegulationID=4) and ASIC & GAML (DWHRegulationID=10) appear in this table by construction. (Tier 1 — upstream wiki, Dictionary.Regulation) |
| 19 | IsGermanBaFin | int | YES | Legacy binary flag. 1 if customer is German (CountryID=79), registered before 2023-07-13 (BaFin crypto regulation cut-off), AND holds non-zero real crypto (LiabilitiesCryptoReal ≠ 0 in V_Liabilities). Determined via V_GermanBaFin JOIN. As of 2026-04-12 only 1 row has value 1 — effectively obsolete. (Tier 2 — SP_ASIC_ClientBalanceFinance via V_GermanBaFin) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Population filter: RegulationID IN(4,10), IsCreditReportValidCB=1 |
| Customer | DWH_dbo.Dim_Customer | ExternalID | Passthrough with rename |
| PreviuosDayBalance | DWH_dbo.V_Liabilities | Liabilities | Previous day; adjusted for negative balances |
| Deposit | DWH_dbo.Fact_CustomerAction | Amount/NetProfit | Aggregated: deposit ActionTypeIDs + adjustments |
| Withdrawal | DWH_dbo.Fact_CustomerAction | Amount | ActionTypeID=8, negated |
| ClosedPnL | DWH_dbo.Fact_CustomerAction | NetProfit | ActionTypeIDs 4,5,6,28,40 |
| Equity | DWH_dbo.V_Liabilities | Liabilities | Current day; adjusted for negative balances |
| TotalOpenMargin | DWH_dbo.V_Liabilities | TotalPositionsAmount | Passthrough |
| RealAssetEquity | DWH_dbo.V_Liabilities | TotalRealCrypto + PositionPnLCryptoReal | Sum of two fields |
| CurrentLabel | DWH_dbo.Dim_Label | Name | Normalized: '%eToro%' → 'eToro' |
| PrevLabel | DWH_dbo.Dim_Label | Name | Normalized: '%eToro%' → 'eToro', previous-day |
| Country | DWH_dbo.Dim_Country | Abbreviation | Passthrough ISO-2 code |
| RegulationName | DWH_dbo.Dim_Regulation | Name | Passthrough, ASIC/ASIC+GAML only |
| IsGermanBaFin | BI_DB_dbo.V_GermanBaFin | CID presence | 0/1 flag derived from view join |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (ASIC/ASIC+GAML filter)
  + DWH_dbo.V_M2M_Date_DateRange (SCD2 date bridge)
  + DWH_dbo.Dim_Label → #cid_cur (current day CIDs) + #cid_prev (prev day CIDs)
  + DWH_dbo.Dim_Country
  + DWH_dbo.Dim_Regulation
  + DWH_dbo.Dim_Customer (ExternalID)
      |-- #Customer (merged current+prev CID snapshot)
      |
  + DWH_dbo.V_Liabilities (today @d_int) → #ClosingBalance
  + DWH_dbo.V_Liabilities (yesterday @dprev_int) → #OpeningBalance
      |-- #liability (balance delta computation)
      |
  + DWH_dbo.Fact_CustomerAction (today ActionTypeIDs) → #action → #action_agg
      |
  + BI_DB_dbo.V_GermanBaFin (DateID=@d_int) → #GermanBafin
      |
      v
SP_ASIC_ClientBalanceFinance(@StartDate)
  DELETE WHERE Date = @StartDate
  INSERT: FINAL SELECT from #Customer + #liability + #action_agg + #GermanBafin
  (WHERE NOT all-zero filter applied)
      |
      v
BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance
  ROUND_ROBIN | CLUSTERED INDEX (Date, CID)
  UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer master |
| Country | DWH_dbo.Dim_Country.Abbreviation | Country lookup |
| RegulationName | DWH_dbo.Dim_Regulation.Name | Regulation lookup |
| CurrentLabel / PrevLabel | DWH_dbo.Dim_Label.Name | Broker label lookup |

### 6.2 Referenced By (other objects point to this)

No known BI_DB_dbo consumers identified via OpsDB dependency scan. This table is a direct regulatory reporting extract.

---

## 7. Sample Queries

### Daily balance snapshot for a specific ASIC customer
```sql
SELECT Date, PreviuosDayBalance, Deposit, Withdrawal, ClosedPnL,
       CurrentDayBalance, OpenPosition, Equity, RealAssetEquity
FROM [BI_DB_dbo].[BI_DB_ASIC_ClientBalanceFinance]
WHERE CID = 123456
  AND Date >= '2026-01-01'
ORDER BY Date
```

### All ASIC customers with deposits on a specific date
```sql
SELECT CID, Customer, RegulationName, Country, Deposit, Withdrawal, ClosedPnL, Equity
FROM [BI_DB_dbo].[BI_DB_ASIC_ClientBalanceFinance]
WHERE Date = '2026-04-12'
  AND Deposit > 0
ORDER BY Deposit DESC
```

### Daily regulation-level balance summary
```sql
SELECT Date, RegulationName,
       SUM(1) AS CustCount,
       SUM(PreviuosDayBalance) AS TotalOpeningBalance,
       SUM(Deposit) AS TotalDeposits,
       SUM(Equity) AS TotalEquity,
       SUM(RealAssetEquity) AS TotalCryptoEquity
FROM [BI_DB_dbo].[BI_DB_ASIC_ClientBalanceFinance]
WHERE Date >= '2026-04-01'
GROUP BY Date, RegulationName
ORDER BY Date DESC, RegulationName
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Original context: SP migrated from RegReportDB_Prod by Katy F (2019-07-30) with subsequent updates by Boris S and Guy M.

---

*Generated: 2026-04-23 | Quality: 9.1/10 | Phases: 14/14*
*Tiers: 6 T1, 12 T2, 0 T3, 0 T4, 1 Propagation | Elements: 19/19, Logic: 9/10, Lineage: 10/10*
*Object: BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance | Type: Table | Production Source: SP_ASIC_ClientBalanceFinance (FinanceReportSPS P99)*
