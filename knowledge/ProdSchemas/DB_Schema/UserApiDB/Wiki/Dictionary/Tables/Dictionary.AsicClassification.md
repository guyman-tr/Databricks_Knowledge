# Dictionary.AsicClassification

> Lookup table defining client classification categories under ASIC (Australian Securities and Investments Commission) regulation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AsicClassificationID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.AsicClassification defines the regulatory client categories for users under the Australian Securities and Investments Commission (ASIC) jurisdiction. Each classification determines the level of regulatory protection, product access, and leverage limits available to Australian-regulated users.

This table exists because ASIC regulation requires brokers to classify clients based on their financial sophistication. Retail clients receive full regulatory protections (negative balance protection, leverage caps), while sophisticated and wholesale investors may access broader product ranges and higher leverage. Classification affects which instruments a user can trade and what risk disclosures are presented.

Classification is typically assessed during onboarding for ASIC-regulated users (RegulationID=4 or 10). Users may start as Pending or RetailPending while documentation is reviewed, then move to their final classification. Users can apply to upgrade from Retail to SophisticatedInvestor or WholesaleInvestor by providing qualifying documentation.

---

## 2. Business Logic

### 2.1 ASIC Client Classification Hierarchy

**What**: Tiered client categorization with increasing product access and decreasing regulatory protection.

**Columns/Parameters Involved**: `AsicClassificationID`, `Name`

**Rules**:
- Retail (4) is the default classification - maximum protections, standard product access
- SophisticatedInvestor (2) requires documented proof of financial experience or assets
- WholesaleInvestor (3) requires meeting statutory wealth/income thresholds
- Pending (5) and RetailPending (1) are transitional states during assessment

**Diagram**:
```
Registration -> RetailPending(1) or Pending(5)
                      |
                Assessment Complete
                      |
              +-------+-------+
              |       |       |
          Retail(4)  Soph(2) Wholesale(3)
```

---

## 3. Data Overview

| AsicClassificationID | Name | Meaning |
|---|---|---|
| 1 | RetailPending | User registered under ASIC, awaiting retail classification confirmation - treated as retail with restrictions |
| 2 | SophisticatedInvestor | Meets ASIC sophisticated investor criteria per s708(8) Corporations Act - reduced disclosure requirements, broader product access |
| 3 | WholesaleInvestor | Meets ASIC wholesale investor threshold per s761G - full product access, minimal regulatory restrictions |
| 4 | Retail | Standard retail client - full ASIC regulatory protections including negative balance protection and leverage limits |
| 5 | Pending | Classification assessment not yet initiated - user in early registration stage |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AsicClassificationID | int | NO | - | CODE-BACKED | Primary key. Classification tier: 1=RetailPending, 2=SophisticatedInvestor, 3=WholesaleInvestor, 4=Retail, 5=Pending. See [ASIC Classification](#asic-classification) in glossary. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Classification label used in UI and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | AsicClassificationID | Lookup | Stores user's ASIC classification on their risk profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | Stores AsicClassificationID per user |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AsicClassification | CLUSTERED PK | AsicClassificationID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all ASIC classifications
```sql
SELECT AsicClassificationID, Name
FROM Dictionary.AsicClassification WITH (NOLOCK)
ORDER BY AsicClassificationID
```

### 8.2 Find users by ASIC classification
```sql
SELECT r.CustomerID, ac.Name AS Classification
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.AsicClassification ac WITH (NOLOCK) ON r.AsicClassificationID = ac.AsicClassificationID
WHERE r.AsicClassificationID = 4 -- Retail
```

### 8.3 Distribution of ASIC-regulated users by classification
```sql
SELECT ac.Name, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.AsicClassification ac WITH (NOLOCK) ON r.AsicClassificationID = ac.AsicClassificationID
WHERE r.AsicClassificationID IS NOT NULL
GROUP BY ac.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AsicClassification | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.AsicClassification.sql*
