# BI_DB_dbo.BI_DB_AGGSilverpopCampaign

> Silverpop (IBM email marketing platform) campaign aggregate metrics table — per-mailing rollup of standard email delivery and engagement KPIs (sent, opens, clicks, bounces, unsubscribes, abuse). Date-clustered for time-series campaign analysis. Currently **empty (0 rows as of 2026-04-23)** — Silverpop was migrated to Optimove circa 2024, and all DWH Silverpop dimension tables are now JUNK-prefixed. No active writer SP in SSDT; not registered in OpsDB. `MailingID` is a foreign key to `BI_DB_SilverpopCampaignDictionary` for campaign metadata.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — Silverpop email campaign aggregate (per-mailing KPI rollup) |
| **Production Source** | Unknown — Silverpop platform (IBM Watson Campaign Automation); migrated to Optimove ~2024 |
| **Refresh** | None active — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CampaignDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_SilverpopCampaignDictionary (MailingID FK), BI_DB_AGGSilverpopCampaign_ByDomain (sibling domain aggregate), BI_DB_SilverpopLanguage |

---

## 1. Business Meaning

`BI_DB_AGGSilverpopCampaign` stored aggregate email campaign performance metrics from **Silverpop** — IBM's email marketing platform (now Watson Campaign Automation / IBM Marketing Cloud). Each row represents a single mailing send (`MailingID`) on a given `CampaignDate`, with rolled-up delivery and engagement counts for the entire campaign audience.

eToro used Silverpop for bulk email marketing campaigns. The table captures the full email funnel:
1. **Audience sizing**: `TotalCustomers` (list size) → `MailsSent` (after deduplication)
2. **Delivery outcome**: `Suppressed` (blocked), `HardBounce` (permanent failure), `SoftBounce` (temporary failure)
3. **Engagement**: `UniqueOpen`/`TotalOpen` (open rate), `UniqueClick`/`TotalClick` (click-through rate)
4. **Negative signals**: `Unsubscribed` (opt-out), `ReportedAbuse` (spam complaint)

The `Domain` and `EmailDomainID` columns provide a lightweight segmentation of the audience by email domain (e.g., gmail.com, yahoo.com) — allowing domain-level deliverability analysis without joining to the sibling `BI_DB_AGGSilverpopCampaign_ByDomain` table.

**Platform migration**: Silverpop was decommissioned at eToro circa 2024 and replaced by Optimove. Evidence: all DWH Silverpop dimension tables (`Dim_SilverpopMailing`, `Dim_SilverpopSubject`, `Dim_SilverpopEventType`, `Dim_SilverpopGroups`, `Dim_SilverpopIPs`) are now JUNK-prefixed in the migration schema, and a `Dim_SilverToOpti_Mail_Rel` mapping table bridges historical Silverpop mailings to their Optimove counterparts.

---

## 2. Business Logic

### 2.1 Email Delivery Funnel

**What**: Standard email delivery accounting — from audience to delivered.

**Columns Involved**: `TotalCustomers`, `MailsSent`, `Seeded`, `Suppressed`, `HardBounce`, `SoftBounce`

**Rules**:
- `TotalCustomers` = total recipients in the target list (before any filtering)
- `MailsSent` ≤ `TotalCustomers` — reduced by deduplication, suppression, and list cleaning
- `Seeded` = emails sent to internal seed addresses (test/QA recipients) — included in MailsSent
- `Suppressed` = emails blocked before send due to opt-out, global suppression, or bounce history
- `HardBounce` = permanent delivery failure (invalid address, non-existent domain) — these addresses are removed from future lists
- `SoftBounce` = temporary failure (mailbox full, server temporarily unavailable) — retried per platform policy

### 2.2 Engagement Metrics

**What**: Unique vs. total counts distinguish deduplicated engagement from raw event counts.

**Columns Involved**: `UniqueOpen`, `TotalOpen`, `UniqueClick`, `TotalClick`

**Rules**:
- `UniqueOpen` ≤ `TotalOpen` — Unique counts each recipient once regardless of how many times they opened
- `UniqueClick` ≤ `TotalClick` — same pattern for click events
- Open Rate = `UniqueOpen / MailsSent` (standard industry metric)
- Click-to-Open Rate (CTOR) = `UniqueClick / UniqueOpen`
- `TotalOpen` inflated by email clients that auto-preview (opens mail without human action)

### 2.3 Negative Engagement Signals

