# Dictionary.TravelRuleComplianceOptions

> Lookup table defining the compliance action options available for travel rule address verification - identical to AddressOwnershipProofOption but specific to the travel rule compliance context.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines compliance action options within the travel rule verification workflow. The values (None, Blocked, Declaration, ProofOfOwnership) mirror `Dictionary.AddressOwnershipProofOption` but are used specifically in the travel rule compliance context, allowing different configuration for travel rule vs. general address verification.

No direct FK references found in the Wallet schema. Consumed by application-layer travel rule compliance logic.

---

## 2. Business Logic

### 2.1 Travel Rule Compliance Actions

**Rules**:
- `None` (0): No travel rule compliance action required
- `Blocked` (1): Address blocked pending travel rule compliance
- `Declaration` (2): Self-declaration of address ownership required
- `ProofOfOwnership` (3): Full cryptographic proof of ownership required

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | None | No compliance action needed for this travel rule scenario. Transaction may proceed without additional verification. |
| 1 | Blocked | Address is blocked until travel rule compliance requirements are met. No transactions permitted. |
| 2 | Declaration | Customer must provide a self-declaration of address ownership for travel rule compliance. |
| 3 | ProofOfOwnership | Full cryptographic proof of address ownership required for travel rule compliance. Highest verification level. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 0=None, 1=Blocked, 2=Declaration, 3=ProofOfOwnership. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Compliance action label. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found. Consumed by application-layer travel rule logic.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found.

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

### 8.1 List all compliance options
```sql
SELECT Id, Name FROM Dictionary.TravelRuleComplianceOptions WITH (NOLOCK) ORDER BY Id
```

### 8.2 Non-blocking options
```sql
SELECT Id, Name FROM Dictionary.TravelRuleComplianceOptions WITH (NOLOCK) WHERE Id != 1
```

### 8.3 Resolve option by ID
```sql
SELECT Name FROM Dictionary.TravelRuleComplianceOptions WITH (NOLOCK) WHERE Id = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TravelRuleComplianceOptions | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TravelRuleComplianceOptions.sql*
