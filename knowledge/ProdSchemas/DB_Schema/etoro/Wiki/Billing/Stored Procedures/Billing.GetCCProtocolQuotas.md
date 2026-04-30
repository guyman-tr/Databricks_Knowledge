# Billing.GetCCProtocolQuotas

> Returns current monthly quota utilization for all active CC processing protocols matching a given currency and card type - without BIN-country filtering. Used by the routing engine and credit card service for quota monitoring across all eligible processors.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CurrencyID, @CardTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCCProtocolQuotas` is the quota-monitoring sibling of `Billing.GetCCProcessingBundle`. It returns the same bank-depot-protocol routing chains with current monthly quota utilization, but without the BIN-country protocol filter - meaning it returns ALL active processors for a given currency and card type regardless of the card's issuing country or BIN-specific routing rules.

This makes it appropriate for:
- **Routing dashboard / admin tools**: view all protocol quotas for a currency/card type without card-specific context
- **CreditCardServiceUser**: checking quota across all CC processors the service manages
- **RoutingUser**: monitoring overall routing capacity before making routing decisions

Created by Shabtay E. on 15/06/2021 (PAYUS-3061). Granted to `CreditCardServiceUser` and `RoutingUser` roles - more infrastructure/monitoring roles than the deposit-path roles that use the BIN-specific variants.

The key difference from `GetCCProcessingBundle`: no `@BinCode`/`@CID` parameters and no `ProtocolCountry` filter. It returns what ALL processors can handle, not what is eligible for a specific card.

---

## 2. Business Logic

### 2.1 All-Protocol Quota Query (No BIN/Country Filter)

**What**: Returns quota utilization for all active processors for the given currency and card type.

**Columns/Parameters Involved**: All quota columns; NO ProtocolCountry or ProtocolByBin filter

**Rules**:
- Same 6-table JOIN chain as GetCCProcessingBundle: Bank -> CardTypeToBank -> BankToDepot -> Depot -> DepotToCurrency -> Protocol
- Same IsActive=1 filters on Bank, Depot, CardTypeToBank
- Same currency and card type filters: DPTC.CurrencyID=@CurrencyID, CTBK.CardTypeID=@CardTypeID
- **No** `INNER/LEFT JOIN Billing.ProtocolCountry` - all eligible protocols returned regardless of country
- **No** `@BinCode` lookup - no card-issuing-country restriction
- `LEFT JOIN Billing.GetMonthlyQuota(@Year, @Month)` - current month volume (NULL -> 0)
- `INNER JOIN Billing.QuotaManagement` - only protocols with quota config included
- `ORDER BY BKTD.Priority DESC`

### 2.2 Quota Utilization (same as CCProcessingBundle family)

**What**: Exposes quota load for each processor.

**Rules**: Identical to the CCProcessingBundle family:
- `ProcessedAmount = COALESCE(GetMonthlyQuota.Amount, 0)`
- `Percentage = (ProcessedAmount / MinQuota) * 100`
- `FilledQuota = CASE WHEN QuotaMin < ProcessedAmount THEN 1 ELSE 0 END`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyID | int | NO | - | VERIFIED | Requested currency. Filters Billing.DepotToCurrency to depots supporting this currency. References Dictionary.Currency. |
| 2 | @CardTypeID | int | NO | - | VERIFIED | Card network type (Visa, Mastercard, etc.). Filters Dictionary.CardTypeToBank to banks supporting this card type. |

**Return Columns (same 15 columns as GetCCProcessingBundle, without IsByBin/FromAmount/ToAmount/IsByCountry):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentTypeID | int | NO | - | VERIFIED | Depot payment type. From Billing.Depot. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Funding method. From Billing.Depot. References Dictionary.FundingType. |
| 3 | ProtocolID | int | NO | - | VERIFIED | Payment processor protocol. From Billing.Depot. References Dictionary.Protocol. |
| 4 | DepotID | int | NO | - | VERIFIED | Processing depot. From Billing.Depot. |
| 5 | CurrencyID | int | NO | - | VERIFIED | Depot currency. Matches @CurrencyID. |
| 6 | Priority | int | NO | - | VERIFIED | Bank-to-depot priority. Results ordered DESC. |
| 7 | BankID | int | NO | - | VERIFIED | Acquiring bank. From Dictionary.Bank. |
| 8 | ClassKey | varchar | NO | - | VERIFIED | Protocol integration class key. From Dictionary.Protocol. |
| 9 | Name | varchar | NO | - | VERIFIED | Protocol human-readable name. From Dictionary.Protocol. |
| 10 | CardTypeID | int | NO | - | VERIFIED | Card type. Matches @CardTypeID. |
| 11 | ProcessedAmount | money | NO | 0 | VERIFIED | Total processed this month. COALESCE(GetMonthlyQuota.Amount, 0). |
| 12 | MinQuota | money | NO | 0 | VERIFIED | Monthly minimum quota. From Billing.QuotaManagement. |
| 13 | MaxQuota | money | NO | 0 | VERIFIED | Monthly maximum quota. From Billing.QuotaManagement. |
| 14 | Percentage | numeric(18,2) | NO | 0 | VERIFIED | Utilization: (ProcessedAmount/MinQuota)*100. |
| 15 | FilledQuota | bit | NO | - | VERIFIED | 1 if ProcessedAmount exceeds MinQuota (quota minimum reached). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Bank chain | Dictionary.Bank | Read | Root of JOIN chain. IsActive=1. |
| Card type | Dictionary.CardTypeToBank | Read | Bank-card-type mapping. |
| Depot routing | Billing.BankToDepot | Read | Bank-depot Priority link. |
| Depot config | Billing.Depot | Read | Processing endpoint. IsActive=1. |
| Currency support | Billing.DepotToCurrency | Read | @CurrencyID filter. |
| Protocol details | Dictionary.Protocol | Read | ClassKey and Name. |
| Quota volume | Billing.GetMonthlyQuota | Read (function) | Current month volume per protocol. LEFT JOIN. |
| Quota limits | Billing.QuotaManagement | Read | Monthly quota config. INNER JOIN. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CreditCardServiceUser (role) | EXECUTE permission | Permission | CC service uses for quota monitoring across all processors. |
| RoutingUser (role) | EXECUTE permission | Permission | Routing tool uses for capacity monitoring before routing decisions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCCProtocolQuotas (procedure)
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
| Dictionary.Bank | Table | Bank chain root. |
| Dictionary.CardTypeToBank | Table | Bank-card-type mapping. |
| Billing.BankToDepot | Table | Bank-depot link. |
| Billing.Depot | Table | Depot config. |
| Billing.DepotToCurrency | Table | Depot currency support. |
| Dictionary.Protocol | Table | ClassKey and Name. |
| Billing.GetMonthlyQuota | Function | Current month processed volume. |
| Billing.QuotaManagement | Table | Monthly quota limits. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CreditCardServiceUser (role) | Permission | Quota monitoring |
| RoutingUser (role) | Permission | Routing capacity check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check quota utilization for all Visa USD processors
```sql
EXEC Billing.GetCCProtocolQuotas @CurrencyID = 1, @CardTypeID = 1
-- Returns: all active Visa/USD processors with current monthly quota %
-- ORDER BY Priority DESC
```

### 8.2 Find overloaded protocols
```sql
-- Via SP result
EXEC Billing.GetCCProtocolQuotas @CurrencyID = 1, @CardTypeID = 1
-- Then filter: WHERE FilledQuota = 1

-- Direct query
SELECT BQMT.ProtocolID, BMQ.Amount AS ProcessedAmount, BQMT.QuotaMin,
       CAST((BMQ.Amount / BQMT.QuotaMin * 100) AS NUMERIC(18,2)) AS PctUsed
FROM Billing.QuotaManagement BQMT WITH (NOLOCK)
JOIN Billing.GetMonthlyQuota(YEAR(GETUTCDATE()), MONTH(GETUTCDATE())) BMQ
  ON BQMT.ProtocolID = BMQ.ProtocolID
WHERE BMQ.Amount > BQMT.QuotaMin
ORDER BY PctUsed DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found in the TRAD space. PAYUS-3061 is the creation ticket (June 2021, Shabtay E.).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCCProtocolQuotas | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCCProtocolQuotas.sql*
