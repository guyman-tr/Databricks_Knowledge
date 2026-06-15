# Column Lineage: main.bi_output.vg_emoney_panel_firstdates_em1

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_panel_firstdates_em1` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_panel_firstdates_em1.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_panel_firstdates_em1.json` (rows: 44, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Panel_FirstDates.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoney_panel_firstdates_em1   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | CID /* =========================        Identifiers        ========================= */ |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `GCID` | `passthrough` | (Tier 1 — dbo.FiatAccount) | GCID |
| 3 | `emoney_fmi_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FMI_Date` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | FMI_Date AS emoney_fmi_date /* =========================        FMI / FMO (eMoney POV)        ========================= */ |
| 4 | `emoney_fmi_source` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FMI_Source` | `rename` | (Tier 2 — SP_eMoney_Panel_FirstDates) | FMI_Source AS emoney_fmi_source |
| 5 | `Seniority_FMI` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Seniority_FMI` | `passthrough` | (Tier 2 — SP_eMoney_Panel_FirstDates) | Seniority_FMI |
| 6 | `emoney_fmo_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FMO_Date` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | FMO_Date AS emoney_fmo_date |
| 7 | `emoney_fmo_target` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FMO_Target` | `rename` | (Tier 2 — SP_eMoney_Panel_FirstDates) | FMO_Target AS emoney_fmo_target |
| 8 | `emoney_fmo_mop` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FMO_MOP` | `rename` | (Tier 2 — SP_eMoney_Panel_FirstDates) | FMO_MOP AS emoney_fmo_mop |
| 9 | `Seniority_FMO` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Seniority_FMO` | `passthrough` | (Tier 2 — SP_eMoney_Panel_FirstDates) | Seniority_FMO |
| 10 | `emoney_last_settled_tx_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `LastSettledTXDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | LastSettledTXDate AS emoney_last_settled_tx_date /* =========================        Settled transaction dates        ====================== |
| 11 | `Seniority_LastTXDate` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Seniority_LastTXDate` | `passthrough` | (Tier 2 — SP_eMoney_Panel_FirstDates) | Seniority_LastTXDate |
| 12 | `emoney_first_settled_tx_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `FirstIBANSettledTXDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | FirstIBANSettledTXDate AS emoney_first_settled_tx_date |
| 13 | `emoney_last_settled_tx_date_iban` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `LastIBANSettledTXDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | LastIBANSettledTXDate AS emoney_last_settled_tx_date_iban |
| 14 | `emoney_1st_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `1stActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 1stActionDate AS emoney_1st_action_date /* =========================        Generic action sequence (1–5)        ========================= * |
| 15 | `emoney_1st_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `1stActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 1stActionType AS emoney_1st_action_type |
| 16 | `emoney_1st_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `1stActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 1stActionUSDApproxAmount AS emoney_1st_action_amount_usd |
| 17 | `emoney_2nd_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `2ndActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 2ndActionDate AS emoney_2nd_action_date |
| 18 | `emoney_2nd_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `2ndActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 2ndActionType AS emoney_2nd_action_type |
| 19 | `emoney_2nd_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `2ndActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 2ndActionUSDApproxAmount AS emoney_2nd_action_amount_usd |
| 20 | `emoney_3rd_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `3rdActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 3rdActionDate AS emoney_3rd_action_date |
| 21 | `emoney_3rd_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `3rdActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 3rdActionType AS emoney_3rd_action_type |
| 22 | `emoney_3rd_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `3rdActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 3rdActionUSDApproxAmount AS emoney_3rd_action_amount_usd |
| 23 | `emoney_4th_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `4thActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 4thActionDate AS emoney_4th_action_date |
| 24 | `emoney_4th_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `4thActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 4thActionType AS emoney_4th_action_type |
| 25 | `emoney_4th_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `4thActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 4thActionUSDApproxAmount AS emoney_4th_action_amount_usd |
| 26 | `emoney_5th_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `5thActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 5thActionDate AS emoney_5th_action_date |
| 27 | `emoney_5th_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `5thActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 5thActionType AS emoney_5th_action_type |
| 28 | `emoney_5th_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `5thActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | 5thActionUSDApproxAmount AS emoney_5th_action_amount_usd |
| 29 | `emoney_card_activation_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `CardActivationTime` | `rename` | (Tier 2 — eMoney_Dim_Account) | CardActivationTime AS emoney_card_activation_date /* =========================        Card lifecycle & actions (1–5)        ================ |
| 30 | `emoney_card_1st_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card1stActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card1stActionDate AS emoney_card_1st_action_date |
| 31 | `emoney_card_1st_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card1stActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card1stActionType AS emoney_card_1st_action_type |
| 32 | `emoney_card_1st_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card1stActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card1stActionUSDApproxAmount AS emoney_card_1st_action_amount_usd |
| 33 | `emoney_card_2nd_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card2ndActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card2ndActionDate AS emoney_card_2nd_action_date |
| 34 | `emoney_card_2nd_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card2ndActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card2ndActionType AS emoney_card_2nd_action_type |
| 35 | `emoney_card_2nd_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card2ndActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card2ndActionUSDApproxAmount AS emoney_card_2nd_action_amount_usd |
| 36 | `emoney_card_3rd_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card3rdActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card3rdActionDate AS emoney_card_3rd_action_date |
| 37 | `emoney_card_3rd_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card3rdActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card3rdActionType AS emoney_card_3rd_action_type |
| 38 | `emoney_card_3rd_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card3rdActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card3rdActionUSDApproxAmount AS emoney_card_3rd_action_amount_usd |
| 39 | `emoney_card_4th_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card4thActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card4thActionDate AS emoney_card_4th_action_date |
| 40 | `emoney_card_4th_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card4thActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card4thActionType AS emoney_card_4th_action_type |
| 41 | `emoney_card_4th_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card4thActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card4thActionUSDApproxAmount AS emoney_card_4th_action_amount_usd |
| 42 | `emoney_card_5th_action_date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card5thActionDate` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card5thActionDate AS emoney_card_5th_action_date |
| 43 | `emoney_card_5th_action_type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card5thActionType` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card5thActionType AS emoney_card_5th_action_type |
| 44 | `emoney_card_5th_action_amount_usd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `Card5thActionUSDApproxAmount` | `rename` | (Tier 2 — eMoney_Dim_Transaction) | Card5thActionUSDApproxAmount AS emoney_card_5th_action_amount_usd |

## Cross-check vs system.access.column_lineage

- Total target columns: **44**
- OK: **44**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
