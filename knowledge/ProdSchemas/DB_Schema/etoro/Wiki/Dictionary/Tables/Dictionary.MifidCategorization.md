# Dictionary.MifidCategorization

> Lookup table defining the MiFID II client categorization levels used to classify customers under EU regulatory requirements.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MifidCategorizationID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MifidCategorization defines the client classification tiers mandated by the Markets in Financial Instruments Directive II (MiFID II). Under EU regulation, every client of a financial services firm must be categorized as either Retail, Professional, or Elective Professional, with each tier granting different levels of regulatory protection, leverage limits, and negative balance protection.

This classification is critical because it determines which leverage caps, margin close-out rules, and marketing restrictions apply to a customer. Retail clients receive the highest protection (restricted leverage, guaranteed negative balance protection), while Professional clients can access higher leverage and fewer restrictions. The "Elective Professional" status is for retail clients who have requested and qualified for professional treatment.

The MifidCategorizationID is stored on BackOffice.Customer (with a DEFAULT of 1 = Retail, the most protective classification) and is updated via BackOffice.UpdateRiskUserInfo during compliance review. It feeds into the computed column `TradingRiskStatusID` on BackOffice.Customer, which combines MiFID categorization with regulation and ASIC classification to determine the overall trading risk profile. History is tracked in History.BackOfficeCustomer via audit triggers.

---

## 2. Business Logic

### 2.1 EU Regulatory Client Classification

**What**: MiFID II requires all EU-regulated clients to be classified into protection tiers that govern leverage, margin rules, and marketing restrictions.

**Columns/Parameters Involved**: `MifidCategorizationID`, `Name`

**Rules**:
- All new customers default to MifidCategorizationID = 1 (Retail) — the most protective tier
- Retail (1) clients have leverage caps (30:1 forex, 2:1 crypto), mandatory margin close-out at 50%, and negative balance protection
- Professional (2) clients have no leverage caps and reduced protections — only granted after assessment by compliance
- Elective Professional (3) clients are retail clients who opted-in and met at least 2 of 3 qualifying criteria (trade frequency, portfolio size, professional experience)
- Retail Pending (4) and Pending (5) are intermediate states during the categorization assessment process
- None (0) applies to clients under non-EU regulations where MiFID does not apply

### 2.2 TradingRiskStatusID Computation

**What**: MifidCategorizationID feeds into the computed column `TradingRiskStatusID` on BackOffice.Customer, which synthesizes regulatory classification from multiple sources.

**Columns/Parameters Involved**: `MifidCategorizationID`, `RegulationID`, `AsicClassificationID`, `SeychellesCategorizationID`, `DesignatedRegulationID`

**Rules**:
- For CySEC regulation (RegulationID=5): Retail (1) → TradingRiskStatus 3, Pending (5) → TradingRiskStatus 2
- For FCA/EU regulation (RegulationID=1,2): Retail Pending (4) → TradingRiskStatus 1
- MiFID classification is only one input — the final TradingRiskStatusID also considers ASIC and Seychelles classifications

**Diagram**:
```
Customer Registration
        │
        ▼
  MifidCategorizationID = 1 (Retail) [DEFAULT]
        │
  Compliance review / Client request
        │
        ├──→ Stays Retail (1) — most customers
        ├──→ Retail Pending (4) — assessment in progress
        ├──→ Pending (5) — categorization assessment
        ├──→ Professional (2) — compliance-approved
        └──→ Elective Professional (3) — client opted-in + qualified
```

---

## 3. Data Overview

