# Wallet.GetAddressTypeDisplayNames

> Stored procedure that returns address type display name mappings from the Dictionary schema for UI labeling of different blockchain address types.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Dictionary.AddressTypeDisplayNames rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAddressTypeDisplayNames returns the mapping between blockchain address type codes and their human-readable display labels. Different blockchains use different address formats (e.g., Bitcoin has Legacy, SegWit, and Native SegWit addresses), and this table provides the localized display names for the wallet UI.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Type, DisplayName from Dictionary.AddressTypeDisplayNames.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Type | varchar | NO | - | CODE-BACKED | Address type identifier code (e.g., 'Legacy', 'SegWit', 'NativeSegWit'). |
| 2 | DisplayName | varchar | NO | - | CODE-BACKED | Human-readable display label for the address type shown in the wallet UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.AddressTypeDisplayNames | FROM | Address type display name mappings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | UI display configuration for address types |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAddressTypeDisplayNames (procedure)
+-- Dictionary.AddressTypeDisplayNames (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AddressTypeDisplayNames | Table | FROM |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all address type display names
```sql
EXEC Wallet.GetAddressTypeDisplayNames
```

### 8.2 Inline equivalent
```sql
SELECT [Type], [DisplayName] FROM [Dictionary].[AddressTypeDisplayNames] WITH (NOLOCK)
```

### 8.3 Join with wallet addresses to see type labels
```sql
SELECT wa.Address, wa.AddressType, atdn.DisplayName
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
LEFT JOIN Dictionary.AddressTypeDisplayNames atdn WITH (NOLOCK) ON atdn.Type = wa.AddressType
WHERE wa.WalletId = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAddressTypeDisplayNames | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAddressTypeDisplayNames.sql*
