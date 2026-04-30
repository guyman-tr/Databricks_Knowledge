# Billing.InsertBankClassification

> Inserts a new bank-to-classification tier mapping into Billing.BankClassification if one does not already exist for the given country, funding type, and bank identifier combination.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Billing.BankClassification (CountryID + FundingTypeID + BankIDStr = unique key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.InsertBankClassification` is the write entry point for the Trustly bank classification system. It adds a single row to `Billing.BankClassification`, which stores the quality tier (Basic/Evaluation/Optimised) assigned to each bank in each country for Trustly (FundingTypeID=35) payment routing. When operations teams need to onboard a new bank or expand Trustly coverage to a new country, they call this procedure with the bank's identity and tier assignment.

The procedure protects data integrity by performing a conditional insert: if a row already exists for the same `CountryID + FundingTypeID + BankIDStr` triple, no action is taken and no error is raised. This allows safe re-running of onboarding scripts without fear of duplicate entries.

Data flows: during Trustly country or bank expansions, operations engineers run SQL scripts that call this procedure once per bank, following the process documented in the Trustly Changes Confluence page (PAYIL-1350). Initial data load at launch inserted ~150 bank rows across 17 European countries. Subsequent calls add incremental bank coverage. The resulting rows are then consumed by `Billing.GetBankClassifications` to route Trustly deposit requests to the appropriate tier handling.

---

## 2. Business Logic

### 2.1 Insert-If-Not-Exists Deduplication

**What**: The procedure uses an existence check before inserting to prevent duplicate bank classification records.

**Columns/Parameters Involved**: `@CountryID`, `@FundingTypeID`, `@BankIDStr`

**Rules**:
- Uniqueness key is the triple (CountryID, FundingTypeID, BankIDStr) - NOT (CountryID, FundingTypeID, BankID)
- `@BankIDStr` defaults to N'0' (string zero), matching the default `@BankID INT = 0`; the BankIDStr key replaced the integer BankID key in December 2020 (per code comment: "Use BankIDStr instead of BankID") to accommodate Trustly's string-based bank identifiers
- `@BankID` is now a legacy parameter retained for backward compatibility; its default is 0 and it is always stored but NOT used as part of the uniqueness check
- If the record already exists, the procedure returns silently (no error, no rows affected)
- If not exists, it inserts one row with all seven column values

**Diagram**:
```
CALL InsertBankClassification(@CountryID, @FundingTypeID, @BankIDStr, ...)
    |
    v
IF NOT EXISTS (SELECT ID FROM BankClassification
               WHERE CountryID=@CountryID AND FundingTypeID=@FundingTypeID
                     AND BankIDStr=@BankIDStr)
    |
    +-- EXISTS -> return (no-op)
    |
    +-- NOT EXISTS -> INSERT row with all 7 columns
```

### 2.2 Dual Classification Assignment

**What**: Each bank row receives two independent tier assignments - a standard classification and an eToro-specific override.

**Columns/Parameters Involved**: `@ClassificationID`, `@EtoroClassificationID`

**Rules**:
- Both reference `Dictionary.BankClassification`: 1=Basic, 2=Evaluation, 3=Optimised
- Both values are stored independently; they may agree or differ for the same bank
- `Billing.GetBankClassifications` only returns banks where `ClassificationID = EtoroClassificationID` - diverging tiers effectively exclude the bank from standard routing queries
- Most banks at Trustly launch were inserted with matching values (ClassificationID = EtoroClassificationID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | Dictionary.Country reference for the country where this bank operates. E.g., 218=United Kingdom, 79=Germany, 143=Netherlands. Determines in which country this bank classification applies for Trustly routing. |
| 2 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. In practice always 35 (Trustly) for all current data - this is the only funding type that uses the bank classification system. Stored in the row and used as part of the uniqueness check. |
| 3 | @BankID | INT | YES | 0 | CODE-BACKED | Legacy integer bank identifier, now always 0. Replaced by @BankIDStr in December 2020 to support Trustly's string-format bank IDs. Stored in the row but not used in the uniqueness check. Retained for backward compatibility. |
| 4 | @BankName | NVARCHAR(500) | NO | - | CODE-BACKED | Human-readable bank name as provided by Trustly (e.g., 'Barclays', 'ING', 'Nordea'). Stored for display and reference purposes. Not part of the uniqueness check - the same bank name could appear under different BankIDStr values. |
| 5 | @ClassificationID | INT | NO | - | CODE-BACKED | Standard tier assignment for this bank from the provider perspective: 1=Basic, 2=Evaluation, 3=Optimised (Dictionary.BankClassification). Determines the bank's standard quality tier for Trustly routing. |
| 6 | @EtoroClassificationID | INT | NO | - | CODE-BACKED | eToro's independent tier assignment for the same bank: 1=Basic, 2=Evaluation, 3=Optimised. May differ from ClassificationID to reflect eToro's own routing preference. Only banks where both tiers agree are returned by Billing.GetBankClassifications for standard routing. |
| 7 | @BankIDStr | NVARCHAR(100) | YES | N'0' | CODE-BACKED | Trustly string-format bank identifier (replaces the integer BankID). Forms the primary uniqueness key alongside CountryID and FundingTypeID. Default N'0' preserves backward compatibility for callers that do not supply a string ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Writes to | Billing.BankClassification | INSERT | Inserts one row per successful call; guarded by IF NOT EXISTS on (CountryID, FundingTypeID, BankIDStr) |
| @CountryID | Dictionary.Country | Implicit FK | Validates the country is in the Dictionary.Country lookup (enforced by FK on Billing.BankClassification) |
| @FundingTypeID | Dictionary.FundingType | Implicit FK | Validates the funding type (enforced by FK on Billing.BankClassification) |
| @ClassificationID | Dictionary.BankClassification | Implicit FK | Tier value must exist in Dictionary.BankClassification (1=Basic, 2=Evaluation, 3=Optimised) |
| @EtoroClassificationID | Dictionary.BankClassification | Implicit FK | Same FK as ClassificationID - eToro's independent tier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| etoro/UsersPermissions/DepositUser.sql | GRANT EXECUTE | Permission | The DepositUser database role has EXECUTE permission on this procedure - it is called during Trustly deposit onboarding flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.InsertBankClassification (procedure)
└── Billing.BankClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BankClassification | Table | Existence-checked and inserted into; the entire procedure body is an IF NOT EXISTS + INSERT on this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetBankClassifications | Stored Procedure | Reads the rows inserted by this procedure to return bank tier data for Trustly routing |
| Billing.GetAllBankClassifications | Stored Procedure | Reads all rows for export/admin purposes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Single-statement body: IF NOT EXISTS (...) INSERT INTO (...) VALUES (...)
- No explicit transaction; atomicity is at the single-statement level
- No RETURN code or OUTPUT parameter - callers cannot programmatically distinguish "inserted" from "already existed"
- Change history embedded in code comments: created 27/08/2020 by Elrom Behar; BankIDStr added 03/12/2020 replacing BankID as the key column

---

## 8. Sample Queries

### 8.1 Add a new UK bank with Optimised tier
```sql
EXEC Billing.InsertBankClassification
    @CountryID          = 218,   -- United Kingdom
    @FundingTypeID      = 35,    -- Trustly
    @BankID             = 0,
    @BankName           = N'Monzo',
    @ClassificationID   = 3,     -- Optimised
    @EtoroClassificationID = 3,  -- Optimised
    @BankIDStr          = N'monzo-uk'
```

### 8.2 Add a German bank with diverging tiers (eToro-specific downgrade)
```sql
EXEC Billing.InsertBankClassification
    @CountryID          = 79,    -- Germany
    @FundingTypeID      = 35,    -- Trustly
    @BankID             = 0,
    @BankName           = N'N26',
    @ClassificationID   = 3,     -- Standard: Optimised
    @EtoroClassificationID = 2,  -- eToro override: Evaluation
    @BankIDStr          = N'n26-de'
-- Note: this bank will NOT appear in GetBankClassifications results
-- because ClassificationID != EtoroClassificationID
```

### 8.3 Verify whether a bank was already inserted (pre-check pattern)
```sql
SELECT ID, CountryID, FundingTypeID, BankName, BankIDStr, ClassificationID, EtoroClassificationID
FROM Billing.BankClassification WITH (NOLOCK)
WHERE CountryID = 218 AND FundingTypeID = 35 AND BankIDStr = N'monzo-uk'
-- If this returns a row, InsertBankClassification will be a no-op
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trustly Changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1336312125/Trustly+Changes) | Confluence | Confirms FundingTypeID=35 for Trustly; documents initial bank classification data load and the full set of Dictionary.BankClassification values (1=Basic, 2=Evaluation, 3=Optimised); provides context that this SP was part of PAYIL-1350 Trustly launch |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 consumers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.InsertBankClassification | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.InsertBankClassification.sql*