| MifidCategorizationID | Name | Meaning |
|---|---|---|
| 0 | None | MiFID II does not apply — customer is registered under a non-EU regulation (e.g., ASIC, Seychelles FSA) where this classification is irrelevant |
| 1 | Retail | Standard retail investor with full EU consumer protection — leverage caps, margin close-out at 50%, negative balance protection. Default for all new EU-regulated customers. |
| 2 | Professional | Institutional or qualified professional investor — no leverage caps, reduced regulatory protections. Requires compliance assessment and approval. |
| 3 | Elective professional | Retail client who requested professional treatment and met qualifying criteria (trade frequency, portfolio size, or professional experience). Gets professional-level access but may retain some protections. |
| 4 | Retail Pending | Transitional state — customer has been flagged for potential reclassification from Retail, assessment in progress by compliance team |
| 5 | Pending | Initial categorization pending — MiFID assessment has not yet been completed. Temporary state during onboarding. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MifidCategorizationID | int | NO | - | VERIFIED | MiFID II client classification tier: **0**=None (non-EU), **1**=Retail (full protection, default), **2**=Professional (reduced protection), **3**=Elective Professional (opted-in retail), **4**=Retail Pending (under review), **5**=Pending (assessment incomplete). Referenced by BackOffice.Customer.MifidCategorizationID (FK, DEFAULT 1) and History.BackOfficeCustomer. Feeds into computed column TradingRiskStatusID. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable classification label. Used in compliance dashboards and regulatory reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | MifidCategorizationID | FK (FK_BCST_MifidCategorizationID) | Stores the MiFID classification per customer; DEFAULT 1 (Retail). Feeds into computed TradingRiskStatusID. |
| History.BackOfficeCustomer | MifidCategorizationID | FK (FK_HBOC_MifidCategorizationID) | Audit history of MiFID classification changes |
| BackOffice.UpdateRiskUserInfo | @MifidCategorizationID | Parameter (DEFAULT 1) | Writes/updates the MiFID categorization during compliance review |
| BackOffice.UpdateRiskUserInfoRemote | @MifidCategorizationID | Parameter | Remote-callable version of the risk user info update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MifidCategorization (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK on MifidCategorizationID |
| History.BackOfficeCustomer | Table | FK on MifidCategorizationID (audit trail) |
| BackOffice.UpdateRiskUserInfo | Stored Procedure | Writes MifidCategorizationID |
| BackOffice.UpdateRiskUserInfoRemote | Stored Procedure | Writes MifidCategorizationID (remote) |
| BackOffice.GetHistoryBackOfficeCustomer | Stored Procedure | JOINs to resolve MifidCategorizationID to Name |
| Customer.GetRiskUserInfo | Stored Procedure | Reads MifidCategorizationID |
| SalesForce.GetBackOfficeCustomer | Stored Procedure | Reads MifidCategorizationID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCMC | CLUSTERED PK | MifidCategorizationID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCMC | PRIMARY KEY | Unique MiFID categorization identifier on DICTIONARY filegroup, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all MiFID categorization levels
```sql
SELECT  MifidCategorizationID,
        Name
FROM    Dictionary.MifidCategorization WITH (NOLOCK)
ORDER BY MifidCategorizationID;
```

### 8.2 Count customers by MiFID category
```sql
SELECT  mc.Name                 AS MifidCategory,
        COUNT(*)                AS CustomerCount
FROM    BackOffice.Customer c WITH (NOLOCK)
JOIN    Dictionary.MifidCategorization mc WITH (NOLOCK)
        ON c.MifidCategorizationID = mc.MifidCategorizationID
GROUP BY mc.Name
ORDER BY COUNT(*) DESC;
```

### 8.3 Find customers pending MiFID assessment
```sql
SELECT  c.CID,
        mc.Name         AS MifidCategory,
        r.Name          AS Regulation
FROM    BackOffice.Customer c WITH (NOLOCK)
JOIN    Dictionary.MifidCategorization mc WITH (NOLOCK)
        ON c.MifidCategorizationID = mc.MifidCategorizationID
JOIN    Dictionary.Regulation r WITH (NOLOCK)
        ON c.RegulationID = r.RegulationID
WHERE   c.MifidCategorizationID IN (4, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Historical code comment: "Ran Ovadia, 10/05/18, 51497 Added MifidCategorizationID" — added to support EU MiFID II regulatory requirements.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MifidCategorization | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MifidCategorization.sql*
