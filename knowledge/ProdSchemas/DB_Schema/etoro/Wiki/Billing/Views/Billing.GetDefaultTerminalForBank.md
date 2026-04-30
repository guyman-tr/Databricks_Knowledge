# Billing.GetDefaultTerminalForBank

> Payment routing view that maps each active bank+card type combination to its configured depot (terminal), currency support, protocol, and priority for determining the default payment gateway for a given BIN/bank.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | (BankID, CardTypeID, CurrencyID, DepotID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetDefaultTerminalForBank` answers the routing question: "given a customer's bank (identified by BIN lookup -> BankID) and card type, which payment depot should process this transaction and in what currencies?" It joins the bank, card-type-to-bank mapping, bank-to-depot routing table, depot configuration, supported currencies, and payment protocol into a single routing lookup result.

The view exists to consolidate the multi-table join required for bank-based payment routing decisions. When a customer deposits with a credit card, the system identifies the issuing bank via the BIN code, then uses this view to determine the correct depot (payment gateway endpoint) to route the transaction through, filtered to active banks/depots/card types.

The WHERE clause applies four active-state filters ensuring only currently operational routing paths are returned: Bank must be active, the depot-to-currency pairing must be active, the card-type-to-bank mapping must be active, and the depot itself must be active. This prevents routing to decommissioned or temporarily suspended gateways.

---

## 2. Business Logic

### 2.1 Four-Layer Active State Filter

**What**: Only routing paths that are fully operational across all four entities are returned.

**Columns/Parameters Involved**: `DBNK.IsActive`, `DPTC.IsActive`, `CTBK.IsActive`, `BDPT.IsActive`

**Rules**:
- `DBNK.IsActive = 1`: The bank itself must be active in Dictionary.Bank
- `DPTC.IsActive = 1`: The depot must support this currency (DepotToCurrency.IsActive=1)
- `CTBK.IsActive = 1`: The card-type-to-bank mapping must be active (not suppressed)
- `BDPT.IsActive = 1`: The depot/terminal itself must be active
- ALL four must be true for a routing path to appear - any single deactivation removes the path

### 2.2 Multi-Hop Routing Path

**What**: The routing path requires traversing four tables to connect a bank to a payment gateway endpoint via card type.

**Columns/Parameters Involved**: `BankID`, `CardTypeID`, `DepotID`, `ProtocolID`, `CurrencyID`, `Priority`

**Rules**:
- Step 1: Dictionary.Bank -> BankID identifies the issuing bank
- Step 2: Dictionary.CardTypeToBank (CTBK) -> links BankID to CardTypeID (Visa=1, Mastercard=2, etc.)
- Step 3: Billing.BankToDepot (BKTD) -> maps BankID to DepotID with a Priority
- Step 4: Billing.Depot (BDPT) -> the gateway endpoint with FundingTypeID, ProtocolID, and Name
- Step 5: Billing.DepotToCurrency (DPTC) -> the currencies this depot supports
- Step 6: Dictionary.Protocol (DPRT) -> the gateway protocol ClassKey

---

## 3. Data Overview

| FundingTypeID | DepotID | ProtocolID | CurrencyID | BankID | CardTypeID | Priority | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 87 | 23 | 1 (USD) | 11 | 1 (Visa) | 0 | BankID=11 Visa cards in USD -> route to Depot 87 via Protocol 23. Priority=0. |
| 1 | 87 | 23 | 2 (EUR) | 11 | 1 (Visa) | 0 | Same bank+card+depot supports EUR currency as well. |
| 1 | 87 | 23 | 3 (GBP) | 11 | 1 (Visa) | 0 | Same bank+card+depot supports GBP. Multi-currency depot. |
| 1 | 87 | 23 | 1 (USD) | 11 | 2 (MC) | 0 | Same bank, Mastercard in USD -> same depot 87. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type for this depot. From Billing.Depot. 1=CreditCard for all credit card routing paths. The FundingTypeID of the depot is what the system routes to. |
| 2 | DepotID | int | NO | - | CODE-BACKED | Payment depot (gateway endpoint) ID. From Billing.Depot and Billing.BankToDepot. The selected routing target for this bank+card+currency combination. FK to Billing.Depot. |
| 3 | ProtocolID | int | NO | - | CODE-BACKED | Payment processing protocol ID. From Billing.Depot. References Dictionary.Protocol. Identifies which payment gateway/processor handles this depot's transactions. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Supported deposit currency. From Billing.DepotToCurrency. The view returns one row per (bank, card, depot, currency) combination. References Dictionary.Currency. 1=USD, 2=EUR, 3=GBP, etc. |
| 5 | IsActive | bit | NO | - | CODE-BACKED | Always 1 (WHERE DPTC.IsActive=1 filter applied). The depot-to-currency pairing is confirmed active. Included in SELECT for caller confirmation. |
| 6 | Priority | int | NO | - | CODE-BACKED | Routing priority from Billing.BankToDepot. When multiple depots are available for the same bank, higher priority wins. Values observed: 0, 50-100. Used by the routing engine to select the preferred depot. |
| 7 | BankID | int | NO | - | CODE-BACKED | Acquiring/issuing bank identifier. From Dictionary.Bank. The bank that issued the customer's card, identified via BIN lookup. Central key for routing - callers filter by BankID to find applicable depots. |
| 8 | ClassKey | nvarchar | YES | - | CODE-BACKED | Protocol class key from Dictionary.Protocol. A string identifier used by the payment processing engine to instantiate the correct protocol handler (e.g., "Checkout", "Adyen", "WorldPay"). |
| 9 | Name | nvarchar | NO | - | CODE-BACKED | Depot name from Billing.Depot. Human-readable label for the gateway endpoint (e.g., "Checkout.com USD", "Adyen EUR"). UNIQUE in Billing.Depot. |
| 10 | CardTypeID | int | NO | - | CODE-BACKED | Card network type. From Dictionary.CardTypeToBank. 1=Visa, 2=Mastercard, and other card schemes. Used together with BankID to select the correct routing path for the specific card network. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | Source (FROM anchor, IsActive=1 filter) | Issuing bank definitions; only active banks |
| BankID, CardTypeID | Dictionary.CardTypeToBank | Source (JOIN, IsActive=1 filter) | Card-type-to-bank mappings; only active mappings |
| BankID, DepotID, Priority | Billing.BankToDepot | Source (JOIN) | Bank-to-depot routing rules with priority |
| DepotID, FundingTypeID, ProtocolID, Name | Billing.Depot | Source (JOIN, IsActive=1 filter) | Depot/gateway endpoint configuration |
| DepotID, CurrencyID, IsActive | Billing.DepotToCurrency | Source (JOIN, IsActive=1 filter) | Depot-to-currency support matrix |
| ProtocolID, ClassKey | Dictionary.Protocol | Source (JOIN) | Payment protocol/processor configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetTerminalWithBankBinCode | FundingTypeID, DepotID, BankID, ... | Reference (similar pattern) | The BankBin-extended version of this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDefaultTerminalForBank (view)
├── Dictionary.Bank (table, cross-schema)
├── Dictionary.CardTypeToBank (table, cross-schema)
├── Billing.BankToDepot (table)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
└── Dictionary.Protocol (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FROM anchor: issuing bank IDs, filtered to IsActive=1 |
| Dictionary.CardTypeToBank | Table | JOIN: card-type-to-bank mappings, filtered to IsActive=1 |
| Billing.BankToDepot | Table | JOIN: bank-to-depot routing with priority |
| Billing.Depot | Table | JOIN: depot/gateway config (FundingTypeID, ProtocolID, Name), filtered to IsActive=1 |
| Billing.DepotToCurrency | Table | JOIN: depot currency support, filtered to IsActive=1 |
| Dictionary.Protocol | Table | JOIN: protocol ClassKey for gateway handler instantiation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetTerminalWithBankBinCode | View | Extended version that adds BankBin filtering |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. All JOINs use PK/FK columns that are indexed in their base tables.

### 7.2 Constraints

N/A for view. All five table-to-table JOINs are INNER JOINs - any missing record in any table silently eliminates the routing path row. No SCHEMABINDING (cross-schema). Four active-state filters ensure only operational paths are returned.

---

## 8. Sample Queries

### 8.1 Find the default routing for a specific bank and card type

```sql
SELECT FundingTypeID, DepotID, Name AS DepotName, ProtocolID, ClassKey, CurrencyID, Priority
FROM Billing.GetDefaultTerminalForBank WITH (NOLOCK)
WHERE BankID = @BankID
  AND CardTypeID = @CardTypeID
ORDER BY Priority DESC, CurrencyID
```

### 8.2 Get all currency-depot combinations for a bank

```sql
SELECT BankID, CardTypeID, DepotID, Name AS DepotName, CurrencyID, Priority
FROM Billing.GetDefaultTerminalForBank WITH (NOLOCK)
WHERE BankID = @BankID
ORDER BY CardTypeID, CurrencyID
```

### 8.3 List all active routing paths with protocol details

```sql
SELECT BankID, CardTypeID, DepotID, Name AS DepotName, ClassKey AS Protocol, CurrencyID, Priority
FROM Billing.GetDefaultTerminalForBank WITH (NOLOCK)
ORDER BY BankID, CardTypeID, Priority DESC, CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetDefaultTerminalForBank | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetDefaultTerminalForBank.sql*
