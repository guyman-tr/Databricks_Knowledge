# Column Lineage: main.bi_output.vg_positions_open_closed_iban_tp

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_positions_open_closed_iban_tp` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_positions_open_closed_iban_tp.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_positions_open_closed_iban_tp.json` (rows: 47, mismatches: 0) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

## Lineage Chain

```
main.dwh.dim_position   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet   (JOIN)
        │
        ▼
main.bi_output.vg_positions_open_closed_iban_tp   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.dwh.dim_position` | `PositionID` | `passthrough` | — | a.PositionID |
| 2 | `CID` | `main.dwh.dim_position` | `CID` | `passthrough` | — | a.CID |
| 3 | `InstrumentID` | `main.dwh.dim_position` | `InstrumentID` | `passthrough` | — | a.InstrumentID |
| 4 | `OpenDateID` | `main.dwh.dim_position` | `OpenDateID` | `passthrough` | — | a.OpenDateID |
| 5 | `CloseDateID` | `main.dwh.dim_position` | `CloseDateID` | `passthrough` | — | a.CloseDateID |
| 6 | `PlatformTypeID` | `main.dwh.dim_position` | `PlatformTypeID` | `passthrough` | — | a.PlatformTypeID |
| 7 | `Amount` | `main.dwh.dim_position` | `Amount` | `passthrough` | — | a.Amount |
| 8 | `Volume` | `main.dwh.dim_position` | `Volume` | `passthrough` | — | a.Volume |
| 9 | `NetProfit` | `main.dwh.dim_position` | `NetProfit` | `passthrough` | — | a.NetProfit |
| 10 | `Commission` | `main.dwh.dim_position` | `Commission` | `passthrough` | — | a.Commission |
| 11 | `Leverage` | `main.dwh.dim_position` | `Leverage` | `passthrough` | — | a.Leverage |
| 12 | `RegulationIDOnOpen` | `main.dwh.dim_position` | `RegulationIDOnOpen` | `passthrough` | — | a.RegulationIDOnOpen |
| 13 | `PositionUpdateDate` | `main.dwh.dim_position` | `UpdateDate` | `rename` | — | a.UpdateDate AS PositionUpdateDate |
| 14 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RealCID |
| 15 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.CountryID |
| 16 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `LanguageID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.LanguageID |
| 17 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.PlayerLevelID |
| 18 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountStatusID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.AccountStatusID |
| 19 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountTypeID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.AccountTypeID |
| 20 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegulationID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.RegulationID |
| 21 | `RiskStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RiskStatusID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.RiskStatusID |
| 22 | `RiskClassificationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RiskClassificationID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.RiskClassificationID |
| 23 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsValidCustomer` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsValidCustomer |
| 24 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.PlayerStatusID |
| 25 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `VerificationLevelID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.VerificationLevelID |
| 26 | `RegionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegionID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RegionID |
| 27 | `IsDepositor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsDepositor` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsDepositor |
| 28 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.FirstDepositDate |
| 29 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountManagerID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc.AccountManagerID |
| 30 | `PremiumAccount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PremiumAccount` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.PremiumAccount |
| 31 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.AffiliateID |
| 32 | `CampaignID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CampaignID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.CampaignID |
| 33 | `SubChannelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `SubChannelID` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.SubChannelID |
| 34 | `LabelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `LabelID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.LabelID |
| 35 | `RegisteredReal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RegisteredReal |
| 36 | `RegisteredDemo` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredDemo` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.RegisteredDemo |
| 37 | `ReferralID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `ReferralID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.ReferralID |
| 38 | `CustomerUpdateDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `UpdateDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.UpdateDate AS CustomerUpdateDate |
| 39 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentType` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | i.InstrumentType |
| 40 | `SellCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SellCurrency` | `join_enriched` | (Tier 1 — Dictionary.Currency) | i.SellCurrency |
| 41 | `InstrumentDisplayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentDisplayName` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | i.InstrumentDisplayName |
| 42 | `IsCloseToIBan` | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | `—` | `case` | — | CASE WHEN NOT b.PositionID IS NULL THEN 1 ELSE 0 END AS IsCloseToIBan |
| 43 | `IsOpenFromIBan` | `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | `—` | `case` | — | CASE WHEN NOT c.PositionID IS NULL THEN 1 ELSE 0 END AS IsOpenFromIBan |
| 44 | `AccountCreateDate` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountCreateDate` | `join_enriched` | (Tier 2 — SP_eMoney_Dim_Account) | e.AccountCreateDate |
| 45 | `AccountSubProgram` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountSubProgram` | `join_enriched` | (Tier 2 — SP_eMoney_Dim_Account) | e.AccountSubProgram |
| 46 | `AccountSubProgramID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountSubProgramID` | `join_enriched` | (Tier 1 — dbo.FiatAccount) | e.AccountSubProgramID |
| 47 | `IsEmoneyCustomer` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `—` | `case` | — | CASE WHEN NOT e.CID IS NULL THEN 1 ELSE 0 END AS IsEmoneyCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **47**
- OK: **3**, WARN: **0**, ERROR: **0**, INFO: **44**  ✓

## Lost / added columns

- Computed/added columns vs primary: **34**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON a.CID = dc.RealCID AND dc.IsValidCustomer = 1
- `INNER JOIN` — JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS i ON a.InstrumentID = i.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account AS e ON a.CID = e.CID AND e.IsValidETM = 1 AND e.GCID_Unique_Count = 1
- `LEFT JOIN` — LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet AS b ON a.PositionID = b.PositionID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet AS c ON a.PositionID = c.PositionID
