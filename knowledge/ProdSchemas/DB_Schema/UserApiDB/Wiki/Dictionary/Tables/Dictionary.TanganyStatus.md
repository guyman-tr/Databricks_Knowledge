# Dictionary.TanganyStatus

> Lookup table defining the status of a user's Tangany crypto custody wallet under MiCA regulation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TanganyStatusID (TINYINT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.TanganyStatus tracks the lifecycle state of a user's Tangany crypto custody wallet. Tangany is a third-party regulated custodian used for secure crypto asset storage, particularly relevant under MiCA (Markets in Crypto-Assets) regulation. The wallet status determines whether a user can hold and transfer crypto assets.

This table supports eToro's MiCA compliance for crypto custody. MiCA requires that crypto assets be held in regulated custody solutions, and Tangany provides this service. The status tracks whether a wallet has been provisioned, is active, or has been deactivated.

---

## 2. Business Logic

### 2.1 Tangany Wallet Lifecycle

**What**: Wallet provisioning and activation states under MiCA regulation.

**Columns/Parameters Involved**: `TanganyStatusID`, `Name`

**Rules**:
- Pending (1) -> Customer (3) or MicaCustomer (5) or ConsentCustomer (6)
- Internal (2) is for test/employee wallets
- Inactive (4) = deactivated wallet
- MicaCustomer (5) specifically indicates MiCA-compliant custody
- ConsentCustomer (6) indicates explicit user consent for Tangany custody was recorded

---

## 3. Data Overview

| TanganyStatusID | Name | Meaning |
|---|---|---|
| 1 | Pending | Wallet creation requested, awaiting Tangany provisioning |
| 2 | Internal | Internal/test wallet - not customer-facing |
| 3 | Customer | Active customer wallet - standard crypto custody |
| 4 | Inactive | Wallet deactivated - no crypto operations allowed |
| 5 | MicaCustomer | Wallet operating under MiCA regulation compliance |
| 6 | ConsentCustomer | Wallet active with explicit user consent recorded for Tangany custody |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TanganyStatusID | tinyint | NO | - | CODE-BACKED | Primary key. Wallet state: 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. See [Tangany Status](_glossary.md#tangany-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Status label for crypto custody monitoring and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer crypto wallet tables | TanganyStatusID | Lookup | Stores current Tangany wallet status per user |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TanganyStatus | CLUSTERED PK | TanganyStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all Tangany statuses
```sql
SELECT TanganyStatusID, Name FROM Dictionary.TanganyStatus WITH (NOLOCK) ORDER BY TanganyStatusID
```

### 8.2 Find active Tangany wallets
```sql
SELECT w.CustomerID, ts.Name AS WalletStatus FROM Customer.TanganyWallets w WITH (NOLOCK)
JOIN Dictionary.TanganyStatus ts WITH (NOLOCK) ON w.TanganyStatusID = ts.TanganyStatusID
WHERE w.TanganyStatusID IN (3, 5, 6) -- Active customer wallets
```

### 8.3 MiCA wallet count
```sql
SELECT ts.Name, COUNT(*) AS WalletCount FROM Customer.TanganyWallets w WITH (NOLOCK)
JOIN Dictionary.TanganyStatus ts WITH (NOLOCK) ON w.TanganyStatusID = ts.TanganyStatusID
GROUP BY ts.Name ORDER BY WalletCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.TanganyStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.TanganyStatus.sql*
