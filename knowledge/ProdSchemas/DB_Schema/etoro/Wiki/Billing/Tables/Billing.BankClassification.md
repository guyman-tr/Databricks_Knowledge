# Billing.BankClassification

> Bank-to-classification tier mapping for Trustly (online banking) payment routing, assigning each bank in each country both a standard classification and an eToro-specific override classification to guide deposit processing decisions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Billing.BankClassification` stores per-bank quality tier assignments for countries and funding types, used to guide Trustly payment routing. Each row maps a specific bank (identified by BankName and BankIDStr) within a country to a classification tier: Basic (1), Evaluation (2), or Optimised (3). The classification reflects how well that bank's integration performs for eToro's deposit and withdrawal flows.

The table currently contains 42,721 rows all for FundingTypeID=35 (Trustly), with Germany and UK as the dominant country coverage. The dual classification design (ClassificationID and EtoroClassificationID) allows storing both the bank's standard tier and eToro's independent assessment separately, enabling routing decisions that may prefer one over the other.

Data enters via `Billing.InsertBankClassification` (upsert by CountryID + FundingTypeID + BankIDStr). It is queried by `Billing.GetBankClassifications` (filtered lookup for a specific country + funding type) and `Billing.GetAllBankClassifications` (full export). The table was created in August 2020 (PAYIL-1279), with BankIDStr replacing the integer BankID in December 2020 to accommodate Trustly's string-based bank identifiers.

---

## 2. Business Logic

### 2.1 Dual Classification System

**What**: Each bank row holds two independent tier assignments - one standard and one eToro-specific.

**Columns/Parameters Involved**: `ClassificationID`, `EtoroClassificationID`

**Rules**:
- `ClassificationID` stores the bank's tier from the standard/provider-facing perspective (1=Basic, 2=Evaluation, 3=Optimised per Dictionary.BankClassification).
- `EtoroClassificationID` stores eToro's own routing-preference tier for the same bank, using the same lookup values.
- `Billing.GetBankClassifications` JOINs Dictionary.BankClassification with condition `BBC.ClassificationID = DBC.ClassificationID AND BBC.EtoroClassificationID = DBC.ClassificationID`, meaning it only returns banks where both tiers agree. Banks with divergent tiers are excluded from standard routing queries.
- Both columns reference the same Dictionary.BankClassification lookup (ClassificationID 1=Basic, 2=Evaluation, 3=Optimised).

**Diagram**:
```
Bank row
  ClassificationID (standard tier) -----> Dictionary.BankClassification
  EtoroClassificationID (eToro tier) ---> Dictionary.BankClassification

GetBankClassifications returns rows only when:
  ClassificationID == EtoroClassificationID
