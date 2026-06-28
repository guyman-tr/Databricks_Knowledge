# Column Lineage: main.bi_output.finance_tables_functions_revenue_trading_fees

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.finance_tables_functions_revenue_trading_fees` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\finance_tables_functions_revenue_trading_fees.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\finance_tables_functions_revenue_trading_fees.json` (rows: 46, mismatches: 2) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
        │
        ▼
main.bi_output.finance_tables_functions_revenue_trading_fees   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fca.RealCID |
| 2 | `TradingFee` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `arithmetic` | — | -1 * fca.Amount AS TradingFee |
| 3 | `TradingFeeType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 117 THEN 'Administrationfee' WHEN fca.ActionTypeID = 36 AND fca.CompensationR |
| 4 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.DateID |
| 5 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.GCID |
| 6 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 7 | `LabelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LabelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.LabelID |
| 8 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 9 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.VerificationLevelID |
| 10 | `DocsOK` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `DocsOK` | `join_enriched` | (Tier 4 — inherited from Fact_SnapshotCustomer wiki) | fsc.DocsOK |
| 11 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 12 | `Bankruptcy` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Bankruptcy` | `join_enriched` | (Tier 4 — inherited from Fact_SnapshotCustomer wiki) | fsc.Bankruptcy |
| 13 | `RiskStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RiskStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.RiskStatusID |
| 14 | `RiskClassificationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RiskClassificationID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.RiskClassificationID |
| 15 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.CommunicationLanguageID |
| 16 | `PremiumAccount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PremiumAccount` | `join_enriched` | (Tier 4 — inherited from Fact_SnapshotCustomer wiki) | fsc.PremiumAccount |
| 17 | `Evangelist` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Evangelist` | `join_enriched` | (Tier 4 — inherited from Fact_SnapshotCustomer wiki) | fsc.Evangelist |
| 18 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 19 | `UpdateDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `UpdateDate` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.UpdateDate |
| 20 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.RegulationID |
| 21 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 22 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.AccountManagerID |
| 23 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 24 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 25 | `DateRangeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `DateRangeID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.DateRangeID |
| 26 | `IsDepositor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsDepositor` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.IsDepositor |
| 27 | `PendingClosureStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PendingClosureStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PendingClosureStatusID |
| 28 | `DocumentStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `DocumentStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.DocumentStatusID |
| 29 | `SuitabilityTestStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `SuitabilityTestStatusID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.SuitabilityTestStatusID |
| 30 | `MifidCategorizationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `MifidCategorizationID` | `join_enriched` | — | fsc.MifidCategorizationID |
| 31 | `IsEmailVerified` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsEmailVerified` | `join_enriched` | — | fsc.IsEmailVerified |
| 32 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |
| 33 | `DesignatedRegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `DesignatedRegulationID` | `join_enriched` | — | fsc.DesignatedRegulationID |
| 34 | `EvMatchStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `EvMatchStatus` | `join_enriched` | — | fsc.EvMatchStatus |
| 35 | `RegionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegionID` | `join_enriched` | — | fsc.RegionID |
| 36 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 37 | `IsCreditReportValidCB` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsCreditReportValidCB` | `join_enriched` | — | fsc.IsCreditReportValidCB |
| 38 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AffiliateID` | `join_enriched` | — | fsc.AffiliateID |
| 39 | `Email` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Email` | `join_enriched` | — | fsc.Email |
| 40 | `City` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `City` | `join_enriched` | — | fsc.City |
| 41 | `Address` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Address` | `join_enriched` | — | fsc.Address |
| 42 | `Zip` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Zip` | `join_enriched` | — | fsc.Zip |
| 43 | `PhoneNumber` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PhoneNumber` | `join_enriched` | — | fsc.PhoneNumber |
| 44 | `IsPhoneVerified` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsPhoneVerified` | `join_enriched` | — | fsc.IsPhoneVerified |
| 45 | `PhoneVerificationDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PhoneVerificationDateID` | `join_enriched` | — | fsc.PhoneVerificationDateID |
| 46 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |

## Cross-check vs system.access.column_lineage

- Total target columns: **46**
- OK: **44**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `TradingFee` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `TradingFeeType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.compensationreasonid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.isfeedividend` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **44**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fca.RealCID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID
