# Review Needed: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP

## 1. Data Freshness

- **UpdateDate is 2025-03-13** — over a year stale as of 2026-04-28. Confirm whether SP_AML_Multiple_Accounts is still running daily or if the ETL schedule has been disrupted.

## 2. IP Column Type Widening

- DDL defines IP as `nvarchar(250)` but source Dim_Customer.IP is `varchar(15)`. The widening is unnecessary — confirm whether this was intentional (e.g., future IPv6 support) or an oversight.

## 3. Companion Table Correlation

- `BI_DB_AML_Multiple_Accounts_SameIP_FullData` uses `CHECKSUM(ss.IP) AS HashIP` — a lossy hash. Confirm whether analysts have a reliable way to join back from HashIP to the raw IP in this table, or if they go through Dim_Customer directly.

## 4. VPN/Corporate IP Noise

- The maximum NumOfClientsSameIP is 374. IPs with very high client counts likely represent VPN exit nodes, corporate NATs, or ISP CGNATs rather than fraud. Consider whether a threshold or flag column would improve analyst workflow.

## 5. VerificationLevelID Filter Discrepancy

- This table filters `VerificationLevelID = 3` (fully verified only), while the companion FundingID tables use `VerificationLevelID >= 2`. Confirm whether this stricter filter is intentional for the IP detection use case.
