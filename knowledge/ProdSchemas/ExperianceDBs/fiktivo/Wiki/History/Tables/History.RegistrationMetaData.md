# History.RegistrationMetaData

> SQL Server temporal history table storing all historical versions of customer registration attribution metadata.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | CID (bigint) - customer ID identifying the registration record across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.RegistrationMetaData is the system-versioned temporal history table for AffiliateCommission.RegistrationMetaData. It captures every historical version of customer registration attribution data - the metadata that records how a registered customer was attributed to a specific affiliate, campaign, banner, and acquisition channel. Each row represents one point-in-time snapshot of a customer's attribution state, including which affiliate gets credit, through which campaign and banner, from which country, and via which funnel.

This is the largest History table in the schema with 1,834,748 rows, reflecting the high frequency of customer re-attribution and data corrections. Customer attribution changes occur when tracking corrections are applied, when customers are re-attributed between affiliates due to dispute resolution, when account merges consolidate multiple CIDs, or when campaign/banner metadata is corrected retroactively. The complete audit trail is essential for commission calculations, dispute resolution, and regulatory reporting.

Data flows in automatically via SQL Server's temporal mechanism whenever rows in the base table AffiliateCommission.RegistrationMetaData are updated or deleted. The volume of historical data (1.8M rows) reflects the business reality that attribution is frequently revised. CID is the customer ID from eToro, GCID is the global customer ID used across platforms, and OriginalCID preserves the customer's original ID before any account merges.

---

## 2. Business Logic

### 2.1 Customer Attribution Versioning

**What**: Tracks all changes to the attribution of registered customers to affiliates, campaigns, banners, and acquisition channels over time.

**Columns/Parameters Involved**: `CID`, `GCID`, `OriginalCID`, `AffiliateID`, `AffiliateCampaign`, `BannerID`, `DownloadID`, `CountryID`, `FunnelID`, `PlayerLevelID`, `ValidFrom`, `ValidTo`

**Rules**:
- CID is the customer ID from eToro; GCID is the global customer ID used across platforms
- OriginalCID preserves the customer's original ID before any account merges
- AffiliateID identifies which affiliate receives attribution credit for this customer
- AffiliateCampaign is a free-text campaign identifier (up to 1024 chars) set by the affiliate
- BannerID and DownloadID track the specific creative and download source
- CountryID records the customer's country at the time of registration
- FunnelID tracks the acquisition funnel through which the customer was acquired
- PlayerLevelID references Dictionary.PlayerLevel to classify the customer's tier
- Re-attribution and data corrections are the primary drivers of the 1.8M historical row count
- PartitionCol is used for internal partitioning alignment with the base table

---

## 3. Data Overview

The table contains 1,834,748 historical rows, making it the largest temporal history table in the History schema. The high volume reflects the frequency of customer re-attribution events, tracking corrections, account merges, and retroactive campaign/banner metadata updates. This is a critical table for commission auditing and dispute resolution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer ID from eToro. Primary identifier for the registration record. |
| 2 | PartitionCol | bigint | NO | - | CODE-BACKED | Partition alignment column. Used for internal data distribution. |
| 3 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Cross-platform identifier for the customer. |
| 4 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate attributed with this customer registration. References dbo.tblaff_Affiliates.AffiliateID. |
| 5 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | Free-text campaign identifier set by the affiliate in their tracking links. |
| 6 | BannerID | int | NO | - | CODE-BACKED | The banner (creative asset) that the customer clicked to register. |
| 7 | DownloadID | bigint | NO | - | CODE-BACKED | The download source identifier tracking which app/installer was used. |
| 8 | CountryID | bigint | NO | - | CODE-BACKED | The customer's country at the time of registration. |
| 9 | FunnelID | int | YES | - | CODE-BACKED | Acquisition funnel through which the customer was acquired. NULL if not tracked. |
| 10 | PlayerLevelID | int | YES | - | CODE-BACKED | Customer tier classification. References Dictionary.PlayerLevel. NULL if not yet classified. |
| 11 | OriginalCID | bigint | NO | - | CODE-BACKED | The customer's original ID before any account merges. Equals CID if no merge occurred. |
| 12 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 13 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 14 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |
| 15 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | Extended attribution data in structured format. Captures supplementary tracking parameters. |
| 16 | EtoroUserName | varchar(50) | YES | - | CODE-BACKED | The eToro username of the registered customer. NULL if not available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | AffiliateCommission.RegistrationMetaData | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate attributed with this customer registration |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit FK | Customer tier classification |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on AffiliateCommission.RegistrationMetaData.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationMetaData | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RegistrationMetaData | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full attribution history for a customer
```sql
SELECT CID, GCID, AffiliateID, AffiliateCampaign, BannerID, CountryID, FunnelID, ValidFrom, ValidTo
FROM AffiliateCommission.RegistrationMetaData FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE CID = 123456789
ORDER BY ValidFrom
```

### 8.2 Check customer attribution at a specific date
```sql
SELECT CID, GCID, AffiliateID, AffiliateCampaign, BannerID, PlayerLevelID
FROM AffiliateCommission.RegistrationMetaData FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE CID = 123456789
```

### 8.3 Find recent re-attribution events for an affiliate
```sql
SELECT CID, GCID, AffiliateID, AffiliateCampaign, BannerID, ValidFrom, ValidTo
FROM History.RegistrationMetaData WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RegistrationMetaData | Type: Table | Source: fiktivo/History/Tables/History.RegistrationMetaData.sql*
