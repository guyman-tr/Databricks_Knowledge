# BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet

> Google Sheet staging table for AML daily alerts — a direct import of the AML team's Google Sheet (colloquially "oglesheet" = Googlesheet) into Synapse. Contains the same alert fields as `BI_DB_AML_Daily_Alerts` but with bounded nvarchar column widths (256/512/2048 instead of max) and a **known DDL typo**: column 2 is named `AlertCatery` instead of `AlertCategory`. Currently **empty (0 rows as of 2026-04-23)** but was active through at least November 2024. This table is the staging layer in the pipeline: Google Sheet → this table → `BI_DB_AML_Daily_Alerts` (main) → `_History` (archive). Distribution: ROUND_ROBIN, CLUSTERED on AlertDate.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — Google Sheet staging for AML daily alerts |
| **Production Source** | Google Sheet maintained by AML compliance analysts |
| **Refresh** | Unknown — table currently empty; was active through Nov 2024 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (AlertDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23; backup from 2024-11-17 confirms historical data existed) |
| **Related Tables** | BI_DB_AML_Daily_Alerts (downstream main table), BI_DB_AML_Daily_Alerts_History (archive), DWH_dbo.Dim_PlayerStatus (PlayerStatus lookup) |
| **Critical Note** | Column `AlertCatery` (col 2) is a DDL typo for `AlertCategory` — all queries must use `AlertCatery` |

---

## 1. Business Meaning

`BI_DB_AML_Daily_Alerts_From_oglesheet` is the **Google Sheet import staging table** for AML daily alert data. AML compliance analysts maintain a Google Sheet containing daily AML alerts — the sheet captures the same alert information as the main `BI_DB_AML_Daily_Alerts` table, organized by alert type, customer, status, and assigned analyst.

The table serves as the first landing zone in the AML alert ETL pipeline:

```
AML monitoring system → Google Sheet (AML team augments/reviews)
  → BI_DB_AML_Daily_Alerts_From_oglesheet  ← THIS TABLE (staging)
  → BI_DB_AML_Daily_Alerts (main reporting table, nvarchar(max))
  → BI_DB_AML_Daily_Alerts_History (archive)
```

**"oglesheet" naming**: This is an informal abbreviation of "Googlesheet" used in the BI_DB_dbo naming convention. The bounded nvarchar column widths (256 for most fields, 2048 for AlertDetails, 512 for PreviousStatus) are consistent with Google Sheets' default cell character constraints.

**Column `AlertCatery` typo**: Column 2 is named `AlertCatery` in the DDL — a typo for `AlertCategory`. This typo has been present since at least November 2024 (confirmed in backup DDL) and has never been corrected. Any query against this table **must use `AlertCatery`** (not `AlertCategory`). The AlertCategory equivalent in the main table (`BI_DB_AML_Daily_Alerts`) is correctly named and is the last column (col 16).

**Current status**: Empty (0 rows as of 2026-04-23). The backup created 2024-11-17 confirms the table was actively used through at least that date. The pipeline appears to be decommissioned or paused.

---

## 2. Business Logic

### 2.1 Staging Role in the AML Alert Pipeline

**What**: This table receives raw Google Sheet data before it is transferred to the main reporting table.
**Columns Involved**: All 16 columns
**Rules**:
- AML analysts fill in or confirm alert fields in the Google Sheet
- An external script (Python/PowerShell/Fivetran or similar) pushes the Google Sheet rows directly to this staging table
- A subsequent ETL step transfers data from this table to `BI_DB_AML_Daily_Alerts`, widening nvarchar bounds from (256/512/2048) to nvarchar(max)
- `UpdateDate` reflects when the Google Sheet push occurred, not when the analyst last updated the Sheet
- All columns are nullable — Google Sheet rows may have incomplete data

### 2.2 Column Width Constraints vs Main Table

**What**: Column widths are bounded here; the main table uses nvarchar(max).
**Columns Involved**: All nvarchar columns
**Rules**:
- Most fields: nvarchar(256) — sufficient for short identifiers, names, statuses, codes
- `AlertDetails`: nvarchar(2048) — longer free-text allowed
- `PreviousStatus`: nvarchar(512) — intermediate length
- Any Google Sheet cell content exceeding these bounds will be **truncated silently** on import
- If `AlertDetails` in the Google Sheet exceeds 2048 characters, the overflow is lost at this staging layer

### 2.3 AlertCatery — The Permanent Typo

