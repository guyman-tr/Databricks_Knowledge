# Dictionary.AddressTypeDisplayNames

> Lookup table mapping cryptocurrency address format types to their user-facing display names, supporting blockchain-specific address encoding variants.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique constraint (Type) |

---

## 1. Business Meaning

This table defines the display names for different cryptocurrency address format types. Some blockchains support multiple address formats (e.g., Bitcoin Cash has both legacy 3-prefix and CashAddr formats, Litecoin has M-prefix addresses). This table maps the internal type code to a user-friendly display name shown in the wallet UI.

Without this table, the application would need to hardcode address format display names, making it difficult to add new formats as blockchains evolve their addressing schemes. It enables the UI to show the appropriate label when a customer selects or views an address format.

The table is read by `Wallet.GetAddressTypeDisplayNames` stored procedure, which provides the full list of address format display options to the application layer.

---

## 2. Business Logic

### 2.1 Blockchain Address Format Variants

**What**: Different blockchains use different address encoding schemes, and some have multiple active formats simultaneously.

**Columns/Parameters Involved**: `Id`, `Type`, `DisplayName`, `Description`

**Rules**:
- `3prefix` (1): Legacy Bitcoin/BCH P2SH addresses starting with "3" - the original format
- `cashaddr` (2): New Bitcoin Cash CashAddr format - adopted after the BCH fork to prevent address confusion with BTC
- `Mprefix` (3): New Litecoin M-prefix addresses replacing the older 3-prefix format to avoid confusion with Bitcoin P2SH addresses

**Diagram**:
```
BCH Address Formats:
  Legacy 3-prefix (1) <-- Original, shared with BTC
  CashAddr (2)        <-- New BCH-specific format

LTC Address Formats:
  M-prefix (3)        <-- New LTC-specific format
```

---

## 3. Data Overview

| Id | Type | DisplayName | Description | Meaning |
|---|---|---|---|---|
| 1 | 3prefix | 3 | Origional PTSH | Legacy Pay-to-Script-Hash address format starting with "3". Originally shared between Bitcoin and Bitcoin Cash, which caused user confusion about which chain an address belonged to. |
| 2 | cashaddr | CashAddr | New BCH cashaddress | Bitcoin Cash adopted CashAddr format (e.g., bitcoincash:qxxx) after the 2017 fork to clearly distinguish BCH addresses from BTC addresses, preventing accidental cross-chain sends. |
| 3 | Mprefix | M | New LCT M address | Litecoin moved from 3-prefix to M-prefix addresses to avoid confusion with Bitcoin P2SH addresses. The M-prefix clearly identifies an address as belonging to the Litecoin network. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the address type. Values: 1=3prefix, 2=cashaddr, 3=Mprefix. |
| 2 | Type | varchar(64) | NO | - | CODE-BACKED | Internal code for the address format type. Unique constraint ensures no duplicate type codes. Used as a programmatic key in application logic. |
| 3 | DisplayName | varchar(64) | NO | - | CODE-BACKED | Short user-facing label shown in the wallet UI when presenting address format options to the customer. |
| 4 | Description | varchar(255) | YES | - | CODE-BACKED | Optional longer description of the address type for internal documentation or extended UI tooltips. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found. Consumed by application logic via `Wallet.GetAddressTypeDisplayNames` stored procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetAddressTypeDisplayNames | Stored Procedure | Reads all address type display names |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AddressTypeDisplayNames | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_AddressTypeDisplayNames_Type | UNIQUE | Type - Ensures no duplicate address type codes exist |

---

## 8. Sample Queries

### 8.1 List all address type display names
```sql
SELECT Id, Type, DisplayName, Description
FROM Dictionary.AddressTypeDisplayNames WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find display name for a specific address type
```sql
SELECT DisplayName
FROM Dictionary.AddressTypeDisplayNames WITH (NOLOCK)
WHERE Type = 'cashaddr'
```

### 8.3 Address types with descriptions
```sql
SELECT Type AS InternalCode, DisplayName AS UILabel,
       ISNULL(Description, 'No description') AS Details
FROM Dictionary.AddressTypeDisplayNames WITH (NOLOCK)
ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AddressTypeDisplayNames | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AddressTypeDisplayNames.sql*
