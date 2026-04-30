# Billing.GetProtocolMIDSettings

> Returns the payment protocol MID (Merchant ID) settings for a specific regulation, depot, currency, and merchant account combination - used by the wire transfer service to resolve which payment protocol and associated settings apply to a given transaction context.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.ProtocolMIDSettings rows WHERE RegulationID=@RegulationID AND DepotID=@DepotID AND CurrencyID=@CurrencyID AND MerchantAccountID=@MerchantAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolMIDSettings` resolves payment protocol MID (Merchant ID) configuration for a specific combination of regulation, depot, currency, and merchant account. A MID is the identifier assigned to a merchant by a payment processor - eToro may have multiple MIDs configured for different regulatory jurisdictions, depot modes, currencies, and merchant accounts.

The procedure exists to allow the wire transfer service to look up the exact protocol and MID configuration that applies to a given deposit transaction. Given the four-dimensional filter (regulation x depot x currency x merchant account), this is a precise lookup that returns the matching protocol settings row(s) from `Billing.ProtocolMIDSettings`.

Data flows: `WireTransferUser` (the wire transfer service) calls this during payment processing to resolve protocol configuration for a customer's transaction context. The four parameters are determined by: the customer's regulation (from Customer schema), the depot handling the transaction, the transaction currency, and the selected merchant account.

---

## 2. Business Logic

### 2.1 Four-Dimensional MID Lookup

**What**: Protocol MID settings are configured per regulation/depot/currency/merchant account combination.

**Columns/Parameters Involved**: `@RegulationID`, `@DepotID`, `@CurrencyID`, `@MerchantAccountID`

**Rules**:
- All four parameters are required - no optional or wildcard filtering
- `WITH (NOLOCK)` - non-blocking read for payment processing hot path
- Multiple rows may match (e.g., different ProtocolIDs for same combination)
- Returns all matching rows; caller selects the appropriate one

### 2.2 Protocol MID Configuration Context

**What**: The `Billing.ProtocolMIDSettings` table stores the mappings from payment context to payment protocol with MID details.

**Structure** (6 columns returned):
- `ProtocolID`: Which payment protocol to use
- `RegulationID`: Regulatory jurisdiction filter
- `DepotID`: Depot/entity filter
- `CurrencyID`: Transaction currency filter
- `MerchantAccountID`: Merchant account filter
- Additional MID configuration column(s) (e.g., actual MID value, priority, active flag)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction. FK to Dictionary.Regulation. Determines which regulations' MID settings to query. |
| 2 | @DepotID | INT | NO | - | CODE-BACKED | Depot (legal entity/processing entity) identifier. FK to Billing.Depot. Scopes MID settings to the specific entity handling the transaction. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Transaction currency. FK to Dictionary.Currency. MID settings may differ per currency (e.g., USD vs EUR merchant accounts). |
| 4 | @MerchantAccountID | INT | NO | - | CODE-BACKED | Merchant account identifier. Narrows to the specific merchant account within the regulation/depot/currency combination. |

**Return columns (6 columns from Billing.ProtocolMIDSettings):**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 5 | ProtocolID | CODE-BACKED | The payment protocol associated with this MID configuration. FK to Billing.Protocol. |
| 6 | RegulationID | CODE-BACKED | Echoed from filter - regulatory jurisdiction for this MID setting. |
| 7 | DepotID | CODE-BACKED | Echoed from filter - depot/entity for this MID setting. |
| 8 | CurrencyID | CODE-BACKED | Echoed from filter - currency for this MID setting. |
| 9 | MerchantAccountID | CODE-BACKED | Echoed from filter - merchant account ID for this MID setting. |
| 10 | (Additional MID column) | NAME-INFERRED | Likely the actual MID value, priority, or active flag for the payment processor configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegulationID | Billing.ProtocolMIDSettings.RegulationID | Filter | Scopes to the customer's regulation |
| @DepotID | Billing.ProtocolMIDSettings.DepotID | Filter | Scopes to the processing depot/entity |
| @CurrencyID | Billing.ProtocolMIDSettings.CurrencyID | Filter | Scopes to the transaction currency |
| @MerchantAccountID | Billing.ProtocolMIDSettings.MerchantAccountID | Filter | Scopes to the selected merchant account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WireTransferUser | GRANT EXECUTE | Permission | Wire transfer service resolves MID configuration for transaction routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolMIDSettings (procedure)
└── Billing.ProtocolMIDSettings (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolMIDSettings | Table | Filtered SELECT by all four parameters; returns matching MID configuration rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WireTransferUser | DB Security Principal | EXECUTE permission - MID resolution for wire transfer payment processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Context**: The `Billing.ProtocolMIDSettings` table is the more granular sibling of `Billing.ProtocolToRegulation`. While `GetProtocolIDsByRegulation` returns all protocols for a regulation, `GetProtocolMIDSettings` returns the specific MID configuration for a 4-dimensional combination. This level of specificity is needed for wire transfers where different merchant accounts handle different currency/depot combinations. **WireTransferUser** is the sole service caller - this is specific to the wire transfer processing flow.

---

## 8. Sample Queries

### 8.1 Get MID settings for a specific transaction context
```sql
EXEC [Billing].[GetProtocolMIDSettings]
    @RegulationID = 1,
    @DepotID = 5,
    @CurrencyID = 1,
    @MerchantAccountID = 10
```

### 8.2 List all MID settings for a regulation
```sql
SELECT *
FROM Billing.ProtocolMIDSettings WITH (NOLOCK)
WHERE RegulationID = 1
ORDER BY DepotID, CurrencyID, MerchantAccountID
```

### 8.3 Find which depots/currencies have MID settings configured
```sql
SELECT DepotID, CurrencyID, COUNT(*) AS SettingsCount
FROM Billing.ProtocolMIDSettings WITH (NOLOCK)
WHERE RegulationID = 1
GROUP BY DepotID, CurrencyID
ORDER BY DepotID, CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolMIDSettings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolMIDSettings.sql*
