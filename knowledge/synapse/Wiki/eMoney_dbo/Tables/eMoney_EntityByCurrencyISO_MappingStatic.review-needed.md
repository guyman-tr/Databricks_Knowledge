# Review Needed: eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic

**Generated**: 2026-04-21 | **Batch**: 13 | **Reviewer**: TBD

## Tier 4 Items (Require Verification)

None — all 7 columns are Tier 2 (manually maintained static reference; no upstream wiki). Descriptions inferred from DDL, live data (full 4-row table retrieved), and consuming SP code analysis.

## Tier 2 Items Requiring Business Context Confirmation

| Column | Question |
|--------|----------|
| Entity | Confirm 'eToro Money UK', 'eToro Money Malta', 'eToro Money AUS' are the canonical legal entity names used for reporting and access-control purposes |
| ReportingCurrency | Confirm DKK reporting in EUR (via eToro Money Malta) is intentional and aligns with regulatory/financial reporting requirements |
| CurrencyISO | Confirm the 4 covered currencies (AUD, DKK, GBP, EUR) are the complete and current set of eToro Money-supported currencies |

## Known Flags / Anomalies

- **Only 4 rows**: The most minimal reference table in eMoney_dbo. Absence of a row for a currency means downstream tables (eMoney_Dim_Account) will silently produce Entity='N/A' for that currency's customers. No alerting mechanism exists.
- **All columns NULL in DDL**: Despite no NULLs in practice, DDL allows NULLs. An inadvertent NULL in CurrencyISO would prevent the JOIN and produce silent NULL propagation in downstream SPs.
- **DKK added 2 months after initial load**: AUD/GBP/EUR loaded 2025-09-29; DKK added 2025-11-26. This confirms the table is an ad-hoc manual process — no deployment/migration script required.
- **Commented-out UPDATE block in SP_eMoney_ClientBalance** (lines 56–63): Historical artifact showing InstrumentID assignment logic. Confirms instrument IDs were originally set via UPDATE, not INSERT. Not executed at runtime.
- **ReportingInstrumentID = InstrumentID for AUD/GBP/EUR**: Only DKK differs (InstrumentID=75, ReportingInstrumentID=1). For 3 of 4 currencies, the column is redundant with InstrumentID.

## Reviewer Checklist

- [ ] Confirm entity names are canonical and match legal/compliance naming
- [ ] Confirm DKK reporting in EUR is by regulatory design (eToro Money Malta EU entity)
- [ ] Confirm the 4 currencies are the complete current eToro Money footprint
- [ ] Assess whether a NULL-guard on CurrencyISO is needed in consuming SPs
- [ ] Determine if new jurisdictions (e.g., additional EEA markets) are planned — if so, establish a migration/deployment process for this table
- [ ] Assess UC export need: `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_entitybycurrencyiso_mappingstatic`
- [ ] Confirm SP_eMoney_Reconciliation_ETLs usage context (not sampled in this batch)
