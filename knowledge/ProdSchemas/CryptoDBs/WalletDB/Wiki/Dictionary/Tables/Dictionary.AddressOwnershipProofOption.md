# Dictionary.AddressOwnershipProofOption

> Lookup table defining the available options for proving ownership of a cryptocurrency wallet address, used in compliance and travel rule workflows.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the set of options a customer can use to prove they own an external cryptocurrency address. Address ownership verification is a regulatory compliance requirement under travel rule frameworks - when a customer wants to send crypto to an external address, the platform may require proof that the customer controls the destination.

Without this table, the system would have no standardized set of proof options to present to customers or to record against address records. It underpins the address ownership verification flow that supports AML/compliance requirements.

Data is static reference data managed by the platform. Rows are defined at deployment time and do not change during normal operations. The values are consumed by application-layer logic that determines which proof option applies to a given address or jurisdiction.

---

## 2. Business Logic

### 2.1 Ownership Proof Escalation

**What**: Different proof options represent increasing levels of assurance about address ownership.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `None` (0): No proof required - used when the address is pre-verified or the jurisdiction does not require ownership proof
- `Blocked` (1): The address is blocked from use until ownership can be established - no transactions permitted
- `Declaration` (2): Customer self-declares ownership via a signed statement or checkbox - lighter compliance touch
- `ProofOfOwnership` (3): Full cryptographic or documentary proof required - highest compliance burden, typically involves signing a message with the address private key

**Diagram**:
```
Proof Level:  None (0) --> Declaration (2) --> ProofOfOwnership (3)
                              |
                          Blocked (1) = Cannot proceed until resolved
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | None | No ownership proof is required for this address. Used when compliance rules do not mandate verification, or the address has already been verified through other means. |
| 1 | Blocked | The address is blocked pending ownership verification. No send or receive operations are permitted until the customer provides acceptable proof. |
| 2 | Declaration | Customer self-declares address ownership via a statement or UI acknowledgment. A lighter-touch verification suitable for lower-risk scenarios or jurisdictions with less stringent requirements. |
| 3 | ProofOfOwnership | Full proof of ownership is required, typically through cryptographic signing or documentary evidence. The highest level of verification, required for high-risk or regulated jurisdictions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the proof option. Values: 0=None, 1=Blocked, 2=Declaration, 3=ProofOfOwnership. Used as FK target by address-related tables in the Wallet schema. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the proof option. Serves as the display name in application UIs and audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found in the Wallet schema. This table is likely consumed by application-layer code that maps proof option IDs to business logic without an explicit database FK constraint.

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

### 8.1 List all proof options
```sql
SELECT Id, Name
FROM Dictionary.AddressOwnershipProofOption WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find addresses requiring full proof of ownership
```sql
SELECT wa.WalletAddressId, wa.Address, aopo.Name AS ProofOption
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Dictionary.AddressOwnershipProofOption aopo WITH (NOLOCK)
  ON wa.AddressOwnershipProofOptionId = aopo.Id
WHERE aopo.Id = 3 -- ProofOfOwnership
```

### 8.3 Distribution of proof options across addresses
```sql
SELECT aopo.Id, aopo.Name, COUNT(wa.WalletAddressId) AS AddressCount
FROM Dictionary.AddressOwnershipProofOption aopo WITH (NOLOCK)
LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK)
  ON wa.AddressOwnershipProofOptionId = aopo.Id
GROUP BY aopo.Id, aopo.Name
ORDER BY aopo.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AddressOwnershipProofOption | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AddressOwnershipProofOption.sql*
