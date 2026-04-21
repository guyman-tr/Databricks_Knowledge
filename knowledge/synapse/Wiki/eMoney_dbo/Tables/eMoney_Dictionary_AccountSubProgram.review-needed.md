# Review Needed: eMoney_dbo.eMoney_Dictionary_AccountSubProgram

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

**FLAGGED**: Synapse table missing 6 of 16 source rows (AUS and DK sub-programs). Potential data quality gap for AUS and DK account analytics.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | **Missing IDs 11-16 (AUS and DK sub-programs)** | HIGH | FiatDwhDB.dbo.SubPrograms has 16 rows (IDs 1-16); Synapse live query returns only 10 (IDs 1-10). Missing: Card Green EU (11), Card Black EU (12), IBAN Green AUS (13), IBAN Black AUS (14), IBAN Green DKK (15), IBAN Black DKK (16). Accounts with these sub-programs in eMoney_Dim_Account will have unresolved AccountSubProgramID on LEFT JOIN. Analysts filtering by sub-program name will silently exclude AUS/DK accounts. Trigger a Generic Pipeline refresh. |
| 2 | Region column dropped from source | MEDIUM | FiatDwhDB.dbo.SubPrograms has a `Region` column (UK, EU, UAE, AUS, DK) not present in the DWH table. The region can be inferred from the AccountSubProgram name string, but a direct Region column would enable cleaner analytics. Consider requesting this column be added to the Bronze export. |
| 3 | `AccountSubProgram varchar(50)` vs source `nvarchar(128)` | LOW | Current 10 sub-program names are all under 50 chars. However, future sub-programs (e.g., "IBAN Standard EU Test") are 22 chars — well within the limit. Monitor if any newly added names approach 50 chars. |
| 4 | UpdateDate static since 2023-06-12 | INFO | Last load aligns with initial eMoney_dbo deployment; the missing rows are newer additions to FiatDwhDB. |

## Tier 4 Items

None — all 4 content columns have confirmed Tier 1 upstream sources.

## Reviewer Confirmation Needed

- [ ] **PRIORITY**: Trigger Generic Pipeline refresh for `External_FiatDwhDB_dbo_SubPrograms` to load IDs 11-16
- [ ] Confirm whether `Region` column should be added to the Bronze export mapping
- [ ] Assess impact of missing IDs 11-16 on AUS/DK account analytics in eMoney_Dim_Account and downstream tables

*Sidecar generated: 2026-04-20 | Quality: 9.1/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
