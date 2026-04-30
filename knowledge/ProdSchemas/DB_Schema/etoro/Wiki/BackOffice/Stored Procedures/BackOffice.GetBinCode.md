# BackOffice.GetBinCode

> Looks up a single payment card BIN (Bank Identification Number) record from Dictionary.CountryBin, returning the full BIN metadata row used for card type and country identification during cashout processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode - card BIN; returns zero or one row from Dictionary.CountryBin |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetBinCode` is a simple BIN lookup procedure: given a card BIN code (typically the first 6-8 digits of a payment card number), it returns all metadata from `Dictionary.CountryBin` for that BIN. This data includes the issuing country, card category (Debit, Credit, Prepaid), card brand, and other attributes used to validate and route cashout requests.

BIN (Bank Identification Number) lookup is used in the cashout workflow to determine:
- Whether the card supports a particular cashout method
- The issuing country (for regulatory compliance checks)
- The card category (some cashout types are only available for debit cards, not prepaid)

The `TOP(1)` guard exists because BIN code assignments can theoretically overlap (though rare in practice) - it ensures a single row response regardless. The `SELECT *` pattern means the result set schema depends on `Dictionary.CountryBin`'s column list.

Note: `GetCashActivities` also reads CountryBin directly via XML extraction from FundingData, joining `LEFT JOIN Dictionary.CountryBin AS DCB ON DCB.BinCode = FundingData.value('...')`. This procedure provides a direct lookup path for when only the BIN string is known.

---

## 2. Business Logic

### 2.1 TOP(1) BIN Lookup

**What**: Returns at most one row for the given BIN code from the central BIN registry.

**Columns/Parameters Involved**: `@BinCode`, `Dictionary.CountryBin.BinCode`

**Rules**:
- WHERE BinCode = @BinCode - exact string match (NVARCHAR(50) comparison, case-insensitive by default collation).
- TOP(1) guards against duplicate BIN entries; deterministic row selection depends on the table's clustered index order.
- Returns zero rows if the BIN is not in the registry (unrecognized card BIN).
- No NOLOCK - reads the live BIN registry without read isolation hint.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | NVARCHAR(50) | NO | - | CODE-BACKED | Card Bank Identification Number. Typically first 6-8 digits of the payment card number. Used as the lookup key into Dictionary.CountryBin. |
| 2 | (All columns from Dictionary.CountryBin) | Various | Various | - | CODE-BACKED | Full row from Dictionary.CountryBin for the matching BIN. Includes CountryID (issuing country), CardCategory (Debit/Credit/Prepaid), BIN range metadata, card brand. Schema is determined by Dictionary.CountryBin column list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Dictionary.CountryBin | Primary source (cross-schema) | Looks up BIN code metadata for card identification. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by BackOffice cashout management services. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetBinCode (procedure)
└── Dictionary.CountryBin (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | Table (cross-schema) | Only source - BIN code registry returning card/country metadata. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by cashout management services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Dictionary.CountryBin should have an index or clustered key on BinCode for efficient lookup.

### 7.2 Constraints

SET NOCOUNT ON. SELECT * - schema is dynamic based on Dictionary.CountryBin column list. TOP(1) guard. No NOLOCK. Three-part name: `[etoro].[Dictionary].[CountryBin]` (fully qualified with database name - ensures correct database context even if default DB changes).

---

## 8. Sample Queries

### 8.1 Look up a specific BIN
```sql
EXEC BackOffice.GetBinCode @BinCode = N'411111';
```

### 8.2 Inline equivalent
```sql
SELECT TOP 1 *
FROM Dictionary.CountryBin
WHERE BinCode = N'411111';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetBinCode | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetBinCode.sql*
