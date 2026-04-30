# Dictionary.CustomerWalletStatus

> Lookup table defining the activation statuses of customer wallet addresses, controlling whether addresses are ready for use in transactions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Status (tinyint IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the lifecycle statuses for customer wallet addresses. When a wallet address is created from the pool and assigned to a customer, it starts as Pending and transitions to Active once blockchain registration is confirmed. This two-state model ensures the platform does not accept deposits to addresses that are not yet fully registered on the blockchain.

The status gate prevents a critical failure mode: if a customer deposited crypto to a Pending address that was not yet registered, the funds could be lost. By tracking activation status, the system ensures addresses are only presented to customers after they are confirmed operational.

The table is FK-referenced by `Wallet.WalletAddresses` (and historical backup tables) and consumed by stored procedures that manage wallet pool assignment and address activation.

---

## 2. Business Logic

### 2.1 Address Activation Gate

**What**: Two-state model gating address availability for customer use.

**Columns/Parameters Involved**: `Status`, `Description`

**Rules**:
- `Pending` (0): Address has been created and assigned but not yet confirmed on the blockchain. The address must NOT be shown to the customer or used for receiving funds.
- `Active` (1): Address is fully registered on the blockchain and ready for use. The customer can deposit crypto to this address. All monitoring and balance tracking is active.

**Diagram**:
```
Pool Address --> Assigned to Customer --> Pending (0)
                                            |
                                    [Blockchain confirms]
                                            |
                                            v
                                        Active (1)
                                    [Ready for deposits]
```

---

## 3. Data Overview

| Status | Description | Meaning |
|---|---|---|
| 0 | Pending | Wallet address has been assigned to a customer from the pool but blockchain registration is not yet confirmed. The address is not yet safe for receiving deposits. Background processes monitor for registration confirmation. |
| 1 | Active | Wallet address is fully registered on the blockchain and confirmed operational. The customer can safely receive cryptocurrency at this address. Balance monitoring and transaction detection are active. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Status | tinyint | NO | IDENTITY(0,1) | CODE-BACKED | Unique status identifier. IDENTITY starting at 0. Values: 0=Pending, 1=Active. FK target for Wallet.WalletAddresses.CustomerWalletStatusId. The IDENTITY(0,1) seed is notable - starts from 0 rather than the typical 1. |
| 2 | Description | nvarchar(100) | NO | - | CODE-BACKED | Human-readable description of the status. Uses nvarchar (Unicode) unlike most Dictionary tables that use varchar. Displayed in operational dashboards and wallet management tools. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.WalletAddresses | CustomerWalletStatusId | FK | Tracks activation status of each customer wallet address |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | FK on CustomerWalletStatusId |
| Wallet.UpdateWalletPoolAddress | Stored Procedure | Updates wallet address status |
| Wallet.InsertWalletToPool | Stored Procedure | Sets initial status when inserting to pool |
| Wallet.AddWalletAddress | Stored Procedure | Sets status when creating customer address |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerWalletStatus_Status | CLUSTERED | Status ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all wallet statuses
```sql
SELECT Status, Description FROM Dictionary.CustomerWalletStatus WITH (NOLOCK) ORDER BY Status
```

### 8.2 Count wallet addresses by activation status
```sql
SELECT cws.Description, COUNT(wa.WalletAddressId) AS AddressCount
FROM Dictionary.CustomerWalletStatus cws WITH (NOLOCK)
LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.CustomerWalletStatusId = cws.Status
GROUP BY cws.Description ORDER BY cws.Description
```

### 8.3 Find pending (not yet activated) wallet addresses
```sql
SELECT wa.WalletAddressId, wa.Address, cws.Description AS Status
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Dictionary.CustomerWalletStatus cws WITH (NOLOCK) ON wa.CustomerWalletStatusId = cws.Status
WHERE cws.Status = 0 -- Pending
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CustomerWalletStatus | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.CustomerWalletStatus.sql*
