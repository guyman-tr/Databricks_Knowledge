# AffiliateCommission.RegistrationMetaData

> Temporal table storing full affiliate attribution context for each registered customer, with system versioning to track changes over time as re-attribution events occur.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CID + PartitionCol (composite PK CLUSTERED) |
| **Partition** | Yes - PS_Mod50 on PartitionCol (CID % 50) |
| **Indexes** | 4 active (PK clustered + 3 NC including unique) |

---

## 1. Business Meaning

RegistrationMetaData is the definitive source of affiliate attribution for each registered customer. While the Registration table tracks the registration event and commission pipeline state, RegistrationMetaData stores WHO referred the customer - the full affiliate attribution context including AffiliateID, campaign, banner, download tracking, funnel, and player level.

This table is critical because affiliate attribution can change after initial registration. A customer may be re-attributed from one affiliate to another (e.g., due to attribution disputes, fraud discovery, or campaign corrections). System versioning (SYSTEM_VERSIONING with History.RegistrationMetaData) maintains a complete audit trail of all attribution changes, ensuring that commission adjustments can be traced back to the exact moment an attribution changed.

The table holds 18.8 million rows (one per customer), making it the largest table in the schema. It is partitioned on PS_Mod50 (CID % 50) for performance. The computed Trace column captures execution context (hostname, app name, user, SPID, procedure name) for each write operation, providing forensic traceability. The AdditionalData column (added later) supports extensible metadata without schema changes.

---

## 2. Business Logic

### 2.1 Attribution Change Tracking

**What**: System versioning tracks every change to a customer's affiliate attribution.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `AffiliateID`, `AffiliateCampaign`

**Rules**:
- Every UPDATE to a row generates a history record in History.RegistrationMetaData
- ValidFrom = when the current attribution became effective
- ValidTo = when it was superseded (9999-12-31 for current row)
- Re-attribution scenarios: organic-to-affiliate, affiliate-to-affiliate, fraud correction
- The Trace column identifies WHO made each change (hostname, app, user, procedure)

### 2.2 Execution Context Tracing

**What**: Every write operation is automatically traced via a computed column.

**Columns/Parameters Involved**: `Trace` (computed)

**Rules**:
- Formula: concat of host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid)
- Captures: which server, which application, which user, which session, which database, which procedure
- NOT PERSISTED - computed at read time, reflecting values at write time via system versioning
- Essential for investigating attribution disputes

---

## 3. Data Overview

