# Column Lineage: main.bi_output.vg_bidb_alldeposits_for_genie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_bidb_alldeposits_for_genie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_bidb_alldeposits_for_genie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_bidb_alldeposits_for_genie.json` (rows: 38, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AllDeposits.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits   ←── primary upstream
        │
        ▼
main.bi_output.vg_bidb_alldeposits_for_genie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CID` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | CID /* ====================== */ /* Core identifiers */ /* ====================== */ |
| 2 | `DepositID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `DepositID` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | DepositID |
| 3 | `FundingType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `FundingType` | `passthrough` | (Tier 2 — SP_AllDeposits) | FundingType |
| 4 | `ModificationDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `ModificationDate` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | ModificationDate /* ====================== */ /* Dates (single main date + tx time) */ /* ====================== */ |
| 5 | `AmountOrig` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Amount_In_Orig_Curr` | `rename` | — | Amount_In_Orig_Curr AS AmountOrig /* ====================== */ /* Amounts & currency (requested) */ /* ====================== */ |
| 6 | `AmountUSD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Amount_in_USD` | `rename` | — | Amount_in_USD AS AmountUSD |
| 7 | `Currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Currency` | `passthrough` | (Tier 2 — SP_AllDeposits) | Currency |
| 8 | `BaseExchangeRate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `BaseExchangeRate` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | BaseExchangeRate |
| 9 | `IsFTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `IsFTD` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | IsFTD /* ====================== */ /* Status & flags (requested) */ /* ====================== */ |
| 10 | `PaymentStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `PaymentStatus` | `passthrough` | (Tier 2 — SP_AllDeposits) | PaymentStatus |
| 11 | `PaymentStatusAsInteger` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `PaymentStatusAsInteger` | `passthrough` | — | PaymentStatusAsInteger |
| 12 | `DepositCategory` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Category` | `rename` | (Tier 2 — SP_AllDeposits) | Category AS DepositCategory |
| 13 | `Provider` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Provider` | `passthrough` | (Tier 2 — SP_AllDeposits) | Provider /* ====================== */ /* Funding / provider (requested) */ /* ====================== */ |
| 14 | `DepotID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `DepotID` | `passthrough` | (Tier 1 — Fact_BillingDeposit) | DepotID |
| 15 | `PSPCode` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `PSPCode` | `passthrough` | (Tier 1 — Fact_BillingDeposit, PSPCodeAsString) | PSPCode |
| 16 | `BINCountry` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `BINCountry` | `passthrough` | (Tier 2 — SP_AllDeposits) | BINCountry /* ====================== */ /* Card / BIN / bank (requested) */ /* ====================== */ |
| 17 | `BinCode` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `BinCode` | `passthrough` | (Tier 1 — Fact_BillingDeposit, BinCodeAsString) | BinCode |
| 18 | `BinCodeAsString` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `BinCodeAsString` | `passthrough` | — | BinCodeAsString |
| 19 | `CardType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CardType` | `passthrough` | (Tier 2 — SP_AllDeposits) | CardType |
| 20 | `CardSubType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CardSubType` | `passthrough` | (Tier 2 — SP_AllDeposits) | CardSubType |
| 21 | `CardTypeIDAsInteger` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CardTypeIDAsInteger` | `passthrough` | — | CardTypeIDAsInteger |
| 22 | `Bank_name_by_Bincode` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Bank_name_by_Bincode` | `passthrough` | — | Bank_name_by_Bincode |
| 23 | `RiskStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `RiskStatus` | `passthrough` | (Tier 2 — SP_AllDeposits) | RiskStatus /* ====================== */ /* Risk & regulation (requested) */ /* ====================== */ |
| 24 | `Regulation` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Regulation` | `passthrough` | (Tier 2 — SP_AllDeposits) | Regulation |
| 25 | `DesignatedRegulation` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `DesignatedRegulation` | `passthrough` | (Tier 2 — SP_AllDeposits) | DesignatedRegulation |
| 26 | `RegistrationCountry` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Country_customer` | `rename` | — | Country_customer AS RegistrationCountry /* ====================== */ /* Geography / attribution (requested) */ /* ====================== */ |
| 27 | `CountryID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CountryIDAsInteger` | `rename` | — | CountryIDAsInteger AS CountryID |
| 28 | `Region` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Region` | `passthrough` | (Tier 2 — SP_AllDeposits) | Region |
| 29 | `Funnel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Funnel` | `passthrough` | (Tier 2 — SP_AllDeposits) | Funnel |
| 30 | `FunnelFrom` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `FunnelFrom` | `passthrough` | (Tier 2 — SP_AllDeposits) | FunnelFrom |
| 31 | `Affiliate_ID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Affiliate_ID` | `passthrough` | — | Affiliate_ID |
| 32 | `Response` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `Response` | `passthrough` | (Tier 2 — SP_AllDeposits) | Response /* ====================== */ /* Responses / 3DS (requested) */ /* ====================== */ |
| 33 | `DeclineReason` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `ResponseMessageAsString` | `rename` | — | ResponseMessageAsString AS DeclineReason |
| 34 | `RREReason` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `ErrorCodeAsString` | `rename` | — | ErrorCodeAsString AS RREReason |
| 35 | `ThreeDSResponseJson` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `ThreeDsAsJson` | `rename` | — | ThreeDsAsJson AS ThreeDSResponseJson |
| 36 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `CustomerIDAsString` | `rename` | — | CustomerIDAsString AS GCID /* ====================== */ /* GCID / customer linkage (likely needed) */ /* ====================== */ |
| 37 | `MID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `MID` | `passthrough` | (Tier 2 — SP_AllDeposits) | MID /* ====================== */ /* Misc useful */ /* ====================== */ |
| 38 | `TransactionIDAsString` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `TransactionIDAsString` | `passthrough` | — | TransactionIDAsString |

## Cross-check vs system.access.column_lineage

- Total target columns: **38**
- OK: **38**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
