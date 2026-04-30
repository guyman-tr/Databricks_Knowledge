# dbo.KypCorporateMembersTableType

> Table-valued parameter type for passing corporate member details during KYP (Know Your Partner) compliance onboarding of corporate affiliate accounts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Index (INT, no PK) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table type supports the KYP (Know Your Partner) compliance process for corporate affiliates. When a corporate entity registers as an affiliate, regulatory requirements mandate collecting details about key corporate members (directors, officers, beneficial owners). This type allows a stored procedure to receive the full list of corporate members in a single parameter.

The Latin1_General_BIN collation on FullName and Position columns indicates case-sensitive, binary comparison - important for compliance documentation where exact name matching matters.

No active stored procedure consumers were found in the current dbo schema. This type is likely used by procedures in other schemas (e.g., Affiliate or AffiliateAdmin) for KYP compliance workflows.

---

## 2. Business Logic

### 2.1 KYP Corporate Compliance Data

**What**: Structured data for regulatory Know Your Partner documentation of corporate affiliate entities.

**Columns/Parameters Involved**: `Index`, `FullName`, `Position`

**Rules**:
- Each row represents one key person in the corporate affiliate entity (director, officer, beneficial owner)
- The Index column provides ordering for UI display and document generation
- FullName must match the official corporate registration documents exactly (binary collation enforces this)
- Position describes their role in the corporate structure (e.g., "Director", "CEO", "Beneficial Owner")

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Index | int | NO | - | CODE-BACKED | Ordinal position of the corporate member in the list. Used for display ordering in compliance forms and PDF generation. |
| 2 | FullName | nvarchar(100) | NO | - | CODE-BACKED | Full legal name of the corporate member as it appears on official documents. Latin1_General_BIN collation ensures exact case-sensitive matching for compliance verification. |
| 3 | Position | nvarchar(50) | NO | - | CODE-BACKED | Role/title of the person within the corporate entity (e.g., "Director", "CEO", "Beneficial Owner", "Secretary"). Latin1_General_BIN collation for exact matching. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for a corporate affiliate
```sql
DECLARE @members dbo.KypCorporateMembersTableType
INSERT INTO @members ([Index], FullName, Position)
VALUES (1, 'John Smith', 'Director'),
       (2, 'Jane Doe', 'CEO'),
       (3, 'Bob Johnson', 'Beneficial Owner')
```

### 8.2 Select from the populated type
```sql
DECLARE @members dbo.KypCorporateMembersTableType
INSERT INTO @members ([Index], FullName, Position)
VALUES (1, 'John Smith', 'Director')
SELECT * FROM @members ORDER BY [Index]
```

### 8.3 Join with affiliate data
```sql
DECLARE @members dbo.KypCorporateMembersTableType
INSERT INTO @members ([Index], FullName, Position)
VALUES (1, 'John Smith', 'Director')
-- Used as parameter to KYP onboarding procedures
SELECT [Index], FullName, Position FROM @members
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.KypCorporateMembersTableType | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.KypCorporateMembersTableType.sql*
