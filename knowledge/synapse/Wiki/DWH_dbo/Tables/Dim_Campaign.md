# DWH_dbo.Dim_Campaign

> **DEAD TABLE** - Marketing campaign dimension. Schema and ID=0 placeholder are maintained by SP_Dictionaries_DL_To_Synapse but the full data load (INSERT) is commented out. Contains exactly 1 row (CampaignID=0, Code='N/A'). Production BackOffice.Campaign has 11,080 rows but none are loaded into DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.BackOffice.Campaign (INTENDED - ETL INSERT commented out) |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + ID=0 placeholder only) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_Campaign was designed to be the DWH version of etoro.BackOffice.Campaign -- a marketing bonus campaign registry defining time-bounded promotional campaigns with user caps and bonus pools. Each campaign has a unique Code (the public-facing identifier customers enter at registration), linked BonusTypes, start/end dates, and a MaxBonusAmount cap.

**DEAD TABLE STATUS**: The INSERT statement in SP_Dictionaries_DL_To_Synapse is entirely commented out (lines 1093-1118). The SP daily runs `TRUNCATE TABLE Dim_Campaign` followed by an active INSERT of only the ID=0 placeholder row. No actual campaign data is loaded. The table always contains exactly 1 row.

The production BackOffice.Campaign has 11,080 campaigns (no new campaigns since May 2017 -- the system appears frozen or superseded by an external campaign management system). None of these are accessible in DWH.

Two columns have Dynamic Data Masking applied in the DWH DDL:
- `ParticipatedUsers`: `MASKED WITH (FUNCTION = 'default()')` - returns 0 for non-privileged users
- `Description`: `MASKED WITH (FUNCTION = 'default()')` - returns NULL for non-privileged users

The DWH table covers only 10 of 16 production columns (excluded: StartJobID, EndJobID, ExtendedCampaignProperties, CreatedOn, CreatedBy, CurrentBonusAmount).

---

## 2. Business Logic (Intended Design)

The following describes what this table was designed to support, based on the upstream wiki. **None of this data is currently available in DWH.**

### 2.1 Campaign Lifecycle (Production Context)

**What**: Campaigns are time-bounded promotional programs granting bonus credits to customers who register with the campaign Code.

**Columns Involved**: `CampaignID`, `Code`, `MaxNumberOfUsers`, `StartDate`, `EndDate`, `MaxBonusAmount`, `IsActive`, `ParticipatedUsers`

**Rules (Production)**:
- Code is the public-facing identifier (e.g., "20coupon", "freecopyref") customers enter at registration
- MaxNumberOfUsers cap: when ParticipatedUsers reaches this value, the campaign is full
- IsActive: 1=active/accepting users, 0=inactive. NOT auto-set to 0 when EndDate passes
- MaxBonusAmount: total bonus pool in dollars (stored as money type)
- StartDate/EndDate: campaign validity window (UTC)

### 2.2 Current DWH State

- 1 row only: CampaignID=0, Code='N/A', all dates='1900-01-01', all numeric values=0
- This row exists for JOIN safety in fact tables (NULL-safe foreign key pattern)
- InsertDate and UpdateDate use @ddate (date-only, midnight) rather than GETDATE() (the timestamp convention for most other DWH dimension placeholders)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a HEAP index. Both are appropriate given the table is effectively a 1-row stub.

### 3.2 Gotchas

- **DO NOT USE FOR CAMPAIGN ANALYSIS**: This table has only the ID=0 placeholder. All 11,080 actual campaigns are missing. Any JOIN to this table will result in only the N/A row matching (or NULLs on LEFT JOIN).
- **INSERT commented out**: The data load was disabled at some point (reason unknown - possibly due to PII in ParticipatedUsers/Description columns, or the campaign system being superseded). Re-enabling requires un-commenting lines 1093-1118 in SP_Dictionaries_DL_To_Synapse.
- **MASKED columns**: ParticipatedUsers and Description have Dynamic Data Masking. Even if data were loaded, non-privileged users would see 0 and NULL respectively.
- **MaxBonusAmount input vs stored**: In production, CampaignAdd receives MaxBonusAmount in cents and stores as dollars. The DWH intended to SELECT directly from staging (already in dollars from the source DB), so no conversion needed in the ETL.
- **@ddate for placeholder dates**: InsertDate/UpdateDate on the ID=0 row are set to `CAST(GETDATE() AS DATE)` (midnight UTC), not GETDATE() with time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

