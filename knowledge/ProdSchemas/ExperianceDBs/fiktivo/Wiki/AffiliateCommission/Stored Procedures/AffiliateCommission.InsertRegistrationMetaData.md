# AffiliateCommission.InsertRegistrationMetaData

> Inserts registration attribution metadata if it doesn't exist for the GCID, then returns the current metadata via GetMetaDataByGCID - used for upsert-like metadata management.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RegistrationMetaData for the GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertRegistrationMetaData is a conditional insert + read procedure for registration attribution metadata. It first checks if metadata exists for the given GCID (Global Customer ID). If not, it inserts a new record with the full attribution context. Regardless of whether an insert occurred, it then calls GetMetaDataByGCID to return the current metadata.

This procedure exists as an alternative entry point for metadata creation when the registration path goes through a GCID-first flow (e.g., options accounts or cross-entity registrations). Unlike InsertRegistration which creates metadata atomically with the registration, this procedure handles metadata-only creation for scenarios where the registration record already exists but metadata is missing.

---

## 2. Business Logic

### 2.1 Conditional Insert + Read Pattern

**What**: Creates metadata if GCID doesn't exist, then always returns current state.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM RegistrationMetaData WHERE GCID = @GCID): INSERT new metadata
- Always EXEC GetMetaDataByGCID @GCID at the end, returning current metadata
- This ensures the caller always gets data, whether newly inserted or pre-existing
- SET NOCOUNT ON for clean result set handling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. |
| 2 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID. Used for existence check and as the metadata key. |
| 3 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Referring affiliate. |
| 4 | @AffiliateCampaign | nvarchar(1024) (IN) | NO | - | CODE-BACKED | Campaign identifier. |
| 5 | @BannerID | int (IN) | NO | - | CODE-BACKED | Banner/creative identifier. |
| 6 | @DownloadID | bigint (IN) | NO | - | CODE-BACKED | Mobile app download ID. |
| 7 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 8 | @FunnelID | int (IN) | YES | NULL | CODE-BACKED | Registration funnel. |
| 9 | @PlayerLevelID | int (IN) | NO | - | CODE-BACKED | Player level classification. |
| 10 | @OriginalCID | bigint (IN) | NO | - | CODE-BACKED | Original CID for legacy mapping. |
| 11 | @AdditionalData | varchar(512) (IN) | NO | - | CODE-BACKED | Extended tracking data. |
| 12 | @EtoroUserName | varchar(50) (IN) | YES | NULL | CODE-BACKED | Customer's username. Added ONBRD-9494. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationMetaData | WRITE (INSERT) + READ (EXISTS check) | Creates metadata if GCID doesn't exist |
| - | AffiliateCommission.GetMetaDataByGCID | EXEC | Calls to return current metadata after insert |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by cross-entity registration flows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertRegistrationMetaData (procedure)
+-- AffiliateCommission.RegistrationMetaData (table)
+-- AffiliateCommission.GetMetaDataByGCID (procedure)
      +-- AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationMetaData | Table | INSERT with NOT EXISTS guard |
| AffiliateCommission.GetMetaDataByGCID | Procedure | EXEC to return current metadata |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Cross-entity registration flow) | External | Creates metadata for GCID-first registrations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert metadata and get result
```sql
EXEC [AffiliateCommission].[InsertRegistrationMetaData]
    @CID = 12345, @GCID = 67890, @AffiliateID = 3,
    @AffiliateCampaign = 'spring2026', @BannerID = 100,
    @DownloadID = 0, @CountryID = 1, @PlayerLevelID = 1,
    @OriginalCID = 12345, @AdditionalData = ''
```

### 8.2 Check if metadata exists for a GCID
```sql
SELECT GCID, CID, AffiliateID, CountryID
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
WHERE GCID = 67890
```

### 8.3 Count metadata records by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS MetadataCount
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY MetadataCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- ONBRD-9494: Added EtoroUserName (2026-03-04)
- PART-5458: ISA MoneyFarm support (2026-01-28)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertRegistrationMetaData | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertRegistrationMetaData.sql*
