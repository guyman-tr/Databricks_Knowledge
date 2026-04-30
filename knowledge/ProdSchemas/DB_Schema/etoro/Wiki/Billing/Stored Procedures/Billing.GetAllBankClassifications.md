# Billing.GetAllBankClassifications

> Full export of all Trustly bank classification tier assignments, returning only banks where the standard tier and eToro tier are aligned (ClassificationID == EtoroClassificationID).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full dataset - no filter parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAllBankClassifications` exports the complete bank classification dataset from `Billing.BankClassification`, enriched with the human-readable tier name from `Dictionary.BankClassification`. This is used by administration and reporting tools to see the full classification state of all 42,721+ Trustly banks across countries and funding types.

`Billing.BankClassification` stores per-bank tier assignments for Trustly (FundingTypeID=35) payment routing. Each bank has TWO tier fields: `ClassificationID` (standard/provider-facing tier) and `EtoroClassificationID` (eToro's independent routing-preference tier). Both reference `Dictionary.BankClassification` for the tier name (1=Basic, 2=Evaluation, 3=Optimised).

**Critical behavior**: The JOIN condition `BBC.ClassificationID = DBC.ClassificationID AND BBC.EtoroClassificationID = DBC.ClassificationID` means only banks where both tiers are equal are returned. This filters out banks with divergent classifications. Because both tiers must match the same `DBC.ClassificationID`, the `ClassificationName AS EtoroClassificationName` column will always return the same value as `ClassificationName` - the two columns are always identical in results.

Created June 2020 (PAYIL-1279) alongside the BankClassification system.

---

## 2. Business Logic

### 2.1 Aligned-Classification Export

**What**: Returns all bank classification records where standard tier equals eToro tier.

**Columns/Parameters Involved**: `BBC.ClassificationID`, `BBC.EtoroClassificationID`, `DBC.ClassificationID`, `DBC.ClassificationName`

**Rules**:
- `INNER JOIN Dictionary.BankClassification ON BBC.ClassificationID = DBC.ClassificationID AND BBC.EtoroClassificationID = DBC.ClassificationID`: this dual-condition JOIN is equivalent to `WHERE ClassificationID = EtoroClassificationID`. Banks with divergent tier assignments are excluded from results.
- `DBC.ClassificationName AS ClassificationName`: human-readable tier label (Basic/Evaluation/Optimised) for ClassificationID.
- `DBC.ClassificationName AS EtoroClassificationName`: identical value because both join on the same DBC row. This column is always the same as ClassificationName.
- No SET NOCOUNT ON. No isolation hint. No RETURN statement. Simple two-table SELECT with no parameters.
- Returns approximately 42,000+ rows (all aligned Trustly bank classifications).

### 2.2 Bank Classification Context

**What**: The tiers reflect payment processing bank integration quality for Trustly routing decisions.

**Rules**:
- **ClassificationID 1 (Basic)**: Default tier - standard processing, no specific optimization.
- **ClassificationID 2 (Evaluation)**: Under active assessment - transaction patterns being monitored.
- **ClassificationID 3 (Optimised)**: Fully tuned integration - highest reliability, may receive routing preference.
- All 42,721 rows are for FundingTypeID=35 (Trustly) only. Germany and UK are dominant countries.
- BankID is always 0 in practice (replaced by BankIDStr string identifier in Dec 2020 per PAYIL-1279 migration).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return columns**:

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | ID | INT | CODE-BACKED | PK of Billing.BankClassification row. IDENTITY. |
| R2 | CountryID | INT | CODE-BACKED | Country this classification applies to. FK to Dictionary.Country. |
| R3 | FundingTypeID | INT | CODE-BACKED | Payment method type. Always 35 (Trustly) in current data. FK to Dictionary.FundingType. |
| R4 | BankID | INT | CODE-BACKED | Legacy integer bank ID. Always 0 since BankIDStr replaced it in Dec 2020. |
| R5 | BankName | NVARCHAR | CODE-BACKED | Display name of the bank. Used for human identification. |
| R6 | ClassificationID | INT | CODE-BACKED | Standard bank tier: 1=Basic, 2=Evaluation, 3=Optimised. FK to Dictionary.BankClassification. |
| R7 | EtoroClassificationID | INT | CODE-BACKED | eToro's routing-preference tier for this bank. Same value as ClassificationID in all returned rows (filtered by JOIN condition). |
| R8 | ClassificationName | NVARCHAR | CODE-BACKED | Human-readable tier name from Dictionary.BankClassification. Values: Basic, Evaluation, Optimised. |
| R9 | EtoroClassificationName | NVARCHAR | CODE-BACKED | Always identical to ClassificationName because both are sourced from the same DBC row via the equality JOIN condition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BBC | Billing.BankClassification | Reader | Source of bank-to-tier mapping rows (42K+ rows, all Trustly) |
| DBC | Dictionary.BankClassification | Reader | Provides ClassificationName for tiers where ClassificationID = EtoroClassificationID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin/reporting tools | External | Caller | Full export of bank tier assignments for data analysis and routing configuration review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAllBankClassifications (procedure)
├── Billing.BankClassification (table)
└── Dictionary.BankClassification (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BankClassification | Table | Main source: all bank-to-tier mapping rows |
| Dictionary.BankClassification | Table (cross-schema) | JOIN: provides ClassificationName for aligned tiers |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin/reporting tools | External | Full bank classification export |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON. No isolation hint (read committed). No RETURN. No parameters - always returns full dataset. JOIN condition enforces ClassificationID = EtoroClassificationID - banks with divergent tiers are excluded. EtoroClassificationName column is always identical to ClassificationName (consequence of the JOIN design).

---

## 8. Sample Queries

### 8.1 Get all bank classifications

```sql
EXEC [Billing].[GetAllBankClassifications];
-- Returns ~42K+ rows with ClassificationName = EtoroClassificationName always
```

### 8.2 See only Optimised-tier banks in a specific country

```sql
SELECT BBC.BankName, BBC.BankIDStr, BBC.CountryID, DBC.ClassificationName
FROM [Billing].[BankClassification] AS BBC
INNER JOIN [Dictionary].[BankClassification] AS DBC
    ON BBC.ClassificationID = DBC.ClassificationID
    AND BBC.EtoroClassificationID = DBC.ClassificationID
WHERE BBC.CountryID = 79  -- e.g., Germany
  AND DBC.ClassificationName = 'Optimised';
```

### 8.3 Find banks with DIVERGENT classifications (excluded by GetAllBankClassifications)

```sql
SELECT BBC.*
FROM [Billing].[BankClassification] AS BBC
WHERE BBC.ClassificationID <> BBC.EtoroClassificationID;
-- These rows are filtered OUT by the JOIN condition in GetAllBankClassifications
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-1279 (Jun 2020) | Jira (code comment) | Procedure created as part of BankClassification system introduction |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAllBankClassifications | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAllBankClassifications.sql*
