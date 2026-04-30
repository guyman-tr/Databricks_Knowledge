# Dictionary.BankBin

> Mapping table linking bank BIN (Bank Identification Number) codes to internal bank identifiers, enabling card-issuer identification for deposit routing and fraud detection.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | BankID + BinCode (composite PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 1 (MCP verified — nearly empty) |
| **Indexes** | 2 active (PK + NC on BinCode) |

---

## 1. Business Meaning

Dictionary.BankBin maps credit card BIN codes (the first 6 digits of a card number that identify the issuing bank) to eToro's internal bank identifiers (Dictionary.Bank). This mapping enables the platform to identify which bank issued a customer's card during deposit processing.

This table appears to be largely superseded by the much more comprehensive Dictionary.CountryBin6 (324K rows) and Dictionary.CountryBin8 (16M rows) tables that map BIN codes to countries. The BankBin table contains only 1 row in production, suggesting it was the original BIN-to-bank mapping mechanism before the country-level BIN tables were introduced.

Referenced by Billing.GetTerminalWithBankBinCode (a view that resolves BIN codes to bank details for terminal routing). The FK to Dictionary.Bank ensures referential integrity between BIN codes and the bank registry.

---

## 2. Business Logic

### 2.1 BIN-to-Bank Resolution

**What**: Mapping card BIN codes to internal bank identifiers for payment routing.

**Columns/Parameters Involved**: `BankID`, `BinCode`, `Comment`

**Rules**:
- A BIN code is the first 6 digits of a credit/debit card number
- Each BIN code maps to exactly one bank (the issuing bank)
- A bank can have multiple BIN codes (different card products from the same bank)
- The composite PK (BankID, BinCode) allows one-to-many bank-to-BIN relationships
- The NC index on BinCode enables efficient lookups by card number prefix
- Largely replaced by Dictionary.CountryBin6/CountryBin8 for country-level BIN resolution

---

## 3. Data Overview

| BankID | BinCode | Comment | Meaning |
|---|---|---|---|
| 10 | 462252 | (null) | Maps BIN prefix 462252 to internal bank ID 10. This is the only mapping currently in production — the table is effectively deprecated in favor of the CountryBin tables. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | int | NO | - | VERIFIED | FK to Dictionary.Bank.BankID. Identifies the issuing bank for this BIN code. Part of composite PK. |
| 2 | BinCode | int | NO | - | VERIFIED | The 6-digit BIN (Bank Identification Number) prefix from the card number. Part of composite PK. Also has a dedicated NC index (DBNB_BINCODE) for efficient lookups by BIN during deposit processing. |
| 3 | Comment | varchar(50) | YES | - | CODE-BACKED | Optional annotation explaining the BIN-to-bank mapping. Currently NULL for the single production row. May contain notes about card product types or special routing instructions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | Explicit FK (FK_DBNK_DBNB) | Identifies the issuing bank for this BIN code |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetTerminalWithBankBinCode | BinCode | View JOIN | Resolves BIN codes to bank details for terminal routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.BankBin (table)
└── Dictionary.Bank (table) — FK target for BankID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FK — BankID references Bank.BankID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetTerminalWithBankBinCode | View | JOINs to resolve BIN codes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DBNB | CLUSTERED PK | BankID ASC, BinCode ASC | - | - | Active (FILLFACTOR 90) |
| DBNB_BINCODE | NC | BinCode ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DBNB | PRIMARY KEY (composite) | Unique bank + BIN combination |
| FK_DBNK_DBNB | FOREIGN KEY | BankID → Dictionary.Bank(BankID) |

---

## 8. Sample Queries

### 8.1 List all BIN-to-bank mappings
```sql
SELECT  bb.BankID,
        b.BankName,
        bb.BinCode,
        bb.Comment
FROM    Dictionary.BankBin bb WITH (NOLOCK)
JOIN    Dictionary.Bank b WITH (NOLOCK)
        ON bb.BankID = b.BankID
ORDER BY bb.BankID, bb.BinCode;
```

### 8.2 Look up bank by BIN code
```sql
SELECT  b.BankName,
        bb.BinCode
FROM    Dictionary.BankBin bb WITH (NOLOCK)
JOIN    Dictionary.Bank b WITH (NOLOCK)
        ON bb.BankID = b.BankID
WHERE   bb.BinCode = 462252;
```

### 8.3 Compare with CountryBin6 coverage
```sql
SELECT  'BankBin' AS Source, COUNT(*) AS Rows
FROM    Dictionary.BankBin WITH (NOLOCK)
UNION ALL
SELECT  'CountryBin6', COUNT(*)
FROM    Dictionary.CountryBin6 WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BankBin | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BankBin.sql*
