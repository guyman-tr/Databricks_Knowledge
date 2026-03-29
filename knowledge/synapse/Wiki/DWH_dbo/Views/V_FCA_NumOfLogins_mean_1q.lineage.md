# Column Lineage — DWH_dbo.V_FCA_NumOfLogins_mean_1q

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Fact_CustomerAction |
| **View Type** | Aggregation (GROUP BY RealCID) |
| **Filter** | `ActionTypeID = 14` (Logins), `DateID` between 3 months ago and today |

## Column Mapping

| # | View Column | Type | Source Table | Source Column | Transform | Upstream Wiki |
|---|------------|------|-------------|---------------|-----------|---------------|
| 1 | Date | date | — (system) | GETDATE() | `CAST(GETDATE() AS DATE)` — computed at query time | N/A — system function |
| 2 | RealCID | int | DWH_dbo.Fact_CustomerAction | RealCID | GROUP BY key (pass-through) | [Fact_CustomerAction.md](../Tables/Fact_CustomerAction.md) — Tier 1 inherited |
| 3 | NumOfLogins_mean_1q | float | DWH_dbo.Fact_CustomerAction | COUNT(*) | `COUNT(*) / DATEDIFF(day, DATEADD(month,-3,GETDATE()), GETDATE())` | N/A — computed aggregate |

## Upstream Dependency Graph

```
DWH_dbo.V_FCA_NumOfLogins_mean_1q
└── DWH_dbo.Fact_CustomerAction [WIKI: ✓ Fact_CustomerAction.md]
    ├── RealCID       → V.RealCID (GROUP BY key)
    ├── ActionTypeID   → WHERE filter (= 14, logins)
    ├── DateID         → WHERE filter (3-month rolling window)
    └── (row count)    → V.NumOfLogins_mean_1q (COUNT(*) / days)
```
