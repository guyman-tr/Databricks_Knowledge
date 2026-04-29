# Compare — `BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +3.1; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.3 | 9.4 | 3.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 26 | 26 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 16 | +16 |
| T2 count | 26 | 10 | -16 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 10 |
| completeness | 10 | 10 |
| data_evidence | 8 | 8 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 3 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `24` | 0.178 | 2 | 1 | Customer account status ID at time of ETL run. From Fact_SnapshotCustomer. Excludes 2=Blocked/4=Fraudster/13=AML Limited. Present values: 1=Normal (98.7%), 9=Trade&MIMO Blocked, 10=Deposit Blocked, 15 | Customer lifecycle status. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer. Note: statuses 2 (Blocked), 4 (Blocked Upon Reque |
| `25` | 0.197 | 2 | 1 | Customer account status name. Resolved from Dim_PlayerStatus.Name via PlayerStatusID. Values mirror PlayerStatusID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_PlayerStatus) | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for |
| `20` | 0.203 | 2 | 1 | Customer's first deposit amount in USD. Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount. Populated for all rows (including FTD=0 rows) showing the historical FTD amount. 0.0 if no deposit. (Tier | Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. Passthrou |
| `18` | 0.251 | 2 | 1 | Customer's first deposit date. CAST of BI_DB_CIDFirstDates.FirstDepositDate AS DATE. NULL if no deposit yet. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) | First successful deposit date. Read directly from Dim_Customer.FirstDepositDate, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override lo |
| `21` | 0.258 | 2 | 1 | Customer's first position open date (manual or copy). CAST of BI_DB_CIDFirstDates.FirstPosOpenDate AS DATE. NULL if no position opened. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstD | First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. CAST to DATE from BI_DB_CIDFirstDates.FirstPosOpenDate. (Tier 1 — BI_DB_CIDFirst |
| `10` | 0.289 | 2 | 1 | Current regulatory entity governing this customer's account. Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID (DWHRegulationID). Top values 2026: BVI (81%), CySEC (7.4%), eToro | Short code for the regulation. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. (Tier 1 — D |
| `23` | 0.29 | 2 | 2 | VBT (Verified-by-eToro) KYC flow flag. 1 if customer GCID appears in External_ComplianceStateDB_KycFlow or _History_KycFlow with KYCFlowTypeID=2, 0 otherwise. VBT is an alternative KYC pathway with it | Video-Based Trading flag. 1 if the customer's GCID appears in ComplianceStateDB KycFlow tables (current or history) with KYCFlowTypeID=2; 0 otherwise. ETL-computed via LEFT JOIN to #VBT_CIDs temp tabl |
| `9` | 0.293 | 2 | 1 | Marketing sub-channel detail. Resolved from Dim_Channel.SubChannel in BI_DB_CIDFirstDates. Values: Direct, Direct Mobile, Google Brand, Affiliate, YT, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT | Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. Passthrough from BI_DB_CIDFirstDates. (Tier |
| `14` | 0.368 | 2 | 1 | Date customer first reached verification level 2 (partial KYC). CAST of BI_DB_CIDFirstDates.VerificationLevel2Date AS DATE. NULL if not yet V2. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_C | First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel2Dat |
| `16` | 0.369 | 2 | 1 | Date customer first reached verification level 3 (full KYC). CAST of BI_DB_CIDFirstDates.VerificationLevel3Date AS DATE. NULL if not yet fully verified. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT vi | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. CAST to DATE from BI_DB_CIDFirstDates.Verif |

## Top issues — regen wiki (per judge)

- [low] `DesignatedRegulation` — Description abbreviated vs upstream Dim_Regulation.Name — drops 'Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name'. Less informative than Regulation column's description for the same upstream source.
- [low] `CID` — Drops 'FK to Dim_Customer (if exists)' from upstream FSC.RealCID description. The FK reference would help analysts understand join paths.
- [low] `Section 1 / Footer` — No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer says 'Phases: 11/14' but data evidence audit trail is not verifiable from the wiki alone.
- [low] `PlayerStatusID` — Drops upstream example values '(e.g., Active, Blocked, Pending)' which help analysts unfamiliar with the numeric IDs.
- [info] `Section 5.1` — Regulation join documented as 'sc.RegulationID = dr1.DWHRegulationID' — correct per SP code, but Dim_Regulation wiki notes DWHRegulationID is always equal to ID and recommends using ID. No functional impact.
