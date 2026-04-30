# Billing.GetProtocolByBin

> Returns active protocol routing rules for a given BIN (Bank Identification Number), enabling the routing and credit card services to determine which payment protocol and amount limits apply to a card's BIN code.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.ProtocolByBin rows where BinNumber=@BinCode AND IsActive=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolByBin` retrieves the active payment protocol routing rules for a specific credit card BIN (Bank Identification Number - the first 6 digits of a card number). BIN-based routing allows eToro to direct cards from specific banks or regions to specific payment protocols, with configurable minimum and maximum amount limits per BIN.

The procedure exists to support the routing service and credit card service during deposit initiation. When a customer uses a credit card, the routing engine calls this to check whether that card's BIN has a specific protocol override - if so, the card must be processed via that protocol (and within the amount limits), rather than following standard country/regulation-based routing.

Data flows: created under PAYUS-3061 (Shabtay E., June 2021). The routing service and credit card service call this at deposit routing time, passing the card's BIN code. See also `Billing.GetProtocolByBinV2` which extends this procedure with provider whitelist/blacklist flags (added in 2023).

---

## 2. Business Logic

### 2.1 BIN-Based Protocol Override

**What**: Active BIN routing rules override standard protocol routing.

**Rules**:
- `WHERE IsActive = 1 AND BinNumber = @BinCode`
- Only active rules are returned - inactive rules are ignored
- A BIN may have multiple active rules (different protocols with different amount ranges)
- The caller uses MinAmount/MaxAmount to select the rule applicable to the transaction amount

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | INT | NO | - | CODE-BACKED | The 6-digit BIN (Bank Identification Number) - first 6 digits of the credit card number. Identifies the issuing bank and card type. Used to look up protocol routing overrides for this specific BIN. |

**Return columns:**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 2 | ID | CODE-BACKED | PK of the ProtocolByBin rule record. |
| 3 | BinNumber | CODE-BACKED | The BIN code this rule applies to (echoed from the filter). |
| 4 | ProtocolID | CODE-BACKED | The payment protocol to use for cards with this BIN. FK to Billing.Protocol (or Billing.ProtocolMIDSettings). |
| 5 | MinAmount | CODE-BACKED | Minimum transaction amount for this rule to apply. Transactions below this amount use standard routing. |
| 6 | MaxAmount | CODE-BACKED | Maximum transaction amount for this rule to apply. Transactions above this use standard routing (or another rule). |
| 7 | ModificationDate | CODE-BACKED | Timestamp of the last update to this routing rule. |
| 8 | IsActive | CODE-BACKED | Always 1 in results (filter condition). Rule is active and in effect. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Billing.ProtocolByBin.BinNumber | Lookup | Retrieves active routing rules for this BIN |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RoutingUser | GRANT EXECUTE | Permission | Routing service reads BIN-based protocol overrides at deposit routing time |
| CreditCardServiceUser | GRANT EXECUTE | Permission | Credit card service checks BIN routing before processing a card deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolByBin (procedure)
└── Billing.ProtocolByBin (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolByBin | Table | Filtered SELECT by BinNumber and IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RoutingUser | DB Security Principal | EXECUTE permission - BIN routing at deposit time |
| CreditCardServiceUser | DB Security Principal | EXECUTE permission - credit card processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Versioning**: GetProtocolByBinV2 (PAYIL-6954, 2023) extends this by adding `IsWhitelistedProvider` and `IsBlacklistedProvider` columns. V1 is still used by services that don't need the provider whitelist/blacklist context.

---

## 8. Sample Queries

### 8.1 Get protocol routing for a specific BIN
```sql
EXEC [Billing].[GetProtocolByBin] @BinCode = 411111
```

### 8.2 Find all active BIN routing rules for a protocol
```sql
SELECT BinNumber, MinAmount, MaxAmount, ModificationDate
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE ProtocolID = 42 AND IsActive = 1
ORDER BY BinNumber
```

### 8.3 Check all active BIN rules with their amount ranges
```sql
SELECT BinNumber, ProtocolID, MinAmount, MaxAmount
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY BinNumber, MinAmount
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-3061 (referenced in DDL comment) | Jira | Initial creation of BIN-based protocol routing feature (June 2021) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYUS-3061 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolByBin | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolByBin.sql*
