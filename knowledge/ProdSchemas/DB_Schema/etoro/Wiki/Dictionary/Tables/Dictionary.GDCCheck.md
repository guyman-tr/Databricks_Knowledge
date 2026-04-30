# Dictionary.GDCCheck

> Lookup table defining the four outcomes of GDC (Global Data Consortium) identity verification checks — None, One Source, Two Sources, or No Match — used to record electronic identity verification depth for KYC compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GDCCheckID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.GDCCheck defines the possible outcomes of electronic identity verification checks performed through GDC (Global Data Consortium), one of eToro's identity verification providers. GDC cross-references customer-provided identity information against multiple independent data sources to verify their identity. The result indicates how many independent sources confirmed the customer's identity.

This table supports eToro's KYC (Know Your Customer) compliance process. Regulators require brokers to verify customer identities before allowing trading. GDC checks provide automated electronic verification that can satisfy regulatory requirements in certain jurisdictions without requiring manual document review. The number of confirming sources (0, 1, or 2) determines the verification strength and may affect which account features are available.

GDCCheckID is stored on BackOffice.Customer to record the GDC verification result for each customer. This works alongside other verification methods (Dictionary.ElectronicIdentityCheck, Dictionary.EIDStatus) as part of the multi-layered KYC process.

---

## 2. Business Logic

### 2.1 Verification Depth Classification

**What**: Each GDC check result indicates how many independent data sources confirmed the customer's identity.

**Columns/Parameters Involved**: `GDCCheckID`, `Name`

**Rules**:
- **None (0)**: No GDC check was performed — customer may be in a jurisdiction where GDC is not used, or the check has not yet been initiated
- **One Source (1)**: Customer identity was confirmed by one independent data source. Provides basic verification but may not meet all regulatory requirements
- **Two Sources (2)**: Customer identity was confirmed by two independent data sources. This is the strongest electronic verification level, typically satisfying regulatory EID requirements
- **No Match (3)**: GDC check was performed but no data sources could confirm the customer's identity. The customer will need to complete manual document verification (POI/POA upload)

**Diagram**:
```
GDC Identity Check Flow:
Customer provides identity details
    │
    ├── GDC check not applicable ──► None (0)
    │
    └── GDC check executed
            │
            ├── 2 sources confirm ──► Two Sources (2) ✓ Strongest
            ├── 1 source confirms ──► One Source (1)   ✓ Basic
            └── No sources confirm ──► No Match (3)    ✗ Manual review required
```

---

## 3. Data Overview

| GDCCheckID | Name | Meaning |
|---|---|---|
| 0 | None | No GDC verification check was performed for this customer. Either the check hasn't been initiated, the jurisdiction doesn't use GDC, or the customer was verified through a different method (manual document review, Au10tix). |
| 1 | One Source | GDC found one independent data source confirming the customer's identity. Provides a baseline level of electronic verification. May be sufficient for basic account access in some jurisdictions but not for full trading in others. |
| 2 | Two Sources | GDC found two independent data sources confirming the customer's identity. This is the gold standard for electronic identity verification — meets regulatory EID (Electronic Identity) requirements in most jurisdictions without manual review. |
| 3 | No Match | GDC was unable to match the customer's identity information against any data source. The customer's provided details could not be electronically verified. Triggers fallback to manual document verification — the customer must upload identity documents (passport, utility bill) for manual review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GDCCheckID | int | NO | - | VERIFIED | Primary key identifying the GDC verification outcome. 0=None (not checked), 1=One Source (basic verification), 2=Two Sources (strong verification), 3=No Match (failed verification). Stored on BackOffice.Customer to record the GDC result for each customer's KYC process. |
| 2 | Name | varchar(30) | YES | - | VERIFIED | Human-readable label for the GDC check outcome. Used in BackOffice KYC review screens, compliance reports, and audit trails. NULL allowed but all production values are populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | GDCCheckID | Implicit Lookup | Records the GDC verification outcome for each customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | References GDCCheckID to store the identity verification result |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GDCCheck_GDCCheckID | CLUSTERED PK | GDCCheckID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_GDCCheck_GDCCheckID | PRIMARY KEY | Unique GDC check outcome identifier |

---

## 8. Sample Queries

### 8.1 List all GDC check outcomes
```sql
SELECT  GDCCheckID,
        Name
FROM    [Dictionary].[GDCCheck] WITH (NOLOCK)
ORDER BY GDCCheckID;
```

### 8.2 Count customers by GDC check result
```sql
SELECT  g.Name          AS GDCResult,
        COUNT(*)        AS CustomerCount
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[GDCCheck] g WITH (NOLOCK)
        ON c.GDCCheckID = g.GDCCheckID
GROUP BY g.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find customers with no GDC match (needing manual review)
```sql
SELECT  c.CID,
        g.Name          AS GDCResult
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[GDCCheck] g WITH (NOLOCK)
        ON c.GDCCheckID = g.GDCCheckID
WHERE   c.GDCCheckID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GDCCheck | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.GDCCheck.sql*
