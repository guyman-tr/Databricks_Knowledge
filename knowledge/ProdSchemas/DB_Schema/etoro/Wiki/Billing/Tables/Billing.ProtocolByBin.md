# Billing.ProtocolByBin

> BIN-to-protocol routing table mapping specific credit card BIN numbers to a designated payment processor, with optional amount limits and provider whitelist/blacklist flags for fine-grained deposit routing control.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) - natural key: BinNumber |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Billing.ProtocolByBin maps individual credit card BIN numbers (6-digit bank identification numbers) to a specific payment processor protocol, overriding the standard dynamic routing algorithm. When a customer deposits with a credit card, the routing service first checks this table: if the card's BIN has a specific routing rule, the deposit is sent to that protocol (and optionally validated against MinAmount/MaxAmount limits). If no BIN-specific rule exists, the standard monthly-quota-based routing kicks in.

16,727 rows are all IsActive=1 (no inactive BIN rules). The dominant mapping is Checkout.com (ProtocolID=43: 12,346 BINs = 74% of entries), followed by WorldPay (ProtocolID=23: 4,370 BINs = 26%). A handful of BINs are mapped to IxopayNuvei (46), and legacy/test protocols (2, 4, 49).

This table is consumed by GetProtocolByBin (single BIN lookup), GetCCProcessingBundleByBin, and GetCCProcessingBundleByBinUS - the main CC routing SPs that check BIN-specific overrides first, then fall back to country-level and dynamic routing.

---

## 2. Business Logic

### 2.1 BIN-Specific Protocol Override

**What**: A BIN entry forces routing to a specific protocol regardless of the standard balancing algorithm.

**Columns/Parameters Involved**: `BinNumber`, `ProtocolID`, `IsActive`

**Rules**:
- GetProtocolByBin returns rows WHERE IsActive=1 AND BinNumber=@BinCode. All 16,727 rows are IsActive=1.
- ProtocolID: The target processor for this BIN. Multiple BINs can point to the same protocol.
- If a BIN appears in this table and IsActive=1, the routing is deterministic (always this protocol).
- IsWhitelistedProvider / IsBlacklistedProvider: Additional flags for provider-level access control on this BIN. Most values are NULL in practice; when set, they can whitelist or blacklist a specific BIN from a provider.

### 2.2 Amount Limits (Optional)

**What**: MinAmount and MaxAmount constrain the deposit amounts this BIN routing rule applies to.

**Columns/Parameters Involved**: `MinAmount`, `MaxAmount`, `BinNumber`

**Rules**:
- NULL MinAmount / MaxAmount: No amount restriction - the BIN rule applies for any deposit amount.
- Non-NULL MinAmount: Only applies when deposit amount >= MinAmount (in USD).
- Non-NULL MaxAmount: Only applies when deposit amount <= MaxAmount (in USD).
- Amount type is `money` (SQL Server: 4-decimal precision, up to ~$922 trillion).
- Used to differentiate routing for high-value vs. low-value deposits from the same BIN range.

### 2.3 Protocol Distribution

