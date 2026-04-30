# Billing.GetCCProcessingBundleByBinUS

> US-market variant of GetCCProcessingBundleByBin that replaces the manual Dictionary.CountryBin lookup with Billing.fn_GetCCDepotCountryId(@BinCode, @CID) to support US state-level routing and optional customer-level country resolution.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode, @CurrencyID, @CardTypeID, @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCCProcessingBundleByBinUS` is identical in structure to `Billing.GetCCProcessingBundleByBin` except for one key difference: instead of a direct `Dictionary.CountryBin` lookup to resolve the BIN's country, it uses `Billing.fn_GetCCDepotCountryId(@BinCode, @CID)` via `OUTER APPLY`. This function can return a more specific country ID by considering both the BIN's issuing country AND the customer's registered country, enabling US state-level routing distinctions.

Created by Shay Oren on 01/11/2020 to handle US regulatory requirements where routing may differ by state (US state = separate CountryID in eToro's system). The `@CID` parameter (NULL-defaulted) feeds into `fn_GetCCDepotCountryId` to allow customer-context-aware country resolution.

The `OUTER APPLY` syntax (instead of a simple subquery) allows `fn_GetCCDepotCountryId` to reference the outer query context and return a table-valued result, though it's used here as a scalar-like result (`GetCountryId.CountryID`).

---

## 2. Business Logic

### 2.1 Customer-Aware Country Resolution

**What**: Uses a function to determine the effective routing country, considering both the card BIN and the customer's profile.

**Columns/Parameters Involved**: `@BinCode`, `@CID`, `Billing.fn_GetCCDepotCountryId`, `GetCountryId.CountryID`

**Rules**:
- `OUTER APPLY Billing.fn_GetCCDepotCountryId(@BinCode, @CID) GetCountryId` - called for each ProtocolCountry row
- `WHERE GetCountryId.CountryID IN (BPC.CountryID, 0)` - the resolved CountryID must match the protocol's country OR be 0 (universal)
- `@CID = NULL` (default) - when no customer context is available, the function falls back to BIN-only country lookup
- This replaces the original `@BinCodeCountryID = COALESCE(SELECT CountryID FROM Dictionary.CountryBin, 0)` direct lookup

### 2.2 Protocol Filtering and Quota Utilization

**What**: Same two-phase logic as GetCCProcessingBundleByBin.

**Rules**: Identical to `GetCCProcessingBundleByBin` - see that doc for full details on:
- @filteredProtocols table variable with IsByBin/IsByCountry/FromAmount/ToAmount
- Billing.ProtocolByBin BIN-specific routing overrides
- Bank-Depot-Protocol 6-table JOIN chain
- Monthly quota utilization via Billing.GetMonthlyQuota + Billing.QuotaManagement

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | int | NO | - | VERIFIED | First 6 digits of the credit/debit card. Passed to fn_GetCCDepotCountryId for country resolution and to ProtocolByBin for BIN routing. |
| 2 | @CurrencyID | int | NO | - | VERIFIED | Requested deposit currency. Filters Billing.DepotToCurrency. |
| 3 | @CardTypeID | int | NO | - | VERIFIED | Card network type. Filters Dictionary.CardTypeToBank. |
| 4 | @CID | int | YES | NULL | VERIFIED | Customer ID. Passed to fn_GetCCDepotCountryId to enable customer-context-aware country resolution (US state routing). NULL = BIN-only lookup. |

**Return Columns:** Identical to `Billing.GetCCProcessingBundleByBin` (19 columns: PaymentTypeID, FundingTypeID, ProtocolID, DepotID, CurrencyID, Priority, BankID, ClassKey, Name, CardTypeID, ProcessedAmount, MinQuota, MaxQuota, Percentage, FilledQuota, IsByBin, FromAmount, ToAmount, IsByCountry).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Country resolution | Billing.fn_GetCCDepotCountryId | Read (function, OUTER APPLY) | Resolves effective routing country from BIN + CID. US-state-aware. |
| BIN-specific routing | Billing.ProtocolByBin | Read | Active BIN-to-protocol routing overrides. LEFT JOIN. |
| Country filter | Billing.ProtocolCountry | Read | Protocol-country eligibility. |
| Bank chain | Dictionary.Bank | Read | Root of JOIN chain. |
| Card type | Dictionary.CardTypeToBank | Read | Bank-card-type mapping. |
| Depot routing | Billing.BankToDepot | Read | Bank-depot link. |
| Depot config | Billing.Depot | Read | Processing endpoint. |
| Currency support | Billing.DepotToCurrency | Read | Depot-currency mapping. |
| Protocol details | Dictionary.Protocol | Read | ClassKey and Name. |
| Quota volume | Billing.GetMonthlyQuota | Read (function) | Current month volume. |
| Quota limits | Billing.QuotaManagement | Read | Monthly quota config. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| GetCCProcessingBundleByBin | - | Predecessor | Non-US version without fn_GetCCDepotCountryId. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCCProcessingBundleByBinUS (procedure)
├── Billing.fn_GetCCDepotCountryId (function) - key differentiator vs ByBin
├── Billing.ProtocolByBin (table)
├── Billing.ProtocolCountry (table)
├── Dictionary.Bank (table)
├── Dictionary.CardTypeToBank (table)
├── Billing.BankToDepot (table)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
├── Dictionary.Protocol (table)
├── Billing.GetMonthlyQuota (function)
└── Billing.QuotaManagement (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.fn_GetCCDepotCountryId | Function (OUTER APPLY) | Returns effective routing CountryID from BIN + CID. Replaces direct Dictionary.CountryBin lookup. |
| Billing.ProtocolByBin | Table | BIN-specific routing overrides. |
| Billing.ProtocolCountry | Table | Protocol-country eligibility. |
| Dictionary.Bank | Table | Bank chain root. |
| Dictionary.CardTypeToBank | Table | Bank-card-type mapping. |
| Billing.BankToDepot | Table | Bank-depot Priority link. |
| Billing.Depot | Table | Depot config. |
| Billing.DepotToCurrency | Table | Depot currency support. |
| Dictionary.Protocol | Table | ClassKey and Name. |
| Billing.GetMonthlyQuota | Function | Monthly volume by ProtocolID. |
| Billing.QuotaManagement | Table | Monthly quota limits. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No explicit GRANT EXECUTE found) | - | Called by US deposit routing flow in application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get US CC routing for a customer with BIN
```sql
EXEC Billing.GetCCProcessingBundleByBinUS
  @BinCode = 411111,
  @CurrencyID = 1,    -- USD
  @CardTypeID = 1,    -- Visa
  @CID = 12345        -- Customer ID for US state routing
```

### 8.2 Compare results vs non-US version
```sql
-- US version (customer context)
EXEC Billing.GetCCProcessingBundleByBinUS @BinCode=411111, @CurrencyID=1, @CardTypeID=1, @CID=12345
-- Standard version (BIN only)
EXEC Billing.GetCCProcessingBundleByBin @BinCode=411111, @CurrencyID=1, @CardTypeID=1
-- Differences in ProtocolIDs indicate US-specific routing
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in the TRAD space.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCCProcessingBundleByBinUS | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCCProcessingBundleByBinUS.sql*
