# Column Lineage: DWH_dbo.Dim_CountryIPAnonymousProxyType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CountryIPAnonymousProxyType` |
| **UC Target** | Not in Generic Pipeline — not exported to UC |
| **Primary Source** | IP2Location Anonymous IP Database (external vendor documentation) |
| **ETL SP** | None — manual one-time load |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
IP2Location Anonymous IP Database (external vendor documentation)
  -> Manual one-time INSERT (no SSDT SP)
    -> DWH_dbo.Dim_CountryIPAnonymousProxyType (6 rows, static reference)
      -> DWH_dbo.Dim_CountryIPAnonymous.ProxyType (via SP_Dictionaries_Country_DL_To_Synapse)
        -> DWH_dbo.Fact_CustomerAction.ProxyType (via SP_Fact_CustomerAction IP range JOIN)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |
| **ETL-computed** | Derived/calculated by ETL process. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ProxyType | IP2Location Anonymous IP Database | ProxyType code | passthrough | 3-char code: DCH, PUB, SES, TOR, VPN, WEB |
| ProxyTypeDescription | IP2Location Anonymous IP Database | Description | passthrough | Full description text from IP2Location documentation |
| Anonymity | IP2Location Anonymous IP Database | Anonymity level | passthrough | "High" or "Low" — IP2Location classification |
| UpdateDate | — | — | ETL-computed | Never set — always NULL (static load, no active ETL) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **ETL-computed** | 1 |
| **Total** | 4 |
