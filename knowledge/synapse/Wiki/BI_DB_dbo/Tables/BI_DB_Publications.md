# BI_DB_dbo.BI_DB_Publications

> 266,266-row incrementally maintained copy of eToro user publication profiles (bio text, sticky posts, language) sourced from UserApiDB.dbo.Publications via an external table bridge — new CIDs are appended and AboutMe is delta-updated daily, while Sticky and LanguageCode are frozen at first-seen values.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.dbo.Publications via BI_DB_dbo.External_UserApiDB_dbo_Publications |
| **Refresh** | Daily — SP_Publications; INSERT new CIDs + UPDATE AboutMe on change; Sticky and LanguageCode NOT updated after initial insert |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

User profile publication dataset — one row per eToro customer with a publication record. The table holds the text content that customers display publicly on their eToro social profile: a bio (`AboutMe`), a pinned sticky post (`Sticky`), and the detected language of that content (`LanguageCode`).

The table was created in May 2020 and accumulates over time. The SP does not perform a full TRUNCATE+INSERT — it appends new CIDs and updates the `AboutMe` field when it detects a change. The `Sticky` and `LanguageCode` fields are written once at first-insert and are never subsequently updated.

As of 2026-04-13: 266,266 rows (customers with publication records). `AboutMe` is populated for 88.0% of rows. `Sticky` has content in only 62 rows (0.02%) — it is NULL for 82.7% and empty string for 17.3%. Language coverage: 153 distinct codes; English dominates (60.8%), followed by blank (14.9%), Spanish (6.9%), French (3.4%), Italian (2.9%).

**NOTE: `Sticky` and `LanguageCode` reflect the values at the time the customer first appeared in this table. Changes to these fields in UserApiDB will NOT be reflected here. Only `AboutMe` is kept current.**

---

## 2. Business Logic

### 2.1 Insert-Only for New CIDs

**What**: The SP identifies customers in the live source who are not yet in this table and inserts them.
**Columns Involved**: CID, all columns
**Rules**:
- Compares `External_UserApiDB_dbo_Publications` (current live state) to `BI_DB_Publications`
- LEFT JOIN ON `pu.CID = pl.CID WHERE pu.CID IS NULL` — finds new CIDs not yet present
- All 5 columns are set on INSERT: CID, Sticky, AboutMe, LanguageCode, UpdateDate=GETDATE()
- If `@newCIDbio = 0` (no new CIDs), the INSERT is skipped

### 2.2 AboutMe Delta Update

**What**: The SP updates the `AboutMe` field when it differs from the live source.
**Columns Involved**: AboutMe, UpdateDate
**Rules**:
- `WHERE p.AboutMe <> pl.AboutMe` — only updates rows where AboutMe has changed (uses string inequality, which will not catch NULL→value changes if p.AboutMe IS NULL)
- Sets `p.UpdateDate = GETDATE()` alongside the AboutMe update
- This is the only field actively maintained after initial insert

### 2.3 Frozen Fields

**What**: Sticky and LanguageCode are not maintained after the initial insert.
**Columns Involved**: Sticky, LanguageCode
**Rules**:
- No UPDATE statement references Sticky or LanguageCode
- Once inserted, these values reflect the state at time of first appearance in the table
- Customers who changed their language preference or sticky post will NOT have those changes reflected
- This is a known design limitation — the SP only tracks AboutMe changes

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID. Point-lookups by CID benefit from the clustered index. With 266K rows the table is small — full scans are fast. No partition scheme needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get bio for a customer | `SELECT * FROM [BI_DB_dbo].[BI_DB_Publications] WHERE CID = X` |
| Customers with non-English bios | `WHERE LanguageCode NOT IN ('en', '') AND LanguageCode IS NOT NULL` |
| Recently updated bios | `WHERE UpdateDate >= '2026-01-01' ORDER BY UpdateDate DESC` |
| Customers with sticky content | `WHERE Sticky IS NOT NULL AND Sticky != ''` — only 62 rows |
| Bio coverage for popular investors | `JOIN BI_DB_Publications ON CID WHERE ... — LEFT JOIN to detect missing` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Enrich bio with customer tier, country, regulation |
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | CID = RealCID | Compliance status for bio holder |

### 3.4 Gotchas

