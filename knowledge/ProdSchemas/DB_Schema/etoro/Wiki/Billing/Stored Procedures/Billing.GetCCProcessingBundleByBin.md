# Billing.GetCCProcessingBundleByBin

> Returns available credit card processing options for a given BIN code, currency, and card type, with enhanced BIN-specific protocol routing (ProtocolByBin) and explicit IsByBin/IsByCountry flags for the deposit routing engine.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode, @CurrencyID, @CardTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCCProcessingBundleByBin` is the enhanced successor to `Billing.GetCCProcessingBundle`. It returns the same bank-depot-protocol routing chains for CC deposit processing, but adds two important capabilities:

1. **BIN-specific routing** (`Billing.ProtocolByBin`): A specific BIN number can be routed to a particular protocol regardless of its country. This enables card-level routing overrides.
2. **Routing classification flags** (`IsByBin`, `IsByCountry`): Each returned option is tagged to indicate why it was included - whether it matched by BIN number specifically, by the BIN's country, or both. The deposit routing engine uses these flags to prioritize BIN-specific routes over country-based ones.

The `@CID` parameter is removed (it was unused in the original `GetCCProcessingBundle`). `GetCCProcessingBundleByBinUS` is the US-specific variant that replaces the manual `Dictionary.CountryBin` lookup with `Billing.fn_GetCCDepotCountryId(@BinCode, @CID)` to handle US state-level routing.

The protocol filter uses a `@filteredProtocols` table variable to first compute eligibility, then join it into the main query - improving readability and separating concerns.

---

## 2. Business Logic

### 2.1 Two-Phase Protocol Filtering with BIN Override

**What**: First computes eligible protocols (with BIN-specific and country-based eligibility flags), then joins into the bank-depot chain.

**Columns/Parameters Involved**: `@filteredProtocols`, `Billing.ProtocolByBin`, `Billing.ProtocolCountry`, `IsByBin`, `IsByCountry`

**Rules**:
- `IsByBIN = 1` if `Billing.ProtocolByBin` has a matching active record for this BinNumber
- `IsByCountry = 1` if the protocol matches the BIN's country via `ProtocolCountry` OR has no country restriction
- A protocol is included if `ISNULL(PBB.ProtocolID, PBC.ProtocolID) IS NOT NULL` - meaning at least one of BIN-specific OR country-based eligibility applies
- `FromAmount` / `ToAmount`: BIN-specific amount range override from `ProtocolByBin.MinAmount` / `MaxAmount`. Default: 0 to max money value (922337203685477) if no BIN-specific restriction.

### 2.2 BIN Amount Range Constraints

**What**: BIN-specific routing can restrict which protocols apply to deposits of certain amounts.

**Columns/Parameters Involved**: `FromAmount`, `ToAmount`, `Billing.ProtocolByBin.MinAmount`, `Billing.ProtocolByBin.MaxAmount`

**Rules**:
- `FromAmount = ISNULL(PBB.MinAmount, 0)` - minimum deposit amount for this BIN to use this protocol
- `ToAmount = ISNULL(PBB.MaxAmount, @maxMoneyValue)` - maximum deposit amount. `@maxMoneyValue = 922337203685477` (SQL MONEY max)
- When `IsByBin = 0`, these default to 0 / max - meaning no amount restriction applies
- The deposit engine uses these to reject a protocol when the deposit amount falls outside the BIN's allowed range

### 2.3 Quota Utilization (same as GetCCProcessingBundle)

**What**: Joins current month's quota utilization for load balancing.

**Columns/Parameters Involved**: `ProcessedAmount`, `MinQuota`, `MaxQuota`, `Percentage`, `FilledQuota`

**Rules**: Same as `Billing.GetCCProcessingBundle` - see that doc for full details.
- `FilledQuota=1` when ProcessedAmount > QuotaMin - signals processor is over minimum quota

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | int | NO | - | VERIFIED | First 6 digits of the credit/debit card. Used to resolve country AND check BIN-specific routing overrides via Billing.ProtocolByBin. |
| 2 | @CurrencyID | int | NO | - | VERIFIED | Requested deposit currency. Filters Billing.DepotToCurrency. References Dictionary.Currency. |
| 3 | @CardTypeID | int | NO | - | VERIFIED | Card network type (Visa, Mastercard, etc.). Filters Dictionary.CardTypeToBank. |

**Return Columns (same core columns as GetCCProcessingBundle plus 4 new flags):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentTypeID | int | NO | - | VERIFIED | Payment type classification of the depot. From Billing.Depot. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Funding method. From Billing.Depot. References Dictionary.FundingType. |
| 3 | ProtocolID | int | NO | - | VERIFIED | Payment protocol/processor. From Billing.Depot. References Dictionary.Protocol. |
| 4 | DepotID | int | NO | - | VERIFIED | Processing endpoint to route through. From Billing.Depot. |
| 5 | CurrencyID | int | NO | - | VERIFIED | Currency supported by this depot. Matches @CurrencyID. |
| 6 | Priority | int | NO | - | VERIFIED | Bank-to-depot routing priority. Results ordered DESC. |
| 7 | BankID | int | NO | - | VERIFIED | Acquiring bank ID. From Dictionary.Bank. |
| 8 | ClassKey | varchar | NO | - | VERIFIED | Protocol class key for payment gateway integration. From Dictionary.Protocol. |
| 9 | Name | varchar | NO | - | VERIFIED | Human-readable protocol name. From Dictionary.Protocol. |
| 10 | CardTypeID | int | NO | - | VERIFIED | Card type this bank supports. Matches @CardTypeID. |
| 11 | ProcessedAmount | money | NO | 0 | VERIFIED | Total amount processed through this protocol this month. |
| 12 | MinQuota | money | NO | 0 | VERIFIED | Monthly minimum quota from Billing.QuotaManagement. |
| 13 | MaxQuota | money | NO | 0 | VERIFIED | Monthly maximum quota from Billing.QuotaManagement. |
| 14 | Percentage | numeric(18,2) | NO | 0 | VERIFIED | Quota utilization percentage: (ProcessedAmount/MinQuota)*100. |
| 15 | FilledQuota | bit | NO | - | VERIFIED | 1 if ProcessedAmount exceeds QuotaMin. Signals overloaded processor. |
| 16 | IsByBin | bit | NO | - | VERIFIED | 1 if this protocol has a specific BIN-based routing rule in Billing.ProtocolByBin for @BinCode. Higher routing priority. |
| 17 | FromAmount | money | NO | 0 | VERIFIED | Minimum deposit amount for this BIN to use this protocol. 0 if no BIN-specific restriction. |
| 18 | ToAmount | money | NO | max | VERIFIED | Maximum deposit amount for this BIN to use this protocol. SQL MONEY max if no restriction. |
| 19 | IsByCountry | bit | NO | - | VERIFIED | 1 if this protocol is eligible due to the BIN's country match (or has no country restriction). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode country | Dictionary.CountryBin | Read | Resolves BIN to issuing country. |
| BIN-specific routing | Billing.ProtocolByBin | Read | Active BIN-to-protocol routing overrides. LEFT JOIN. |
| Country filter | Billing.ProtocolCountry | Read | Protocol-country eligibility restrictions. |
| Bank chain | Dictionary.Bank | Read | Root of JOIN chain. IsActive=1. |
| Card type | Dictionary.CardTypeToBank | Read | Bank-to-card-type mapping. |
| Depot routing | Billing.BankToDepot | Read | Bank-to-depot link with Priority. |
| Depot config | Billing.Depot | Read | Processing endpoint. IsActive=1. |
| Currency support | Billing.DepotToCurrency | Read | Depot-currency mapping. |
| Protocol details | Dictionary.Protocol | Read | ClassKey and Name. |
| Quota volume | Billing.GetMonthlyQuota | Read (function) | Current month processed volume. LEFT JOIN. |
| Quota limits | Billing.QuotaManagement | Read | Monthly quota config. INNER JOIN. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCCProcessingBundleByBinUS | - | Variant | US-specific version that replaces Dictionary.CountryBin lookup with fn_GetCCDepotCountryId for state-level routing. |
| Billing.GetCCProcessingBundle | - | Predecessor | Original version without BIN-specific routing. @CID was included but unused. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCCProcessingBundleByBin (procedure)
├── Dictionary.CountryBin (table)
├── Billing.ProtocolByBin (table) - BIN routing overrides
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
| Dictionary.CountryBin | Table | BIN to country resolution. |
| Billing.ProtocolByBin | Table | BIN-specific routing overrides (IsActive=1, BinNumber=@BinCode). LEFT JOIN. |
| Billing.ProtocolCountry | Table | Country-based protocol eligibility. |
| Dictionary.Bank | Table | Bank chain root. IsActive=1. |
| Dictionary.CardTypeToBank | Table | Bank-card-type mapping. |
| Billing.BankToDepot | Table | Bank-depot link. |
| Billing.Depot | Table | Depot config. IsActive=1. |
| Billing.DepotToCurrency | Table | Depot currency support. |
| Dictionary.Protocol | Table | Protocol ClassKey and Name. |
| Billing.GetMonthlyQuota | Function | Current month volume. |
| Billing.QuotaManagement | Table | Quota limits. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No explicit GRANT EXECUTE found) | - | Called by deposit routing application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get CC options for a BIN with routing flags
```sql
EXEC Billing.GetCCProcessingBundleByBin
  @BinCode = 411111,  -- Visa US test BIN
  @CurrencyID = 1,    -- USD
  @CardTypeID = 1     -- Visa
-- Returns: IsByBin=1 rows first (BIN-specific routes), then IsByCountry-only rows
```

### 8.2 Check BIN-specific routing overrides
```sql
SELECT ProtocolID, BinNumber, MinAmount, MaxAmount, IsActive
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE BinNumber = 411111 AND IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in the TRAD space. Related content in MG space: "CC Routing With Regulation Support", "Routing Tool Mapping" (not accessible via configured search).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCCProcessingBundleByBin | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCCProcessingBundleByBin.sql*
