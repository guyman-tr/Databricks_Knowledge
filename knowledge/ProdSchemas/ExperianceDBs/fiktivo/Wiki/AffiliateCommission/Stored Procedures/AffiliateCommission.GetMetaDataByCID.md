# AffiliateCommission.GetMetaDataByCID

> Retrieves the full registration attribution metadata for a customer by CID, providing the affiliate linkage, campaign, country, and tracking context needed for commission processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RegistrationMetaData fields for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetMetaDataByCID retrieves the complete registration attribution record for a customer. This metadata was captured when the customer registered and includes which affiliate referred them, through which campaign, from which country, and various tracking identifiers. The commission engine needs this data for every commission calculation to properly attribute revenue to the correct affiliate.

This procedure exists as the primary metadata lookup in the commission pipeline. It is also called by UpdateMetaData to read the current state before applying updates. The query uses partition pruning (PartitionCol = CID % 50) for optimal performance against the 18.8M-row RegistrationMetaData table.

---

## 2. Business Logic

### 2.1 Partition-Pruned Lookup

**What**: Efficient single-row lookup using the computed partition column.

**Columns/Parameters Involved**: `@CID`, `PartitionCol`

**Rules**:
- WHERE CID = @CID AND PartitionCol = @CID % 50
- PartitionCol is a computed modulo-50 hash used for data distribution and fast lookup
- Returns all attribution fields in a single result set
- Returns empty result set if CID not found (customer has no registration metadata)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID to look up. Matched against RegistrationMetaData.CID with partition pruning on CID%50. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID. Cross-system identifier for the customer. |
| 3 | CID | bigint | - | - | CODE-BACKED | Customer ID (echo of input). |
| 4 | AffiliateID | int | - | - | CODE-BACKED | The affiliate who referred this customer. Core attribution field for all commission calculations. |
| 5 | AffiliateCampaign | nvarchar | - | - | CODE-BACKED | Campaign identifier from the affiliate's tracking link. Used for campaign-level reporting. |
| 6 | CountryID | int | - | - | CODE-BACKED | Customer's country at registration. Used for country-specific commission rates. |
| 7 | PlayerLevelID | int | - | - | CODE-BACKED | Customer's player level classification at registration. |
| 8 | OriginalCID | bigint | - | - | CODE-BACKED | Original Customer ID for legacy dual-path join support (CreditVW/ClosedPositionVW Path 2 for CID=-1 records). |
| 9 | AdditionalData | nvarchar | - | - | CODE-BACKED | Free-form metadata field for extended tracking data. Added PART-3606. |
| 10 | DownloadID | bigint | - | - | CODE-BACKED | Mobile app download identifier from AppsFlyer attribution. |
| 11 | BannerID | int | - | - | CODE-BACKED | Banner/creative identifier from the affiliate's marketing material. |
| 12 | FunnelID | int | - | - | CODE-BACKED | Registration funnel identifier tracking the signup path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.RegistrationMetaData | READ (SELECT) | Retrieves full attribution metadata by CID with partition pruning |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.UpdateMetaData | - | EXEC | Calls this procedure to read current metadata before applying updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetMetaDataByCID (procedure)
+-- AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationMetaData | Table | SELECT by CID with PartitionCol=CID%50 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.UpdateMetaData | Procedure | Calls to read current metadata state |
| (Commission engine) | External | Reads customer attribution for commission calculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get metadata for customer 12345
```sql
EXEC [AffiliateCommission].[GetMetaDataByCID] @CID = 12345
```

### 8.2 Find all customers attributed to a specific affiliate
```sql
SELECT CID, GCID, AffiliateCampaign, CountryID
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
WHERE AffiliateID = 3
ORDER BY CID DESC
```

### 8.3 Check customer registration metadata with partition pruning
```sql
SELECT GCID, CID, AffiliateID, AffiliateCampaign, CountryID, AdditionalData
FROM [AffiliateCommission].[RegistrationMetaData] WITH (NOLOCK)
WHERE CID = 12345 AND PartitionCol = 12345 % 50
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3683: Returning all fields from metadata
- PART-3606: Added AdditionalData (2024-10-21)
- PART-2448: CPA New Compensation Design (2023-12-17)
- Unlabeled: Fix PartitionCol WHERE clause (2024-02-07)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetMetaDataByCID | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetMetaDataByCID.sql*