**What**: `AlertCatery` (col 2) is the DDL typo for `AlertCategory`.
**Columns Involved**: AlertCatery
**Rules**:
- The Google Sheet column this maps to is presumably named `AlertCategory` (or `Alert Category`) — the typo occurred when the table was created
- In the main table (`BI_DB_AML_Daily_Alerts`), the equivalent column is `AlertCategory` (correctly named, col 16)
- The typo means `AlertCatery` and `AlertCategory` in main table are the **same concept, different names** — any ETL or JOIN logic must account for this mapping
- The typo has existed since at least Nov 2024 — renaming would require recreating or altering the table and updating all dependent ETL scripts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on AlertDate. Same distribution as the main table. As a staging table, this is typically queried only by the ETL pipeline that loads `BI_DB_AML_Daily_Alerts`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What's in the staging table (before ETL)? | `SELECT TOP 100 * FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_From_oglesheet] ORDER BY AlertDate DESC` |
| Does staging have rows not yet in main? | `SELECT s.* FROM [BI_DB_AML_Daily_Alerts_From_oglesheet] s LEFT JOIN [BI_DB_AML_Daily_Alerts] m ON s.AlertID = m.AlertID WHERE m.AlertID IS NULL` |
| Alert categories in staging? | `SELECT AlertCatery, COUNT(*) FROM [BI_DB_AML_Daily_Alerts_From_oglesheet] GROUP BY AlertCatery` — note: use `AlertCatery`, NOT `AlertCategory` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Daily_Alerts | `ON AlertID = m.AlertID` | Identify staging rows not yet transferred to main |
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Add current customer profile |

### 3.4 Gotchas

- **`AlertCatery` is a typo**: Use `AlertCatery` not `AlertCategory` — this column does not exist in this table. All references must use the misspelled name.
- **Table is empty**: 0 rows as of 2026-04-23 — no current staging data.
- **Column widths are bounded**: `AlertDetails` truncates at 2048 chars; all other nvarchar fields at 256. Silent truncation may occur at import time.
- **This is staging**: Do not use for end-user reporting — use `BI_DB_AML_Daily_Alerts` (main) instead. Staging data may be incomplete or unvalidated.
- **Column ordering differs from main table**: `AlertCatery` (category equivalent) is col 2 here vs `AlertCategory` as col 16 in the main table. Column position-based queries will misalign.
- **RelatedAccounts max 256 chars**: Comma-separated related CIDs may be truncated if the list is long.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from writer SP code (source-to-target mapping) |
| Tier 3 | Inferred from DDL, column name patterns, live Dim table data, or sibling table docs |
| Tier 4 | Best-guess — no definitive source found |
| Tier 5 | Propagation constant (ETL metadata — UpdateDate) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AlertID | nvarchar(256) | NULL | Unique identifier for the AML alert from the upstream AML monitoring system. (Tier 4 — Google Sheet / external AML tool) |
| 2 | AlertCatery | nvarchar(256) | NULL | **DDL typo for AlertCategory** — higher-level category grouping for the alert (e.g., 'Screening', 'Transaction Monitoring'). Column name has been `AlertCatery` since at least Nov 2024. Maps to `AlertCategory` in `BI_DB_AML_Daily_Alerts`. (Tier 4 — Google Sheet) |
| 3 | AlertType | nvarchar(256) | NULL | Specific alert type/rule that triggered the alert (e.g., 'Sanctions Hit', 'PEP Match', 'Unusual Transaction'). Narrower than AlertCatery. (Tier 4 — Google Sheet / external AML tool) |
| 4 | CID | int | NULL | Customer ID of the alerted customer. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 4 — Google Sheet) |
| 5 | Name | nvarchar(256) | NULL | Customer full name — pre-populated from AML tool or Dim_Customer at alert generation time. Denormalized snapshot. (Tier 3 — Dim_Customer) |
| 6 | Country | nvarchar(256) | NULL | Customer's country at alert time — denormalized snapshot. (Tier 3 — Dim_Customer) |
| 7 | AccountType | nvarchar(256) | NULL | Customer account type (e.g., 'Retail', 'Corporate') — denormalized snapshot. (Tier 3 — Dim_Customer) |
| 8 | AlertDate | datetime | NULL | Date and time the AML alert was generated. Cluster key. (Tier 4 — Google Sheet / external AML tool) |
| 9 | Regulation | nvarchar(256) | NULL | Regulatory jurisdiction of the customer (e.g., 'FCA', 'CySEC') — denormalized snapshot. (Tier 3 — Dim_Customer) |
| 10 | RelatedAccounts | nvarchar(256) | NULL | Other CIDs related to this alert — free-text (likely comma-separated). **Truncated to 256 chars** at import; may lose CIDs if the related account list is long. (Tier 4 — Google Sheet) |
| 11 | PlayerStatus | nvarchar(256) | NULL | Customer's PlayerStatus at alert time — stored as name string (e.g., 'Normal', 'Blocked'). Not an integer ID. (Tier 3 — Dim_PlayerStatus) |
| 12 | AlertStatus | nvarchar(256) | NULL | Alert investigation lifecycle status (e.g., 'Open', 'In Review', 'Closed') — entered/updated by AML analyst in the Google Sheet. (Tier 4 — Google Sheet) |
| 13 | Assigned | nvarchar(256) | NULL | AML analyst name assigned to investigate this alert. Free-text name — no FK to personnel table. (Tier 4 — Google Sheet) |
| 14 | AlertDetails | nvarchar(2048) | NULL | Free-text description of why the alert was triggered. **Truncated to 2048 chars** at import (vs nvarchar(max) in main table). (Tier 4 — Google Sheet / AML tool) |
| 15 | PreviousStatus | nvarchar(512) | NULL | Customer's PlayerStatus before any action taken as a result of this alert — stored as name string. **Truncated to 512 chars**. (Tier 3 — Dim_PlayerStatus) |
| 16 | UpdateDate | datetime | NULL | ETL metadata: timestamp when Google Sheet data was pushed to this staging table. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AlertID, AlertType | External AML monitoring tool → Google Sheet | Alert identifier, type | Passthrough from AML system via Sheet |
| AlertCatery | Google Sheet | AlertCategory column (typo in DDL) | Passthrough — column name has typo `AlertCatery` |
| CID, AlertDate, RelatedAccounts | Google Sheet | CID, AlertDate, RelatedAccounts | Passthrough; RelatedAccounts truncated at 256 chars |
| Name, Country, AccountType, Regulation | Dim_Customer (pre-populated in Sheet) | FullName, Country, AccountType, Regulation | Denormalized snapshot; nvarchar(256) truncation |
| PlayerStatus, PreviousStatus | Dim_PlayerStatus (pre-populated in Sheet) | PlayerStatusName | Denormalized name string; PreviousStatus truncated at 512 chars |
| AlertStatus, Assigned, AlertDetails | Google Sheet (analyst-entered) | Manual entry | Passthrough; AlertDetails truncated at 2048 chars |
| UpdateDate | ETL metadata | GETDATE() | Google Sheet push timestamp |

