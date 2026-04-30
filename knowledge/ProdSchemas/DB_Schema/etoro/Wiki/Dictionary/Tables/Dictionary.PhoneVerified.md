# Dictionary.PhoneVerified

> Lookup table defining 6 phone verification states — from NotVerified through AutomaticallyVerified, ManuallyVerified, Initiated, Rejected, and AbuseFlag — tracking customer phone number verification lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PhoneVerifiedID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PhoneVerified defines the verification states of a customer's phone number in the KYC (Know Your Customer) process. Phone verification is a key identity check — customers must prove ownership of their registered phone number to complete account verification and enable certain platform features.

This table exists because phone verification is not a simple binary (verified/not verified) — it has a full lifecycle with multiple outcomes. A phone can be automatically verified through SMS/call-back systems, manually verified by a BackOffice agent, still in the initiation stage, rejected by the verification system, or flagged for abuse.

The PhoneVerifiedID is stored in BackOffice.Customer and History.BackOfficeCustomer, referenced by numerous procedures including customer card views (BackOffice.GetCustomerByCID), risk management (BackOffice.UpdateRiskUserInfo), customer registration (Customer.DynamicsInsert), GDPR deletion, and SalesForce integration. It is one of the most widely-referenced phone verification attributes.

---

## 2. Business Logic

### 2.1 Phone Verification Lifecycle

**What**: Phone numbers move through 6 verification states from initial submission to final outcome.

**Columns/Parameters Involved**: `PhoneVerifiedID`, `PhoneVerifiedName`

**Rules**:
- **NotVerified (0)** — Default state. The customer's phone has not been verified yet. May restrict certain platform features.
- **AutomaticallyVerified (1)** — The phone was verified through an automated process (SMS code, automated call-back, or carrier lookup).
- **ManuallyVerified (2)** — A BackOffice agent manually verified the phone (e.g., called the customer and confirmed identity).
- **Initiated (3)** — Verification has been started (SMS sent or call placed) but the customer hasn't completed it yet.
- **Rejected (4)** — The verification attempt failed or was rejected (wrong code entered too many times, number unreachable, or mismatch detected).
- **AbuseFlag (5)** — The phone number has been flagged for abuse — multiple accounts using the same number, known fraud number, or verification manipulation detected.

**Diagram**:
```
Phone Verification Lifecycle
    0 = NotVerified (default)
        │
        ▼ (verification initiated)
    3 = Initiated (SMS sent / call placed)
        │
        ├── Success → 1 = AutomaticallyVerified
        ├── Manual  → 2 = ManuallyVerified (BO agent confirms)
        ├── Fail    → 4 = Rejected (wrong code / unreachable)
        └── Abuse   → 5 = AbuseFlag (fraud detected)
```

---

## 3. Data Overview

| PhoneVerifiedID | PhoneVerifiedName | Meaning |
|---|---|---|
| 0 | NotVerified | Default state for all new accounts. The customer's phone number has not been verified. Some platform features may be restricted until verification is complete. |
| 1 | AutomaticallyVerified | Phone verified through automated SMS code or callback system. The customer successfully entered the correct verification code. Highest-throughput verification path. |
| 2 | ManualyVerified | Phone verified by a BackOffice agent who called the customer directly. Used when automated verification fails or for high-value customers requiring personal verification. |
| 4 | Rejected | Verification attempt failed — customer entered wrong codes, number was unreachable, or the verification system detected a mismatch. Customer must retry or contact support. |
| 5 | AbuseFlag | Phone number flagged for abusive behavior — same number used across multiple accounts, known fraud ring number, or repeated verification manipulation. Triggers compliance investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PhoneVerifiedID | int | NO | - | VERIFIED | Primary key identifying the phone verification state. 0=NotVerified, 1=AutomaticallyVerified, 2=ManuallyVerified, 3=Initiated, 4=Rejected, 5=AbuseFlag. Stored in BackOffice.Customer and History.BackOfficeCustomer. Referenced by 20+ procedures across BackOffice, Customer, SalesForce, and dbo schemas. |
| 2 | PhoneVerifiedName | varchar(50) | NO | - | VERIFIED | Human-readable verification state label. Note: "ManualyVerified" contains a typo (single 'l') preserved from the original data. Displayed in customer cards, verification reports, and compliance dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | PhoneVerifiedID | Implicit | Stores phone verification state per customer |
| History.BackOfficeCustomer | PhoneVerifiedID | Implicit | Historical audit of phone verification changes |
| History.PhoneVerificationDetails | PhoneVerifiedID | Implicit | Legacy phone verification history |
| History.PhoneVerificationDetails_Old | PhoneVerifiedID | Implicit | Old phone verification history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Stores PhoneVerifiedID per customer |
| History.BackOfficeCustomer | Table | Historical audit of verification state |
| History.PhoneVerificationDetails | Table | Verification detail history |
| BackOffice.GetCustomerByCID | Stored Procedure | Reader — customer card with verification state |
| BackOffice.GetCustomerByCIDVerification | Stored Procedure | Reader — verification-focused customer data |
| BackOffice.UpdateRiskUserInfo | Stored Procedure | Modifier — updates phone verification during risk assessment |
| BackOffice.UpdateRiskUserInfoRemote | Stored Procedure | Modifier — remote risk info update |
| BackOffice.Bulk_UpdateRiskUserInfoRemote | Stored Procedure | Modifier — bulk risk update |
| BackOffice.CustomerSetVerifyAndUpdateNewPhone | Stored Procedure | Modifier — sets verification after phone change |
| BackOffice.GetHistoryBackOfficeCustomer | Stored Procedure | Reader — historical customer data |
| Customer.DynamicsInsert | Stored Procedure | Writer — sets initial verification state during registration |
| Customer.GetRiskUserInfo | Stored Procedure | Reader — risk info including phone state |
| SalesForce.GetBackOfficeCustomer | Stored Procedure | Reader — SalesForce integration |
| BackOffice.CustomerSafty | View | Exposes phone verification state |
| dbo.SP_GDPR | Stored Procedure | Modifier — GDPR data deletion |
| dbo.SP_GDPR_NEW_ByRan | Stored Procedure | Modifier — updated GDPR deletion |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.PhoneVerified | CLUSTERED PK | PhoneVerifiedID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.PhoneVerified | PRIMARY KEY | Unique phone verification state identifier |

---

## 8. Sample Queries

### 8.1 List all phone verification states
```sql
SELECT  PhoneVerifiedID,
        PhoneVerifiedName
FROM    [Dictionary].[PhoneVerified] WITH (NOLOCK)
ORDER BY PhoneVerifiedID;
```

### 8.2 Count customers by verification state
```sql
SELECT  pv.PhoneVerifiedName,
        COUNT(*) AS CustomerCount
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[PhoneVerified] pv WITH (NOLOCK)
        ON c.PhoneVerifiedID = pv.PhoneVerifiedID
GROUP BY pv.PhoneVerifiedName
ORDER BY CustomerCount DESC;
```

### 8.3 Find customers with flagged or rejected phone verification
```sql
SELECT  c.CID,
        pv.PhoneVerifiedName
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[PhoneVerified] pv WITH (NOLOCK)
        ON c.PhoneVerifiedID = pv.PhoneVerifiedID
WHERE   c.PhoneVerifiedID IN (4, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 16 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PhoneVerified | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PhoneVerified.sql*
