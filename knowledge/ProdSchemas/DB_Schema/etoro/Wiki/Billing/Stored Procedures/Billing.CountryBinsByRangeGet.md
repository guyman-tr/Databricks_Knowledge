# Billing.CountryBinsByRangeGet

> Returns all BIN (Bank Identification Number) records from `Dictionary.CountryBin` whose BIN code falls within a numeric range, with automatic range-swap protection; used for card routing and compliance checks.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCodeFrom / @BinCodeTo (range parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CountryBinsByRangeGet` is a lookup procedure that retrieves card BIN (Bank Identification Number) metadata for all credit/debit cards whose BIN falls within a specified numeric range. A BIN is typically the first 6 or 8 digits of a card number; it identifies the issuing bank, country of issue, card type, and applicable payment rules.

The procedure is used during payment routing and compliance processes to identify card characteristics in bulk for a range of card prefixes. For example, a payment routing system might query all BINs between 400000 and 499999 to understand which Visa-prefix cards are eligible for certain processing routes, 3DS requirements, AFT/CFT fund transfer flags, and domestic vs cross-border restrictions.

The companion procedure `Billing.CountryBinsGet` serves the same purpose but accepts a comma-separated list of specific BIN codes rather than a range.

---

## 2. Business Logic

### 2.1 Auto-Swap Range Parameters

**What**: If the caller passes the range in the wrong order (BinCodeFrom > BinCodeTo), the procedure silently swaps them before querying. This prevents empty results from an inverted range.

**Parameters Involved**: `@BinCodeFrom`, `@BinCodeTo`

**Rules**:
- `IF @BinCodeFrom > @BinCodeTo`: swap using `@temp` variable
- After swap: `@BinCodeFrom <= @BinCodeTo` is guaranteed
- Query uses: `WHERE BinCode BETWEEN @BinCodeFrom AND @BinCodeTo`

**Diagram**:
```
Input: @BinCodeFrom=499999, @BinCodeTo=400000 (inverted)
  -> Swap: @BinCodeFrom=400000, @BinCodeTo=499999
  -> Query: WHERE BinCode BETWEEN 400000 AND 499999

Input: @BinCodeFrom=400000, @BinCodeTo=499999 (correct)
  -> No swap needed
  -> Query: WHERE BinCode BETWEEN 400000 AND 499999
```

### 2.2 BIN Metadata Result Set

**What**: Returns comprehensive card metadata for each matching BIN code, covering routing eligibility, security requirements, and transfer type flags.

**Key flag columns**:
- `ShouldCheck3ds` / `MinAmountFor3ds` / `ChallengeIndicator3DS`: 3D Secure authentication requirements
- `IsPrepaid`: prepaid card flag (affects chargeback risk and withdrawal eligibility)
- `SupportsAFT` / `IsCFT`: Automated Funds Transfer and Card Funds Transfer capabilities (used for push-to-card payouts)
- `DomesticMoneyTransfer` / `CrossBorderMoneyTransfer`: transfer type restrictions for local vs international

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCodeFrom | INTEGER | NO | - | CODE-BACKED | Lower bound of the BIN code range to query. Auto-swapped with @BinCodeTo if this value is larger. BIN codes are numeric prefixes (typically 6-8 digits, e.g., 400000 for the start of Visa prefix space). |
| 2 | @BinCodeTo | INTEGER | NO | - | CODE-BACKED | Upper bound of the BIN code range to query. Auto-swapped with @BinCodeFrom if smaller. Both parameters are inclusive (BETWEEN). |

**Result set columns** (from `Dictionary.CountryBin`):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CountryID | Dictionary.CountryBin | Country of the issuing bank. References Dictionary.Country. |
| 2 | BinCode | Dictionary.CountryBin | The BIN code itself (6 or 8 digits). Primary identifier. |
| 3 | IssuingBank | Dictionary.CountryBin | Name of the bank that issued cards with this BIN. |
| 4 | CardTypeID | Dictionary.CountryBin | Card network type (Visa/Mastercard/Amex/etc.). References Dictionary.CardType. |
| 5 | CardSubType | Dictionary.CountryBin | Subcategory of the card (e.g., Classic, Gold, Platinum, Business). |
| 6 | CardCategory | Dictionary.CountryBin | Commercial category of the card (e.g., Consumer, Corporate, Prepaid). |
| 7 | BankWebSite | Dictionary.CountryBin | Website URL of the issuing bank. |
| 8 | BankInfo | Dictionary.CountryBin | Additional bank information text. |
| 9 | ShouldCheck3ds | Dictionary.CountryBin | Whether 3D Secure authentication should be performed for cards with this BIN: 1=required, 0=not required. |
| 10 | MinAmountFor3ds | Dictionary.CountryBin | Minimum transaction amount (in account currency) at which 3DS is triggered. Below this amount, 3DS may be skipped. |
| 11 | IsPrepaid | Dictionary.CountryBin | Whether the card is a prepaid card: 1=prepaid. Prepaid cards may face restrictions for withdrawals and have higher fraud risk. |
| 12 | ChallengeIndicator3DS | Dictionary.CountryBin | 3DS challenge indicator code sent to the card network (e.g., 01=no preference, 04=challenge requested). Controls frictionless vs full 3DS flow. |
| 13 | SupportsAFT | Dictionary.CountryBin | Whether the card supports Automated Funds Transfer (AFT) for push-to-card payouts: 1=supported. |
| 14 | IsCFT | Dictionary.CountryBin | Whether the card supports Card Funds Transfer (CFT) for push-to-card cashout: 1=supported. Added 23/10/2023. |
| 15 | CrossBorderMoneyTransfer | Dictionary.CountryBin | Whether cross-border (international) money transfers are permitted for this BIN: 1=allowed. Added 30/01/2024. |
| 16 | DomesticMoneyTransfer | Dictionary.CountryBin | Whether domestic (same-country) money transfers are permitted for this BIN: 1=allowed. Added 30/01/2024. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query source) | Dictionary.CountryBin | Read | View combining Dictionary.CountryBin6 and Dictionary.CountryBin8; BIN metadata lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Card routing and compliance services | @BinCodeFrom / @BinCodeTo | Caller | Used to query bulk BIN properties for routing decisions and compliance checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CountryBinsByRangeGet (procedure)
+-- Dictionary.CountryBin (view) [query source]
      +-- Dictionary.CountryBin6 (table) [6-digit BIN data]
      +-- Dictionary.CountryBin8 (table) [8-digit BIN data]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | View | SELECT source - BIN metadata for the range |

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

**Performance note**: Query performance depends on `Dictionary.CountryBin` view and the BIN code index on the underlying `CountryBin6`/`CountryBin8` tables. Narrow ranges (e.g., single issuer prefix) return quickly; very wide ranges (0 to 99999999) may scan significant portions of the BIN table.

---

## 8. Sample Queries

### 8.1 Get all BINs in Visa classic prefix range

```sql
EXEC Billing.CountryBinsByRangeGet
    @BinCodeFrom = 400000,
    @BinCodeTo = 499999
```

### 8.2 Check 3DS requirements for a specific BIN range

```sql
-- Use result set to analyze 3DS coverage for a BIN range
EXEC Billing.CountryBinsByRangeGet @BinCodeFrom = 411111, @BinCodeTo = 411199
-- Inspect ShouldCheck3ds, MinAmountFor3ds, ChallengeIndicator3DS columns
```

### 8.3 Query Dictionary.CountryBin directly for the same data

```sql
SELECT
    CountryID, BinCode, IssuingBank, CardTypeID, IsPrepaid,
    ShouldCheck3ds, SupportsAFT, IsCFT,
    DomesticMoneyTransfer, CrossBorderMoneyTransfer
FROM Dictionary.CountryBin WITH (NOLOCK)
WHERE BinCode BETWEEN 400000 AND 499999
ORDER BY BinCode
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Funding Service changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/8646099006/Funding+Service+changes) | Confluence | Page mentions BIN-related routing changes; IsCFT, CrossBorderMoneyTransfer, DomesticMoneyTransfer columns added in 2023-2024 service updates |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CountryBinsByRangeGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CountryBinsByRangeGet.sql*