| CID | GCID | AffiliateID | AffiliateCampaign | BannerID | CountryID | FunnelID | PlayerLevelID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 999164968 | 6971994 | 2 | 166065028109995... | 13972 | 74 | 36 | 1 | High-CID customer (possibly test). Affiliate 2 with a long campaign tracking string. Country 74, Funnel 36, active banner tracking. |
| 25707174 | 28233312 | 3 | (empty) | 0 | 196 | NULL | 1 | Recent customer. Affiliate 3 with no campaign string. No banner/funnel tracking - organic or direct affiliate link. |
| 25707172 | 28233310 | 3 | (empty) | 0 | 196 | NULL | 1 | Similar pattern - Affiliate 3, country 196, minimal tracking data. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer ID. First column of composite PK. One row per customer. |
| 2 | PartitionCol | computed (int) | NO | CID % 50, PERSISTED | CODE-BACKED | Computed partition column. Formula: CID modulo 50. Distributes data across 50 partitions on PS_Mod50. Second column of composite PK. |
| 3 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Cross-provider customer identifier. Unique index on (GCID, CID, PartitionCol) ensures 1:1 mapping. |
| 4 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate attributed with this customer's registration. Can change via re-attribution (tracked by system versioning). Indexed for affiliate-based lookups. |
| 5 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | Campaign tracking string from the affiliate link. May contain encoded tracking parameters. Empty string when no campaign context was captured. NOT NULL (uses empty string instead of NULL). |
| 6 | BannerID | int | NO | - | CODE-BACKED | Banner that led to the registration. 0 = no banner tracked. References the banner/creative system. |
| 7 | DownloadID | bigint | NO | - | CODE-BACKED | Download/app install tracking ID. 0 = no download tracked. Links to app installation events. |
| 8 | CountryID | bigint | NO | - | CODE-BACKED | Customer's registration country. May differ from country in Registration table if attribution changes include country correction. |
| 9 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier. NULL when funnel tracking is not applicable or not configured for the affiliate. |
| 10 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level classification at registration time. 1 = standard new player. May be updated as player progresses. |
| 11 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer in sub-account/copy-trade scenarios. For standard registrations, equals CID or another reference. |
| 12 | Trace | computed (nvarchar) | - | concat(...) | CODE-BACKED | Computed execution context. NOT PERSISTED. Captures hostname, app name, SQL user, SPID, database name, and calling procedure name. Provides forensic trail for attribution changes. |
| 13 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | System versioning start time. When this version of the row became effective. Automatically set by SQL Server temporal tables. |
| 14 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | System versioning end time. When this version was superseded. 9999-12-31 for the current row. History rows have the actual end time. |
| 15 | AdditionalData | varchar(512) | NO | '' (empty string) | CODE-BACKED | Extensible metadata field. Defaults to empty string. Allows additional attribution data without schema changes. |
| 16 | EtoroUserName | varchar(50) | YES | - | CODE-BACKED | eToro username of the registered customer. Allows quick human-readable identification alongside the numeric CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the referring affiliate |
| CID | External customer system | Implicit | Customer identity |
| GCID | External global customer system | Implicit | Global customer identity |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.InsertRegistrationMetaData | INSERT | Writer | Creates metadata during registration |
| AffiliateCommission.UpdateMetaData | UPDATE | Modifier | Updates attribution (triggers history) |
| AffiliateCommission.GetMetaDataByCID | SELECT | Reader | Retrieves by CID |
| AffiliateCommission.GetMetaDataByGCID | SELECT | Reader | Retrieves by GCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.InsertRegistrationMetaData | Stored Procedure | Writer |
| AffiliateCommission.UpdateMetaData | Stored Procedure | Modifier (re-attribution) |
| AffiliateCommission.GetMetaDataByCID | Stored Procedure | Reader |
| AffiliateCommission.GetMetaDataByGCID | Stored Procedure | Reader |
| History.RegistrationMetaData | History Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegistrationMetaData_CID | CLUSTERED PK | CID, PartitionCol | - | - | Active (PS_Mod50) |
| IX_RegistrationMetaData_AffiliateID | NC | AffiliateID | AffiliateCampaign, OriginalCID | - | Active (PAGE compression) |
| IX_RegistrationMetaData_ValidFrom | NC | CID | ValidFrom | - | Active (PAGE compression) |
| UIX_RegistrationMetaData_GCIDCID | UNIQUE NC | GCID, CID, PartitionCol | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RegistrationMetaData_CID | PRIMARY KEY | Composite on CID + PartitionCol, partitioned |
| DF_RegistrationMetaData_AdditionalData | DEFAULT | '' - empty string for extensible metadata |
| SYSTEM_VERSIONING | Temporal | HISTORY_TABLE = History.RegistrationMetaData |
| PERIOD FOR SYSTEM_TIME | Temporal | ValidFrom to ValidTo |

---

## 8. Sample Queries

### 8.1 Look up customer attribution
```sql
SELECT CID, GCID, AffiliateID, AffiliateCampaign, BannerID,
       CountryID, FunnelID, PlayerLevelID, EtoroUserName
FROM AffiliateCommission.RegistrationMetaData WITH (NOLOCK)
WHERE CID = 25707172;
```

### 8.2 View attribution change history for a customer
```sql
SELECT CID, AffiliateID, AffiliateCampaign, ValidFrom, ValidTo
FROM AffiliateCommission.RegistrationMetaData
FOR SYSTEM_TIME ALL
WHERE CID = 25707172
ORDER BY ValidFrom;
```

### 8.3 Find recently re-attributed customers
```sql
SELECT rm.CID, rm.GCID, rm.AffiliateID, rm.ValidFrom,
       h.AffiliateID AS PreviousAffiliateID, h.ValidFrom AS PreviousFrom
FROM AffiliateCommission.RegistrationMetaData rm WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 AffiliateID, ValidFrom
    FROM History.RegistrationMetaData h
    WHERE h.CID = rm.CID
    ORDER BY h.ValidTo DESC
) h
WHERE rm.ValidFrom >= DATEADD(day, -7, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationMetaData | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.RegistrationMetaData.sql*
