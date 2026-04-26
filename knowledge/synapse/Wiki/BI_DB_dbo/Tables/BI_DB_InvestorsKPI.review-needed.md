# Review Needed: BI_DB_dbo.BI_DB_InvestorsKPI

Generated: 2026-04-22 | Reviewer: Finance / Account Management / Data Platform

## Tier 4 / Unverified Items

1. **Classification (Tier 4 — always NULL)**: This column was commented out in the SP (`--,pp.Classification`) and has `NULL AS Classification` in all INSERT paths. Can this column be dropped from the table DDL, or is there a plan to populate it? If a backfill is planned, what would it represent?

## Questions for Business Reviewer

1. **InvestedAmountCopy next-day logic**: The SP reads `BI_DB_Guru_Copiers` at `TimestampID = DateID+1` (tomorrow's timestamp). Is this intentional to capture the day-end copy AUM snapshot? If Guru_Copiers hasn't loaded for the next day when SP_InvestorKPI runs, does InvestedAmountCopy default to 0?

2. **Balance = V_Liabilities.Credit**: The column name "Balance" might suggest portfolio equity to analysts, but the source is `V_Liabilities.Credit`. Is this the customer's available credit/cash balance (not total portfolio value)? Should this be documented as "credit balance" to avoid confusion?

3. **IsFullMonth flag semantics for AM bonus**: The wiki states IsFullMonth=1 means the customer was in the AM portfolio at both start and end of month. Is this the exact definition used in the bonus calculation, or is there additional logic in the reporting layer?

4. **PlayerLevelID IN (2,3,6,7)**: The SP filter uses these 4 IDs for Gold through Diamond. The live data shows Gold, Platinum, Platinum Plus, Diamond. Can you confirm the exact mapping (which ID = which tier)? Dim_PlayerLevel drops the equity threshold columns so the IDs can't be verified from Synapse alone.

5. **InstrumentTypeID classification for Investment**: The SP uses InstrumentTypeID=6, or (4,5 with Leverage<3) as "Investment". Is InstrumentTypeID=6 specifically "real stocks/equities"? What does InstrumentTypeID=4 and 5 represent (ETFs? Indices?)? The Dim_Instrument wiki should clarify but InstrumentTypeID descriptions aren't in scope here.

6. **MirrorID=0 filter**: Copy-trading mirror positions (MirrorID != 0) are excluded from Investment/Crypto/Trade. Is this intentional for bonus calculation (only count direct positions, not copy positions)? If a customer is primarily a copier, all their AUA via copy would be 0 in these columns.

7. **ReportingMonth for days 1–3 new customers**: On day 1 of a new month (days <= 3), the SP deletes ALL rows for DateID >= @DateID AND ActiveMonth = @StartOfMonth before reinserting. Does this mean that if a new customer joins on day 2, they would be included in the start-of-month snapshot with ReportingMonth = current month? The code path suggests yes.

## Known Data Quality Issues

- **Classification always NULL**: Column declared in DDL but never populated (commented out in SP)
- **InvestedAmountCopy = 0 if Guru_Copiers next-day unavailable**: Heavy dependence on load ordering
- **Rolling IsEndOfMonth/IsFullMonth rewrite**: Historical rows have IsEndOfMonth=0 after each daily run — querying historical end-of-month state requires DateID filtering, not IsEndOfMonth flag
- **Balance misleading name**: V_Liabilities.Credit labeled as "Balance" — analysts may confuse with portfolio equity

## Lineage Confidence

| Column Group | Confidence | Source |
|-------------|------------|--------|
| DateID, Date, ActiveMonth | HIGH (Tier 2) | SP parameter derivations |
| ReportingMonth | MEDIUM (Tier 2) | SP logic confirmed but day-boundary semantics need business confirmation |
| Investment, Crypto, Trade | HIGH (Tier 2) | SP code with InstrumentTypeID classification logic confirmed |
| InvestedAmountCopy | HIGH (Tier 2) | SP reads Guru_Copiers explicitly |
| Balance | HIGH (Tier 2) | SP reads V_Liabilities.Credit explicitly — naming concern only |
| Deposit, Withdrawal | HIGH (Tier 2) | Fact_CustomerAction ActionTypeID=7/8 confirmed |
| IsStartOfMonth, IsEndOfMonth, IsFullMonth | HIGH (Tier 2) | SP logic fully analyzed |
| IsBlocked | HIGH (Tier 2) | PlayerStatusID IN (2,4,6,7,8,14) confirmed in SP |
| Club | HIGH (Tier 2) | Dim_PlayerLevel.Name via BI_DB_CID_DailyPanel_Club |
| Classification | HIGH (Tier 4) | Always NULL — confirmed in both SP branches |
