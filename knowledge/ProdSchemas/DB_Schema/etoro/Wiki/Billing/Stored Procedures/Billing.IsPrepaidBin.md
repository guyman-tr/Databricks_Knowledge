# Billing.IsPrepaidBin

> Returns 1 if the supplied credit card BIN (Bank Identification Number) is registered as a prepaid card in Dictionary.CountryBin, or an empty result set if not prepaid - used as a boolean prepaid card detection check during deposit processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar 1 or empty from Dictionary.CountryBin |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.IsPrepaidBin` detects whether a credit card's BIN (the first 6 digits of the card number) belongs to a prepaid card product. Prepaid cards are loaded with a fixed balance by the cardholder before use, as opposed to standard credit or debit cards linked to a bank account. Prepaid cards present elevated risk in payment processing (chargeback patterns, compliance concerns, fraudulent use) and are commonly restricted or blocked by financial platforms.

The procedure enables the deposit service to identify prepaid cards at the point of payment instrument registration or deposit initiation. If the BIN is found with IsPrepaid=1 in Dictionary.CountryBin, the caller can reject the transaction, flag it for review, or route it through alternative processing. An empty result means the BIN is not classified as prepaid (either it's a standard card, or the BIN is not in the registry).

Data flows: the calling process passes the BIN extracted from the customer's card number. The procedure performs a boolean lookup and returns a definitive prepaid status. Dictionary.CountryBin is the authoritative BIN registry, populated from card network data and periodically updated by operations teams.

---

## 2. Business Logic

### 2.1 Prepaid BIN Detection

**What**: A simple boolean lookup in the BIN registry for the combination of BinCode match and IsPrepaid=1 flag.

**Columns/Parameters Involved**: `@Bin`, `BinCode`, `IsPrepaid`

**Rules**:
- Returns `1` (literal integer, not the row data) if BinCode=@Bin AND IsPrepaid=1 exists in Dictionary.CountryBin
- Returns empty result set if the BIN is not found, or found with IsPrepaid=0 (standard card)
- SELECT TOP 1 ensures at most one row is returned even if multiple entries exist for the same BIN
- Callers interpret: row present = prepaid card, empty = not prepaid
- @Bin is an INT type; BINs are the first 6 digits of card numbers (range 100000-999999)

**Diagram**:
```
Customer submits card number -> extract first 6 digits = BIN (@Bin)
        |
        v
EXEC IsPrepaidBin @Bin = 411111
        |
        v
SELECT TOP 1 (1) FROM Dictionary.CountryBin
WHERE BinCode = @Bin AND IsPrepaid = 1
        |
        +-- Returns row (1): BIN is prepaid -> restrict/block deposit
        +-- Returns empty: BIN is not prepaid -> proceed normally
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Bin | INT | NO | - | CODE-BACKED | The Bank Identification Number to check - the first 6 digits of the credit card number (e.g., 411111 for Visa). Matched against Dictionary.CountryBin.BinCode. |

### Output Column

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | (column 1) | INT | CODE-BACKED | Literal value `1` if the BIN is classified as prepaid. Empty result set if not prepaid. Callers check for row presence rather than value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Bin lookup | Dictionary.CountryBin | READ | Queries the BIN registry for prepaid classification; filtered by BinCode and IsPrepaid=1 |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found. Called from the application deposit/payment service layer when validating a customer's credit card at registration or deposit time.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.IsPrepaidBin (procedure)
└── Dictionary.CountryBin (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | Table | Queried by BinCode (=@Bin) and IsPrepaid=1; the authoritative BIN classification registry |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `SELECT TOP 1 (1)` - returns literal 1 (not any column data) since only presence/absence matters
- No WITH (NOLOCK) hint - reads with shared lock; acceptable given Dictionary.CountryBin is a low-write reference table
- No ORDER BY with TOP 1 - non-deterministic if multiple rows match (unlikely given BinCode uniqueness expectations)

---

## 8. Sample Queries

### 8.1 Check if a BIN is prepaid
```sql
EXEC Billing.IsPrepaidBin @Bin = 411111
-- Returns 1 row if prepaid, empty if not
```

### 8.2 Direct equivalent lookup
```sql
SELECT TOP 1 1
FROM Dictionary.CountryBin WITH (NOLOCK)
WHERE BinCode = 411111
  AND IsPrepaid = 1
```

### 8.3 List all prepaid BINs in the registry
```sql
SELECT BinCode, CountryID, IsPrepaid
FROM Dictionary.CountryBin WITH (NOLOCK)
WHERE IsPrepaid = 1
ORDER BY BinCode
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.IsPrepaidBin | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.IsPrepaidBin.sql*
