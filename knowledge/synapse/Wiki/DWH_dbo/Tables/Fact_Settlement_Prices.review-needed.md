# DWH_dbo.Fact_Settlement_Prices - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All 5 columns are Tier 2 (from SP analysis).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| SettlementPrice | Are settlement prices from an exchange clearing house, or are they internally computed by eToro? |
| InstrumentID | InstrumentIDs 200004+ appear to be futures contracts. What is the naming/numbering convention for futures InstrumentIDs vs spot InstrumentIDs in Dim_Instrument? |

## Structural Questions

| Question |
|----------|
| Data starts 2024-12-24 -- what prompted the creation of this table in late 2024? Was a new futures product line launched? |
| Is there a matching settlement prices table for pre-2024 data, or was futures settlement price tracking simply not tracked before? |
| Is this table exported to Databricks UC? Not found in _generic_pipeline_mapping.json. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
