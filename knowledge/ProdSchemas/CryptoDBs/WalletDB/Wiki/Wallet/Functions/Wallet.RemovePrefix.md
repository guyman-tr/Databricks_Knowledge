# Wallet.RemovePrefix

> Scalar function that removes the prefix portion of a string up to and including a specified delimiter, searching from the end of the string. Used for stripping protocol prefixes from blockchain addresses.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) - string with prefix removed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.RemovePrefix removes protocol prefixes from blockchain addresses by locating a delimiter character (typically `:`) and returning everything after the last occurrence. For example, `bitcoin:bc1q7ugqn4...` becomes `bc1q7ugqn4...`. Many blockchain URI schemes include a protocol prefix (e.g., `bitcoin:`, `ethereum:`, `litecoin:`) that must be stripped for address matching and storage.

This function exists because blockchain addresses arrive from various external sources (wallet providers, blockchain nodes, user input) in inconsistent formats - some with protocol prefixes, some without. Address normalization ensures reliable matching regardless of format.

Used in conjunction with `Wallet.RemoveSuffix` in `Wallet.StoreReceivedTransaction` as a two-step address normalization pipeline: first strip the protocol prefix via RemovePrefix, then strip query parameters via RemoveSuffix. The procedure passes configurable delimiters (`@PrefixDelimiter`, `@SuffixDelimiter`) to both functions.

---

## 2. Business Logic

### 2.1 Reverse-Search Prefix Removal

**What**: Strips the prefix portion of a string by searching for the delimiter from the END (using REVERSE), returning everything after the last occurrence.

**Columns/Parameters Involved**: `@Input`, `@Delimiter`

**Rules**:
- Uses `REVERSE(@Input)` to find the delimiter position from the right side
- If the delimiter is found, returns `RIGHT(@Input, @Pos - 1)` - everything after the last delimiter
- If the delimiter is NOT found, returns `@Input` unchanged
- Searching from the end handles edge cases where the delimiter might appear within the address itself (e.g., some base58 addresses can contain `:`)

**Diagram**:
```
@Input: "bitcoin:bc1q7ugqn4ssrcv0p"
         |      |
         prefix |-- returned portion
         |
         @Delimiter = ':'

REVERSE search finds ':' at position from right
RIGHT(@Input, @Pos - 1) = "bc1q7ugqn4ssrcv0p"
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Input | varchar(max) | YES | - | CODE-BACKED | The string to process, typically a blockchain address with a potential protocol prefix (e.g., `bitcoin:bc1q...`). Sourced from blockchain node responses or user input during received transaction processing in `Wallet.StoreReceivedTransaction`. |
| 2 | @Delimiter | varchar(10) | NO | - | CODE-BACKED | The delimiter character that separates the prefix from the address body. In practice, `Wallet.StoreReceivedTransaction` passes `@PrefixDelimiter` (typically `':'`). |
| 3 | RETURN | varchar(max) | YES | - | CODE-BACKED | The input string with the prefix portion removed (everything after the last occurrence of the delimiter). Returns the input unchanged if the delimiter is not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreReceivedTransaction | n.Address, b.Address | Function Call | Strips protocol prefix from blockchain addresses during received transaction address normalization. Used in a JOIN condition: `RemoveSuffix(RemovePrefix(n.Address, @PrefixDelimiter), @SuffixDelimiter)` |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreReceivedTransaction | Stored Procedure | Calls this function as the first step in two-step address normalization (prefix removal before suffix removal) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove protocol prefix from a Bitcoin address
```sql
SELECT Wallet.RemovePrefix('bitcoin:bc1q7ugqn4ssrcv0p2z4kt0', ':')
-- Returns: 'bc1q7ugqn4ssrcv0p2z4kt0'
```

### 8.2 No delimiter found - returns unchanged
```sql
SELECT Wallet.RemovePrefix('bc1q7ugqn4ssrcv0p2z4kt0', ':')
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
*Object: Wallet.RemovePrefix | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.RemovePrefix.sql*
