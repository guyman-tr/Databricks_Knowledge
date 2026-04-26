# Review Needed — BI_DB_dbo.BI_DB_NewBonusReport

**Generated**: 2026-04-23 | **Batch**: 70 | **Quality**: 7.8/10

## Tier 4 Items (Undetermined — Pending Review)

None. All columns resolved (Tier 1–3). Seven Tier 3 columns require domain expert confirmation — see questions below.

## Questions for Domain Expert

1. **"CO" meaning in TotalCoAmount**: The column appears to be mutually exclusive with TotalDepositAmount per row (deposit rows have TotalCoAmount=0 and vice versa). Very large CO amounts observed ($1.37M, $1.29M). Is "CO" = "Cash Out" (client withdrawal), "Cash Out from CopyPortfolio", or something else? This affects the business meaning of the column significantly.

2. **SP code inaccessible**: `SP_NewBonusReport` shows empty definition in sys.sql_modules and has no SSDT file. All Tier 3 column descriptions are inferred from data evidence. Please confirm: (a) the exact source tables for deposits and CO events, (b) whether TotalDepositAmount is a single transaction amount or a daily aggregation per CID, and (c) how IsContacted gets set to 1 (manually by managers, or by another process).

3. **Table name "NewBonusReport"**: Despite the name, the table appears to track all deposit/CO events, not just bonus-related ones. Was this table originally scoped to bonus deposits and expanded? Is "Bonus" referring to specific deposit types (welcome bonus, first deposit bonus) that are now filtered differently?

4. **IsContacted = 1 update mechanism**: 3% of rows have IsContacted=1. Is this field updated by account managers manually (CRM system), by another SP, or by SP_NewBonusReport itself? If it's updated post-insert, what triggers the update?

5. **DaysSinceContact refresh**: Is DaysSinceContact recomputed every day on ALL historical rows (i.e., the table is fully refreshed daily, not append-only)? Or is it only updated when a contact event occurs?

6. **ManagerID source**: Where does the manager assignment come from? Is there a separate manager–customer mapping table that feeds SP_NewBonusReport?

## Propagation Metadata

- `UpdateDate` is ETL metadata (SP_NewBonusReport batch run timestamp) — confirmed Propagation tier. All rows in a batch run share the same UpdateDate value.

## Corrections Log

*(Empty — no reviewer corrections yet)*