**What**: Compliance and list health signals.

**Columns Involved**: `Unsubscribed`, `ReportedAbuse`

**Rules**:
- `Unsubscribed` = recipients who clicked the unsubscribe link in this mailing — immediately removed from future sends per CAN-SPAM/GDPR
- `ReportedAbuse` = recipients who clicked "Report Spam" in their email client — critical for sender reputation; high abuse rates trigger ISP blocks
- Abuse Rate threshold: >0.08% typically triggers inbox filtering penalties

### 2.4 Domain Segmentation

**What**: Per-domain context for deliverability analysis.

**Columns Involved**: `EmailDomainID`, `Domain`

**Rules**:
- `EmailDomainID` = integer reference to an email domain lookup (domain reference table not directly identified in SSDT)
- `Domain` = de-normalized email domain name (e.g., "gmail.com", "yahoo.com", "hotmail.com")
- One campaign can appear with multiple rows at different domain granularities — or `Domain` may represent the primary domain of the audience

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CampaignDate. Designed for time-series campaign performance queries. Given the table is empty, no current query optimizations are relevant.

**Warning**: The table is currently empty. Any query returns 0 rows. Silverpop data may still exist in `DWH.mailtracking.Fact_MailTracking` for historical analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign open rate trend | `SELECT CampaignDate, CAST(UniqueOpen AS FLOAT)/NULLIF(MailsSent,0) AS OpenRate ORDER BY CampaignDate` |
| Hard bounce analysis | `SELECT MailingID, HardBounce, CAST(HardBounce AS FLOAT)/NULLIF(MailsSent,0) AS BounceRate ORDER BY BounceRate DESC` |
| Click-to-open rate | `SELECT UniqueClick / NULLIF(UniqueOpen,0) AS CTOR` |
| Unsubscribe trend | `SELECT CampaignDate, SUM(Unsubscribed) GROUP BY CampaignDate ORDER BY CampaignDate` |
| Campaign metadata JOIN | `JOIN BI_DB_SilverpopCampaignDictionary ON MailingID` for name, segment, subject |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_SilverpopCampaignDictionary | `ON a.MailingID = d.MailingID` | Campaign name, number, language, segment, subject line |
| BI_DB_AGGSilverpopCampaign_ByDomain | `ON a.MailingID = b.MailingID` | Per-domain breakdown of the same campaign |
| BI_DB_SilverpopLanguage | `ON d.CampaignLanguageID = l.LanguageID` | Campaign language (via SilverpopCampaignDictionary) |
| DWH.mailtracking.Fact_MailTracking | `ON a.MailingID = mt.SilverpopMailingID` | Individual-level email events (open, click, bounce) |

### 3.4 Gotchas

