# Review Needed: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

## Summary

No upstream wiki was available for any column (`_no_upstream_found.txt` present). All descriptions are grounded in DDL types, SP code (`SP_Create_fiktivo_AffiliateCommission_ClosedPosition`, `SP_Marketing_Cube`), live data sampling, and Confluence documentation. Zero Tier 1 columns.

## Tier 3 Columns Requiring SME Validation

| # | Column | Current Tier | Reason for Review |
|---|--------|-------------|-------------------|
| 1 | ClosedPositionID | Tier 3 | No upstream wiki. Description based on DDL + JOIN pattern in SP_Marketing_Cube. SME should confirm if this maps to a specific production PK. |
| 2 | CommissionDate | Tier 3 | No upstream wiki. Is this the date the commission was calculated, or the date the position was closed? SP uses it as a date-range filter. |
| 3 | Amount | Tier 3 | No upstream wiki. Confirm: is this always in USD, or does it follow the position's currency? |
| 4 | HedgeCommission | Tier 3 | No upstream wiki. Confirm the business meaning — is this the hedge portion of the commission or a separate commission type? |
| 5 | CID vs OriginalCID | Tier 3 | No upstream wiki. In copy-trading: which is the copier and which is the leader? SP uses OriginalCID as the attribution key. |
| 6 | ProviderID / OriginalProviderID / RealProviderID | Tier 3 | No upstream wiki. Three provider columns with unclear distinction. Sample data shows ProviderID=1, OriginalProviderID=0, RealProviderID=1 for all rows — may be legacy columns. |
| 7 | PlayerLevelID | Tier 3 | No upstream wiki. Values 1-6 observed. Confirm mapping to player level names (e.g., 1=Silver, 2=Gold, etc.). SP changelog mentions "player level 4" specifically. |
| 8 | AdditionalData | Tier 3 | No upstream wiki. 100% empty in sample. Confirm if this column is deprecated or populated for specific scenarios. |

## Tier 2 Columns Requiring Verification

| # | Column | Current Tier | Reason for Review |
|---|--------|-------------|-------------------|
| 1 | LabelID | Tier 2 | Hardcoded NULL in ClosedPositionVW (100% NULL in 36.8M rows). Confirm: is this intentionally unused or a migration artifact? |
| 2 | Valid | Tier 2 | Described as 1=eligible, 0=disqualified. Confirm these exact business meanings. |
| 3 | IsProcessed | Tier 2 | Described as 1=calculated, 0=pending. Confirm these exact business meanings. |
| 4 | NetProfit | Tier 2 | Marked as computed in ClosedPositionVW. Confirm the computation logic (e.g., is it P&L after spreads?). |
| 5 | ValidFrom / UpdateDate | Tier 2 | Assumed to be system-generated timestamps. Confirm whether these are set by the fiktivo application or by database triggers. |

## Data Quality Observations

- **Rolling window only**: Table contains only ~2 months of data (2026-03-01 to 2026-04-26) due to the daily DROP + rebuild pattern starting from start of last month.
- **No clustered index**: HEAP table with ROUND_ROBIN distribution. Query performance may degrade for large analytical queries.
- **LabelID 100% NULL**: Column exists in DDL but carries no data. Candidate for deprecation review.
- **Fake FTD exclusion**: SP_Marketing_Cube explicitly excludes customers with FirstDepositDate between 2025-08-19 and 2025-08-22 with FirstDepositAmount=1. This is a hardcoded data quality patch.

## Missing Upstream Documentation

- No wiki exists for `fiktivo.AffiliateCommission.ClosedPositionVW` (production view).
- No wiki exists for `fiktivo.AffiliateCommission.ClosedPositionFromEtoro` (source table).
- No wiki exists for `fiktivo.AffiliateCommission.RegistrationMetaData` (metadata table).
- Confluence pages provide partial context but not column-level documentation.
