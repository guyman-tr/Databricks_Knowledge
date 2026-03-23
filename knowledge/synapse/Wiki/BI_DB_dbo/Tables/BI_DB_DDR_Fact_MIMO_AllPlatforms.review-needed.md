# Review Sidecar: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Writer SP | Verified | `SP_DDR_Fact_Fact_MIMO_AllPlatforms` — double `Fact` in name |
| Core lineage | Verified | Union of `BI_DB_DDR_Fact_MIMO_Trading_Platform` + `BI_DB_DDR_Fact_MIMO_eMoney_Platform`; Options and MoneyFarm append paths |
| Global FTD | Verified | `Function_MIMO_First_Deposit_All_Platforms(0)` + post-UPDATEs with `Dim_Customer` / `eMoney_Fact_Transaction_Status` |
| DDL vs SP | Review | Table DDL defines `TransactionID` as `int`; SP text casts via `VARCHAR(50)` in INSERT — confirm deployed Synapse object matches SSDT (implicit conversion or drift) |
| Consumer list | Verified via repo grep | `SP_DDR_Customer_Daily_Status`, `SP_MarketingCloudDaily`, `SP_RevenueForum`, `BI_DB_V_DDR_MIMO`, functions |

## Unverified Items

| Topic | Tier | Issue |
|-------|------|--------|
| Full `MIMOAction` domain | T4 | Enumerate all distinct values across platforms — not extracted here |
| `FundingTypeID` / `CurrencyID` dictionaries | T4 | Confirm Dim / dictionary joins for decode lists |
| Options data readiness | T4 | Procedure states Options feed is “best effort” and not always ready at DDR send — quantify lag if needed for SLAs |
| Function_MIMO_First_Deposit_All_Platforms ↔ this table | T4 | Circular dependency — document execution order in OpsDB / orchestration if required |

## Quality Notes

- No live Synapse data sampling in this pass — distributions of flags and action types should be validated with MCP or sampled queries when available.
- Section 8 (Atlassian) left empty of real links — Phase 10 should attach DDR / payments Confluence context.
- SQF columns intentionally omitted — MIMO-only scope per product context.
