# Review Needed — BI_DB_dbo.BI_DB_Crypto_Top_1000_List

Generated: 2026-04-28

---

## Items Requiring Human Review

### 1. Hardcoded CID List May Be Stale
The 1,000 target CIDs are permanently hardcoded in SP_Crypto_Top_1000_List. The list was last revised 2023-11-23. These customers were relevant for a late-2023 crypto win-back campaign. As of 2026-04-28 the SP still runs daily, but the cohort is 2+ years old. **Review**: Is this list still used for active outreach, or should the campaign be retired / the SP updated with a dynamic selection?

### 2. UC Target Unknown
No UC target is configured for this table. The DDL uses HEAP (no clustered index), suggesting it was not intended as a permanent analytical table. **Review**: Should this be migrated to UC Delta, or is it retained as an operational AM tool only?

### 3. ACC_Revenue Description — Upstream Elements Truncated
The MonthlyPanel wiki was truncated before the ACC_Revenue_Total element row. The description for ACC_Revenue was reconstructed from the Business Logic commentary (section 2.4) in that wiki. **Review**: Verify the description against the full BI_DB_CID_MonthlyPanel_FullData.ACC_Revenue_Total element definition.

### 4. Revenue_Crypto_from_20231201 — Unbounded Growth
This column accumulates from 2023-12-01 with no end date cap. On each daily refresh it absorbs additional revenue. If the campaign period has ended, this may need an explicit end date to preserve the original campaign metric. **Review**: Confirm whether an end date should be applied or if continuous accumulation is intentional.

### 5. SP Cohort Criteria vs. Actual CID Values
The SP comment states the original criterion was "revenue < $100 since 20230801". However, the code comment shows `< 1000` (dollar amount $1,000, not $100). The observed ACC_Revenue_Crypto minimum in the current data is $27,128 (lifetime), suggesting these are high-value crypto customers with low recent activity. **Review**: Confirm whether the cohort threshold was $100 or $1,000 and update the SP comment accordingly.

### 6. LastCryptoPosOpenDate — MirrorID=0 Only
The SP filters `MirrorID=0` (manual positions only) for LastCryptoPosOpenDate. Copy-trade crypto positions are excluded. **Review**: Confirm whether this is intentional — AMs may want the absolute last crypto open date regardless of trade type.
