# Dictionary.CardTypeToBank

> Junction table mapping credit card types (Visa, MasterCard, Amex, etc.) to processing banks, with an active/inactive flag controlling which card-bank combinations are enabled for payment routing. Core routing configuration for credit card deposits.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CardTypeID, BankID (composite, CLUSTERED PK) |
| **Filegroup** | DICTIONARY |
| **Indexes** | 2 active |
| **Triggers** | CardTypeToBankUpdate (UPDATE) — emails on credit card routing activation |
| **FILLFACTOR** | 90 |

---

## 1. Business Meaning

Dictionary.CardTypeToBank is the core routing configuration table for credit card payment processing. Each row represents a valid card-type-to-bank combination (e.g., Visa → Bank A, MasterCard → Bank B) with an IsActive flag that controls whether that route is currently enabled. When a customer deposits using a credit card, the system uses this mapping to determine which bank/gateway processes the transaction. Operations can enable or disable specific routes without deleting rows — IsActive=0 keeps the mapping for history and quick reactivation.

The table is protected by two foreign keys: CardTypeID → Dictionary.CardType (Visa, MasterCard, Amex, etc.) and BankID → Dictionary.Bank (processing banks/gateways). The composite primary key (CardTypeID, BankID) ensures each card-bank pair appears at most once. A nonclustered index on BankID supports lookups by bank (e.g., "which card types does this bank support?").

An UPDATE trigger (Dictionary.CardTypeToBankUpdate) fires when IsActive changes to 1 (activation). It builds an HTML email listing all active card-type-to-bank mappings and sends it via Internal.EmailsToSend. Recipients are configured in Maintenance.Feature WHERE FeatureID=49. If no recipients are configured, the trigger falls back to DBA@eToro.com with a warning. This ensures operations teams are notified when routing changes go live.

---

## 2. Business Logic

### 2.1 Credit Card Routing

**What**: How the system selects which bank processes a credit card deposit based on card type.

**Columns/Parameters Involved**: `CardTypeID`, `BankID`, `IsActive`

**Rules**:
- **Active routes only**: Billing procedures (GetActiveCreditCardDepots, GetCCProcessingBundle, GetCCProcessingBundleByBin, GetCCProcessingBundleByBinUS, GetTerminalWithBankBinCode, GetCCProtocolQuotas) filter on IsActive=1 to get current routing.
- **Default terminal**: Billing.GetDefaultTerminalForBank uses this table to resolve default terminals for banks.
- **Updates**: Billing.UpdateCardTypeToBank modifies mappings; the trigger fires on IsActive changes to 1.

**Diagram**:
```
Customer deposits with Visa
       │
       ▼
Dictionary.CardTypeToBank (IsActive=1)
  CardTypeID=Visa, BankID=3, IsActive=1
       │
       ▼
Bank 3 processes the transaction
```

### 2.2 Trigger: Routing Change Notification

**What**: Dictionary.CardTypeToBankUpdate fires on UPDATE; when any row's IsActive changes to 1, an email is sent.

**Columns/Parameters Involved**: `IsActive` (Inserted/Deleted)

**Rules**:
- Fires only when Count(Inserted WHERE IsActive=1) > Count(Deleted WHERE IsActive=1) — i.e., net activation increase.
- Builds HTML body with CardType, Bank, IsActive for all active mappings.
- Recipients from Maintenance.Feature WHERE FeatureID=49; fallback: DBA@eToro.com.
- Inserts into Internal.EmailsToSend (Recipients, Subject='Change in credit card routing', Body, BodyFormat='HTML').

---

## 3. Data Overview

| CardTypeID | BankID | IsActive | Meaning |
|---|---|---|---|
| (Visa) | (Bank A) | 1 | Visa deposits route to Bank A; active. |
| (MasterCard) | (Bank B) | 1 | MasterCard deposits route to Bank B; active. |
| (Amex) | (Bank A) | 0 | Amex-Bank A mapping exists but currently disabled. |
| (Visa) | (Bank B) | 0 | Visa can also route to Bank B when enabled. |
| (MasterCard) | (Bank A) | 1 | Bank A supports multiple card types. |