```

### 2.2 BankIDStr Upsert Key (Replaced BankID)

**What**: The combination of CountryID + FundingTypeID + BankIDStr is the natural unique key for inserts.

**Columns/Parameters Involved**: `CountryID`, `FundingTypeID`, `BankIDStr`, `BankID`

**Rules**:
- `Billing.InsertBankClassification` checks for existence using `WHERE CountryID=@CountryID AND FundingTypeID=@FundingTypeID AND BankIDStr=@BankIDStr` before inserting.
- BankIDStr (string identifier) replaced the integer BankID in December 2020 to support Trustly's string-based bank codes. BankID is now always 0 in practice.
- BankIDStr default is '0' (matches the old BankID default of 0), so legacy rows inserted before the change continue to be findable.

---

## 3. Data Overview

| ID | CountryID | BankName | ClassificationID | EtoroClassificationID | Meaning |
|----|-----------|----------|------------------|-----------------------|---------|
| 1 | 13 (Austria) | Bank Austria | 1 (Basic) | 1 (Basic) | Austrian bank with default Basic tier - new or unoptimized Trustly integration. Both standard and eToro tiers agree. |
| 4 | 13 (Austria) | Erste Bank and Sparkasse George | 3 (Optimised) | 3 (Optimised) | Austrian bank with the highest tier - Trustly integration fully tested and preferred for routing. |
| 5 | 19 (Belgium) | Argenta (Argenta Banque d'Epargne, ASPA) | 2 (Evaluation) | 2 (Evaluation) | Belgian bank under active evaluation - transaction patterns being monitored before promotion to Optimised. |
| - | 79 (Germany) | (various, 26,786 rows) | mixed | mixed | Germany is the single largest country block, reflecting Trustly's dominance in German online banking. |
| - | 218 (UK) | (various, 15,806 rows) | mixed | mixed | UK is the second largest country block, reflecting significant Trustly adoption for GBP deposits. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate primary key. Has no business meaning beyond row identification. Referenced by no other table - purely internal. |
| 2 | CountryID | int | NO | - | VERIFIED | Country where this bank operates. FK to Dictionary.Country (CountryID). Dominant values: 79=Germany (26,786 rows), 218=United Kingdom (15,806 rows). Used as a filter key in GetBankClassifications to return only banks relevant to the customer's country. |
| 3 | FundingTypeID | int | NO | - | VERIFIED | Payment method type for which this bank classification applies. Implicit FK to Dictionary.FundingType. Currently always 35 (Trustly) - this table is exclusively used for Trustly online banking payments. Used as a filter key in GetBankClassifications alongside CountryID. |
| 4 | BankID | int | YES | - | CODE-BACKED | Legacy integer bank identifier. Always 0 in current data - replaced by BankIDStr in December 2020 (PAYIL-1279). Retained for schema compatibility. Do not use for new queries; use BankIDStr instead. |
| 5 | BankName | nvarchar(100) | NO | - | CODE-BACKED | Display name of the bank as it appears in the Trustly bank selection interface (e.g., "Bank Austria", "Erste Bank and Sparkasse George"). Used for human-readable output in GetBankClassifications and GetAllBankClassifications. Not a system identifier - BankIDStr is the machine key. |
| 6 | ClassificationID | int | NO | - | VERIFIED | Standard bank classification tier. FK to Dictionary.BankClassification (ClassificationID). Values: 1=Basic (new/unoptimized, 29% of rows), 2=Evaluation (under assessment, 36%), 3=Optimised (fully tuned, 35%). Used in routing decisions via GetBankClassifications JOIN condition. See Dictionary.BankClassification for full tier definitions. |
| 7 | EtoroClassificationID | int | NO | - | VERIFIED | eToro's independent classification tier for this bank, stored separately from the standard ClassificationID. FK to Dictionary.BankClassification (same lookup, same values 1-3). Allows eToro to assign a different tier than the standard classification. In practice, GetBankClassifications requires this to equal ClassificationID to return the row. |
| 8 | BankIDStr | nvarchar(100) | NO | '0' | VERIFIED | String identifier for the bank within Trustly's system (e.g., a Trustly bank code or provider-assigned identifier). Replaced the integer BankID in December 2020 to support Trustly's string-based bank codes. Part of the upsert uniqueness key: (CountryID + FundingTypeID + BankIDStr). Default '0' preserves compatibility with pre-Dec-2020 rows where BankID was 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | FK (explicit) | Identifies the country where the bank operates. Constrains entries to valid eToro country records. |
| FundingTypeID | Dictionary.FundingType | Implicit | Identifies the payment method (always Trustly=35). No DDL FK constraint but enforced by InsertBankClassification parameter. |
| ClassificationID | Dictionary.BankClassification | FK (explicit) | Bank's standard quality tier (1=Basic, 2=Evaluation, 3=Optimised). |
| EtoroClassificationID | Dictionary.BankClassification | FK (explicit) | eToro's own quality tier for the bank, using the same 3-tier classification lookup. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.InsertBankClassification | CountryID, FundingTypeID, BankIDStr | WRITER | Creates/upserts bank classification entries. Main data entry point. |
| Billing.GetBankClassifications | CountryID, FundingTypeID | READER | Returns classified banks for a specific country + funding type. Used in routing. |
| Billing.GetAllBankClassifications | (all columns) | READER | Returns all bank classifications; used for bulk exports and admin. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BankClassification (table)
|- Dictionary.BankClassification (table) [FK: ClassificationID]
|- Dictionary.BankClassification (table) [FK: EtoroClassificationID]
|- Dictionary.Country (table)             [FK: CountryID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BankClassification | Table | FK target for ClassificationID and EtoroClassificationID - defines the 3 tier values |
| Dictionary.Country | Table | FK target for CountryID - constrains to valid country records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.InsertBankClassification | Stored Procedure | WRITER - upserts rows keyed on CountryID + FundingTypeID + BankIDStr |
| Billing.GetBankClassifications | Stored Procedure | READER - filtered by CountryID + FundingTypeID; JOINs to Dict.BankClassification for tier names |
| Billing.GetAllBankClassifications | Stored Procedure | READER - full table scan with Dict.BankClassification JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | ID ASC | - | - | Active (PAD_INDEX OFF, FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK on ClassificationID | FOREIGN KEY | ClassificationID must exist in Dictionary.BankClassification(ClassificationID). WITH CHECK enforced at data entry. |
| FK on CountryID | FOREIGN KEY | CountryID must exist in Dictionary.Country(CountryID). WITH CHECK enforced at data entry. |
| FK on EtoroClassificationID | FOREIGN KEY | EtoroClassificationID must exist in Dictionary.BankClassification(ClassificationID). WITH CHECK enforced at data entry. |
| DEFAULT on BankIDStr | DEFAULT | BankIDStr defaults to '0' for backwards compatibility with pre-Dec-2020 rows. |

---

## 8. Sample Queries

### 8.1 Get bank classifications for Trustly deposits in Germany
```sql
SELECT  BC.ID,
        BC.BankName,
        BC.BankIDStr,
        DBC.ClassificationName      AS StandardTier,
        DBC.ClassificationName      AS EtoroTier
