# AffiliateCommission.GetAffiliateDataByAffiliateId

> Simple lookup procedure that retrieves the account type and affiliate type classification for a given affiliate, used by the commission engine to determine which compensation rules apply.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AccountTypeID, AffiliateTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAffiliateDataByAffiliateId retrieves the two key classification fields for an affiliate: AccountTypeID (what kind of account the affiliate operates) and AffiliateTypeID (which compensation plan/tier structure governs the affiliate's commissions). These two values determine the entire commission calculation path for any event attributed to this affiliate.

This procedure exists because the commission processing pipeline needs to quickly resolve an affiliate's configuration before calculating commissions. Rather than joining to the affiliate tables in every commission calculation query, the pipeline calls this once per affiliate to get the classification, then routes to the appropriate commission logic.

The data comes from dbo.tblaff_Affiliates, which is an external cross-schema table in the dbo schema (part of the core affiliate management system, not the commission system).

---

## 2. Business Logic

### 2.1 Affiliate Classification Lookup

**What**: Maps an AffiliateID to its account type and commission plan type.

**Columns/Parameters Involved**: `@ID`, `AccountTypeID`, `AffiliateTypeID`

**Rules**:
- Direct single-row lookup by AffiliateID in dbo.tblaff_Affiliates
- AccountTypeID determines the account classification (e.g., standard, options)
- AffiliateTypeID links to the compensation plan in dbo.tblaff_AffiliateTypes (queried by GetAffiliateTypeDataByAffiliateId or GetAffiliateTypeDataByAffiliateTypeId)
- Returns empty result set if affiliate does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int (IN) | NO | - | CODE-BACKED | The AffiliateID to look up. Matched against dbo.tblaff_Affiliates.AffiliateID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AccountTypeID | int | - | - | CODE-BACKED | The affiliate's account type classification. Determines which account system the affiliate uses (e.g., standard trading vs options). From dbo.tblaff_Affiliates. |
| 3 | AffiliateTypeID | int | - | - | CODE-BACKED | The affiliate's compensation plan identifier. Links to dbo.tblaff_AffiliateTypes which contains the full commission rate structure (per-deposit, per-sale, CPA, slab rates, tier configuration). From dbo.tblaff_Affiliates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | dbo.tblaff_Affiliates | READ (SELECT) | Looks up affiliate by AffiliateID; returns AccountTypeID and AffiliateTypeID |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the commission processing pipeline to classify an affiliate before commission calculation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetAffiliateDataByAffiliateId (procedure)
+-- dbo.tblaff_Affiliates (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (external) | Single-row SELECT by AffiliateID; returns AccountTypeID, AffiliateTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Calls to classify affiliate before calculating commissions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get affiliate classification
```sql
EXEC [AffiliateCommission].[GetAffiliateDataByAffiliateId] @ID = 3
```

### 8.2 Check all affiliates and their types
```sql
SELECT AffiliateID, AccountTypeID, AffiliateTypeID
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
ORDER BY AffiliateID
```

### 8.3 Find affiliates sharing the same compensation plan
```sql
SELECT AffiliateID, AccountTypeID
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE AffiliateTypeID = 1
ORDER BY AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP unavailable (410).

DDL comments reference:
- PART-4763: Update (2025-09-10)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetAffiliateDataByAffiliateId | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetAffiliateDataByAffiliateId.sql*
