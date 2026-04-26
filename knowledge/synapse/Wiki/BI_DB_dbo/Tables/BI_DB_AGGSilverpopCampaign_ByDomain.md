# BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain

> Silverpop (IBM email marketing platform) campaign metrics broken down by recipient email domain — domain-level sibling of `BI_DB_AGGSilverpopCampaign`. Each row represents one mailing/domain/week combination, storing sent, bounce, open, and click counts segmented by the recipient's email provider (gmail.com, yahoo.com, etc.). Currently **empty (0 rows as of 2026-04-23)** — Silverpop was migrated to Optimove circa 2024; no active writer SP in SSDT; not in OpsDB. `MailingID` is a foreign key to `BI_DB_SilverpopCampaignDictionary`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — Silverpop email campaign aggregate by email domain |
| **Production Source** | Unknown — IBM Silverpop SaaS platform (Watson Campaign Automation); migrated to Optimove ~2024 |
| **Refresh** | None active — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Domain ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_AGGSilverpopCampaign (per-mailing KPI sibling, CampaignDate-clustered), BI_DB_SilverpopCampaignDictionary (MailingID FK), BI_DB_SilverpopLanguage |

---

## 1. Business Meaning

`BI_DB_AGGSilverpopCampaign_ByDomain` stored aggregate email campaign performance metrics from **Silverpop** (IBM Watson Campaign Automation), broken down by recipient email domain. Each row represents a specific mailing (`MailingID`) in a given calendar year and week, scoped to a single email domain (e.g., gmail.com, yahoo.com, hotmail.com).

This table is the **domain-level sibling** of `BI_DB_AGGSilverpopCampaign` (which aggregates by mailing × date without domain segmentation). The domain breakdown enabled analysis of email deliverability and engagement by provider — for example, understanding whether Gmail or Yahoo users had higher open rates for a given campaign.

**Current status**: The table is empty (0 rows). Silverpop was decommissioned and migrated to **Optimove** circa 2024. Evidence of migration: DWH Silverpop dimension tables (`Dim_SilverpopMailing`, `Dim_SilverpopSubject`, `Dim_SilverpopEventType`, `Dim_SilverpopGroups`, `Dim_SilverpopIPs`) now carry the `JUNK_` prefix, and a `Dim_SilverToOpti_Mail_Rel` mapping table exists. Historical Silverpop event data remains accessible in `DWH.mailtracking.Fact_MailTracking` (SilverpopEventID=16 for sends).

The table was clustered on `Domain ASC` to support efficient per-domain aggregation queries, and uses `ROUND_ROBIN` distribution (no natural distribution key given the cross-mailing scope).

---

## 2. Business Logic

### 2.1 Domain Segmentation

**What**: Each row scopes campaign metrics to one email domain, enabling provider-level deliverability analysis.
**Columns Involved**: Domain, MailingID, Year, Week
**Rules**:
- One row per (MailingID × Domain × Year × Week) combination
- `Domain` contains the recipient email domain (e.g., `gmail.com`, `yahoo.com`, `hotmail.com`)
- Clustered on Domain for efficient per-provider querying

### 2.2 Email Funnel Metrics

**What**: Four KPIs measure engagement across the email funnel for the scoped domain.
**Columns Involved**: Sent, Bounce, Opened, Click
**Rules**:
- `Sent` = emails successfully delivered to this domain's recipients
- `Bounce` = hard + soft bounces combined (permanent + temporary failures)
- `Opened` = email opens (unique or total — unclear without active data)
- `Click` = link clicks (unique or total — unclear without active data)
- All metrics are integers; `NULL` indicates missing data (not zero)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Domain. Efficient for per-domain filtering but requires data movement on cross-domain aggregations. Table is currently empty — no query optimization applies.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which email domains had the most opens for a campaign? | `SELECT Domain, Opened FROM ... WHERE MailingID = X ORDER BY Opened DESC` |
| What is the bounce rate by domain? | `SELECT Domain, SUM(Bounce)*1.0/NULLIF(SUM(Sent),0) FROM ... GROUP BY Domain` |
| Campaign metrics by year/week for a domain? | `SELECT Year, Week, SUM(Sent), SUM(Opened) FROM ... WHERE Domain = 'gmail.com' GROUP BY Year, Week` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_SilverpopCampaignDictionary | `ON d.MailingID = dict.MailingID` | Retrieve CampaignName, Subject, MailingName |
| BI_DB_AGGSilverpopCampaign | `ON d.MailingID = agg.MailingID AND d.Date = agg.CampaignDate` | Compare domain-level vs. overall campaign metrics |

### 3.4 Gotchas