*Note: Exact CardTypeID/BankID values depend on Dictionary.CardType and Dictionary.Bank. This is a configuration table; row count varies by environment.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CardTypeID | int | NO | - | HIGH | FK to Dictionary.CardType; which card type (Visa, MasterCard, Amex, etc.). Part of composite PK. |
| 2 | BankID | int | NO | - | HIGH | FK to Dictionary.Bank; which bank/gateway supports this card type. Part of composite PK. NC index DC2B_BANK on this column. |
| 3 | IsActive | bit | NO | 0 | HIGH | Whether this card-type-to-bank route is currently active for routing. DEFAULT 0. Trigger fires when changed to 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Bank | BankID | Explicit FK (FK_DBNK_DC2B) | Bank that processes this card type |
| Dictionary.CardType | CardTypeID | Explicit FK (FK_DCDT_DC2B) | Card type (Visa, MasterCard, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDefaultTerminalForBank | - | View/query | Default terminal resolution |
| Billing.GetActiveCreditCardDepots | - | Proc | Active CC depot lookups |
| Billing.UpdateCardTypeToBank | - | Proc | Updates mappings |
| Billing.GetCCProcessingBundle | - | Proc | CC processing bundle resolution |
| Billing.GetCCProcessingBundleByBin | - | Proc | CC processing by BIN |
| Billing.GetCCProcessingBundleByBinUS | - | Proc | CC processing by BIN (US) |
| Billing.GetTerminalWithBankBinCode | - | View | Terminal resolution |
| Billing.GetCCProtocolQuotas | - | Proc | CC protocol quotas |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CardTypeToBank (table)
  └── depends on Dictionary.Bank (FK), Dictionary.CardType (FK)
  └── trigger: CardTypeToBankUpdate → Internal.EmailsToSend, Maintenance.Feature
  └── consumed by Billing.GetActiveCreditCardDepots, GetCCProcessingBundle*, UpdateCardTypeToBank
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FK BankID → BankID |
| Dictionary.CardType | Table | FK CardTypeID → CardTypeID |
| Maintenance.Feature | Table | FeatureID=49 for trigger recipients |
| Internal.EmailsToSend | Table | Trigger inserts email on activation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDefaultTerminalForBank | View | Routing resolution |
| Billing.GetActiveCreditCardDepots | Stored Procedure | Active CC depots |
| Billing.UpdateCardTypeToBank | Stored Procedure | Updates mappings |
| Billing.GetCCProcessingBundle | Stored Procedure | CC processing |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | CC by BIN |
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | CC by BIN US |
| Billing.GetTerminalWithBankBinCode | View | Terminal resolution |
| Billing.GetCCProtocolQuotas | Stored Procedure | Protocol quotas |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DC2B | CLUSTERED PK | CardTypeID ASC, BankID ASC | - | - | Active |
| DC2B_BANK | NONCLUSTERED | BankID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|------------------------|
| PK_DC2B | PRIMARY KEY | Composite unique identifier, DICTIONARY filegroup, FILLFACTOR 90 |
| FK_DBNK_DC2B | FOREIGN KEY | BankID → Dictionary.Bank(BankID) |
| FK_DCDT_DC2B | FOREIGN KEY | CardTypeID → Dictionary.CardType(CardTypeID) |
| (Default) | DEFAULT | IsActive = 0 |

---

## 8. Sample Queries

### 8.1 List all active card-type-to-bank mappings
```sql
SELECT  dc.Name AS CardType,
        db.Name AS BankName,
        dc2b.IsActive
FROM    Dictionary.CardTypeToBank dc2b WITH (NOLOCK)
JOIN    Dictionary.CardType dc WITH (NOLOCK) ON dc2b.CardTypeID = dc.CardTypeID
JOIN    Dictionary.Bank db WITH (NOLOCK) ON dc2b.BankID = db.BankID
WHERE   dc2b.IsActive = 1
ORDER BY dc.Name, db.Name;
```

### 8.2 Banks supporting a specific card type
```sql
SELECT  db.Name AS BankName,
        dc2b.IsActive
FROM    Dictionary.CardTypeToBank dc2b WITH (NOLOCK)
JOIN    Dictionary.Bank db WITH (NOLOCK) ON dc2b.BankID = db.BankID
WHERE   dc2b.CardTypeID = @CardTypeID
ORDER BY dc2b.IsActive DESC, db.Name;
```

### 8.3 Card types supported by a bank
```sql
SELECT  dc.Name AS CardType,
        dc2b.IsActive
FROM    Dictionary.CardTypeToBank dc2b WITH (NOLOCK)
JOIN    Dictionary.CardType dc WITH (NOLOCK) ON dc2b.CardTypeID = dc.CardTypeID
WHERE   dc2b.BankID = @BankID
ORDER BY dc2b.IsActive DESC, dc.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from codebase analysis: Billing.GetActiveCreditCardDepots, GetCCProcessingBundle, GetCCProcessingBundleByBin, GetCCProcessingBundleByBinUS, GetTerminalWithBankBinCode, GetCCProtocolQuotas, GetDefaultTerminalForBank, UpdateCardTypeToBank, and trigger Dictionary.CardTypeToBankUpdate. Routing logic inferred from DDL, FKs, and trigger behavior.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 VERIFIED, 0 CODE-BACKED, 3 HIGH, 0 ATLASSIAN-ONLY | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | Live Data: Configuration table | Corrections: 0 applied*
*Object: Dictionary.CardTypeToBank | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CardTypeToBank.sql*
