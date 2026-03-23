# Review Sidecar: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Writer / refresh pattern | Verified from SP | `DELETE` by `DateID` + `INSERT`; post-`UPDATE` for FTD recovery |
| Row grain | Verified from SP | Dedupe by `TransactionID` after UNION deposits + withdraws |
| Deposit vs withdraw TxType sets | Verified from SP | Deposits 7,5,14; withdraws 8,6; settled only |
| Amount signs | Verified from SP | Withdrawals negated; FTD amount update on deposits from `#FTDIBAN` |
| Currency resolution | Verified from SP | Two paths: ISO static mapping vs `Dim_Currency.Abbreviation` |
| Consumers | Verified from repo grep | `SP_DDR_Fact_Fact_MIMO_AllPlatforms`, `SP_DDR_Process_Monitor` |
| Synapse physical DDL | Verified from user DDL | `HASH(RealCID)`, clustered columnstore |

## Unverified Items

| Topic | Tier | Issue |
|-------|------|-------|
| TxTypeID semantics (7,5,14,8,6) | T4 | Business names for each eMoney TxType id not enumerated in SP — need eMoney data dictionary or product confirmation |
| FundingTypeID = 33 | T4 | Meaning of code `33` in DDR / reporting dims not confirmed beyond “internal transfer” branch |
| IsTradeFromIBAN business label | T4 | Rule is in SP; product naming (“trade from IBAN”) should be validated with payments / eMoney owners |
| TxType 8 withdraw inclusion | T4 | Author comment: may include trade-open flows — downstream users should confirm inclusion in MIMO KPIs |
| ReferenceNumber sentinel `-1` | T2 | Behavior is in SP; confirm consumer compatibility (string vs numeric expectation) |

## Quality Notes

- **No live Synapse sampling** in this documentation pass — distributions of `TxTypeID` / `FundingTypeID` not validated from data.
- **Atlassian**: No Confluence/Jira links captured; Phase 10 can add eMoney IBAN / DDR sources.
- **Column count**: DDL lists 21 columns (header comment “20 columns” may be outdated).