- **Table is empty**: No rows as of 2026-04-23. Silverpop migrated to Optimove ~2024.
- **Domain clustering**: CLUSTERED on Domain, so domain-filtered queries are efficient, but date-range scans are expensive.
- **Bounce ambiguity**: `Bounce` may combine hard and soft bounces — cannot distinguish type from this table alone.
- **Sibling differences**: The sibling `BI_DB_AGGSilverpopCampaign` has additional columns (TotalCustomers, MailsSent, HardBounce/SoftBounce separately, UniqueOpen/TotalOpen separately, Unsubscribed, ReportedAbuse, EmailDomainID) — this table only has the simplified Sent/Bounce/Opened/Click.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from writer SP code (source-to-target mapping) |
| Tier 3 | Inferred from DDL, column name patterns, sibling table docs, or live data |
| Tier 4 | Best-guess — no definitive source found |
| Tier 5 | Propagation constant (ETL metadata — UpdateDate, InsertDate) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MailingID | int | NOT NULL | Unique identifier for the Silverpop mailing send. FK to `BI_DB_SilverpopCampaignDictionary` for MailingName, CampaignName, and Subject. (Tier 3 — IBM Silverpop platform) |
| 2 | Year | int | NULL | Calendar year of the campaign send (e.g., 2023). Used for time-series analysis across years. (Tier 3 — IBM Silverpop platform) |
| 3 | Week | int | NULL | Calendar/ISO week number of the campaign send (1–53). Enables weekly campaign pacing analysis by domain. (Tier 3 — IBM Silverpop platform) |
| 4 | Domain | varchar(200) | NULL | Email domain of the recipient cohort (e.g., `gmail.com`, `yahoo.com`, `hotmail.com`). Clustering key — domain-level delivery segmentation. (Tier 3 — IBM Silverpop platform) |
| 5 | Sent | int | NULL | Count of emails successfully delivered to recipients at this domain during the mailing. (Tier 3 — IBM Silverpop platform) |
| 6 | Bounce | int | NULL | Count of email bounces (hard + soft combined) for this domain. High bounce rate signals deliverability issues with the provider. (Tier 3 — IBM Silverpop platform) |
| 7 | Opened | int | NULL | Count of email opens by recipients in this domain. May represent unique or total opens — ambiguous without active data for verification. (Tier 3 — IBM Silverpop platform) |
| 8 | Click | int | NULL | Count of link clicks by recipients in this domain. May represent unique or total clicks — ambiguous without active data for verification. (Tier 3 — IBM Silverpop platform) |
| 9 | Date | date | NULL | Campaign send date (calendar date of the mailing). Used alongside Year/Week for time-based analysis. (Tier 3 — IBM Silverpop platform) |
| 10 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns | IBM Silverpop SaaS platform | Silverpop campaign API / export | Direct export — no intermediary SSDT SP |

### 5.2 ETL Pipeline

```
IBM Silverpop (Watson Campaign Automation) — SaaS email platform
  |-- Direct platform export (mechanism unknown) ---|
  v
BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain (decommissioned, 0 rows)
  |-- No active ETL — platform migrated to Optimove ~2024 ---|
  v
No UC Gold target (_Not_Migrated)

Historical data:
DWH.mailtracking.Fact_MailTracking (SilverpopEventID=16 for sends)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| MailingID | BI_DB_SilverpopCampaignDictionary | FK — retrieve MailingName, CampaignNumber, CampaignName, Subject |

### 6.2 Referenced By

No known downstream consumers (table is decommissioned and empty).

---

## 7. Sample Queries

### Domain deliverability breakdown for a mailing

```sql
SELECT 
    d.Domain,
    d.Sent,
    d.Bounce,
    d.Opened,
    d.Click,
    CAST(d.Bounce AS FLOAT) / NULLIF(d.Sent, 0) AS BounceRate,
    CAST(d.Opened AS FLOAT) / NULLIF(d.Sent, 0) AS OpenRate
FROM [BI_DB_dbo].[BI_DB_AGGSilverpopCampaign_ByDomain] d
WHERE d.MailingID = 12345
ORDER BY d.Sent DESC;
```

### Top domains by open rate across all mailings in a year

```sql
SELECT 
    Domain,
    SUM(Sent) AS TotalSent,
    SUM(Opened) AS TotalOpened,
    CAST(SUM(Opened) AS FLOAT) / NULLIF(SUM(Sent), 0) AS OpenRate
FROM [BI_DB_dbo].[BI_DB_AGGSilverpopCampaign_ByDomain]
WHERE Year = 2023
GROUP BY Domain
HAVING SUM(Sent) > 100
ORDER BY OpenRate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this decommissioned table. Historical Silverpop documentation, if it exists, would be under the email marketing or CRM team's Confluence space. The platform migration to Optimove was executed circa 2024.

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 6/10, Data Evidence: 2/10*
*Object: BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain | Type: Table | Production Source: IBM Silverpop (decommissioned)*
