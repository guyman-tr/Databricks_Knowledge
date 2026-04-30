# Dictionary.VisaType

> Lookup table defining US visa categories (E1, H1B, L1, etc.) used to classify non-US-resident customers by their visa type for regulatory compliance and tax reporting in the US market.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | VisaTypeID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on VisaTypeID) |

---

## 1. Business Meaning

Dictionary.VisaType defines the US visa categories that can be assigned to non-US-citizen customers who reside in the United States. When a customer registers or updates their profile, they may indicate their visa type. This classification is critical for US regulatory compliance — different visa types have different tax implications (W-8BEN vs W-9 requirements), trading restrictions, and reporting obligations.

Without this table, the system could not capture structured visa information for US-based non-citizen customers. Tax reporting (1099 forms, FATCA compliance) and regulatory onboarding (SEC requirements for foreign nationals) both depend on knowing the customer's immigration status.

The table is consumed by KYC/document classification procedures: BackOffice.AddDocumentClassification, BackOffice.UpdateDocumentClassification, and BackOffice.GetDocumentClassifications/GetAllDocumentClassifications. It connects to BackOffice.CustomerDocumentToDocumentType and the BackOffice.DocumentClassification UDT, enabling document requirements to vary by visa type.

---

## 2. Business Logic

### 2.1 US Visa Category Classification

**What**: Non-citizen US residents are classified by their visa type, which determines compliance requirements.

**Columns/Parameters Involved**: `VisaTypeID`, `Name`

**Rules**:
- E1/E2/E3 — Treaty visas (investors/traders from treaty countries). E2 investors and E1 treaty traders may have specific tax reporting needs
- F1 — Student visa. Customers on F1 visas may have restrictions on investment income types
- G4 — International organization employees. Exempt from certain US taxes under specific conditions
- H1B — Specialty occupation. Most common work visa; standard US tax treatment (W-9, 1099 reporting)
- L1 — Intra-company transferee. Similar tax treatment to H1B
- O1 — Extraordinary ability. High-profile individuals, standard tax treatment
- TN1/TN2 — NAFTA/USMCA professionals (TN1=Canadian, TN2=Mexican). Specific tax treaty implications
- The visa type influences which documents are required during KYC (e.g., visa stamp, I-94, EAD card)

**Diagram**:
```
Visa Categories by Purpose:
  ┌──────────────────────────────────────────────┐
  │  Treaty/Investment:  E1, E2, E3              │
  │  Employment:         H1B, L1, O1             │
  │  Student:            F1                      │
  │  Diplomatic:         G4                      │
  │  Trade Agreement:    TN1 (Canada), TN2 (MX)  │
  └──────────────────────────────────────────────┘
```

---

## 3. Data Overview

| VisaTypeID | Name | Meaning |
|---|---|---|
| 1 | E1 | Treaty trader visa — for nationals of treaty countries engaged in substantial trade between the US and their home country. May qualify for treaty-based tax benefits. |
| 4 | F1 | Student visa — non-immigrant academic students. May have restrictions on investment income; typically non-resident alien status for tax purposes during first 5 years. |
| 6 | H1B | Specialty occupation work visa — the most common US work visa. Standard resident-alien tax treatment (W-9, 1099). Largest customer segment among non-citizen US residents. |
| 8 | O1 | Extraordinary ability visa — for individuals with exceptional talent in sciences, arts, business, or athletics. Standard tax treatment; typically high-net-worth customers. |
| 9 | TN1 | NAFTA/USMCA Canadian professional — Canadian citizens working in the US under trade agreement. US-Canada tax treaty may affect withholding on investment income. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VisaTypeID | int | NO | - | CODE-BACKED | Unique identifier for the US visa category: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. Referenced by document classification procedures to tailor KYC requirements by visa type. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Standard visa category code as used by USCIS (e.g., "H1B", "F1", "TN1"). Displayed in BackOffice document classification screens and compliance reports. Nullable by DDL but all current values are populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDocumentToDocumentType | VisaTypeID | Implicit | Links customer documents to their visa type for classification |
| BackOffice.AddDocumentClassification | @VisaTypeID | Reader | Includes visa type when adding document classifications |
| BackOffice.UpdateDocumentClassification | @VisaTypeID | Reader | Updates document classifications with visa type |
| BackOffice.GetDocumentClassifications | VisaTypeID | Reader | Returns visa type in classification queries |
| BackOffice.GetAllDocumentClassifications | VisaTypeID | Reader | Returns all classifications including visa type |
| BackOffice.DocumentClassification (UDT) | VisaTypeID | UDT | Includes visa type in the document classification table type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.VisaType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Stores visa type per customer document |
| BackOffice.AddDocumentClassification | Stored Procedure | Reads visa type during document classification |
| BackOffice.UpdateDocumentClassification | Stored Procedure | Updates classifications with visa type |
| BackOffice.GetDocumentClassifications | Stored Procedure | Returns visa type in results |
| BackOffice.GetAllDocumentClassifications | Stored Procedure | Returns all classifications with visa types |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_VisaType | CLUSTERED | VisaTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all visa types
```sql
SELECT  VisaTypeID,
        Name AS VisaCode
FROM    [Dictionary].[VisaType] WITH (NOLOCK)
ORDER BY VisaTypeID;
```

### 8.2 Find documents classified by visa type
```sql
SELECT  d.CustomerID,
        v.Name AS VisaType,
        d.DocumentTypeID
FROM    [BackOffice].[CustomerDocumentToDocumentType] d WITH (NOLOCK)
JOIN    [Dictionary].[VisaType] v WITH (NOLOCK)
        ON v.VisaTypeID = d.VisaTypeID
WHERE   d.VisaTypeID IS NOT NULL
ORDER BY d.CustomerID;
```

### 8.3 Group visa types by category
```sql
SELECT  Name AS VisaCode,
        CASE
            WHEN Name IN ('E1','E2','E3') THEN 'Treaty/Investment'
            WHEN Name IN ('H1B','L1','O1') THEN 'Employment'
            WHEN Name = 'F1' THEN 'Student'
            WHEN Name = 'G4' THEN 'Diplomatic'
            WHEN Name IN ('TN1','TN2') THEN 'Trade Agreement'
        END AS Category
FROM    [Dictionary].[VisaType] WITH (NOLOCK)
ORDER BY VisaTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.VisaType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.VisaType.sql*
