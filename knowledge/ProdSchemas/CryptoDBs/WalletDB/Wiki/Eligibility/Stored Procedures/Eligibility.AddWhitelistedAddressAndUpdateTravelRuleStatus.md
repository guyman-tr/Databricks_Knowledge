# Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus

> Registers a verified cryptocurrency address in the travel rule whitelist AND automatically approves all pending travel rule transactions from that address for the customer.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into TravelRuleWhitelistedAddresses + updates TransactionTravelRuleStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure combines address whitelisting with automatic approval of pending travel rule transactions. When a customer proves ownership of an external address, this procedure not only records the whitelist entry but also finds all pending travel rule transactions from that address and approves them (TravelRuleStatusId = 1). This is the most common flow in the travel rule verification process - the customer verifies an address, and previously held transactions are released.

Unlike the other two AddWhitelisted* procedures, this one has a cross-schema side effect: it writes to `Wallet.TransactionTravelRuleStatuses`, which triggers downstream processing of held transactions.

---

## 2. Business Logic

### 2.1 Address Whitelist + Auto-Approve

**What**: Two-step operation: whitelist the address, then approve pending transactions.

**Columns/Parameters Involved**: `@Address`, `@Gcid`, cross-schema tables

**Rules**:
- Step 1: Same uniqueness check as AddWhitelistedAddress - RAISERROR if address claimed by another customer
- Step 2: INSERT into Eligibility.TravelRuleWhitelistedAddresses
- Step 3: Find all TransactionTravelRuleInformation records where CounterpartyAddress = @Address AND the request belongs to @Gcid
- Step 4: INSERT TravelRuleStatusId = 1 (Approved) into Wallet.TransactionTravelRuleStatuses for each match
- Both steps execute in the same transaction - if whitelist insert succeeds, approvals also commit

**Diagram**:
```
Customer verifies address ownership
    |
    +-> [1] Uniqueness check (same as other SPs)
    |
    +-> [2] INSERT into TravelRuleWhitelistedAddresses
    |
    +-> [3] Find pending travel rule transactions
    |       WHERE CounterpartyAddress = @Address AND Gcid = @Gcid
    |
    +-> [4] INSERT Approved (1) into TransactionTravelRuleStatuses
            (releases held transactions)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID claiming ownership and whose pending transactions will be approved. |
| 2 | @BlockchainCryptoId | INT (IN) | NO | - | CODE-BACKED | Blockchain network identifier (1=Bitcoin, 2=Ethereum, etc.). |
| 3 | @Address | NVARCHAR(512) (IN) | NO | - | CODE-BACKED | The blockchain address being whitelisted and used to match pending transactions. |
| 4 | @ProofOfOwnership | NVARCHAR(MAX) (IN) | NO | - | CODE-BACKED | Proof data demonstrating address ownership. |
| 5 | @ProofOfOwnershipTypeId | TINYINT (IN) | NO | - | CODE-BACKED | Method of proof: 1=Declaration, 2=Signature. FK to Dictionary.AddressOwnershipProofType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT INTO | Eligibility.TravelRuleWhitelistedAddresses | WRITER | Creates whitelist entry |
| SELECT FROM | Eligibility.TravelRuleWhitelistedAddresses | READER | Uniqueness check |
| INSERT INTO | Wallet.TransactionTravelRuleStatuses | WRITER | Inserts Approved status for matched transactions |
| FROM | Wallet.TransactionTravelRuleInformation | JOIN | Matches by CounterpartyAddress |
| FROM | Wallet.Requests | LEFT JOIN | Links travel rule info to customer Gcid |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project.

---

## 6. Dependencies

```
Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus (procedure)
+-- Eligibility.TravelRuleWhitelistedAddresses (table)
+-- Wallet.TransactionTravelRuleStatuses (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.TravelRuleWhitelistedAddresses | Table | INSERT target and uniqueness check |
| Wallet.TransactionTravelRuleStatuses | Table | INSERT Approved status records |
| Wallet.TransactionTravelRuleInformation | Table | Match pending travel rule records by CounterpartyAddress |
| Wallet.Requests | Table | Link travel rule info to customer Gcid |

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

### 8.1 Whitelist address and auto-approve pending transactions
```sql
EXEC Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus
    @Gcid = 12345678, @BlockchainCryptoId = 2,
    @Address = '0xABC123...', @ProofOfOwnership = '0x..sig..', @ProofOfOwnershipTypeId = 2
```

### 8.2 Check which transactions were auto-approved
```sql
SELECT trts.Id, trts.TravelRuleStatusId, tri.CounterpartyAddress
FROM Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = trts.TransactionTravelRuleInformationId
WHERE tri.CounterpartyAddress = '0xABC123...' AND trts.TravelRuleStatusId = 1
ORDER BY trts.Id DESC
```

### 8.3 Find pending travel rule transactions for an address before whitelisting
```sql
SELECT tri.Id, tri.CounterpartyAddress, r.Gcid
FROM Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK)
LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON tri.RequestId = r.Id
WHERE tri.CounterpartyAddress = @Address AND r.Gcid = @Gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.AddWhitelistedAddressAndUpdateTravelRuleStatus.sql*
