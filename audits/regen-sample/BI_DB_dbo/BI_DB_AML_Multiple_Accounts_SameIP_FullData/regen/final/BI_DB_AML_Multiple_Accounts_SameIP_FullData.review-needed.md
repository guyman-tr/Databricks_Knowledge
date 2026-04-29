# Review Needed — BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData

## 1. Data Freshness Concern

- **UpdateDate is 2025-03-13** for all rows — over a year stale as of 2026-04-28. Verify whether `SP_AML_Multiple_Accounts` is still scheduled and executing. The table may be abandoned or the SP may have been paused.

## 2. HashIP Column Type Mismatch

- **HashIP is nvarchar(250)** but stores the output of `CHECKSUM()` which returns `int`. The value is an integer stored as a string. Consider whether this is intentional (future extensibility for longer hashes) or a DDL oversight.

## 3. Sibling Table Cross-Reference

- This table is one of 6 output tables from `SP_AML_Multiple_Accounts`. The aggregate companion table `BI_DB_AML_Multiple_Accounts_SameIP` stores the raw IP and count — this table stores the per-CID detail with a hashed IP. Confirm whether downstream dashboards join these two tables or use them independently.

## 4. CHECKSUM Collision Risk

- `CHECKSUM()` is a non-cryptographic hash. For the ~353K distinct IPs in this dataset, collision probability is low but nonzero. If exact IP matching is critical for investigations, the raw IP should be resolved at query time from `Dim_Customer`.

## 5. No Downstream Consumers Found

- No views, SPs, or other tables were found to reference this table. Confirm whether it is consumed by an external BI tool (Power BI, Tableau) or API.