- **Sticky and LanguageCode are point-in-time, not current**: These fields reflect the production value at time of first insert only. Do NOT treat them as current values — they may be years out of date.
- **AboutMe inequality check misses NULL→value**: The SP updates when `p.AboutMe <> pl.AboutMe`. If `p.AboutMe IS NULL` and `pl.AboutMe` has a value, SQL NULL inequality returns UNKNOWN — the row is NOT updated. A customer who started with NULL AboutMe and later added a bio may not get updated until the row is re-inserted.
- **No delete handling**: If a user deletes their bio from UserApiDB, the row stays in this table indefinitely with the last known AboutMe.
- **Empty string vs NULL for Sticky**: 17.3% of rows have Sticky='' (empty string), 82.7% have Sticky=NULL. These are semantically different: NULL = never had a sticky; empty = had one that was cleared. Filter appropriately.
- **LanguageCode = empty string for 14.9% of rows**: These may be users who didn't write a bio (or wrote one in a language that wasn't detected). Not the same as NULL.
- **153 distinct LanguageCodes**: These appear to be machine-detected language codes (similar to Google language detection output — note codes like 'zh-latn', 'ar-latn', 'hi-latn' for transliterated scripts). They are NOT user-selected language preferences.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production or DWH wiki |
| Tier 2 | Description derived from SP code analysis |
| Tier 3 | Description inferred from context and data patterns |
| Tier 4 | Description is best-available estimate; low confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer identifier. Primary key for this table — one row per customer with a Publications record. Source: UserApiDB.dbo.Publications.CID. Only new CIDs are inserted; existing CIDs are never re-inserted. (Tier 2 — SP_Publications via External_UserApiDB_dbo_Publications) |
| 2 | Sticky | nvarchar(1000) | YES | Pinned publication text shown at the top of the customer's social feed. Source: UserApiDB.dbo.Publications.Sticky. Set once at INSERT — never updated by the SP. 82.7% NULL, 17.3% empty string, 62 rows have content (0.02%). Semantics: NULL = no Publications row existed with sticky content at time of first insert; empty string = sticky was explicitly blank. (Tier 3 — inferred from SP code and data patterns) |
| 3 | AboutMe | nvarchar(1000) | YES | Customer biography text displayed on their public eToro profile. Source: UserApiDB.dbo.Publications.AboutMe. The only field actively maintained — SP updates this when it differs from the live source. 88.0% of rows have a non-null value. Note: NULL→non-NULL transitions may be missed by the SP's inequality check (see Gotchas). (Tier 3 — inferred from SP code and data patterns) |
| 4 | LanguageCode | varchar(50) | YES | Language code detected for the customer's bio/publications content. 153 distinct values. Set at INSERT only — not updated if the user changes language or rewrites their bio. Dominant values: 'en' (60.8%), empty string (14.9%), 'es' (6.9%), 'fr' (3.4%), 'it' (2.9%), 'de' (2.8%), others. Appears to be machine-detected (values include transliterated codes: 'ar-latn', 'zh-latn', 'hi-latn'). (Tier 3 — inferred from data patterns) |
| 5 | UpdateDate | datetime | YES | Timestamp of the most recent SP operation for this row: GETDATE() at INSERT for new CIDs, or GETDATE() at UPDATE when AboutMe changed. Range: 2020-05-17 to 2026-04-13. Rows with old UpdateDates have had an unchanged AboutMe since that date. (Tier 2 — SP_Publications) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | UserApiDB.dbo.Publications | CID | Direct — INSERT new only |
| Sticky | UserApiDB.dbo.Publications | Sticky | Direct — set at INSERT; frozen thereafter |
| AboutMe | UserApiDB.dbo.Publications | AboutMe | Direct — INSERT + delta UPDATE when changed |
| LanguageCode | UserApiDB.dbo.Publications | LanguageCode | Direct — set at INSERT; frozen thereafter |
| UpdateDate | SP-computed | GETDATE() | Timestamp of INSERT or last AboutMe update |

### 5.2 ETL Pipeline

```
UserApiDB.dbo.Publications (production — user profile bio and sticky content)
  |-- Generic Pipeline (Bronze export to lake) ---|
  v
BI_DB_dbo.External_UserApiDB_dbo_Publications (external table — lake bridge)
  |-- SP_Publications (daily, no parameters) ---|
  |   Step 1: #Publications_live = current live state (CCI temp table)  |
  |   Step 2: #newCIDbio = new CIDs not yet in BI_DB_Publications        |
  |   Step 3: IF @newCIDbio > 0 — INSERT new rows with all 5 columns     |
  |   Step 4: UPDATE AboutMe + UpdateDate WHERE value differs            |
  v
BI_DB_dbo.BI_DB_Publications (266,266 rows, accumulating since 2020-05-17)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile and account details |
| (sourced from) | BI_DB_dbo.External_UserApiDB_dbo_Publications | Live lake bridge for UserApiDB.dbo.Publications |

### 6.2 Referenced By

No downstream consumers found in SSDT repo. This is an analytics enrichment leaf table used for social/bio analytics.

---

## 7. Sample Queries

### Customers with Bio by Language

```sql
SELECT
    LanguageCode,
    COUNT(*) AS CustomerCount,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Pct
FROM [BI_DB_dbo].[BI_DB_Publications]
WHERE LanguageCode IS NOT NULL AND LanguageCode != ''
GROUP BY LanguageCode
ORDER BY CustomerCount DESC;
```

### Recently Updated Bios (last 30 days)

```sql
SELECT TOP 100
    CID,
    LanguageCode,
    LEFT(AboutMe, 100) AS BioPeek,
    UpdateDate
FROM [BI_DB_dbo].[BI_DB_Publications]
WHERE UpdateDate >= DATEADD(day, -30, GETDATE())
    AND AboutMe IS NOT NULL
ORDER BY UpdateDate DESC;
```

### Bio Coverage for a Customer List

```sql
SELECT
    dc.RealCID,
    CASE WHEN pub.CID IS NOT NULL THEN 1 ELSE 0 END AS HasBio,
    pub.LanguageCode,
    LEFT(pub.AboutMe, 50) AS BioSnippet
FROM [DWH_dbo].[Dim_Customer] dc
LEFT JOIN [BI_DB_dbo].[BI_DB_Publications] pub ON dc.RealCID = pub.CID
WHERE dc.RegulationID = 7  -- CySEC example
    AND dc.PlayerLevelID = 4;  -- Popular Investors
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. User bio content context may exist under Product or Social features spaces in Confluence (not queried).

---

*Generated: 2026-04-22 | Quality: 7.8/10 | Phases: 13/14*
*Tiers: 0 T1, 2 T2, 3 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_Publications | Type: Table | Production Source: UserApiDB.dbo.Publications via External_UserApiDB_dbo_Publications*