FROM    Billing.BankClassification BC WITH (NOLOCK)
INNER JOIN Dictionary.BankClassification DBC WITH (NOLOCK)
        ON BC.ClassificationID = DBC.ClassificationID
        AND BC.EtoroClassificationID = DBC.ClassificationID
WHERE   BC.CountryID = 79           -- Germany
        AND BC.FundingTypeID = 35   -- Trustly
ORDER BY DBC.ClassificationName, BC.BankName;
```

### 8.2 Count banks per classification tier and country
```sql
SELECT  DC.Name                     AS Country,
        DBC.ClassificationName      AS Tier,
        COUNT(*)                    AS BankCount
FROM    Billing.BankClassification BC WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON BC.CountryID = DC.CountryID
INNER JOIN Dictionary.BankClassification DBC WITH (NOLOCK)
        ON BC.ClassificationID = DBC.ClassificationID
GROUP BY DC.Name, DBC.ClassificationName
ORDER BY DC.Name, DBC.ClassificationID;
```

### 8.3 Find all banks with divergent standard vs eToro classifications
```sql
SELECT  BC.*,
        DBC1.ClassificationName     AS StandardTier,
        DBC2.ClassificationName     AS EtoroTier
FROM    Billing.BankClassification BC WITH (NOLOCK)
INNER JOIN Dictionary.BankClassification DBC1 WITH (NOLOCK)
        ON BC.ClassificationID = DBC1.ClassificationID
INNER JOIN Dictionary.BankClassification DBC2 WITH (NOLOCK)
        ON BC.EtoroClassificationID = DBC2.ClassificationID
WHERE   BC.ClassificationID <> BC.EtoroClassificationID
ORDER BY BC.CountryID, BC.BankName;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit Finalize Steps Current](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/2212135001) | Confluence | Mentions BankClassification in deposit finalization flow context (MEDIUM - general deposit flow, not specific to this table) |

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BankClassification | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.BankClassification.sql*
