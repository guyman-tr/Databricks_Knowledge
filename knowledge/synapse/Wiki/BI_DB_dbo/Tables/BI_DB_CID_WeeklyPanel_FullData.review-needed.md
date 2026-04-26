# Review Needed: BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData

Generated: 2026-04-23 | Batch: 69 | Quality target: 7.5+

---

## 1. ACC_ Column Semantics — Verify Intended Use

**Issue**: In the WeeklyPanel SP, ACC_ columns (ACC_Revenue_*, ACC_PnL_*, ACC_TotalDeposits, ACC_CountDeposits, ACC_TotalCashouts, ACC_TotalCoFee, ACC_NetDeposits, ACC_WithdrawalToWallet) are computed as `SUM(daily_ACC_value)` across the week's 7 days — **not** as a self-referencing running total (unlike MonthlyPanel pattern).

**Example**: If a customer has ACC_Revenue_Total = 100, 110, 120, 120, 120, 130, 140 on Mon–Sun respectively, the weekly ACC_Revenue_Total = 840 — far larger than the week's Revenue_Total of ~40. This is mathematically unusual.

**Action needed**: Confirm with business/engineering (Or Filizer or Dan Iliescu) whether this is:
- (a) Intentional design for a specific analytical use case
- (b) A known limitation/artifact of the weekly aggregation pattern inherited from an earlier design
- (c) An error that should instead use MAX(ACC_Revenue_Total) — i.e., the last day's lifetime total

Until confirmed, the wiki documents the actual computation truthfully in §2.6 with a usage warning.

---

## 2. Weekly_Classification — Always Empty String

**Issue**: `Weekly_Classification` is always empty string `''` in 2025–2026. It is inherited from `Daily_Classification` in DailyPanel, which is set by `SP_CID_DailyPanel_UpdateCluster` — a post-insert SP that is non-operational post-Synapse migration.

**Action needed**: Confirm if this column will ever be repopulated, or if it should be formally deprecated (and the column eventually dropped).

---

## 3. IsReg_ThisD / IsFTD_ThisD Naming Inconsistency

**Issue**: Column names `IsReg_ThisD` and `IsFTD_ThisD` use the "D" (Day) suffix but in the WeeklyPanel context they represent a point-in-time snapshot from the **last day of the week** only — not "any day in the week" semantics. The "W" variants (`IsReg_ThisW`, `IsFTD_ThisW`) are the proper weekly flags.

**Action needed**: Confirm this is an intentional naming convention (retained from DailyPanel for consistency) versus a potential bug where these should instead be the EOW-snapshot variants of IsFTD/IsReg flags.

---

## 4. 2024-03-26 Lifestage Column — Missing from Weekly

**Issue**: The SP change history states "Add Lifestage Column 2024-03-26 (Or Filizer)". However, reviewing the WeeklyPanel DDL and SP code, there is **no Lifestage column** in the WeeklyPanel. The DailyPanel has `EOD_LSD` (LifeStageDefinition) which does pass through to the WeeklyPanel as `EOW_LSD`. The 2024-03-26 change history note appears to be carried over from the DailyPanel's own change history (referenced in the SP comment block) rather than a WeeklyPanel-specific change.

**Action needed**: Verify whether the 2024-03-26 change note in SP_CID_WeeklyPanel_FullData refers to:
- (a) The addition of EOW_LSD passthrough (which IS present)
- (b) A separate "Lifestage" column that was intended but not yet added to Weekly

---

## 5. Historical Date Range Not Verified

**Issue**: Live data sampling confirmed 2026-01-04 to 2026-04-05. The SP was created 2021-06-29. Historical data for 2021–2025 was not live-queried to confirm full date coverage.

**Action needed**: If historical weekly analysis is planned, run:
```sql
SELECT MIN(FirstDayOfWeek), MAX(FirstDayOfWeek), COUNT(DISTINCT FirstDayOfWeek) 
FROM BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData
```
to confirm the full date range.

---

## 6. ACC_ChurnDays and FirstNewFundedDate Excluded

**Issue**: `ACC_ChurnDays` and `FirstNewFundedDate` are present in the DailyPanel and appear in the `#dailydata` SELECT in the WeeklyPanel SP, but are **NOT** included in `#dailysum` aggregation or the final INSERT. These columns are absent from the WeeklyPanel DDL.

**Action needed**: Confirm this is an intentional design decision (weekly churn day counting was not deemed useful) or an oversight. If weekly churn analysis is needed downstream, these columns would need to be added.

---

## 7. Tier Annotations — T1 Source Verification

The following columns were given Tier 1 sourcing from the DailyPanel wiki, which itself sourced them from DWH_dbo. Confirm the DailyPanel wiki's own T1 annotations are still accurate before using these for downstream propagation:
- `CID` → DWH_dbo.Dim_Customer wiki
- `Region`, `Country` → DWH_dbo.Dim_Country wiki
- `V2_Complete`, `V3_Complete`, `LastLoggedIn` → DWH_dbo.Dim_Customer wiki
- `EOW_Club` → DWH_dbo.Dim_PlayerLevel wiki

---

## Documentation Generation Notes

- **Phase 2 live sample**: TOP 10 rows confirmed (Week 2026-15, UpdateDate 2026-04-12)
- **Phase 3 distributions**: EOW_Club (7 values), EOW_Regulation (15 values), EOW_LSD (17 values) fully sampled
- **Phase 9 SP analysis**: Full SP_CID_WeeklyPanel_FullData.sql read (639 lines); all 174 column assignments traced
- **OpsDB**: Priority 0, SB_Daily confirmed; dependency on SP_CID_DailyPanel_FullData confirmed
- **DailyPanel wiki**: Used as primary T1 source for all column descriptions (183-col sibling)
- **MonthlyPanel wiki**: Consulted for ACC_ semantics comparison and documentation style
- **DDL verification**: All 174 columns, types, and NOT NULL constraints confirmed from SSDT repo