- **Table is currently empty** — 0 rows as of 2026-04-23. Silverpop was migrated to Optimove; no new data expected.
- **Historical data in DWH** — `DWH.mailtracking.Fact_MailTracking` retains individual Silverpop events. Use it for historical campaign analysis if this table remains empty.
- **UniqueOpen vs TotalOpen** — Use UniqueOpen for open rate calculations. TotalOpen is inflated by bot-driven auto-previews (especially post-Apple MPP).
- **MailsSent includes Seeded** — Seed addresses inflate MailsSent. For true customer delivery metrics: MailsSent − Seeded.
- **Domain column meaning** — With a single Domain value per row but multiple campaign rows possible, confirm whether Domain = primary domain or audience domain distribution requires joining to BI_DB_AGGSilverpopCampaign_ByDomain.
- **NOT NULL constraints** — MailingID, CampaignID, CampaignDate are NOT NULL (the only non-nullable columns). All metric columns can be NULL.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, email marketing domain knowledge, and Silverpop platform context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MailingID | int | NO | Silverpop mailing identifier — unique ID for a specific email send. FK to BI_DB_SilverpopCampaignDictionary.MailingID for campaign name, segment, and subject line. (Tier 3 — BI_DB_SilverpopCampaignDictionary DDL + Silverpop platform domain) |
| 2 | CampaignID | int | NO | Silverpop campaign identifier. One campaign can have multiple mailings (A/B test variants, re-sends, translated versions). (Tier 3 — column name + Silverpop campaign/mailing hierarchy) |
| 3 | CampaignDate | date | NO | Date the email campaign was sent. Clustered index key — date-range queries over campaign history are efficient. (Tier 3 — column name + email marketing domain) |
| 4 | TotalCustomers | int | YES | Total number of recipients in the campaign audience list before any filtering or deduplication. (Tier 3 — column name + standard email marketing funnel) |
| 5 | MailsSent | int | YES | Total emails successfully dispatched (after suppression, deduplication). Includes seeded addresses. Denominator for delivery and engagement rate calculations. (Tier 3 — column name + Silverpop platform metrics) |
| 6 | Seeded | int | YES | Count of emails sent to seed addresses — internal test/QA recipients used to monitor email rendering and delivery before/during the live send. (Tier 3 — column name + email marketing seed list domain) |
| 7 | Suppressed | int | YES | Count of emails blocked before send by the suppression list — recipients who have previously opted out, hard-bounced, or are on global do-not-email lists. (Tier 3 — column name + CAN-SPAM/GDPR suppression compliance) |
| 8 | HardBounce | int | YES | Count of permanent delivery failures — invalid email addresses or non-existent domains. Hard-bounced addresses are removed from future send lists. (Tier 3 — column name + standard email deliverability domain) |
| 9 | SoftBounce | int | YES | Count of temporary delivery failures — mailbox full, server temporarily unavailable. Platform retries soft bounces per configured policy. (Tier 3 — column name + standard email deliverability domain) |
| 10 | UniqueOpen | int | YES | Count of unique recipients who opened the email (deduplicated — one count per recipient regardless of how many times they opened). Standard open rate numerator. (Tier 3 — column name + Silverpop standard metrics) |
| 11 | TotalOpen | int | YES | Total open events, counting multiple opens per recipient. Higher than UniqueOpen. Note: can include automated opens from email preview clients (Apple MPP, bot traffic). (Tier 3 — column name + email marketing engagement domain) |
| 12 | UniqueClick | int | YES | Count of unique recipients who clicked any link in the email (deduplicated). Standard click-through rate numerator. (Tier 3 — column name + Silverpop standard metrics) |
| 13 | TotalClick | int | YES | Total click events, counting multiple clicks per recipient across all links. (Tier 3 — column name + email marketing engagement domain) |
| 14 | Unsubscribed | int | YES | Count of recipients who clicked the unsubscribe link in this mailing. Immediately triggers suppression per CAN-SPAM/GDPR compliance. (Tier 3 — column name + email compliance domain) |
| 15 | ReportedAbuse | int | YES | Count of recipients who marked the email as spam or abuse through their email client. High abuse rates damage sender reputation and trigger ISP filtering. (Tier 3 — column name + email deliverability/sender reputation domain) |
| 16 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. (Tier 5 — propagation) |
| 17 | EmailDomainID | int | YES | Integer reference to an email domain lookup table. Allows filtering/grouping by recipient email domain. (Tier 3 — column name + BI_DB_AGGSilverpopCampaign_ByDomain domain segmentation pattern) |
| 18 | Domain | varchar(50) | YES | De-normalized email domain name (e.g., "gmail.com", "yahoo.com"). Provides direct domain segmentation without a join. Consistent with the Domain column in BI_DB_AGGSilverpopCampaign_ByDomain. (Tier 3 — column name + sibling table schema) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| MailingID | Silverpop platform | MailingID | Passthrough |
| CampaignID | Silverpop platform | CampaignID | Passthrough |
| CampaignDate | Silverpop platform | CampaignDate | Passthrough |
| TotalCustomers | Silverpop platform | TotalCustomers | Passthrough |
| MailsSent | Silverpop platform | MailsSent | Passthrough |
| Seeded | Silverpop platform | Seeded | Passthrough |
| Suppressed | Silverpop platform | Suppressed | Passthrough |
| HardBounce | Silverpop platform | HardBounce | Passthrough |
| SoftBounce | Silverpop platform | SoftBounce | Passthrough |
| UniqueOpen | Silverpop platform | UniqueOpen | Passthrough |
| TotalOpen | Silverpop platform | TotalOpen | Passthrough |
| UniqueClick | Silverpop platform | UniqueClick | Passthrough |
| TotalClick | Silverpop platform | TotalClick | Passthrough |
| Unsubscribed | Silverpop platform | Unsubscribed | Passthrough |
| ReportedAbuse | Silverpop platform | ReportedAbuse | Passthrough |
| EmailDomainID | Silverpop/domain reference | DomainID | Passthrough |
| Domain | Silverpop/domain reference | DomainName | Passthrough (de-normalized) |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Silverpop (IBM Watson Campaign Automation / IBM Marketing Cloud)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_AGGSilverpopCampaign (0 rows — EMPTY as of 2026-04-23)

