# Review Needed: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP

**Generated**: 2026-04-23 | **Quality**: 8.0/10 | **Reviewer**: BI / AML team

---

## Items Requiring Human Review

### 1. %SameIP Decimal Precision Discrepancy
- **Flag**: SP computes ROUND(NumOfClientsSameIP * 100.0 / TotalClients, 2) (2 decimal places) but DDL stores `[%SameIP]` as `decimal(18,0)` — integer only
- **Why**: Either the DDL was defined incorrectly (should be decimal(10,2)) or the integer precision was intentional for the AML report
- **Action**: Confirm with SP owner or BI team whether decimal precision was intentionally dropped. If DDL is wrong, this is a data quality issue affecting historical values.

### 2. CHECKSUM Collision Risk
- **Flag**: `[Group]` = CHECKSUM(IP) is a 32-bit hash — collisions are possible (~1 in 4 billion per pair, but with millions of IPs the probability compounds)
- **Why**: Two different IPs mapping to the same [Group] value would be treated as the same IP group, inflating NumOfClientsSameIP
- **Action**: For any analytical use requiring precision, cross-validate [Group] against raw IP from BI_DB_AML_Affiliate_Abuse_Users

### 3. V_Liabilities INNER JOIN Denominator Effect
- **Flag**: TotalClients = equity-filtered customers only, not all registered affiliate customers
- **Why**: Customers who registered but never had financial activity are excluded from both numerator and denominator, potentially distorting %SameIP for affiliates with many non-depositors
- **Action**: Confirm intended scope with AML team — was the equity filter intentional for this metric?

### 4. UC Migration / Decommission
- **Flag**: `UC Target: Not_Migrated` — 1.17M rows, no active SP
- **Why**: Large frozen table; migration adds cost without operational value
- **Action**: Confirm with BI team whether table should be formally decommissioned or archived

---

## No Review Needed

- Row count (1,178,451): large table consistent with all IP groups (no HAVING filter)
- SP disable date (2024-12-31): confirmed in SP header comment
- SubChannelID scope: confirmed via SP Step 01
- CHECKSUM usage: explicitly coded in SP Step 09
- TotalClients computation (SUM OVER PARTITION BY AffiliateID): confirmed in SP Step 09
