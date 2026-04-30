# AffiliateCommission.UpdateMetaData

> Updates registration metadata fields for a customer (by CID or GCID) and returns the refreshed metadata record via GetMetaDataByCID.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates RegistrationMetaData by CID or GCID, then calls GetMetaDataByCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary mechanism for updating a customer's registration metadata within the affiliate commission system. Registration metadata includes the customer's affiliate attribution, campaign information, country, player level, download source, and additional data - all of which influence commission calculations and reporting.

The procedure supports two lookup modes: by CID (Customer ID) with partition pruning, or by GCID (Global Customer ID) when CID is not available. When using CID, the procedure leverages partition pruning via PartitionCol = @CID % 50 for optimal performance on the partitioned RegistrationMetaData table. When using GCID, the procedure also captures the resolved CID for use in the subsequent GetMetaDataByCID call.

All parameter updates use ISNULL(@param, existingValue), which means only non-NULL parameters are applied - NULL parameters leave the existing value unchanged. This allows selective updates of individual fields without requiring all fields to be specified. After the update, the procedure calls GetMetaDataByCID to return the refreshed metadata record to the caller.

---

## 2. Business Logic

### 2.1 CID-Based Update (Partition Pruned)

**What**: When @CID is provided, updates RegistrationMetaData using CID with partition pruning for optimal performance.

**Columns/Parameters Involved**: @CID, @AffiliateID, @AffiliateCampaign, @DownloadID, @CountryID, @PlayerLevelID, @AdditionalData, PartitionCol

**Rules**:
- Uses WHERE CID = @CID AND PartitionCol = @CID % 50 for partition-pruned lookup
- Each field uses ISNULL(@param, existingValue) - only non-NULL params overwrite
- Executes when @CID IS NOT NULL

### 2.2 GCID-Based Update (Fallback)

**What**: When @CID is NULL, updates RegistrationMetaData using GCID as the lookup key.

**Columns/Parameters Involved**: @GCID, @AffiliateID, @AffiliateCampaign, @DownloadID, @CountryID, @PlayerLevelID, @AdditionalData

**Rules**:
- Uses WHERE GCID = @GCID (no partition pruning possible)
- Same ISNULL(@param, existingValue) pattern for selective field updates
- Captures @CID = CID from the update to resolve CID for downstream call
- Only executes when @CID IS NULL

### 2.3 Metadata Return

**What**: Calls GetMetaDataByCID to return the updated metadata record.

**Columns/Parameters Involved**: @CID

**Rules**:
- Always called after the update, regardless of which path was taken
- EXEC AffiliateCommission.GetMetaDataByCID @CID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | Yes | NULL | CODE-BACKED | Customer ID - primary lookup key with partition pruning |
| 2 | @GCID | BIGINT | Yes | NULL | CODE-BACKED | Global Customer ID - fallback lookup key when CID is unknown |
| 3 | @AffiliateID | INT | Yes | NULL | CODE-BACKED | Affiliate ID to attribute to this customer |
| 4 | @AffiliateCampaign | NVARCHAR(1024) | Yes | NULL | CODE-BACKED | Affiliate campaign identifier string |
| 5 | @DownloadID | BIGINT | Yes | NULL | CODE-BACKED | Download source identifier |
| 6 | @CountryID | INT | Yes | NULL | CODE-BACKED | Country identifier for the customer |
| 7 | @PlayerLevelID | INT | Yes | NULL | CODE-BACKED | Player level classification identifier |
| 8 | @AdditionalData | VARCHAR(512) | Yes | NULL | CODE-BACKED | Free-form additional metadata |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @GCID | AffiliateCommission.RegistrationMetaData | UPDATE target | Updates metadata fields by CID or GCID |
| @CID | AffiliateCommission.GetMetaDataByCID | EXEC call | Calls SP to return refreshed metadata |

### 5.2 Referenced By (other objects point to this)

Called by the registration and attribution services when customer metadata needs to be updated - for example after affiliate reattribution, campaign changes, or country corrections.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateMetaData
  --> AffiliateCommission.RegistrationMetaData (UPDATE)
  --> AffiliateCommission.GetMetaDataByCID (EXEC)
      --> AffiliateCommission.RegistrationMetaData (SELECT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationMetaData | Table | UPDATE target - sets metadata fields |
| AffiliateCommission.GetMetaDataByCID | Stored Procedure | Called to return the updated metadata record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Registration/attribution service | Application | Calls this SP to update customer metadata |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update metadata by CID
```sql
EXEC AffiliateCommission.UpdateMetaData
    @CID = 500001,
    @AffiliateID = 2001,
    @AffiliateCampaign = N'summer_2026_crypto',
    @CountryID = 44;
```

### 8.2 Update metadata by GCID (CID unknown)
```sql
EXEC AffiliateCommission.UpdateMetaData
    @GCID = 900001,
    @AffiliateID = 2001,
    @PlayerLevelID = 3;
```

### 8.3 Check current metadata for a customer
```sql
SELECT CID, GCID, AffiliateID, AffiliateCampaign, CountryID, PlayerLevelID, DownloadID, AdditionalData
FROM AffiliateCommission.RegistrationMetaData WITH (NOLOCK)
WHERE CID = 500001 AND PartitionCol = 500001 % 50;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- 7/2/24 Noga: Fix WHERE clause of PartitionCol

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateMetaData | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateMetaData.sql*