Platform migrated to Optimove circa 2024:
  DWH_Migration.JUNK_Dim_SilverpopMailing (archived)
  DWH_Migration.JUNK_Dim_SilverpopSubject (archived)
  DWH_Migration.JUNK_Dim_SilverpopEventType (archived)
  DWH_Migration.JUNK_Dim_SilverToOpti_Mail_Rel (Silverpop → Optimove mailing mapping)

Silverpop ecosystem tables still in DDL:
  BI_DB_dbo.BI_DB_SilverpopCampaignDictionary (MailingID → name/segment/subject, still present)
  BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain (domain-clustered sibling aggregate)
  BI_DB_dbo.BI_DB_SilverpopLanguage (campaign language reference)

DWH-side historical Silverpop data:
  DWH.mailtracking.Fact_MailTracking (individual email events, SilverpopMailingID FK)
  DWH.mailtracking.Dim_SilverpopMailing (mailing metadata — still queryable in DWH)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| MailingID | BI_DB_SilverpopCampaignDictionary | Campaign name, number, language, segment, subject line |
| Domain aggregate | BI_DB_AGGSilverpopCampaign_ByDomain | Per-domain breakdown of same campaigns (Domain-clustered) |
| Language | BI_DB_SilverpopLanguage (via SilverpopCampaignDictionary.CampaignLanguageID) | Campaign locale |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views. `SP_CIDFirstDates_HistoricalRun` reads from `DWH.mailtracking.Fact_MailTracking` and `DWH.mailtracking.Dim_SilverpopMailing` directly, not from this aggregate table.

---

## 7. Sample Queries

### Campaign performance summary (when populated)

```sql
SELECT
    a.CampaignDate,
    a.MailingID,
    d.CampaignName,
    d.CampaignSegment,
    a.MailsSent,
    a.UniqueOpen,
    a.UniqueClick,
    CAST(a.UniqueOpen AS FLOAT) / NULLIF(a.MailsSent, 0) AS OpenRate,
    CAST(a.UniqueClick AS FLOAT) / NULLIF(a.UniqueOpen, 0) AS CTOR,
    CAST(a.HardBounce AS FLOAT) / NULLIF(a.MailsSent, 0) AS HardBounceRate
FROM [BI_DB_dbo].[BI_DB_AGGSilverpopCampaign] a
LEFT JOIN [BI_DB_dbo].[BI_DB_SilverpopCampaignDictionary] d
    ON a.MailingID = d.MailingID
ORDER BY a.CampaignDate DESC;
-- Returns 0 rows as of 2026-04-23
```

### Abuse and unsubscribe monitoring

```sql
SELECT
    CampaignDate,
    MailingID,
    MailsSent,
    Unsubscribed,
    ReportedAbuse,
    CAST(ReportedAbuse AS FLOAT) / NULLIF(MailsSent, 0) AS AbuseRate
FROM [BI_DB_dbo].[BI_DB_AGGSilverpopCampaign]
WHERE CAST(ReportedAbuse AS FLOAT) / NULLIF(MailsSent, 0) > 0.0008  -- 0.08% threshold
ORDER BY AbuseRate DESC;
```

### Check table state

```sql
SELECT
    COUNT(*) AS row_count,
    MIN(CampaignDate) AS earliest_campaign,
    MAX(CampaignDate) AS latest_campaign,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_DB_AGGSilverpopCampaign];
-- Returns 0 rows as of 2026-04-23
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. Silverpop platform was migrated to Optimove circa 2024 — no active Silverpop documentation expected.

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 5/14 (P3/P5/P6-live/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 17 T3, 0 T4, 1 T5 | Elements: 18/18 | Object: BI_DB_dbo.BI_DB_AGGSilverpopCampaign | Type: Table | Production Source: Unknown (Silverpop — decommissioned, migrated to Optimove ~2024)*
*Note: Table is currently empty (0 rows). Silverpop email marketing platform migrated to Optimove circa 2024. All DWH Silverpop dimension tables are JUNK-prefixed. Historical Silverpop data available in DWH.mailtracking.Fact_MailTracking. Quality 6.5 — penalized for empty table and no writer SP; columns well-characterized by standard email marketing domain knowledge.*
