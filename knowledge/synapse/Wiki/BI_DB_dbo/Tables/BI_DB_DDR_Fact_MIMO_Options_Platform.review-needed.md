# Review Needed — BI_DB_DDR_Fact_MIMO_Options_Platform

Lightweight QA sidecar (**not** wiki content).

## Tier 4 / ambiguity flags

| Topic | Gap | Owner / next step |
|-------|-----|-------------------|
| **Ops orchestration linkage** | `SB_Daily` / `ServiceBrokerPriority` row for **`SP_DDR_Fact_MIMO_Options_Platform` not enumerated** (`user-opsdb_sql` guarded-name query failed syntax) | OpsDB reviewer — cite procedure priority vs TP/eMoney |
| **`IsFTD` / `IsGlobalFTD` readability** | Business interpretation for FINRA `FO1` vs `Dim_Customer` platform `FTDPlatformID = 2` requires Options PM / broker ops sign-off beyond SSDT wording | Compliance / DDR analytics |
| **UC export** | Databricks MCP **cannot locate** nominal `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_options_platform` | Data platform mapping / lakebridge parity |
| **Sodreconciliation cash dictionary** | No dedicated local wiki beyond pipeline JSON for **`EXT869_CashActivity` column semantics** (`EnteredBy`, `TerminalID`, `RegisteredRepCode`, etc.) — descriptions lean on SSDT External DDL + MCP samples | Bonnie / broker integration |

## PII checklist

| Column | Notes |
|--------|-------|
| `RealCID` | Indirect identifier — aligns with **`Dim_Customer`** access policies |
| Operational strings (`TransactionID` / Apex references) | No direct name/email/phone in CCI projection — treat mirrored lake paths as finance/confidential |

## Open questions for DA

1. Should **`FundingTypeID` loader zeroing** be retired so DDR reflects TVF-coded rails (`42/29/2`) without off-table inspection?
2. Confirm **withdraw positivity** aligns with Apex reporting expectations versus TP signed withdraw convention.
3. Does **`Fact_SnapshotCustomer` vs `Dim_Customer` join split** inside TVF still match intended governance (potential drift auditing)?

## Reviewer corrections

(Add dated bullet notes here.)
