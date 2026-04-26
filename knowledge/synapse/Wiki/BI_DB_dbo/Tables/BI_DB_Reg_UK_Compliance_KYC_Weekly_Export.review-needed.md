# Review Needed — BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 8.5/10

## Tier 4/5 Items Requiring Review

No Tier 4 or Tier 5 items — all 40 columns are Tier 2/3 with strong SP authority.

## Questions for Domain Expert

### 1. KYC PIVOT semantics — MAX(AnswerText) for text values
- The SP uses `PIVOT(MAX(AnswerText) FOR QuestionText IN (...))` across `BI_DB_KYCUserRawDataLeveled`. For text answers, MAX is lexicographic, not chronological. If a customer re-answered a question (e.g., changed occupation), the row with the lexicographically largest answer value is returned — not necessarily the most recent. Reviewer should confirm whether MAX is intentional (last answer wins by alphabetic sort) or whether a recency-ordered approach was intended.

### 2. DaysLastPosOpCFD staleness
- `DaysLastPosOpCFD` is computed as `DATEDIFF(day, LastPositionOpenDateCFD, GETDATE())` at INSERT time on Tuesday. By Wednesday this value is already 1 day stale; by the following Monday it is 6 days stale. Any downstream report consuming this column directly (rather than re-computing from `LastPosOpCFD`) will drift. Reviewer should confirm whether consuming systems re-derive days or rely on the stored value.

### 3. Club tier string matching — future-proofing
- The SP uses `Club IN ('Platinum', 'Platinum Plus', 'Diamond', 'Gold')`. If new premium tiers are introduced in `BI_DB_CIDFirstDates` (e.g., "Elite", "Private"), they would not automatically appear in this export — the SP would require a code change. Reviewer should confirm whether new premium tiers should be auto-included or require explicit SP updates.

### 4. OpenCFDPositions NULL semantics
- Customers with no open positions have no row in `#opencfd` (the SP uses a LEFT JOIN). The resulting NULL in the final table is ambiguous — it could mean "zero open positions" or "position data not available". The SP does not COALESCE to 0. Reviewer should confirm whether NULL should be treated as 0 in downstream reports, or whether it signals a missing data condition.

### 5. Desk derivation from Dim_Country, not Dim_Manager
- `Desk` is sourced from `DWH_dbo.Dim_Country.Desk` (via CountryID join) — it reflects the *country-level desk assignment*, not a manager-assigned desk or account manager's team. Reviewer should confirm whether this is intentional (desk = country routing) or whether for some regulated populations the Desk should come from account manager structure instead.

## No ALTER Script Generated

ALTER script deferred to `/generate-alter-dwh` pass. UC Target = `_Not_Migrated`, so no ALTER will be generated unless UC migration occurs.