**Note**: All Tier 1 descriptions are based on the intended design from the upstream wiki. The actual DWH table has only the ID=0 placeholder row -- no live data for these columns exists.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CampaignID | int | NOT NULL | Primary key. Auto-incrementing campaign identifier in production. PK NOT ENFORCED in DWH. Currently only ID=0 (N/A placeholder) exists. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 2 | CampaignGroupID | int | YES | Campaign group for organization/reporting. FK to BackOffice.CampaignGroup in production. NULL for 30.5% of production campaigns (ungrouped). (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 3 | Code | varchar(15) | NOT NULL | Unique public-facing campaign code (e.g., "20coupon", "freecopyref"). The identifier customers enter at registration. UNIQUE in production. Currently only 'N/A' (ID=0 placeholder). (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 4 | MaxNumberOfUsers | int | NOT NULL | Maximum number of customers who can use this campaign. Range in production: 0 to 100,000,000. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 5 | StartDate | datetime | NOT NULL | Campaign activation datetime (UTC). '1900-01-01' in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 6 | EndDate | datetime | NOT NULL | Campaign expiry datetime (UTC). Must be after StartDate. IsActive is NOT auto-set to 0 when EndDate passes in production. '1900-01-01' in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 7 | MaxBonusAmount | money | NOT NULL | Maximum total bonus pool in dollars. Range in production: $0 to $15,000,000. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 8 | IsActive | bit | NOT NULL | Whether campaign is active. 1=active, 0=inactive. False in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 9 | ParticipatedUsers | int | YES | Count of customers who used this campaign. MASKED WITH default() - non-privileged users see 0. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 10 | Description | varchar(255) | YES | Human-readable campaign description. MASKED WITH default() - non-privileged users see NULL. NULL in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign) |
| 11 | InsertDate | datetime | NOT NULL | ETL load date. For ID=0 placeholder: set to @ddate (CAST(GETDATE() AS DATE) = midnight). Would be GETDATE() for live rows if INSERT were active. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 12 | UpdateDate | datetime | YES | ETL load date. For ID=0 placeholder: set to @ddate (CAST(GETDATE() AS DATE) = midnight). Would be GETDATE() for live rows if INSERT were active. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform | Status |
|---------------|-------------------|---------------|-----------|--------|
| CampaignID | etoro.BackOffice.Campaign | CampaignID | Passthrough | LOAD DISABLED |
| CampaignGroupID | etoro.BackOffice.Campaign | CampaignGroupID | Passthrough | LOAD DISABLED |
| Code | etoro.BackOffice.Campaign | Code | Passthrough | LOAD DISABLED |
| MaxNumberOfUsers | etoro.BackOffice.Campaign | MaxNumberOfUsers | Passthrough | LOAD DISABLED |
| StartDate | etoro.BackOffice.Campaign | StartDate | Passthrough | LOAD DISABLED |
| EndDate | etoro.BackOffice.Campaign | EndDate | Passthrough | LOAD DISABLED |
| MaxBonusAmount | etoro.BackOffice.Campaign | MaxBonusAmount | Passthrough | LOAD DISABLED |
| IsActive | etoro.BackOffice.Campaign | IsActive | Passthrough | LOAD DISABLED |
| ParticipatedUsers | etoro.BackOffice.Campaign | ParticipatedUsers | Passthrough | LOAD DISABLED |
| Description | etoro.BackOffice.Campaign | Description | Passthrough | LOAD DISABLED |
| InsertDate | - | - | ETL-computed: @ddate for placeholder; GETDATE() if INSERT active | ID=0 placeholder only |
| UpdateDate | - | - | ETL-computed: @ddate for placeholder; GETDATE() if INSERT active | ID=0 placeholder only |
| *(not in DWH)* | etoro.BackOffice.Campaign | StartJobID | Excluded | SQL Agent job ID - not loaded |
| *(not in DWH)* | etoro.BackOffice.Campaign | EndJobID | Excluded | SQL Agent job ID - not loaded |
| *(not in DWH)* | etoro.BackOffice.Campaign | ExtendedCampaignProperties | Excluded | XML configuration - not loaded |
| *(not in DWH)* | etoro.BackOffice.Campaign | CreatedOn | Excluded | Not loaded |
| *(not in DWH)* | etoro.BackOffice.Campaign | CreatedBy | Excluded | Not loaded |
| *(not in DWH)* | etoro.BackOffice.Campaign | CurrentBonusAmount | Excluded | Always NULL in production anyway |

### 5.2 ETL Pipeline

```
etoro.BackOffice.Campaign -> [NOT LOADED] -> DWH_dbo.Dim_Campaign (ID=0 placeholder only)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.BackOffice.Campaign | 11,080-row campaign catalog (etoroDB-REAL) |
| Lake | Bronze/etoro/BackOffice/Campaign/ | Daily full export exists (staging is populated) |
| Staging | DWH_staging.etoro_BackOffice_Campaign | Raw staging import (data exists) |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE; INSERT COMMENTED OUT; only ID=0 placeholder inserted using @ddate |
| Target | DWH_dbo.Dim_Campaign | 1 row (ID=0 placeholder only) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CampaignID (intended) | etoro.BackOffice.Campaign | Production source -- data not loaded |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact tables referencing CampaignID | CampaignID | JOIN safety for NULL-safe lookups (only ID=0 matches currently) |

---

## 7. Sample Queries

### 7.1 Verify dead table status

```sql
SELECT COUNT(*) AS RowCount, MAX(UpdateDate) AS LastLoad
FROM [DWH_dbo].[Dim_Campaign]
-- Returns: 1 row, UpdateDate = today at midnight (from @ddate variable)
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 7.0/10 (4 stars design, dead table) | Phases: 8/14 (P3/P5/P6/P9B/P10 skipped)*
*Tiers: 10 T1 (design intent), 2 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 8.0/10, Logic: 6.0/10, Relationships: 4.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_Campaign | Type: Table | Production Source: etoro.BackOffice.Campaign (DEAD - INSERT disabled)*
