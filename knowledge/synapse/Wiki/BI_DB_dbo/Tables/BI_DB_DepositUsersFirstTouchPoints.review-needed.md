# BI_DB_DepositUsersFirstTouchPoints — Review Notes

**Generated**: 2026-04-22 | **Batch**: 23 | **Priority**: 20

---

## Tier 4 Items (Low Confidence — Needs Verification)

None. All columns have confirmed sourcing from SP code analysis or direct upstream inheritance.

---

## Open Questions for Reviewers

1. **6 permanently disabled columns**: EmailVerification, DepositView, DepositSubmits, DepositSubmitClick, PhoneVerification, KYCFlow are all 100% NULL in production. They have been disabled for 2–4 years. Are there plans to repopulate or remove these columns? They waste DDL space and may confuse new analysts.

2. **FirstDemoTrade always 0**: The demo table (BI_DB_Demo_CID_Panel) has been disconnected from this SP since 2024-01-15 (per SP change log). All rows have FirstDemoTrade=0. If demo-first analysis is needed, is there an alternative source? Or should this column be deprecated?

3. **Multi-row grain**: A customer appears once per distinct milestone date. If two milestones happen on the same day, they collapse to one row (both flags=1). If analyzing funnel steps, consumers must aggregate with SUM, not COUNT. Is this grain documented/known by dashboard authors consuming this table?

4. **Rolling 2-year window**: The table only contains milestones from the past 2 years. Customers who registered and deposited more than 2 years ago are excluded (unless they had a recent FirstAction or CrossDate). Is this the intended scope? If historical cohort analysis is needed pre-2024, is there an archive?

5. **TRUNCATE on full refresh with 14M rows**: The SP issues TRUNCATE + INSERT on every run. Given 14M rows and the window of all customers active in 2 years, this is a heavy operation. Is there a documented schedule/SLA? What is the downstream dependency chain?

6. **FunnelFrom / Platform column clarity**: These are renamed from BI_DB_CIDFirstDates.FunnelFromName / FunnelName. What specific values do they take in production? The mapping from FunnelName to business product names may not be obvious to new consumers.

---

## Data Quality Observations

- **Date range limited to 2 years**: Unlike most BI_DB_dbo tables that have multi-year history, this table's oldest date moves forward as @date advances. Historical analysis before 2024 is unavailable.
- **Registration rows dominate**: 9.5M of 14M rows have Registration=1, suggesting most rows are registration-date rows. FTD rows (977K) and OpenTrade rows (1M) are much smaller populations — reflecting actual funnel drop-off.
- **Desk via Country name JOIN**: SP joins Dim_Country ON D.Country=DD.Name — a text join, not an integer key join. If Country names in BI_DB_CIDFirstDates have formatting differences (case, special chars) from Dim_Country.Name, some Desk values will be NULL.

---

## Cross-Object Consistency Checks

- **CID description**: Copied verbatim from DWH_dbo.Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) ✓
- **AffiliateID description**: Copied verbatim from DWH_dbo.Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) ✓
- **SubAffiliateID description**: Copied verbatim from DWH_dbo.Dim_Customer.SubSerialID wiki (Tier 1 — Customer.CustomerStatic) ✓
