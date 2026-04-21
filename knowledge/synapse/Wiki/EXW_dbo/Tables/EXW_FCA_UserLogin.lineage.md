---
object: EXW_dbo.EXW_FCA_UserLogin
type: Table
batch: 9
---

# EXW_FCA_UserLogin — Column Lineage

> SP_EXW_FCA_UserLogin is a near-perfect passthrough from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=14`, filtered to wallet users via `EXW_Wallet.CustomerWalletsView`. All columns except UpdateDate inherit directly from FCA.

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| GCID | GCID | `DWH_dbo.Fact_CustomerAction` → `etoro.Customer.CustomerStatic` | Passthrough | Tier 1 |
| RealCID | RealCID | `DWH_dbo.Fact_CustomerAction` → `etoro.Customer.CustomerStatic` | Passthrough | Tier 1 |
| DateID | DateID | `DWH_dbo.Fact_CustomerAction` (ETL-computed) | Passthrough of ETL-computed YYYYMMDD int | Tier 2 |
| DemoCID | DemoCID | `DWH_dbo.Fact_CustomerAction` (ETL-assigned) | Passthrough; always 0 in FCA | Tier 3 |
| Occurred | Occurred | `DWH_dbo.Fact_CustomerAction` → `STS_Audit_UserOperationsData` | Passthrough; login timestamp | Tier 1 |
| IPNumber | IPNumber | `DWH_dbo.Fact_CustomerAction` → `STS / Billing.Login` | Passthrough | Tier 1 |
| IsReal | IsReal | `DWH_dbo.Fact_CustomerAction` (ETL-assigned) | Passthrough; always 1 | Tier 3 |
| ActionTypeID | ActionTypeID | `DWH_dbo.Fact_CustomerAction` (ETL-derived) | Passthrough; always 14 (LoggedIn filter) | Tier 1 |
| PlatformTypeID | PlatformTypeID | `DWH_dbo.Fact_CustomerAction` (ETL-assigned) | Passthrough | Tier 3 |
| LoginID | LoginID | `DWH_dbo.Fact_CustomerAction` → `Billing.Login` | Passthrough | Tier 1 |
| TimeID | TimeID | `DWH_dbo.Fact_CustomerAction` (ETL-computed) | Passthrough of DATEPART(HOUR, Occurred) | Tier 2 |
| StatusID | StatusID | `DWH_dbo.Fact_CustomerAction` (ETL-assigned) | Passthrough | Tier 3 |
| SessionID | SessionID | `DWH_dbo.Fact_CustomerAction` → `STS` | Passthrough | Tier 1 |
| PlatformID | PlatformID | `DWH_dbo.Fact_CustomerAction` → domain expert | Passthrough | Tier 5 |
| CountryIDByIP | CountryIDByIP | `DWH_dbo.Fact_CustomerAction` → IP geolocation | Passthrough | Tier 5 |
| IsAnonymousIP | IsAnonymousIP | `DWH_dbo.Fact_CustomerAction` → IP geolocation | Passthrough | Tier 1 |
| ProxyType | ProxyType | `DWH_dbo.Fact_CustomerAction` → `STS` | Passthrough | Tier 1 |
| UpdateDate | — | SP_EXW_FCA_UserLogin | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
STS_Audit_UserOperationsData (Session Tracking Service — login events)
  └─ Generic Pipeline (Bronze export)
  └─ DWH_dbo.Fact_CustomerAction (WHERE ActionTypeID=14 — login rows only, ~11B row table)
       ├─ Wallet scope filter via LEFT JOIN EXW_Wallet.CustomerWalletsView ON GCID
       └─ DELETE WHERE DateID=@d_i + INSERT INTO EXW_dbo.EXW_FCA_UserLogin

Wallet filter: Only rows where GCID EXISTS in CustomerWalletsView are retained.
All non-wallet users' login rows are excluded.
```
