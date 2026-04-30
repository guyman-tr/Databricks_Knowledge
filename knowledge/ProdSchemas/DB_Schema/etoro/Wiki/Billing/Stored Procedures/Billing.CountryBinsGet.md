# Billing.CountryBinsGet

> Returns BIN (Bank Identification Number) metadata from `Dictionary.CountryBin` for a caller-specified comma-separated list of BIN codes; companion to `Billing.CountryBinsByRangeGet` for targeted multi-BIN lookup.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCodes (comma-separated BIN code list) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CountryBinsGet` retrieves card BIN (Bank Identification Number) metadata for a specific set of BIN codes supplied by the caller as a comma-separated string. It is the targeted lookup counterpart to `Billing.CountryBinsByRangeGet` which queries by range. When a payment service knows exactly which BIN codes it needs to inspect (e.g., from a card number prefix already on hand), this procedure provides an efficient list-based query via `STRING_SPLIT`.

BIN metadata drives card routing decisions: 3DS authentication requirements, prepaid card restrictions, AFT/CFT push-to-card eligibility, and domestic vs cross-border transfer permissions. This procedure is used during payment initiation or routing rule evaluation when the specific card BINs are already known.

---

## 2. Business Logic

### 2.1 Comma-Separated BIN Code Lookup via STRING_SPLIT

**What**: The procedure parses the `@BinCodes` VARCHAR parameter using `STRING_SPLIT` and joins the resulting values against `Dictionary.CountryBin.BinCode` to return metadata for exactly the requested BINs.

**Parameters Involved**: `@BinCodes`

**Rules**:
- `@BinCodes` must be a comma-separated string of integer BIN codes, e.g., `'400000,411111,521234'`
- Uses `INNER JOIN STRING_SPLIT(@BinCodes, ',') a ON (c.BinCode = a.value)` - only BINs present in both the input and the BIN table are returned
- BIN codes not found in `Dictionary.CountryBin` are silently omitted (INNER JOIN)
- No range swap logic needed (unlike `CountryBinsByRangeGet`) - exact match semantics

**Diagram**:
```
Input: @BinCodes = '400000,411111,521234'

STRING_SPLIT -> ['400000', '411111', '521234']

INNER JOIN Dictionary.CountryBin ON BinCode = value
  -> Returns rows for each BIN code that exists in the table
  -> BINs not in Dictionary.CountryBin are silently excluded
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCodes | VARCHAR(4000) | NO | - | CODE-BACKED | Comma-separated list of integer BIN codes to look up. Maximum 4000 characters (~400-600 BIN codes per call given typical 6-8 digit codes). Example: `'400000,411111,521234'`. Values that do not match `Dictionary.CountryBin.BinCode` are silently excluded from the result. |

**Result set columns** (from `Dictionary.CountryBin`):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CountryID | Dictionary.CountryBin | Country of the issuing bank. References Dictionary.Country. |
| 2 | BinCode | Dictionary.CountryBin | The matched BIN code. Primary identifier. |
| 3 | IssuingBank | Dictionary.CountryBin | Name of the bank that issued cards with this BIN. |
| 4 | CardTypeID | Dictionary.CountryBin | Card network type (Visa/Mastercard/Amex/etc.). References Dictionary.CardType. |
| 5 | CardSubType | Dictionary.CountryBin | Subcategory of the card (e.g., Classic, Gold, Platinum, Business). |
| 6 | CardCategory | Dictionary.CountryBin | Commercial category of the card (e.g., Consumer, Corporate, Prepaid). |
| 7 | BankWebSite | Dictionary.CountryBin | Website URL of the issuing bank. |
| 8 | BankInfo | Dictionary.CountryBin | Additional bank information text. |
| 9 | ShouldCheck3ds | Dictionary.CountryBin | Whether 3D Secure authentication should be performed: 1=required. |
| 10 | MinAmountFor3ds | Dictionary.CountryBin | Minimum transaction amount at which 3DS is triggered. |
| 11 | IsPrepaid | Dictionary.CountryBin | Whether the card is a prepaid card: 1=prepaid. |
| 12 | ChallengeIndicator3DS | Dictionary.CountryBin | 3DS challenge indicator code (e.g., 01=no preference, 04=challenge requested). |
| 13 | SupportsAFT | Dictionary.CountryBin | Whether the card supports Automated Funds Transfer for push-to-card payouts: 1=supported. |
| 14 | IsCFT | Dictionary.CountryBin | Whether the card supports Card Funds Transfer (CFT): 1=supported. Added 23/10/2023. |
| 15 | DomesticMoneyTransfer | Dictionary.CountryBin | Whether domestic (same-country) money transfers are permitted: 1=allowed. Added 30/01/2024. |
| 16 | CrossBorderMoneyTransfer | Dictionary.CountryBin | Whether cross-border (international) transfers are permitted: 1=allowed. Added 30/01/2024. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query source) | Dictionary.CountryBin | Read | View combining CountryBin6 and CountryBin8; joined via STRING_SPLIT on BinCode |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Card routing and compliance services | @BinCodes | Caller | Used when specific BIN codes are already known and targeted metadata retrieval is needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CountryBinsGet (procedure)
+-- Dictionary.CountryBin (view) [query source via STRING_SPLIT JOIN]
      +-- Dictionary.CountryBin6 (table) [6-digit BIN data]
      +-- Dictionary.CountryBin8 (table) [8-digit BIN data]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | View | INNER JOIN source - BIN metadata for each requested code |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing SP layer. | - | Called by application services directly. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Comparison with CountryBinsByRangeGet**:
- `CountryBinsByRangeGet`: range query (BETWEEN), auto-swap, best for prefix-range scans
- `CountryBinsGet`: list query (STRING_SPLIT + INNER JOIN), best for known specific BINs
- Both return the same 16 columns (column order slightly different: CountryBinsGet has DomesticMoneyTransfer before CrossBorderMoneyTransfer)

---

## 8. Sample Queries

### 8.1 Look up metadata for specific known BIN codes

```sql
EXEC Billing.CountryBinsGet
    @BinCodes = '400000,411111,521234,541333'
```

### 8.2 Check AFT/CFT support for multiple card BINs

```sql
-- Use result to determine push-to-card eligibility
EXEC Billing.CountryBinsGet @BinCodes = '400000,521234,677727'
-- Inspect SupportsAFT, IsCFT columns to determine payout eligibility
```

### 8.3 Direct equivalent query on Dictionary.CountryBin

```sql
SELECT
    c.CountryID, c.BinCode, c.IssuingBank, c.CardTypeID,
    c.IsPrepaid, c.ShouldCheck3ds, c.SupportsAFT, c.IsCFT,
    c.DomesticMoneyTransfer, c.CrossBorderMoneyTransfer
FROM Dictionary.CountryBin c WITH (NOLOCK)
INNER JOIN STRING_SPLIT('400000,411111,521234', ',') a ON c.BinCode = a.value
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Funding Service changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/8646099006/Funding+Service+changes) | Confluence | IsCFT, DomesticMoneyTransfer, CrossBorderMoneyTransfer columns added in 2023-2024 BIN enrichment updates |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CountryBinsGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CountryBinsGet.sql*
