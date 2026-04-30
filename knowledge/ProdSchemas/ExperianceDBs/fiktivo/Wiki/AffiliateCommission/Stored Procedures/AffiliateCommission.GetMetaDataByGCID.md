# AffiliateCommission.GetMetaDataByGCID

> Retrieves the full registration attribution metadata for a customer by Global Customer ID (GCID), used when only the cross-system identifier is available.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RegistrationMetaData fields for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetMetaDataByGCID is the GCID-based variant of the metadata lookup. While GetMetaDataByCID looks up by the local Customer ID (CID) with partition pruning, this procedure looks up by the Global Customer ID (GCID), which is the cross-system customer identifier. This is needed when the calling system (e.g., the options platform or a cross-entity service) only has the GCID.

This procedure returns the same 11 attribution fields as GetMetaDataByCID. Unlike its CID counterpart, it does NOT use PartitionCol pruning because GCID cannot be mapped to the CID-based partition scheme without first knowing the CID.

The procedure is called by InsertRegistrationMetaData to check if metadata already exists for a GCID before inserting new records.

---

## 2. Business Logic

### 2.1 GCID-Based Lookup (No Partition Pruning)

**What**: Looks up registration metadata by the cross-system Global Customer ID.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- WHERE GCID = @GCID (no PartitionCol filter - cannot derive CID-based partition from GCID)
- May return multiple rows if a GCID maps to multiple CIDs (rare but possible in cross-entity scenarios)
- Returns empty result set if GCID not found

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID to look up. Cross-system identifier. Matched against RegistrationMetaData.GCID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID (echo of input). |
| 3 | CID | bigint | - | - | CODE-BACKED | Local Customer ID. |
| 4 | AffiliateID | int | - | - | CODE-BACKED | The affiliate who referred this customer. |
| 5 | AffiliateCampaign | nvarchar | - | - | CODE-BACKED | Campaign identifier from the affiliate's tracking link. |
| 6 | CountryID | int | - | - | CODE-BACKED | Customer's country at registration. |
| 7 | PlayerLevelID | int | - | - | CODE-BACKED | Customer's player level classification. |
| 8 | OriginalCID | bigint | - | - | CODE-BACKED | Original CID for legacy join support. |
| 9 | AdditionalData | nvarchar | - | - | CODE-BACKED | Free-form extended tracking data. Added PART-3606. |
| 10 | DownloadID | bigint | - | - | CODE-BACKED | Mobile app download identifier. |
| 11 | BannerID | int | - | - | CODE-BACKED | Banner/creative identifier. |
| 12 | FunnelID | int | - | - | CODE-BACKED | Registration funnel identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | AffiliateCommission.RegistrationMetaData | READ (SELECT) | Retrieves attribution metadata by GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.InsertRegistrationMetaData | - | EXEC | Calls to check if metadata exists for GCID before insert |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetMetaDataByGCID (procedure)
+-- AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationMetaData | Table | SELECT by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.InsertRegistrationMetaData | Procedure | Calls to check GCID existence |
| (Cross-entity services) | External | Looks up attribution by GCID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get metadata by Global Customer ID
```sql
EXEC [AffiliateCommission].[GetMetaDataByGCID] @GCID = 67890
```

### 8.2 Find customers by GCID range
```sql
SELECT GCID, CID, AffiliateID, CountryID
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
WHERE GCID BETWEEN 60000 AND 70000
ORDER BY GCID
```

### 8.3 Check for GCIDs with multiple CID mappings
```sql
SELECT GCID, COUNT(*) AS CIDCount
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
GROUP BY GCID
HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3683: Returning all fields from metadata
- PART-3606: Added AdditionalData (2024-10-21)
- PART-2448: CPA New Compensation Design (2023-12-17)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetMetaDataByGCID | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetMetaDataByGCID.sql*