### 5.2 ETL Pipeline

```
AML monitoring system
  |-- Alert export to Google Sheet ---|
  v
Google Sheet (AML compliance team maintains alert list, assigns analysts, updates statuses)
  |-- External import script (Python / PowerShell / Fivetran) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet (THIS TABLE — staging, bounded nvarchar, AlertCatery typo)
  |-- ETL transfer (widen nvarchar to max, rename no columns) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts (main reporting table, nvarchar(max), AlertCategory col 16)
  |-- Archive step ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_History
  |-- No UC Gold target ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity reference |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status name lookup (stored as string) |
| PreviousStatus | DWH_dbo.Dim_PlayerStatus | Prior status name lookup (stored as string) |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_AML_Daily_Alerts | Downstream target — staging data is transferred here |

---

## 7. Sample Queries

### Check staging contents vs main table (reconciliation)

```sql
-- Rows in staging not yet in main table
SELECT s.*
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_From_oglesheet] s
LEFT JOIN [BI_DB_dbo].[BI_DB_AML_Daily_Alerts] m 
    ON s.AlertID = m.AlertID
WHERE m.AlertID IS NULL
ORDER BY s.AlertDate DESC;
```

### Alert category breakdown in staging (using correct typo column name)

```sql
SELECT 
    AlertCatery,   -- NOTE: typo for AlertCategory — do NOT use AlertCategory
    AlertType,
    COUNT(*) AS AlertCount
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_From_oglesheet]
GROUP BY AlertCatery, AlertType
ORDER BY AlertCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. AML Google Sheet integration documentation, if available, would reside in the AML/Compliance team's operational runbooks or the data engineering team's integration documentation.

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 5 T3, 10 T4, 1 T5 | Elements: 16/16, Logic: 7/10, Data Evidence: 1/10*
*Object: BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet | Type: Table | Production Source: Google Sheet (AML analysts)*
