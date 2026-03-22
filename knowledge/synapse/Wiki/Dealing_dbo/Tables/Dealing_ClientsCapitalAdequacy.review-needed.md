# Dealing_dbo.Dealing_ClientsCapitalAdequacy — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| NOP currency | Are Clients_Long_OP and Clients_Short_OP in the position's native currency or USD-converted? The NOP column from BI_DB_PositionPnL appears to be in native currency — is an FX conversion applied? | SP code uses NOP directly from BI_DB_PositionPnL without currency conversion |
| Regulation "None" | What does Regulation='None' represent? Are these pre-migration customers, test accounts, or a legitimate no-regulation state? | Live data shows rows with Regulation='None' |
| IFR/KPMG context | Is this table specifically for KPMG audit submissions, or is it also used for internal risk monitoring? | SP name: SP_Capital_Adequacy_IFR_KPMG suggests audit use |

## Structural Questions

| Question | Context |
|----------|---------|
| The same SP also populates Dealing_LP_StocksNOP — are these always analyzed together as a pair (client exposure vs LP hedged volume)? | SP writes to both tables in sequence |
| Are composite regulations like "FinCEN+FINRA" and "NYDFS+FINRA" still active, or are they historical artifacts? | 15 distinct regulations found in live data |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
