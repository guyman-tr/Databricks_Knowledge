# Review Needed: BI_DB_dbo.BI_DB_AML_KYC_Process

## Phase 16 Adversarial Evaluation

**Overall Score: 8.3 / 10 — PASS**

| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|---------|
| Tier Accuracy | 9.0 | 25% | 2.25 |
| Upstream Fidelity | 8.5 | 20% | 1.70 |
| Completeness | 9.0 | 20% | 1.80 |
| Business Meaning | 8.5 | 15% | 1.28 |
| Data Evidence | 9.0 | 10% | 0.90 |
| Shape Fidelity | 9.0 | 10% | 0.90 |
| **Total** | | | **8.83** |

### T1 Upstream Fidelity Table

| Column | Upstream Wiki | Verbatim Copy? |
|--------|--------------|----------------|
| CID | DWH_dbo.Dim_Customer.RealCID | ✅ |
| Regulation | DWH_dbo.Dim_Regulation.Name | ✅ |
| Country | DWH_dbo.Dim_Country.Name | ✅ |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus.Name | ✅ |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons.Name | ✅ |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName | ✅ |
| Club | DWH_dbo.Dim_PlayerLevel.Name | ✅ |
| RiskScoreName | No upstream wiki (external table) | N/A → Tier 2 |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus.Name | ✅ |
| AccountType | DWH_dbo.Dim_AccountType.Name | ✅ |
| Has_EV | Computed (SP code) | N/A → Tier 2 |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus.EvMatchStatusName | ✅ |
| Has_POI | DWH_dbo.Dim_Customer.IsIDProof | ✅ |
| Is_POI_Expired | Computed (SP code) | N/A → Tier 2 |
| POI_ExpiryDate | DWH_dbo.Dim_Customer.IsIDProofExpiryDate | ✅ |
| Has_POA | DWH_dbo.Dim_Customer.IsAddressProof | ✅ |
| Is_POA_Expired | Computed (SP code) | N/A → Tier 2 |
| POA_ExpiryDate | DWH_dbo.Dim_Customer.IsAddressProofExpiryDate | ✅ |
| HasWallet | DWH_dbo.Dim_Customer.HasWallet | ✅ |
| Has_eMoney | Computed (eMoney_dbo.eMoney_Dim_Account) | N/A → Tier 2 |
| Equity | DWH_dbo.V_Liabilities (no wiki exists) | N/A → Tier 2 |
| Revenue | BI_DB_DailyCommisionReport (BI_DB layer) | N/A → Tier 2 |
| Equiy_IBAN | BI_DB_DDR_Fact_AUM (BI_DB layer) | N/A → Tier 2 |
| UpdateDate | Propagation blacklist | Propagation |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates (wiki exists) | ✅ |
| UAE_Pass_Status | Computed (External_etoro_BackOffice_Customer) | N/A → Tier 2 |
| Ind | Hardcoded string | N/A → Tier 2 |

**T1 coverage: 16 / 26 non-propagation columns = 61.5%** — above threshold, no hard fail.

### Column Statistics Check

- All 27 columns documented: ✅
- Row count confirmed via MCP: 923,261 ✅
- Distribution data confirmed: Regulation breakdown (12 values), RiskScoreName (4 values), POI/POA flags (9 combinations), Ind+UAE_Pass_Status (2 segments), AccountType (8 values) ✅
- Sample data (TOP 10) reviewed ✅

---

## Items for Human Review

### HIGH — Data Issues

1. **`#deposits` temp table unused in final SELECT**: The SP builds `#deposits` (SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=7) but never references it in the final INSERT. Revenue comes from `#Commission` (BI_DB_DailyCommisionReport). The `#deposits` temp table appears to be a legacy artifact — either a leftover from an earlier SP version or intended for a future column. A human familiar with SP history should confirm whether this is truly unused or if there's a bug.

2. **`Equiy_IBAN` column name typo**: The DDL column `[Equiy_IBAN]` is missing the 'T' (should be `Equity_IBAN`). This typo exists in both the SP code and the DDL definition. Observed values: 0.0000 for all sampled rows. The ALTER target column name must match the DDL exactly (`Equiy_IBAN`).

3. **All Has_EV = 0 by design**: The population filter `EvMatchStatus ≠ 2` means this column is always 0. This is correct by design — the table only holds customers who have NOT completed EV verification. No data quality issue, but analysts should be aware the column is constant.

### MEDIUM — Tier Confidence

4. **RiskScoreName source accuracy**: The `RiskScoreName` column is sourced from `External_RiskClassification_dbo_V_RiskClassificationDataLake` (lake path: DE_OUTPUT/Risk_Classification). No upstream wiki exists for the RiskClassification database's `V_RiskClassificationDataLake` view. The description relies on live data values (Low/Medium/High) and SP code. A Subject Matter Expert from the Risk Classification team should validate the score definitions.

5. **UAE_Pass_Status — 'Completed' value never observed**: In the 92 UAE Pass rows, only 'PartiallyCompleted' was observed (all 92 rows). The 'Completed' value is theoretically possible (EIDStatusID other than NULL or 1) but no examples were seen. The 'None' value (EIDStatusID IS NULL) was also not observed in current data. The SP logic suggests these are possible states — review if UAE Pass filter or business rules have changed.

6. **VerificationLevel3Date NULL handling**: Not all customers may have a VerificationLevel3Date even though they are current VL3 (historical records may predate the tracking). The BI_DB_CIDFirstDates wiki notes this column can be NULL. Analysts filtering on VerificationLevel3Date should use `IS NOT NULL`.

### LOW — Documentation Gaps

7. **V_Liabilities wiki not available**: The Equity column sources from `DWH_dbo.V_Liabilities` but no wiki exists for this view. The SP code uses `Liabilities + ActualNWA` — the precise definition of these two components is not independently confirmed. Consider documenting V_Liabilities in a future batch.

8. **BI_DB_DailyCommisionReport not yet documented**: Revenue comes from this table but it is not yet in the wiki. The column names `FullCommissions` and `RollOverFee` are self-explanatory but should be verified against the BI_DB_DailyCommisionReport documentation when available.

9. **Downstream consumers unknown**: No downstream reports or views referencing this table were identified during the batch. AML team-facing dashboards or SSRS/Power BI reports consuming this table should be documented here when discovered.

---

*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_KYC_Process | Batch 46*
