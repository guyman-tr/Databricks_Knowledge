# Eligibility.TravelRuleWhitelistedAddresses

> Registry of external cryptocurrency addresses that customers have verified ownership of, enabling those addresses to bypass travel rule manual approval for incoming transactions.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 4 active (PK clustered + 3 nonclustered) |

---

## 1. Business Meaning

This table stores cryptocurrency addresses that customers have proven they own through a verification process (cryptographic signature or legal declaration). Under travel rule regulations (FATF Recommendation 16), cryptocurrency service providers must collect originator and beneficiary information for transfers above certain thresholds. When a customer proves they own an external address, transactions from that address can be treated as self-transfers and may be exempt from full travel rule scrutiny or manual approval.

Without this table, every incoming transaction from an external address would require manual travel rule compliance review. By maintaining a whitelist of verified addresses, the platform can automatically approve transfers from addresses the customer has cryptographically proven they control, reducing compliance friction and processing time.

Addresses are added through three stored procedures: `Eligibility.AddTravelRuleWhitelistedAddress`, `Eligibility.AddWhitelistedAddress`, and `Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus` (which also auto-approves pending travel rule transactions from the address). The `Eligibility.GetTravelRuleWhitelistedAddress` procedure checks if an incoming address is whitelisted. All three write procedures enforce uniqueness: an address can only be whitelisted for one Gcid + BlockchainCryptoId combination.

---

## 2. Business Logic

### 2.1 Address Uniqueness Enforcement

**What**: Each blockchain address can only be whitelisted for a single customer and blockchain combination.

**Columns/Parameters Involved**: `Address`, `Gcid`, `BlockchainCryptoId`

**Rules**:
- Before inserting, all three writer procedures check: `IF EXISTS (SELECT 1 ... WHERE Address = @Address AND (Gcid != @Gcid OR BlockchainCryptoId != @BlockchainCryptoId))`
- If the address is already whitelisted for a different customer or blockchain, the procedure raises an error and aborts
- The same customer CAN whitelist the same address multiple times (creates duplicate rows) - only cross-customer conflicts are blocked
- This prevents address spoofing where one customer claims ownership of another customer's verified address

### 2.2 Auto-Approval of Pending Travel Rule Transactions

**What**: When an address is whitelisted, pending travel rule transactions from that address are automatically approved.

**Columns/Parameters Involved**: `Address` (used for matching), cross-schema: `Wallet.TransactionTravelRuleStatuses`, `Wallet.TransactionTravelRuleInformation`, `Wallet.Requests`

**Rules**:
- Only `AddWhitelistedAddressAndUpdateTravelRuleStatus` performs auto-approval; the other two writers do not
- Matches pending transactions by `CounterpartyAddress = @Address AND Gcid = @Gcid`
- Inserts TravelRuleStatusId = 1 (Approved) into `Wallet.TransactionTravelRuleStatuses`
- This triggers downstream processing of previously held transactions

**Diagram**:
```
Customer proves address ownership
    |
    +-> AddWhitelistedAddress / AddTravelRuleWhitelistedAddress
    |       (just stores the whitelist entry)
    |
    +-> AddWhitelistedAddressAndUpdateTravelRuleStatus
            (stores whitelist entry AND auto-approves pending transactions)
            |
            +-> Wallet.TransactionTravelRuleStatuses INSERT (StatusId=1 Approved)
```

---

## 3. Data Overview

