# Wallet.AmlBlackList

> Maintains a blacklist of cryptocurrency addresses blocked from sending to or receiving from eToro wallets, used for AML (Anti-Money Laundering) compliance enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores blockchain addresses that have been flagged as prohibited for AML compliance purposes. Each row represents either a sender address (an address from which eToro will not accept incoming transactions) or a receiver address (an address to which eToro will not send outgoing transactions). This is a manually curated blacklist separate from the automated Chainalysis-based AML screening.

The table serves as a critical compliance safeguard. Without it, eToro would have no mechanism to manually block specific known-bad addresses beyond what automated AML providers detect. This is the "last line of defense" for addresses identified through internal investigations, regulatory directives, or intelligence sharing that may not yet appear in Chainalysis data.

Data is manually inserted by compliance operations (no automated population procedures exist in the SSDT project). The table is queried at transaction time by two stored procedures - `Wallet.IsAddressInSenderBlackList` and `Wallet.IsAddressInReciverBlackList` - which return 1 if the address is found, causing the transaction to be blocked. The table is currently empty (0 rows), suggesting the automated Chainalysis-based AML screening (via `Wallet.AmlValidations`) handles most cases, and this table serves as a manual override for edge cases.

---

## 2. Business Logic

### 2.1 Directional Blacklisting

**What**: Addresses can be blacklisted in one or both directions (sender vs receiver) independently.

**Columns/Parameters Involved**: `SenderAddress`, `ReciverAddress`

**Rules**:
- A row can have only `SenderAddress` populated (block incoming from this address, allow sending to it)
- A row can have only `ReciverAddress` populated (block outgoing to this address, allow receiving from it)
- A row can have both populated (block in both directions)
- Both columns are nullable, allowing directional flexibility
- Address matching is exact (no normalization applied in the lookup procedures)

**Diagram**:
```
External Address --> [Check SenderAddress] --> BLOCKED (if found)
                                          --> ALLOWED (if not found) --> Continue AML flow

eToro Wallet --> [Check ReciverAddress] --> BLOCKED (if found)
                                        --> ALLOWED (if not found) --> Continue send flow
```

---

## 3. Data Overview

The table is currently empty (0 rows). This suggests the manual blacklist is rarely used, with the automated Chainalysis-based AML screening (`Wallet.AmlValidations` + `Dictionary.AmlProviders`) handling the vast majority of address risk assessment.

If populated, example entries would look like:

| Id | SenderAddress | ReciverAddress | Meaning |
|---|---|---|---|
| 1 | 1A1zP1eP5QGefi2... | NULL | Block all incoming transactions from this specific Bitcoin address (e.g., known ransomware wallet). Outgoing to this address is not restricted. |
| 2 | NULL | bc1qxy2kgdygjrsq... | Block all outgoing transactions to this address (e.g., sanctioned entity wallet). Incoming from this address is not restricted. |
| 3 | 0xABC123... | 0xABC123... | Fully block this Ethereum address in both directions - no transactions allowed to or from it. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Used only for row identification; not referenced by other tables. |
| 2 | SenderAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address blacklisted as a sender. When populated, any incoming transaction from this address will be blocked by `Wallet.IsAddressInSenderBlackList`. Supports all blockchain address formats (Bitcoin, Ethereum, Ripple, etc.) via the 512-character limit. NULL means this row does not restrict incoming from any specific sender. |
| 3 | ReciverAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address blacklisted as a receiver. When populated, any outgoing transaction to this address will be blocked by `Wallet.IsAddressInReciverBlackList`. Note: column name contains a typo ("Reciver" instead of "Receiver") preserved from original schema. NULL means this row does not restrict outgoing to any specific receiver. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.IsAddressInSenderBlackList | @Address | Reader | Checks if a given address exists in the SenderAddress column; returns 1 if blacklisted |
| Wallet.IsAddressInReciverBlackList | @Address | Reader | Checks if a given address exists in the ReciverAddress column; returns 1 if blacklisted |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.IsAddressInSenderBlackList | Stored Procedure | Reads SenderAddress column to check if an address is blacklisted for incoming |
| Wallet.IsAddressInReciverBlackList | Stored Procedure | Reads ReciverAddress column to check if an address is blacklisted for outgoing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlAmlBlackList_Id | CLUSTERED PK | Id ASC | - | - | Active |
| ix_AmlBlackList_ReciverAddress | NC | ReciverAddress ASC | - | - | Active |
| ix_AmlBlackList_SenderAddress | NC | SenderAddress ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a sender address is blacklisted
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Wallet.AmlBlackList WITH (NOLOCK)
    WHERE SenderAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
) THEN 'BLOCKED' ELSE 'ALLOWED' END AS SenderStatus
```

### 8.2 Check if a receiver address is blacklisted
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Wallet.AmlBlackList WITH (NOLOCK)
    WHERE ReciverAddress = '0xABC123DEF456...'
) THEN 'BLOCKED' ELSE 'ALLOWED' END AS ReceiverStatus
```

### 8.3 List all blacklisted addresses with direction
```sql
SELECT
    Id,
    SenderAddress,
    ReciverAddress,
    CASE
        WHEN SenderAddress IS NOT NULL AND ReciverAddress IS NOT NULL THEN 'Both Directions'
        WHEN SenderAddress IS NOT NULL THEN 'Inbound Only'
        WHEN ReciverAddress IS NOT NULL THEN 'Outbound Only'
        ELSE 'Empty Entry'
    END AS BlockDirection
FROM Wallet.AmlBlackList WITH (NOLOCK)
ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AmlBlackList | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.AmlBlackList.sql*
