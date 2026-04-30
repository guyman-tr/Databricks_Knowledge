# Dictionary.AddressOwnershipProofType

> Lookup table defining the types of evidence accepted for verifying cryptocurrency address ownership under travel rule compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the accepted forms of evidence that a customer can submit to prove they own an external cryptocurrency address. While AddressOwnershipProofOption defines whether proof is required at all, this table specifies the method of proof when it IS required.

Address ownership proof types are a compliance necessity under travel rule and AML regulations. When a customer declares or proves ownership of an address, the system records which type of proof was provided. This creates an audit trail for regulatory examination.

Rows are static reference data defined at deployment. The application layer references these IDs when recording the proof method chosen by the customer during the address verification workflow.

---

## 2. Business Logic

### 2.1 Proof Method Selection

**What**: Each proof type represents a different verification method with different levels of assurance.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Declaration` (1): The customer signs a legal declaration stating they own the address - a self-attestation approach requiring no cryptographic verification
- `Signature` (2): The customer proves ownership by signing a message with the private key associated with the address - cryptographic proof that is technically irrefutable

**Diagram**:
```
Customer wants to verify address ownership
    |
    +--> Declaration (1): Self-attestation, legal liability
    |       Lower technical barrier, higher legal risk
    |
    +--> Signature (2): Cryptographic proof via private key signing
            Higher technical barrier, irrefutable proof
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Declaration | Customer provides a signed legal declaration or attestation that they own the address. This method relies on legal accountability rather than technical proof, suitable for customers who may not be able to perform cryptographic signing. |
| 2 | Signature | Customer proves ownership by cryptographically signing a challenge message with the private key of the address. This is the strongest form of proof as it is mathematically verifiable and cannot be forged. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the proof type. Values: 1=Declaration, 2=Signature. Referenced by address verification records to indicate which proof method was used. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the proof type. Used in UI displays and compliance audit reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.TravelRuleWhitelistedAddresses | ProofOfOwnershipTypeId | FK | Records which proof method was used to verify address ownership |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all proof types
```sql
SELECT Id, Name
FROM Dictionary.AddressOwnershipProofType WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find addresses verified by cryptographic signature
```sql
SELECT wa.WalletAddressId, wa.Address, aopt.Name AS ProofType
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Dictionary.AddressOwnershipProofType aopt WITH (NOLOCK)
  ON wa.AddressOwnershipProofTypeId = aopt.Id
WHERE aopt.Id = 2 -- Signature
```

### 8.3 Count addresses by proof type
```sql
SELECT aopt.Id, aopt.Name, COUNT(wa.WalletAddressId) AS AddressCount
FROM Dictionary.AddressOwnershipProofType aopt WITH (NOLOCK)
LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK)
  ON wa.AddressOwnershipProofTypeId = aopt.Id
GROUP BY aopt.Id, aopt.Name
ORDER BY aopt.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AddressOwnershipProofType | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AddressOwnershipProofType.sql*
