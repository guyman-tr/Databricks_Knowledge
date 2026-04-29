# Compare — `DWH_dbo.Dim_CardType`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.9; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.45 | 8.35 | 1.9 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 4 | 4 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 3 | 3 | +0 |
| T2 count | 1 | 1 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 7 | 7 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 4 | 10 |
| upstream_fidelity | 3 | 5 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.281 | 1 | 1 | Card brand name. DDL note: column has a typo ("Car" instead of "Card") — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Exp | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3= |
| `3` | 0.308 | 1 | 1 | Whether this card brand was accepted for deposits as of the 2019 migration snapshot: 1=active, 0=inactive. DWH note: production uses bit type; DWH uses int. This snapshot may not reflect current produ | Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. Type widened from bit to int in DWH. Only 4 of 32 are currently active in production. DWH note: DWH snapshot values  |
| `4` | 0.451 | 2 | 2 | ETL migration timestamp. All 18 rows = 2019-06-30 — the date this table was migrated from the legacy DWH SQL Server. Not a production field from Dictionary.CardType (which has no UpdateDate). (Tier 2  | ETL metadata timestamp recording when the row was loaded into the DWH. All 18 rows show 2019-06-30 00:22:57, indicating a single bulk migration load. (Tier 2 — DWH_Migration load) |
| `1` | 0.578 | 1 | 1 | Card network identifier. Active brands (IsActive=1 as of 2019): 0=None (unknown/fallback), 1=Visa, 2=Master Card, 3=Diners. Inactive: 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro (active i | Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Loca |

## Top issues — regen wiki (per judge)

- [high] `IsActive` — Tier 1 upstream description dropped 'DEFAULT 1 (new card types are active by default)' and replaced with DWH-specific notes. This is a semantic loss — the default behavior for new card types is meaningful business context that was removed.
- [medium] `CardTypeID` — Truncated upstream description by removing '18=Unknown, 19-31=various regional/legacy brands'. While the DWH only has 18 rows, the Tier 1 instruction is to quote verbatim from upstream.
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer lacks a phases-completed list, making it impossible to verify which data-gathering phases were run.
- [low] `All nullable columns` — No NULL-rate or distribution analysis mentioned for any of the 4 columns, all of which are nullable in the DDL.
- [low] `CarTypeName` — Added 'in production' qualifier and full value enumeration to upstream description. While these are additions rather than losses, they deviate from verbatim upstream quoting.