| ProtocolID | Protocol | BIN Count | % | Role |
|-----------|----------|-----------|---|------|
| 43 | Checkout.com | 12,346 | 74% | Primary BIN-specific routing target |
| 23 | WorldPay | 4,370 | 26% | Secondary BIN-specific routing target |
| 46 | IxopayNuvei | 7 | <1% | Specific BIN routing |
| 2 | (legacy) | 2 | <1% | Legacy protocol routing |
| 4 | (legacy) | 1 | <1% | Legacy protocol routing |
| 49 | (other) | 1 | <1% | Specific provider BIN |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 16,727 |
| Active rows (IsActive=1) | 16,727 (100%) |
| Distinct protocols | 6 |
| Dominant protocol | Checkout.com (43): 12,346 BINs (74%) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. BIN lookups use BinNumber directly. |
| 2 | BinNumber | int | NO | - | CODE-BACKED | 6-digit credit card BIN (Bank Identification Number) stored as integer. Identifies the card-issuing bank and card type. The natural lookup key for routing decisions. |
| 3 | ProtocolID | int | YES | - | VERIFIED | Target payment processor for this BIN. FK to Dictionary.Protocol (explicit FK_BillingProtocolByBin_DictionaryProtocol). Observed: 43=Checkout.com, 23=WorldPay, 46=IxopayNuvei, 2=legacy, 4=legacy, 49=other. NULL would mean no specific protocol override. |
| 4 | MinAmount | money | YES | - | CODE-BACKED | Minimum deposit amount (USD) for this BIN rule to apply. NULL=no lower limit. money type has 4-decimal precision. When set, only deposits >= MinAmount trigger this BIN routing. |
| 5 | MaxAmount | money | YES | - | CODE-BACKED | Maximum deposit amount (USD) for this BIN rule to apply. NULL=no upper limit. When set, only deposits <= MaxAmount trigger this BIN routing. Enables different processors for high-value vs. low-value deposits. |
| 6 | ModificationDate | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of the last modification to this row. Default GETUTCDATE(). Used for tracking when BIN routing rules were last updated. |
| 7 | IsActive | bit | NO | 1 | VERIFIED | Whether this BIN routing rule is active. Default 1. GetProtocolByBin filters WHERE IsActive=1. All 16,727 rows are currently active - no inactive rules in the dataset. |
| 8 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | When 1: this BIN is explicitly whitelisted for the specified provider. NULL/0: no whitelist designation. Used in the broader CC routing logic for provider-level access control per BIN. |
| 9 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | When 1: this BIN is explicitly blacklisted from the specified provider. NULL/0: no blacklist designation. Used to prevent specific card BINs from routing to a protocol (e.g., known fraudulent BIN ranges). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | FK (FK_BillingProtocolByBin_DictionaryProtocol) | References the target payment processor. WITH CHECK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetProtocolByBin | BinNumber, ProtocolID | SELECT reader | Returns active BIN routing rule for a given BIN code. Single-BIN lookup. Jira PAYUS-3061. |
| Billing.GetProtocolByBinV2 | BinNumber, ProtocolID | SELECT reader | V2 version of the BIN protocol lookup. |
| Billing.GetCCProcessingBundleByBin | BinNumber | SELECT reader (via GetProtocolByBin) | CC processing bundle lookup using BIN routing. |
| Billing.GetCCProcessingBundleByBinUS | BinNumber | SELECT reader (via GetProtocolByBin) | US-specific CC processing bundle using BIN routing. |
| Billing.CreditCardRoutingTransactionsVerification | - | Reader | Validates CC routing correctness including BIN-specific rules. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProtocolByBin (table)
  -> Dictionary.Protocol (FK)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK target for ProtocolID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetProtocolByBin | Stored Procedure | BIN-to-protocol lookup |
| Billing.GetProtocolByBinV2 | Stored Procedure | V2 BIN-to-protocol lookup |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | CC routing via BIN lookup |
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | US CC routing via BIN lookup |
| Billing.CreditCardRoutingTransactionsVerification | Stored Procedure | Routing validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingProtocolByBin | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingProtocolByBin | PRIMARY KEY | ID clustered |
| FK_BillingProtocolByBin_DictionaryProtocol | FOREIGN KEY | ProtocolID -> Dictionary.Protocol WITH CHECK |
| DF_ProtocolByBin_ModificationDate | DEFAULT | GETUTCDATE() for ModificationDate |
| DF_ProtocolByBin_IsActive | DEFAULT | 1 for IsActive |

---

## 8. Sample Queries

### 8.1 Look up protocol for a specific BIN

```sql
EXEC Billing.GetProtocolByBin @BinCode = 411111
-- Returns ProtocolID for this BIN if configured
```

### 8.2 Get all BINs routed to a specific protocol

```sql
SELECT BinNumber, MinAmount, MaxAmount, ModificationDate
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE ProtocolID = 43  -- Checkout.com
  AND IsActive = 1
ORDER BY BinNumber
```

### 8.3 Find BINs with amount restrictions

```sql
SELECT BinNumber, ProtocolID, MinAmount, MaxAmount
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE IsActive = 1
  AND (MinAmount IS NOT NULL OR MaxAmount IS NOT NULL)
ORDER BY BinNumber
```

---

## 9. Atlassian Knowledge Sources

Code comments in GetProtocolByBin and GetCountryProtocols reference Jira PAYUS-3061 (Shabtay E., 15/06/2021 - Initial version of BIN-based routing).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ProtocolByBin | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ProtocolByBin.sql*