| Id | Gcid | BlockchainCryptoId | AddressPrefix | ProofOfOwnershipTypeId | Meaning |
|---|---|---|---|---|---|
| 305 | 18953233 | 2 | 0xe6de797... | 2 (Signature) | Ethereum address ownership verified via cryptographic signature. Customer can now receive ETH/ERC-20 tokens from this address without travel rule hold. |
| 301 | 25052438 | 18 | addr1qyz... | 2 (Signature) | Cardano address verified via signature. The "addr1q" prefix identifies this as a Cardano mainnet address. |
| 85 | (varies) | 1 | (BTC format) | 2 (Signature) | Bitcoin addresses form the majority of whitelist entries (85 of 145), reflecting Bitcoin's dominance in self-custody transfers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Each row represents one verified address-customer-blockchain combination. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID identifying the customer who proved ownership of this address. Used in the uniqueness check: an address whitelisted for one Gcid cannot be claimed by another. Also used by `AddWhitelistedAddressAndUpdateTravelRuleStatus` to match pending travel rule transactions. |
| 3 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Identifies the blockchain network of the whitelisted address. Values observed: 1=Bitcoin (59%), 2=Ethereum (37%), 18=Cardano (3%), 6 and 19=other chains. Part of the uniqueness constraint alongside Gcid and Address. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp of when the whitelist entry was created. Set to `GETUTCDATE()` by all three writer procedures on INSERT. Indexed as part of a composite covering index with Gcid, BlockchainCryptoId, and Address. |
| 5 | Address | nvarchar(512) | NO | - | VERIFIED | The full blockchain address string that has been verified. Format varies by blockchain: "0x..." for Ethereum, "addr1q..." for Cardano, various formats for Bitcoin. Has a dedicated nonclustered index for fast lookup by `GetTravelRuleWhitelistedAddress`. The uniqueness enforcement logic checks this column across all customers. |
| 6 | ProofOfOwnership | nvarchar(max) | NO | - | CODE-BACKED | The actual proof data - either the cryptographic signature bytes or the signed declaration text. Stored as a large text/blob since cryptographic signatures can be lengthy. Used for compliance audit purposes. |
| 7 | ProofOfOwnershipTypeId | tinyint | NO | - | VERIFIED | Method used to verify address ownership. FK to Dictionary.AddressOwnershipProofType: 1=Declaration (legal self-attestation), 2=Signature (cryptographic private key signing). In practice, 100% of current entries use Signature (2). See [Address Ownership Proof Type](../_glossary.md#address-ownership-proof-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProofOfOwnershipTypeId | Dictionary.AddressOwnershipProofType | FK | Type of proof used to verify address ownership (Declaration or Signature) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.AddTravelRuleWhitelistedAddress | INSERT target | WRITER | Inserts a new whitelisted address after uniqueness check |
| Eligibility.AddWhitelistedAddress | INSERT target | WRITER | Inserts a new whitelisted address after uniqueness check (near-identical to above) |
| Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus | INSERT target | WRITER | Inserts whitelist entry AND auto-approves pending travel rule transactions |
| Eligibility.GetTravelRuleWhitelistedAddress | FROM source | READER | Looks up the most recent whitelist entry for a given address |

---

## 6. Dependencies

This object has no code-level dependencies. FK target is a Dictionary table.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AddressOwnershipProofType | Table | FK target for ProofOfOwnershipTypeId column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.AddTravelRuleWhitelistedAddress | Stored Procedure | WRITER - inserts verified addresses |
| Eligibility.AddWhitelistedAddress | Stored Procedure | WRITER - inserts verified addresses |
| Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus | Stored Procedure | WRITER - inserts + auto-approves pending transactions |
| Eligibility.GetTravelRuleWhitelistedAddress | Stored Procedure | READER - checks if address is whitelisted |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | Id ASC | - | - | Active |
| IX_Eligibility_TravelRuleWhitelistedAddresses_Created_Gcid_BlockchainCryptoId_Address | NONCLUSTERED | Created ASC, Gcid ASC, BlockchainCryptoId ASC, Address ASC | - | - | Active |
| IX_TravelRuleWhitelistedAddresses_Address | NONCLUSTERED | Address ASC | - | - | Active |
| IX_TravelRuleWhitelistedAddresses_Gcid | NONCLUSTERED | Gcid ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TravelRuleWhitelistedAddresses_ProofOfOwnershipTypeId | FOREIGN KEY | ProofOfOwnershipTypeId -> Dictionary.AddressOwnershipProofType(Id). Ensures proof type is a recognized verification method. |

---

## 8. Sample Queries

### 8.1 Check if an address is whitelisted
```sql
SELECT TOP 1 Gcid, BlockchainCryptoId, Created, Address
FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = @Address
ORDER BY Id DESC
```

### 8.2 Get all whitelisted addresses for a customer
```sql
SELECT trwa.Id, trwa.BlockchainCryptoId, trwa.Address, trwa.Created, pt.Name AS ProofType
FROM Eligibility.TravelRuleWhitelistedAddresses trwa WITH (NOLOCK)
JOIN Dictionary.AddressOwnershipProofType pt WITH (NOLOCK) ON pt.Id = trwa.ProofOfOwnershipTypeId
WHERE trwa.Gcid = @Gcid
ORDER BY trwa.Created DESC
```

### 8.3 Count whitelisted addresses by blockchain
```sql
SELECT BlockchainCryptoId, COUNT(*) AS AddressCount
FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
GROUP BY BlockchainCryptoId
ORDER BY AddressCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.1/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.TravelRuleWhitelistedAddresses | Type: Table | Source: WalletDB/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.sql*
