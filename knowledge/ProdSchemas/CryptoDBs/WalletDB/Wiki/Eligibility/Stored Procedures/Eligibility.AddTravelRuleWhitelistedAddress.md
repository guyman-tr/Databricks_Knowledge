# Eligibility.AddTravelRuleWhitelistedAddress

> Registers a verified cryptocurrency address in the travel rule whitelist after validating it is not already claimed by a different customer.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Eligibility.TravelRuleWhitelistedAddresses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds a blockchain address to the travel rule whitelist for a customer. Once whitelisted, incoming transactions from this address may bypass manual travel rule approval. The procedure enforces address uniqueness across customers - the same address cannot be whitelisted for two different Gcid/BlockchainCryptoId combinations.

The procedure is called after a customer proves ownership of an external address (via cryptographic signature or legal declaration). It does NOT auto-approve pending transactions - for that, use `AddWhitelistedAddressAndUpdateTravelRuleStatus`.

---

## 2. Business Logic

### 2.1 Address Uniqueness Validation

**What**: Prevents the same address from being claimed by different customers.

**Columns/Parameters Involved**: `@Address`, `@Gcid`, `@BlockchainCryptoId`

**Rules**:
- Checks if the address exists for a DIFFERENT Gcid OR BlockchainCryptoId
- If conflict found: RAISERROR('Address already whitelisted for another GCID and BlockchainCryptoId', 16, 1) and RETURN
- Same customer re-registering the same address is allowed (creates a duplicate row)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID claiming ownership of the address. |
| 2 | @BlockchainCryptoId | INT (IN) | NO | - | CODE-BACKED | Blockchain network identifier for the address (1=Bitcoin, 2=Ethereum, etc.). |
| 3 | @Address | NVARCHAR(512) (IN) | NO | - | CODE-BACKED | The full blockchain address string being whitelisted. |
| 4 | @ProofOfOwnership | NVARCHAR(MAX) (IN) | NO | - | CODE-BACKED | The proof data (signature bytes or declaration text) demonstrating address ownership. |
| 5 | @ProofOfOwnershipTypeId | TINYINT (IN) | NO | - | CODE-BACKED | Method of proof: 1=Declaration, 2=Signature. FK to Dictionary.AddressOwnershipProofType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT INTO | Eligibility.TravelRuleWhitelistedAddresses | WRITER | Creates a new whitelist entry |
| SELECT FROM | Eligibility.TravelRuleWhitelistedAddresses | READER | Uniqueness check before insert |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service application layer.

---

## 6. Dependencies

```
Eligibility.AddTravelRuleWhitelistedAddress (procedure)
+-- Eligibility.TravelRuleWhitelistedAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.TravelRuleWhitelistedAddresses | Table | INSERT target and uniqueness check source |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Register a Bitcoin address
```sql
EXEC Eligibility.AddTravelRuleWhitelistedAddress
    @Gcid = 12345678,
    @BlockchainCryptoId = 1,
    @Address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
    @ProofOfOwnership = '0x..signature_data..',
    @ProofOfOwnershipTypeId = 2
```

### 8.2 Verify an address was added
```sql
SELECT TOP 1 * FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'
ORDER BY Id DESC
```

### 8.3 Check for address conflicts before adding
```sql
SELECT Gcid, BlockchainCryptoId FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = @Address AND (Gcid != @Gcid OR BlockchainCryptoId != @BlockchainCryptoId)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.AddTravelRuleWhitelistedAddress | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.AddTravelRuleWhitelistedAddress.sql*
