# Billing.GetCCProcessingBundle

> Returns available credit card processing options (bank-to-depot routing chains) for a given BIN code, currency, and card type, including current monthly quota utilization. Original version - superseded by GetCCProcessingBundleByBin for new integrations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @BinCode, @CurrencyID, @CardTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCCProcessingBundle` is the original CC deposit routing lookup procedure. Given a customer, their card's BIN code, the desired currency, and card type (Visa/Mastercard/etc.), it returns all eligible bank-to-depot processing chains with their current monthly quota utilization. The deposit system uses this to select which payment processor to route the deposit through.

The procedure resolves the BIN code to a country (via Dictionary.CountryBin), then finds all active Depot configurations that:
1. Support the requested currency and card type
2. Are linked to active banks and card type mappings
3. Pass the protocol-country filter: the protocol is either unrestricted (not in ProtocolCountry) OR is allowed for the BIN's country
4. Have quota configuration in Billing.QuotaManagement

The result includes quota utilization percentages so the deposit routing engine can balance load across processors. `FilledQuota=1` signals that a processor has exceeded its monthly minimum quota and should be deprioritized.

Created by Ran Ovadia on 19/06/2018 (FG: 51351, parent of 51352). This is the original version; `GetCCProcessingBundleByBin` (no @CID param) is the enhanced successor with ProtocolByBin BIN-specific routing and explicit IsByBin/IsByCountry flags.

---

## 2. Business Logic

### 2.1 BIN-to-Country Resolution

**What**: Resolves the 6-digit BIN code to its issuing country for protocol-country filtering.

**Columns/Parameters Involved**: `@BinCode`, `@BinCodeCountryID`, `Dictionary.CountryBin`

**Rules**:
- `@BinCodeCountryID = COALESCE((SELECT CountryID FROM Dictionary.CountryBin WHERE BinCode = @BinCode), 0)`
- If BIN not found in Dictionary.CountryBin, defaults to 0 (treated as "any country")
- This country is used to filter which payment protocols are eligible

### 2.2 Protocol-Country Eligibility Filter

**What**: Determines which protocols are eligible based on the card's country of issue.

**Columns/Parameters Involved**: `Billing.ProtocolCountry`, `@BinCodeCountryID`

**Rules**:
- Protocol is eligible if: `ProtocolID IN (SELECT FROM ProtocolCountry WHERE CountryID = @BinCodeCountryID OR @BinCodeCountryID = 0)`
- OR: `ProtocolID NOT IN (SELECT FROM ProtocolCountry)` - protocols with no country restrictions are always eligible
- Logic: "must either match the BIN country or have no country restriction at all"

### 2.3 Bank-Depot-Protocol Chain JOIN

**What**: Traverses the 6-table join chain to assemble complete processing options.

**Columns/Parameters Involved**: `Dictionary.Bank`, `Dictionary.CardTypeToBank`, `Billing.BankToDepot`, `Billing.Depot`, `Billing.DepotToCurrency`, `Dictionary.Protocol`

**Rules**:
- `Dictionary.Bank` -> `Dictionary.CardTypeToBank` -> `Billing.BankToDepot` -> `Billing.Depot` -> `Billing.DepotToCurrency` -> `Dictionary.Protocol`
- All three `IsActive=1` filters: DBNK.IsActive, BDPT.IsActive, CTBK.IsActive
- `DPTC.CurrencyID = @CurrencyID` - only depots supporting the requested currency
- `CTBK.CardTypeID = @CardTypeID` - only banks supporting the requested card type
- `ORDER BY BKTD.Priority DESC` - higher priority banks/depots appear first

### 2.4 Monthly Quota Utilization

**What**: Joins the current month's processed volume against configured quotas to expose utilization percentages.

**Columns/Parameters Involved**: `Billing.GetMonthlyQuota`, `Billing.QuotaManagement`, `ProcessedAmount`, `MinQuota`, `MaxQuota`, `Percentage`, `FilledQuota`

**Rules**:
- `@Year` and `@Month` = current UTC year/month
- `LEFT JOIN Billing.GetMonthlyQuota(@Year, @Month)` - may return NULL if no volume yet this month (hence COALESCE to 0)
- `INNER JOIN Billing.QuotaManagement` - protocols without quota config are excluded (must have quota to be considered)
- `Percentage = (ProcessedAmount / MinQuota) * 100` - utilization relative to monthly minimum. 0 if no quota or no volume.
- `FilledQuota = CASE WHEN QuotaMin < ProcessedAmount THEN 1 ELSE 0 END` - 1 if monthly minimum quota is exceeded

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID. Included in this original version but not used in the query logic - present for API compatibility only. |
| 2 | @BinCode | int | NO | - | VERIFIED | First 6 digits of the credit/debit card. Used to resolve issuing country via Dictionary.CountryBin for protocol-country filtering. |
| 3 | @CurrencyID | int | NO | - | VERIFIED | Requested deposit currency. Filters Billing.DepotToCurrency to only depots supporting this currency. References Dictionary.Currency. |
| 4 | @CardTypeID | int | NO | - | VERIFIED | Card network type (Visa, Mastercard, etc.). Filters Dictionary.CardTypeToBank to only banks supporting this card type. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentTypeID | int | NO | - | VERIFIED | Payment type classification of the depot. From Billing.Depot.PaymentTypeID. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Funding method (e.g., Credit Card, Debit Card). From Billing.Depot.FundingTypeID. References Dictionary.FundingType. |
| 3 | ProtocolID | int | NO | - | VERIFIED | Payment protocol/processor identifier. From Billing.Depot.ProtocolID. References Dictionary.Protocol. |
| 4 | DepotID | int | NO | - | VERIFIED | The specific depot (processing endpoint) to route through. From Billing.Depot.DepotID. |
| 5 | CurrencyID | int | NO | - | VERIFIED | Currency supported by this depot. From Billing.DepotToCurrency.CurrencyID. Matches @CurrencyID. |
| 6 | Priority | int | NO | - | VERIFIED | Bank-to-depot routing priority. From Billing.BankToDepot.Priority. Results ordered by this DESC. |
| 7 | BankID | int | NO | - | VERIFIED | The acquiring bank. From Dictionary.Bank.BankID. |
| 8 | ClassKey | varchar | NO | - | VERIFIED | Protocol class key identifier. From Dictionary.Protocol.ClassKey. Used by payment gateway integration code. |
| 9 | Name | varchar | NO | - | VERIFIED | Human-readable protocol name. From Dictionary.Protocol.Name. |
| 10 | CardTypeID | int | NO | - | VERIFIED | Card type this bank supports. From Dictionary.CardTypeToBank.CardTypeID. Matches @CardTypeID. |
| 11 | ProcessedAmount | money | NO | 0 | VERIFIED | Total amount processed through this protocol this month. COALESCE(GetMonthlyQuota.Amount, 0). 0 if no volume yet. |
| 12 | MinQuota | money | NO | 0 | VERIFIED | Monthly minimum quota for this protocol from Billing.QuotaManagement. COALESCE(QuotaMin, 0). |
| 13 | MaxQuota | money | NO | 0 | VERIFIED | Monthly maximum quota for this protocol from Billing.QuotaManagement. COALESCE(QuotaMax, 0). |
| 14 | Percentage | numeric(18,2) | NO | 0 | VERIFIED | Quota utilization: (ProcessedAmount / MinQuota) * 100. 0 if no volume or no quota. |
| 15 | FilledQuota | bit | NO | - | VERIFIED | 1 if ProcessedAmount > QuotaMin (quota minimum exceeded). 0 otherwise. Used to deprioritize overloaded processors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Dictionary.CountryBin | Read | Resolves BIN code to issuing country for protocol filtering. |
| Bank chain | Dictionary.Bank | Read | Root of the JOIN chain; IsActive=1 filter applied. |
| Card type filter | Dictionary.CardTypeToBank | Read | Links banks to card types; IsActive=1 filter applied. |
| Depot routing | Billing.BankToDepot | Read | Maps banks to processing depots with Priority. |
| Depot config | Billing.Depot | Read | Processing endpoint config with FundingTypeID, ProtocolID, PaymentTypeID. IsActive=1 filter. |
| Currency support | Billing.DepotToCurrency | Read | Depot-to-currency mapping; filters by @CurrencyID. |
| Protocol details | Dictionary.Protocol | Read | Protocol name and ClassKey lookup. |
| Protocol country filter | Billing.ProtocolCountry | Read | Determines which protocols are eligible for the BIN's country. |
| Quota utilization | Billing.GetMonthlyQuota | Read (function) | Returns current month's processed volume by ProtocolID. |
| Quota config | Billing.QuotaManagement | Read | Monthly min/max quota limits per protocol. Must have entry to be included. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| GetCCProcessingBundleByBin | - | Supersedes | Enhanced version: adds BIN-specific routing (ProtocolByBin), IsByBin/IsByCountry flags, removes unused @CID param. |
| GetCCProcessingBundleByBinUS | - | Supersedes | US-market version: replaces manual BIN country lookup with Billing.fn_GetCCDepotCountryId(). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCCProcessingBundle (procedure)
├── Dictionary.CountryBin (table)
├── Dictionary.Bank (table)
├── Dictionary.CardTypeToBank (table)
├── Billing.BankToDepot (table)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
├── Dictionary.Protocol (table)
├── Billing.ProtocolCountry (table)
├── Billing.GetMonthlyQuota (function)
└── Billing.QuotaManagement (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | Table | BIN code to country resolution for protocol-country filter. |
| Dictionary.Bank | Table | Root of JOIN chain. IsActive=1 filter. |
| Dictionary.CardTypeToBank | Table | Bank-to-card-type mapping. IsActive=1 filter; @CardTypeID filter. |
| Billing.BankToDepot | Table | Bank-to-depot link with Priority. |
| Billing.Depot | Table | Processing depot config. IsActive=1 filter; source of PaymentTypeID, FundingTypeID, ProtocolID. |
| Billing.DepotToCurrency | Table | Depot-to-currency support. @CurrencyID filter. |
| Dictionary.Protocol | Table | Protocol ClassKey and Name. |
| Billing.ProtocolCountry | Table | Protocol-country eligibility restrictions. |
| Billing.GetMonthlyQuota | Function (table-valued) | Current month's volume by ProtocolID. LEFT JOIN. |
| Billing.QuotaManagement | Table | Monthly quota limits. INNER JOIN (excludes protocols without quotas). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No explicit GRANT EXECUTE found) | - | Likely called by application layer via integrated security |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get CC processing options for a Visa card in USD
```sql
EXEC Billing.GetCCProcessingBundle
  @CID = 12345,
  @BinCode = 411111,  -- Visa test BIN
  @CurrencyID = 1,    -- USD
  @CardTypeID = 1     -- Visa
-- Returns: all eligible bank-depot routing options ordered by Priority DESC
```

### 8.2 Check current quota utilization across all protocols
```sql
SELECT ProtocolID, ProcessedAmount, MinQuota, MaxQuota, Percentage, FilledQuota
FROM (
  EXEC Billing.GetCCProcessingBundle @CID=1, @BinCode=411111, @CurrencyID=1, @CardTypeID=1
) AS results
ORDER BY FilledQuota DESC, Percentage DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in the TRAD space. Related content exists in MG space: "CC Routing With Regulation Support" and "Routing Tool Mapping" (not accessible via configured search).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCCProcessingBundle | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCCProcessingBundle.sql*
