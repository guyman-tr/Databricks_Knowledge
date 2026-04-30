# AffiliateAttribution.GetAffiliateInfo

> Lookup procedure that retrieves the current affiliate's marketing expense channel and a target affiliate's marketing expense channel for a given customer, used by Databricks notebooks to evaluate re-attribution eligibility.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: current affiliate info + target affiliate info |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAttribution.GetAffiliateInfo is the first step in the affiliate re-attribution workflow. When a Databricks notebook needs to determine whether a customer should be re-attributed from their current affiliate to a different one, it calls this procedure to retrieve the marketing expense channel (MarketingExpenseID) for both the current and target affiliates. This information is used to evaluate eligibility rules before proceeding with the actual re-attribution.

This procedure exists to provide the Databricks re-attribution process with the data it needs to make re-attribution decisions. The marketing expense channel is a key factor in determining whether a customer can be moved between affiliates - different channels may have different attribution rules.

The procedure returns two result sets: (1) the current affiliate's AffiliateID and MarketingExpenseID found via the customer's registration record, and (2) the target affiliate's MarketingExpenseID. The Databricks notebook compares these to decide whether to proceed with UpdateAffiliationInfo and UpdateEvents.

---

## 2. Business Logic

### 2.1 Dual Result Set Pattern

**What**: Returns two separate result sets for comparison by the calling Databricks notebook.

**Columns/Parameters Involved**: `@CID`, `@TargetAffiliateID`

**Rules**:
- Result Set 1: Joins AffiliateCommission.RegistrationVW (ON CID=@CID) to dbo.tblaff_Affiliates (ON AffiliateID) to get the current affiliate's AffiliateID and MarketingExpenseID
- Result Set 2: Directly queries dbo.tblaff_Affiliates for the @TargetAffiliateID's MarketingExpenseID
- If the CID has no registration record, Result Set 1 is empty
- If @TargetAffiliateID doesn't exist, Result Set 2 is empty
- Both results use WITH (NOLOCK) for non-blocking reads

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint | NO | - | CODE-BACKED | Customer ID to look up. Used to find the customer's registration record in AffiliateCommission.RegistrationVW, which links to their current affiliate. |
| 2 | @TargetAffiliateID | int | NO | - | CODE-BACKED | The affiliate ID being considered as the new attribution target. Its MarketingExpenseID is returned in the second result set for comparison with the current affiliate's channel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.RegistrationVW | READ | Finds the customer's registration record to identify their current affiliate |
| - | dbo.tblaff_Affiliates | READ | Looks up MarketingExpenseID for both current and target affiliates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Databricks Notebook (external) | - | Caller | Re-attribution eligibility evaluation workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAttribution.GetAffiliateInfo (procedure)
+-- AffiliateCommission.RegistrationVW (view, cross-schema)
+-- dbo.tblaff_Affiliates (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationVW | View | INNER JOIN on CID to find current affiliate |
| dbo.tblaff_Affiliates | Table | INNER JOIN for current affiliate + direct SELECT for target affiliate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Databricks Notebook (external) | External | Calls before UpdateAffiliationInfo/UpdateEvents to evaluate eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up affiliate info for a customer
```sql
EXEC AffiliateAttribution.GetAffiliateInfo @CID = 12345, @TargetAffiliateID = 67890
```

### 8.2 Check current affiliate's channel for a customer
```sql
SELECT R.AffiliateID, A.MarketingExpenseID
FROM AffiliateCommission.RegistrationVW AS R WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates AS A WITH (NOLOCK) ON A.AffiliateID = R.AffiliateID
WHERE R.CID = 12345
```

### 8.3 Compare current vs target affiliate channels
```sql
-- Current affiliate
SELECT R.AffiliateID, A.MarketingExpenseID AS CurrentChannel
FROM AffiliateCommission.RegistrationVW AS R WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates AS A WITH (NOLOCK) ON A.AffiliateID = R.AffiliateID
WHERE R.CID = 12345

-- Target affiliate
SELECT MarketingExpenseID AS TargetChannel
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE AffiliateID = 67890
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-1999 (referenced in SQL comments) | Jira | New SP for Databricks notebook - affiliate re-attribution (Oct 2023, Gil Haba) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAttribution.GetAffiliateInfo | Type: Stored Procedure | Source: fiktivo/AffiliateAttribution/Stored Procedures/AffiliateAttribution.GetAffiliateInfo.sql*
