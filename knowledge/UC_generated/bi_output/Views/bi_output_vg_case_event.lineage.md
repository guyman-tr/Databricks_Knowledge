# Column Lineage: main.bi_output.bi_output_vg_case_event

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_case_event` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_case_event.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_case_event.json` (rows: 22, mismatches: 2) |
| **Primary upstream** | `main.bi_output.bi_output_customer_customer_support_case_event` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_customer_customer_support_case_event` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_case_event.md` |
| `main.bi_output.bi_output_customer_customer_support_agent_user` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_agent_user.md` |

## Lineage Chain

```
main.bi_output.bi_output_customer_customer_support_case_event   ←── primary upstream
  + main.bi_output.bi_output_customer_customer_support_agent_user   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_case_event   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `EventID` | `main.bi_output.bi_output_customer_customer_support_case_event` | `EventID` | `passthrough` | — | bdsce.EventID |
| 2 | `EventName` | `main.bi_output.bi_output_customer_customer_support_case_event` | `EventName` | `passthrough` | — | bdsce.EventName |
| 3 | `CreatedById` | `main.bi_output.bi_output_customer_customer_support_case_event` | `CreatedById` | `passthrough` | — | bdsce.CreatedById |
| 4 | `CaseID` | `main.bi_output.bi_output_customer_customer_support_case_event` | `CaseID` | `passthrough` | — | bdsce.CaseID |
| 5 | `EventType` | `main.bi_output.bi_output_customer_customer_support_case_event` | `EventType` | `passthrough` | — | bdsce.EventType |
| 6 | `OldStatus` | `main.bi_output.bi_output_customer_customer_support_case_event` | `OldStatus` | `passthrough` | — | bdsce.OldStatus |
| 7 | `NewStatus` | `main.bi_output.bi_output_customer_customer_support_case_event` | `NewStatus` | `passthrough` | — | bdsce.NewStatus |
| 8 | `DoneBy` | `main.bi_output.bi_output_customer_customer_support_case_event` | `DoneBy` | `passthrough` | — | bdsce.DoneBy |
| 9 | `DoneByCSDesk` | `main.bi_output.bi_output_customer_customer_support_case_event` | `DoneByCSDesk` | `passthrough` | — | bdsce.DoneByCSDesk |
| 10 | `DoneByRole` | `main.bi_output.bi_output_customer_customer_support_case_event` | `DoneByRole` | `passthrough` | — | bdsce.DoneByRole |
| 11 | `UpdatedByAutomaticProcess` | `main.bi_output.bi_output_customer_customer_support_case_event` | `UpdatedByAutomaticProcess` | `passthrough` | — | bdsce.UpdatedByAutomaticProcess |
| 12 | `FromDate` | `main.bi_output.bi_output_customer_customer_support_case_event` | `Occurred` | `rename` | — | bdsce.Occurred AS FromDate |
| 13 | `ToDate` | `main.bi_output.bi_output_customer_customer_support_case_event` | `ToDate` | `passthrough` | — | bdsce.ToDate |
| 14 | `UpdateDate` | `main.bi_output.bi_output_customer_customer_support_case_event` | `UpdateDate` | `passthrough` | — | bdsce.UpdateDate |
| 15 | `EventNumber` | `main.bi_output.bi_output_customer_customer_support_case_event` | `EventNumber` | `passthrough` | — | bdsce.EventNumber |
| 16 | `Touches` | `main.bi_output.bi_output_customer_customer_support_case_event` | `Touches` | `passthrough` | — | bdsce.Touches |
| 17 | `IsWorkload` | `main.bi_output.bi_output_customer_customer_support_case_event` | `IsWorkload` | `passthrough` | — | bdsce.IsWorkload |
| 18 | `Converteddate` | `main.bi_output.bi_output_customer_customer_support_case_event` | `Occurred` | `cast` | — | cast to DATE — CAST(Occurred AS DATE) AS Converteddate |
| 19 | `CaseNumber` | `main.bi_output.bi_output_customer_customer_support_case_event` | `CaseNumber` | `passthrough` | — | bdsce.CaseNumber |
| 20 | `IsReopen` | `main.bi_output.bi_output_customer_customer_support_case_event` | `IsReopen` | `passthrough` | — | bdsce.IsReopen |
| 21 | `FromDateTimeZone` | `main.bi_output.bi_output_customer_customer_support_case_event` | `—` | `unknown` | — | CONVERT_TIMEZONE('UTC', u.TimeZoneSidKeys, bdsce.Occurred) AS FromDateTimeZone |
| 22 | `IsSolved` | `main.bi_output.bi_output_customer_customer_support_case_event` | `—` | `case` | — | CASE WHEN LAST(CASE WHEN bdsce.NewStatus <> 'Closed' THEN bdsce.NewStatus END) OVER (PARTITION BY CaseID ORDER BY bdsce.Occurred) = 'Solved' |

## Cross-check vs system.access.column_lineage

- Total target columns: **22**
- OK: **20**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FromDateTimeZone` | — | `main.bi_output.bi_output_customer_customer_support_agent_user.reportsto`, `main.bi_output.bi_output_customer_customer_support_agent_user.timezonesidkey`, `main.bi_output.bi_output_customer_customer_support_case_event.occurred` | ERROR |
| `IsSolved` | — | `main.bi_output.bi_output_customer_customer_support_case_event.caseid`, `main.bi_output.bi_output_customer_customer_support_case_event.newstatus`, `main.bi_output.bi_output_customer_customer_support_case_event.occurred` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN (SELECT ID, CASE WHEN ReportsTo IN ('0050800000EE0zOAAT', '0050800000GyOLrAAN', '0050800000DArh6AAD') THEN 'Australia/Sydney' ELSE TimeZoneSidKey END AS TimeZoneSidKeys FROM bi_output.bi_output_customer_customer_support_agent_user
