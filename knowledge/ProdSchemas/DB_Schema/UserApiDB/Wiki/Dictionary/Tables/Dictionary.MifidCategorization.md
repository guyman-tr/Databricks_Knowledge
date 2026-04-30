# Dictionary.MifidCategorization

> Lookup table defining client classification categories under MiFID II (Markets in Financial Instruments Directive) EU regulation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MifidCategorizationID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.MifidCategorization defines the client categories required by MiFID II regulation for EU-regulated users. MiFID II mandates that investment firms classify all clients to determine appropriate product access, leverage limits, and regulatory protections. This classification is one of the most impactful regulatory attributes, directly controlling what a user can trade and at what risk level.

This table exists because MiFID II is the primary regulation for eToro's largest user base (CySEC/EU). Retail clients receive negative balance protection, leverage caps (30:1 max for major FX), and mandatory risk warnings. Professional clients can access higher leverage and broader instruments. Elective professionals have opted up from retail by demonstrating qualifying experience.

MiFID categorization is assessed during onboarding for CySEC-regulated users. All new users default to Retail (1) unless they apply for professional status. Retail Pending (4) and Pending (5) are transitional states during the assessment process. Stored on Customer.RiskUserInfo and referenced by multiple risk/aggregated info procedures.

---

## 2. Business Logic

### 2.1 MiFID Client Classification Impact

**What**: Tiered classification determining product access and protections under EU regulation.

**Columns/Parameters Involved**: `MifidCategorizationID`, `Name`

**Rules**:
- None (0): MiFID not applicable (user under non-EU regulation like ASIC, FCA-only)
- Retail (1): Full protections - leverage caps, negative balance protection, mandatory risk warnings
- Professional (2): Reduced protections - higher leverage, fewer restrictions
- Elective professional (3): Retail user who met criteria and opted up - has Professional access
- To opt up: must meet 2 of 3 criteria (trading frequency, portfolio size, professional experience)

---

## 3. Data Overview

| MifidCategorizationID | Name | Meaning |
|---|---|---|
| 0 | None | MiFID categorization not applicable - user is under a non-EU regulation (ASIC, FinCEN, FSA, etc.) |
| 1 | Retail | Standard retail client under MiFID II - maximum regulatory protections, leverage caps (30:1 major FX) |
| 2 | Professional | Professional client status - reduced protections, higher leverage (up to 400:1), broader instruments |
| 3 | Elective professional | Retail client who has opted up to professional by meeting 2 of 3 qualifying criteria |
| 4 | Retail Pending | Pending determination of retail status - temporarily treated as retail with restrictions |
| 5 | Pending | MiFID classification assessment in progress |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MifidCategorizationID | int | NO | - | CODE-BACKED | Primary key. MiFID classification: 0=None (non-EU), 1=Retail, 2=Professional, 3=Elective professional, 4=Retail Pending, 5=Pending. Referenced by Customer.RiskUserInfo and risk-related procedures. See [MiFID Categorization](_glossary.md#mifid-categorization). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Classification display name used in compliance reports and user management tools. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | MifidCategorizationID | Lookup | Stores user's MiFID classification |
| History.RiskUserInfo | MifidCategorizationID | Lookup | Historical record of MiFID classification changes |
| Customer.GetRiskUserInfo | MifidCategorizationID | Lookup | Returns MiFID status in risk profile |
| Customer.UpdateRiskUserInfo | MifidCategorizationID | Lookup | Updates MiFID classification |
| Customer.GetSingleAggregatedInfo | MifidCategorizationID | Lookup | Returns MiFID status in aggregated info |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | Stores MifidCategorizationID |
| History.RiskUserInfo | Table | Historical tracking |
| Customer.GetRiskUserInfo | Stored Procedure | Reads MifidCategorizationID |
| Customer.UpdateRiskUserInfo | Stored Procedure | Writes MifidCategorizationID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MifidCategorization | CLUSTERED PK | MifidCategorizationID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all MiFID categories
```sql
SELECT MifidCategorizationID, Name
FROM Dictionary.MifidCategorization WITH (NOLOCK)
ORDER BY MifidCategorizationID
```

### 8.2 Find professional clients
```sql
SELECT r.CustomerID, mc.Name AS MifidCategory
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.MifidCategorization mc WITH (NOLOCK) ON r.MifidCategorizationID = mc.MifidCategorizationID
WHERE r.MifidCategorizationID IN (2, 3) -- Professional or Elective Professional
```

### 8.3 MiFID distribution for EU users
```sql
SELECT mc.Name, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.MifidCategorization mc WITH (NOLOCK) ON r.MifidCategorizationID = mc.MifidCategorizationID
WHERE r.MifidCategorizationID > 0 -- EU users only
GROUP BY mc.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MifidCategorization | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.MifidCategorization.sql*
