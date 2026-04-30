# Dictionary.CountryRiskGroup

> Lookup table defining the risk classification tiers assigned to countries for AML/KYC compliance and onboarding controls.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CountryRiskGroup classifies countries into risk tiers for Anti-Money Laundering (AML) and Know Your Customer (KYC) compliance. Each country is assigned a risk group that determines the level of scrutiny applied to customers registering from that country — from no special treatment to mandatory verification before any deposit is allowed.

These risk tiers drive automated compliance controls: customers from high-risk countries may face additional document requirements, enhanced due diligence (EDD), restricted deposit amounts, or pre-deposit verification gates. The FATF (Financial Action Task Force) designation represents the most stringent tier, aligning with the international AML blacklist.

The CountryRiskGroupID is stored on `Dictionary.Country` and consumed by onboarding, compliance, and risk assessment procedures to enforce risk-proportionate customer handling.

---

## 2. Business Logic

### 2.1 Risk-Based Customer Controls

**What**: Each risk group triggers different compliance controls during customer onboarding and transaction processing.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **None (0)**: Standard onboarding — no additional risk controls beyond baseline KYC requirements.
- **High risk country (1)**: Enhanced due diligence required. Additional documentation, manual review by compliance. Higher monitoring thresholds for suspicious activity.
- **High risk country for new clients (2)**: Risk controls apply only to new registrations — existing verified clients from these countries are grandfathered. Prevents blocking long-standing customers when a country's risk rating changes.
- **High risk FATF country (3)**: Aligned with FATF grey/blacklist. Strictest controls — may require source of funds documentation, enhanced ongoing monitoring, or even restrict certain services.
- **Verified before deposit (4)**: Customer must complete full identity verification BEFORE making their first deposit. Unlike standard flow where verification can happen post-deposit (up to regulatory limits).

**Diagram**:
```
Country Risk Assessment
        │
        ├── 0 (None): Standard KYC flow
        │
        ├── 1 (High risk): Enhanced due diligence for ALL customers
        │
        ├── 2 (High risk new): Enhanced only for NEW registrations
        │
        ├── 3 (FATF high risk): Strictest controls, FATF-aligned
        │
        └── 4 (Verify before deposit): Block deposits until verified
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | None | Standard risk — baseline KYC requirements, no additional country-specific controls. Applies to most countries. |
| 1 | High risk country | Country flagged for elevated AML/KYC risk — all customers face enhanced due diligence, additional documentation requirements, and heightened transaction monitoring. |
| 2 | High risk country for new clients | Country flagged for new registrations only — existing verified customers are unaffected. Prevents disruption to established customers when a country's risk rating is upgraded. |
| 3 | High risk FATF country | Country on the FATF grey/blacklist — maximum compliance controls. Source of funds documentation, enhanced ongoing monitoring, possible service restrictions. |
| 4 | Verified before deposit | Customers from this country must complete full identity verification before any deposit is accepted. Blocks the standard "deposit first, verify later" flow. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Country risk tier: **0**=None (standard), **1**=High risk country (enhanced DD for all), **2**=High risk for new clients only (existing clients grandfathered), **3**=High risk FATF (strictest, FATF-aligned), **4**=Verified before deposit (block deposits until verified). Referenced by Dictionary.Country.CountryRiskGroupID. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable risk tier label. Used in compliance dashboards and onboarding logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | CountryRiskGroupID | Implicit | Each country is assigned to a risk group that determines compliance controls |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CountryRiskGroup (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | References CountryRiskGroupID for AML/KYC compliance tier |
| Onboarding/Compliance procedures | Stored Procedures | Use risk group to enforce appropriate customer controls |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | Unique risk group identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all country risk groups
```sql
SELECT  ID,
        Name
FROM    Dictionary.CountryRiskGroup WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count countries per risk group
```sql
SELECT  crg.Name            AS RiskGroup,
        COUNT(*)            AS CountryCount
FROM    Dictionary.Country c WITH (NOLOCK)
JOIN    Dictionary.CountryRiskGroup crg WITH (NOLOCK)
        ON c.CountryRiskGroupID = crg.ID
GROUP BY crg.Name
ORDER BY COUNT(*) DESC;
```

### 8.3 List high-risk FATF countries
```sql
SELECT  c.Name              AS Country,
        c.TwoLetterIsoCode,
        crg.Name            AS RiskGroup
FROM    Dictionary.Country c WITH (NOLOCK)
JOIN    Dictionary.CountryRiskGroup crg WITH (NOLOCK)
        ON c.CountryRiskGroupID = crg.ID
WHERE   crg.ID = 3
ORDER BY c.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryRiskGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryRiskGroup.sql*
