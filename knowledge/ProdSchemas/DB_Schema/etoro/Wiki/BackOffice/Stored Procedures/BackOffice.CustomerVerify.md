# BackOffice.CustomerVerify

> Sets the identity verification status (Verified flag) for a customer in BackOffice.Customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerVerify sets or clears the `Verified` bit on a customer's BackOffice profile, indicating whether the customer has passed identity verification. `Verified = 1` means the customer's identity has been confirmed (document check, face match, etc.) enabling full platform access and higher deposit/withdrawal limits. `Verified = 0` unverifies a customer - typically done during a re-verification process or when documents are found to be invalid.

As documented in BackOffice.Customer, 46.9% of customers (8.79M) are Verified=1. The Verified column coexists with VerificationLevelID (more granular, 0-3 scale) - a customer can have Verified=1 while VerificationLevelID < 3 if they were verified under an older workflow.

The procedure is one of the most widely used BackOffice operations - granted to all regional BackOffice teams and accessible to agents across all geographies.

---

## 2. Business Logic

### 2.1 Unconditional Verification Toggle

**What**: Directly sets the Verified flag without checking current state.

**Columns/Parameters Involved**: `@CID`, `@Verified`, `BackOffice.Customer.Verified`

**Rules**:
- UPDATE fires unconditionally: Verified = @Verified WHERE CID = @CID.
- Returns @@ERROR. 0 = success.
- History captured by BackOffice.Customer UPDATE trigger -> History.BackOfficeCustomer (ValidFrom/ValidTo timestamps).
- @Verified = 1: marks customer as identity-verified.
- @Verified = 0: removes verification - customer may lose access to certain features or need re-verification.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Internal Customer ID. Identifies the customer whose Verified flag is being set. |
| 2 | @Verified | BIT | NO | - | CODE-BACKED | Identity verification result: 1 = customer has passed identity verification and is confirmed, 0 = customer is not verified or has been de-verified. Written to BackOffice.Customer.Verified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE target - sets the Verified flag on the customer's compliance profile. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC/verification workflow | EXEC | Caller | Called when a compliance agent approves or rejects a customer's identity verification. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerVerify (procedure)
└── BackOffice.Customer (table) - UPDATE Verified flag
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets Verified = @Verified WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice KYC workflow | External | EXEC - called during identity verification approval/rejection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@ERROR return | Convention | Returns SQL error code. 0 = success. |
| No guard condition | Behavior | UPDATE fires even if @Verified equals current value - no idempotency check. |

---

## 8. Sample Queries

### 8.1 Verify a customer (approve identity)
```sql
EXEC BackOffice.CustomerVerify @CID = 12345678, @Verified = 1
```

### 8.2 De-verify a customer (flag for re-verification)
```sql
EXEC BackOffice.CustomerVerify @CID = 12345678, @Verified = 0
```

### 8.3 Check verification status and history for a customer
```sql
SELECT bc.CID, cs.UserName, bc.Verified, bc.VerificationLevelID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
WHERE bc.CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerVerify | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerVerify.sql*
