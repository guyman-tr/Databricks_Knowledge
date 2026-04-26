# Review Needed: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID

**Generated**: 2026-04-23 | **Quality**: 8.0/10 | **Reviewer**: BI / AML team

---

## Items Requiring Human Review

### 1. Session Join Logic (Fact_BillingDeposit linkage)
- **Flag**: The SP joins STS_User_Operations_Data_History to Fact_BillingDeposit ON SessionId — this means only sessions that have an associated approved deposit are counted
- **Why**: Customers who shared a device but never deposited would be excluded. This may undercount device sharing.
- **Action**: Confirm with SP owner whether deposit-filtered device sharing was intentional (AML focus on financial activity) or a side effect of the SessionId join

### 2. UC Migration / Decommission
- **Flag**: `UC Target: Not_Migrated` — 74-row table with no active SP
- **Why**: Minimal value for migration; formal decommission may be more appropriate
- **Action**: Confirm with BI team whether this table can be archived or dropped

### 3. HAVING > 1 Threshold
- **Flag**: Only device IDs shared by 2+ customers survive. The threshold is hard-coded in the SP.
- **Why**: For future reference — if threshold is changed, row count would change significantly
- **Action**: No immediate action needed; documented here for completeness

---

## No Review Needed

- Row count (74): consistent with very narrow threshold (HAVING COUNT > 1)
- SP disable date (2024-12-31): confirmed in SP header comment
- All-zero GUID exclusion: explicitly coded in SP Step 09
- SubChannelID scope: confirmed via SP Step 01 + Step 03
- DateID >= 20220101 for STS history: confirmed in SP Step 09
