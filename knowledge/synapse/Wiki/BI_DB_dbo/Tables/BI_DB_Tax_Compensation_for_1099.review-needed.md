# Review Sidecar — BI_DB_dbo.BI_DB_Tax_Compensation_for_1099

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | PASS | 27 columns in DDL, 27 in wiki |
| All columns have tier suffix | PASS | 12 Tier 1 + 14 Tier 2 + 1 Tier 5 |
| Writer SP confirmed | PASS | SP_Tax_Compensation_for_1099 — code reviewed |
| Sample data reviewed | PASS | 10 rows — all US addresses, Regulation = FinCEN+FINRA, SSN mostly NULL, Equity present |
| Row count verified | PASS | 215,242 rows via COUNT_BIG |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | SSN coverage | Medium | Sample data shows SSN as empty/NULL for all 10 sampled rows. Confirm what percentage of customers have SSN populated — if very low, 1099 filing may have data quality gaps. |
| 2 | Equity snapshot timing | Medium | Equity is computed from V_Liabilities for yesterday (GETDATE()-1). This means Equity reflects the balance at time of SP run, not at time of compensation event. Confirm this is the intended behavior for 1099 reporting. |
| 3 | State via RegionByIP_ID | Medium | State is resolved via LEFT JOIN Dim_State_and_Province ON dc.RegionID = dsap.RegionByIP_ID. The "ByIP" suffix suggests this may be IP-geolocation-based rather than registration address. Confirm this yields the correct legal state for 1099 purposes. |
| 4 | No DISTINCT on #pop_comp | Low | Step 1 does not apply DISTINCT. If a CID has multiple rows in Dim_Customer (e.g., multiple RealCID mappings), this could produce duplicates. Step 3 applies DISTINCT on #final — confirm this is sufficient deduplication. |
| 5 | Dim_PlayerStatus / Dim_State_and_Province | Low | No upstream wiki exists for DWH_dbo.Dim_PlayerStatus, Dim_State_and_Province, Dim_Customer, or V_Liabilities. Tier 2 assignments for columns sourced from these tables are based on SP code analysis only. |
| 6 | Schedule / Priority | Low | SP has no OpsDB metadata visible. Confirm the daily schedule and priority level. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 12 | CID, Amount, Type, Time, Description, Category, Reason, Manager, AffiliateID, Club, Regulation, Country |
| Tier 2 | 14 | YEAR, PlayerStatus, VerificationLevelID, IsDepositor, FirstName, LastName, Email, Address, State, City, BuildingNumber, Zip, SSN, Equity |
| Tier 5 | 1 | UpdateDate |
