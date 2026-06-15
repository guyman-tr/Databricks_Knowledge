# Column Lineage: main.de_output.customer_segments_mail_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.customer_segments_mail_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\de_output\_discovery\source_code\customer_segments_mail_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\de_output\_discovery\column_lineage\customer_segments_mail_v.json` (rows: 24, mismatches: 1) |
| **Primary upstream** | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_marketing_sfmc_sfmc_report.md` |

## Lineage Chain

```
main.bi_output.bi_output_marketing_sfmc_sfmc_report   ←── primary upstream
        │
        ▼
main.de_output.customer_segments_mail_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `SubscriberID` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `SubscriberID` | `passthrough` | — | SubscriberID |
| 2 | `GCID` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `GCID` | `passthrough` | — | GCID |
| 3 | `SentTime` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `SentTime` | `passthrough` | — | SentTime |
| 4 | `SendDateID` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `SendDateID` | `passthrough` | — | SendDateID |
| 5 | `Subject` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `Subject` | `passthrough` | — | Subject |
| 6 | `SendID` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `SendID` | `passthrough` | — | SendID |
| 7 | `EmailName` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `EmailName` | `passthrough` | — | EmailName |
| 8 | `CampaignGroup` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CampaignGroup` | `passthrough` | — | CampaignGroup |
| 9 | `CampaignSubGroup` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CampaignSubGroup` | `passthrough` | — | CampaignSubGroup |
| 10 | `CampaignName` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CampaignName` | `passthrough` | — | CampaignName |
| 11 | `CampaignNumber` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CampaignNumber` | `passthrough` | — | CampaignNumber |
| 12 | `CountOpen` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CountOpen` | `passthrough` | — | CountOpen |
| 13 | `UniqueOpen` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `UniqueOpen` | `passthrough` | — | UniqueOpen |
| 14 | `CountClicks` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CountClicks` | `passthrough` | — | CountClicks |
| 15 | `UniqueClicks` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `UniqueClicks` | `passthrough` | — | UniqueClicks |
| 16 | `CountBounce` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CountBounce` | `passthrough` | — | CountBounce |
| 17 | `Delivered` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `Delivered` | `passthrough` | — | Delivered |
| 18 | `OpenDate` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `OpenDate` | `passthrough` | — | OpenDate |
| 19 | `ClickDate` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `ClickDate` | `passthrough` | — | ClickDate |
| 20 | `CountSend` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `CountSend` | `passthrough` | — | CountSend |
| 21 | `LSD` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `LSD` | `passthrough` | — | LSD |
| 22 | `etr_y` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `etr_y` | `passthrough` | — | etr_y |
| 23 | `etr_ym` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `etr_ym` | `passthrough` | — | etr_ym |
| 24 | `etr_ymd` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | `etr_ymd` | `passthrough` | — | etr_ymd |

## Cross-check vs system.access.column_lineage

- Total target columns: **24**
- OK: **23**, WARN: **1**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `GCID` | `main.bi_output.bi_output_marketing_sfmc_sfmc_report.gcid` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.gcid`, `main.bi_output.bi_output_marketing_sfmc_sfmc_report.gcid` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**
