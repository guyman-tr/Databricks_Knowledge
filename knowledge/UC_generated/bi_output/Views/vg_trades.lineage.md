# Column Lineage: main.bi_output.vg_trades

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_trades` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_trades.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_trades.json` (rows: 23, mismatches: 11) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
        │
        ▼
main.bi_output.vg_trades   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_ymd` | `rename` | — | fca.etr_ymd AS `Date` |
| 2 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `rename` | (Tier 1 — Customer.CustomerStatic) | fca.RealCID AS CID |
| 3 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 4 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 5 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `InstrumentType` | `passthrough` | — | InstrumentType |
| 6 | `InstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `InstrumentID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.InstrumentID |
| 7 | `InstrumentDisplayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `InstrumentDisplayName` | `passthrough` | — | InstrumentDisplayName |
| 8 | `IsFuture` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IsFuture` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.IsFuture |
| 9 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 10 | `PlayerStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | ps.Name AS PlayerStatus |
| 11 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 12 | `RegistrationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to DATE — CAST(dmc.RegisteredReal AS DATE) AS RegistrationDate |
| 13 | `FTDDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `cast` | (Tier 2 — SP_Dim_Customer) | cast to DATE — CAST(dmc.FirstDepositDate AS DATE) AS FTDDate |
| 14 | `IsProfessionalCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.MifidCategorizationID IN (2, 3) THEN 1 ELSE 0 END AS IsProfessionalCustomer |
| 15 | `ActionType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN ActionTypeID IN (1, 4, 39, 40) THEN 'Manual' ELSE 'Copy' END AS ActionType |
| 16 | `Real/CFD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN IsSettled = 1 THEN 'Real' WHEN IsSettled = 0 THEN 'CFD' END AS `Real/CFD` |
| 17 | `OpenTrades` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN 1 ELSE 0 END) AS OpenTrades |
| 18 | `ClosedTrades` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN 1 ELSE 0 END) AS ClosedTrades |
| 19 | `TotalTrades` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40) THEN 1 ELSE 0 END) AS TotalTrades |
| 20 | `InvestedAmountOpen` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * fca.Amount ELSE 0 END) AS InvestedAmountOpen |
| 21 | `AmountClose` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN fca.Amount ELSE 0 END) AS AmountClose |
| 22 | `TotalAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * fca.Amount WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN fca.Amount ELSE 0 END) AS Total |
| 23 | `Leverage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Leverage` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.Leverage |

## Cross-check vs system.access.column_lineage

- Total target columns: **23**
- OK: **12**, WARN: **2**, ERROR: **9**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.instrumenttype` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype` | WARN |
| `InstrumentDisplayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.instrumentdisplayname` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumentdisplayname` | WARN |
| `IsProfessionalCustomer` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.mifidcategorizationid` | ERROR |
| `ActionType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `Real/CFD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled` | ERROR |
| `OpenTrades` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `ClosedTrades` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `TotalTrades` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `InvestedAmountOpen` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `AmountClose` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `TotalAmount` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **15**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fsc.RealCID = fca.RealCID AND fca.DateID BETWEEN fsc.FromDateID AND fsc.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dmc ON fca.RealCID = dmc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON di.InstrumentID = fca.InstrumentID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON dpl.DWHPlayerLevelID = fsc.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus AS ps ON ps.DWHPlayerStatusID = fsc.PlayerStatusID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON dr.ID = fsc.RegulationID
