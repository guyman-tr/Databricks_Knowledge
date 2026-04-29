# BI_DB_dbo.BI_DB_Airdrop_Data -- Review Needed

## Dormant Table Assessment

- **Status**: 0 rows, no writer SP, fully orphaned
- **Recommendation**: Consider DROP -- table was likely an early prototype abandoned in favor of BI_DB_Crypto_Airdrop
- **Column typo**: "Revnue" should be "Revenue" -- if table is ever reactivated, rename the column

## Tier 4 Items (All Columns)

All 14 non-ETL columns are Tier 4 (inferred from column names). No upstream wiki, no SP code, no live data to verify against. Descriptions are best-effort based on:
1. Column naming conventions (standard eToro customer/trading terminology)
2. SP_BI_DB_Crypto_Airdrop code (the active airdrop SP that writes to a DIFFERENT table -- gives domain context)
3. Domain knowledge of crypto airdrop distribution programs

## Questions for Reviewer

1. **Was this table populated on-prem?** If so, what was the production source?
2. **Relationship to BI_DB_Crypto_Airdrop**: Was this the predecessor? Are they from different teams/projects?
3. **Should this be decommissioned?** The active airdrop analysis uses BI_DB_Crypto_Airdrop instead
4. **EU column**: Is this a boolean (0/1) or does it use other values (e.g., EEA membership)?
5. **Deposited vs Deposit**: What is the semantic difference? Count vs amount? Current vs total?
6. **SymbolFull format**: Full instrument name (e.g., "Bitcoin") or ticker symbol (e.g., "BTC")?

## Cross-Object Consistency

- Related: BI_DB_Crypto_Airdrop (separate, active table with SP_BI_DB_Crypto_Airdrop writer)
- CID column: matches standard eToro CID definition
