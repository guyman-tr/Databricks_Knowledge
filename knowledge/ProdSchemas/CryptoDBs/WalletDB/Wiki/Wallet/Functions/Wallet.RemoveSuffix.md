# Wallet.RemoveSuffix

> Scalar function that removes the suffix portion of a string from a specified delimiter onward. Used for stripping query parameters from blockchain addresses.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) - string with suffix removed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.RemoveSuffix removes query-string suffixes from blockchain addresses by locating the first occurrence of a delimiter character (typically `?`) and returning everything before it. For example, `rN7GFkTz5jxSMb9HF?dt=12345` becomes `rN7GFkTz5jxSMb9HF`. Many blockchain protocols encode routing metadata as query parameters (XRP destination tags, Stellar memos, EOS memo fields) that must be stripped for consistent address identity matching.

This function exists as the counterpart to `Wallet.RemovePrefix` - together they form a two-step address normalization pipeline. RemovePrefix strips protocol prefixes (e.g., `bitcoin:`), then RemoveSuffix strips query parameters (e.g., `?dt=12345`).

Used in `Wallet.StoreReceivedTransaction` for normalizing blockchain addresses during received transaction ingestion. The procedure passes a configurable `@SuffixDelimiter` parameter, allowing different delimiter characters for different blockchain protocols.

---

## 2. Business Logic

### 2.1 Forward-Search Suffix Removal

**What**: Strips the suffix portion of a string by finding the first occurrence of the delimiter and returning everything before it.

**Columns/Parameters Involved**: `@Input`, `@Delimiter`

**Rules**:
- Uses `CHARINDEX(@Delimiter, @Input)` to find the first occurrence of the delimiter
- If found, returns `LEFT(@Input, @Pos - 1)` - everything before the first delimiter
- If NOT found, returns `@Input` unchanged
- Searching from the left (forward) ensures that the first `?` terminates the address - query parameters can contain additional `?` or `&` which are all stripped

**Diagram**:
```
@Input: "rN7GFkTz5jxSMb9HF?dt=12345&memo=abc"
         |                 |
         returned portion  |-- suffix (stripped)
                           |
                           @Delimiter = '?'

CHARINDEX finds '?' at position 19
LEFT(@Input, 18) = "rN7GFkTz5jxSMb9HF"
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Input | varchar(max) | YES | - | CODE-BACKED | The string to process, typically a blockchain address with potential query parameters (e.g., `rN7GFk?dt=12345`). Often the output of `Wallet.RemovePrefix` in a chained normalization call. |
| 2 | @Delimiter | varchar(10) | NO | - | CODE-BACKED | The delimiter character that marks the start of the suffix to remove. In practice, `Wallet.StoreReceivedTransaction` passes `@SuffixDelimiter` (typically `'?'`). |
| 3 | RETURN | varchar(max) | YES | - | CODE-BACKED | The input string with the suffix removed (everything before the first occurrence of the delimiter). Returns the input unchanged if the delimiter is not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreReceivedTransaction | n.Address, b.Address | Function Call | Strips query parameters from blockchain addresses during received transaction address normalization. Used as the second step: `RemoveSuffix(RemovePrefix(Address, @PrefixDelimiter), @SuffixDelimiter)` |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreReceivedTransaction | Stored Procedure | Calls this function as the second step in two-step address normalization (suffix removal after prefix removal) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove query parameters from an XRP address
```sql
SELECT Wallet.RemoveSuffix('rN7GFkTz5jxSMb9HF?dt=12345', '?')
-- Returns: 'rN7GFkTz5jxSMb9HF'
```

### 8.2 No delimiter found - returns unchanged
```sql
SELECT Wallet.RemoveSuffix('bc1q7ugqn4ssrcv0p2z4kt0', '?')
-- Returns: 'bc1q7ugqn4ssrcv0p2z4kt0'
```

### 8.3 Full normalization pipeline as used in StoreReceivedTransaction
```sql
SELECT Wallet.RemoveSuffix(
    Wallet.RemovePrefix('bitcoin:bc1q7ugqn4ssrcv0p?dt=12345', ':'),
    '?'
)
-- Returns: 'bc1q7ugqn4ssrcv0p'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.RemoveSuffix | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.RemoveSuffix.sql*
