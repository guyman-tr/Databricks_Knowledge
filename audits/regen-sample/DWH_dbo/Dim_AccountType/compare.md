# Compare — `DWH_dbo.Dim_AccountType`

**Bucket**: `random`

**Verdict**: **BETTER**  (score delta +2.9; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 5.65 | 8.55 | 2.9 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 6 | 6 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 2 | 0 | -2 |
| T2 count | 4 | 4 | +0 |
| T3 count | 0 | 2 | +2 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 9 |
| completeness | 6 | 9 |
| data_evidence | 5 | 7 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 6 | 10 |
| upstream_fidelity | 3 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.114 | 1 | 3 | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. (Tier 1 - upstream wiki, Dictiona | Human-readable label for the account type. Renamed from `AccountTypeName` in production `etoro.Dictionary.AccountType`. Used in BackOffice UI, compliance reporting, and DWH exports. (Tier 3 — no upstr |
| `6` | 0.578 | 2 | 2 | ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) | ETL insert timestamp. Set to `GETDATE()` at each daily refresh. Identical to UpdateDate because the SP does TRUNCATE + INSERT (no upsert logic). (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| `4` | 0.676 | 2 | 2 | ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) | ETL status flag. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not sourced from production. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| `3` | 0.684 | 2 | 2 | ETL surrogate key. Set equal to AccountTypeID by SP_Dictionaries_DL_To_Synapse (SELECT AccountTypeID AS DWHAccountTypeID). Carries no additional information beyond AccountTypeID. Present for DWH schem | DWH surrogate key. ETL-computed: always equals AccountTypeID (`[AccountTypeID] AS [DWHAccountTypeID]`). Carries no additional information beyond the PK. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| `1` | 0.685 | 1 | 3 | Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, | Primary key identifying the account classification. Passthrough from `etoro.Dictionary.AccountType.AccountTypeID`. Sentinel row 0=N/A added by SP. 18 live values: 1=Private, 2=Corporate, 3=IB Account, |
| `5` | 0.712 | 2 | 2 | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) | ETL load timestamp. Set to `GETDATE()` at each daily refresh. Reflects when the SP last ran, not when the source data changed. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

## Top issues — regen wiki (per judge)

- [medium] `Section 2.1 (Account Category Groups)` — The Retail/Corporate/Partner/Internal/Managed groupings are fabricated by the writer. No SP code, upstream wiki, or application source defines these categories. Could mislead analysts into treating them as official system classifications.
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist section with P1/P2/P3 completion markers. Data claims appear live-backed but validation phases are unverifiable.
- [low] `Section 6.2 (Referenced By)` — 12 downstream references listed without stated discovery methodology. May be incomplete — missing references could leave analysts unaware of downstream impact.
- [info] `AccountTypeID=18 (Trust)` — Correctly flagged in gotchas as potentially undocumented upstream. Honest handling of uncertain data.
- [info] `AccountTypeID, Name` — Both columns are Tier 3 because no etoro.Dictionary.AccountType wiki exists. The bundle provided USABroker.Dictionary.AccountType (Apex Clearing, 3 rows: CASH/MARGIN/OPTION) which is the wrong system. Writer correctly rejected it.
