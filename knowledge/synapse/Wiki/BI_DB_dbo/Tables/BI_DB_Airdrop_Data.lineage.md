# BI_DB_dbo.BI_DB_Airdrop_Data — Column Lineage

## Source Objects

| Source | Type | Relationship |
|--------|------|-------------|
| (Unknown) | Unknown | No writer SP found in SSDT; table is fully orphaned |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Confidence |
|---|---------------|-------------|---------------|-----------|------------|
| 1 | CID | Unknown | Unknown | No writer SP — likely Customer.CustomerStatic.CID | Tier 4 |
| 2 | Country | Unknown | Unknown | No writer SP — likely Dim_Country.Name or customer country | Tier 4 |
| 3 | EU | Unknown | Unknown | No writer SP — likely EU membership flag (1/0) | Tier 4 |
| 4 | Desk | Unknown | Unknown | No writer SP — likely customer desk assignment | Tier 4 |
| 5 | Club | Unknown | Unknown | No writer SP — likely eToro Club membership tier | Tier 4 |
| 6 | Regulation | Unknown | Unknown | No writer SP — likely Dim_Regulation.Name | Tier 4 |
| 7 | SymbolFull | Unknown | Unknown | No writer SP — likely crypto instrument symbol | Tier 4 |
| 8 | Amount | Unknown | Unknown | No writer SP — likely airdrop token amount | Tier 4 |
| 9 | ExecutionOccurred | Unknown | Unknown | No writer SP — likely airdrop execution date | Tier 4 |
| 10 | FirstDepositDate | Unknown | Unknown | No writer SP — likely customer first deposit date | Tier 4 |
| 11 | Equity | Unknown | Unknown | No writer SP — likely customer equity at time of airdrop | Tier 4 |
| 12 | Deposited | Unknown | Unknown | No writer SP — likely total deposited amount | Tier 4 |
| 13 | Revnue | Unknown | Unknown | No writer SP — typo for "Revenue"; likely customer revenue | Tier 4 |
| 14 | Deposit | Unknown | Unknown | No writer SP — likely deposit amount (money type) | Tier 4 |
| 15 | UpdateDate | Unknown | Unknown | No writer SP — ETL metadata timestamp | Tier 5 |

## Lineage Notes

- **Fully orphaned**: No stored procedure in the Synapse SSDT repo reads or writes this table
- **Not in OpsDB**: No orchestration entry exists
- **Not in Generic Pipeline**: No Bronze/lake mapping found
- **Related table**: BI_DB_Crypto_Airdrop is a SEPARATE, active table written by SP_BI_DB_Crypto_Airdrop with a different column structure (35 columns tracking V3 customer post-airdrop behavior analysis)
- **Likely origin**: Early prototype for crypto airdrop customer data, abandoned in favor of the more comprehensive BI_DB_Crypto_Airdrop analysis table
