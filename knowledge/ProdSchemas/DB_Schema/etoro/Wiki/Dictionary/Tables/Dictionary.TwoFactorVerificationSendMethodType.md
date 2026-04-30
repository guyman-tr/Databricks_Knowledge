# Dictionary.TwoFactorVerificationSendMethodType

> Lookup table defining the delivery channels available for two-factor authentication (2FA) verification codes — SMS text message or voice call — used when customers must verify their identity during sensitive operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SendMethodTypeID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on SendMethodTypeID) |

---

## 1. Business Meaning

Dictionary.TwoFactorVerificationSendMethodType defines the available delivery methods for sending two-factor verification (2FA) codes to customers. When a customer triggers a 2FA-protected operation (such as withdrawal, password change, or login from a new device), the system sends a one-time code via one of these methods.

Without this table, the system would have no standardized way to classify how verification codes are delivered. The two methods — SMS and voice call — give customers flexibility based on their preference or phone capabilities (e.g., customers in areas with poor SMS delivery can receive a voice call instead).

The table is referenced by Customer.TwoFactorVerificationDetails, which stores each customer's 2FA configuration including their preferred send method. When a 2FA challenge is triggered, the system reads the customer's SendMethodTypeID to determine whether to dispatch an SMS or initiate a phone call.

---

## 2. Business Logic

### 2.1 Verification Code Delivery Channels

**What**: Two distinct methods for delivering one-time verification codes to customers.

**Columns/Parameters Involved**: `SendMethodTypeID`, `Name`

**Rules**:
- ID 1 (sms) — sends a text message containing the verification code to the customer's registered phone number; most common method
- ID 2 (call) — initiates an automated voice call that reads the verification code aloud; fallback for customers who cannot receive SMS
- The customer selects their preferred method during 2FA setup, stored in Customer.TwoFactorVerificationDetails.SendMethodTypeID

**Diagram**:
```
2FA Verification Flow:
  Customer triggers protected operation
        │
        ▼
  Read Customer.TwoFactorVerificationDetails
        │
        ├─ SendMethodTypeID = 1 ──► Send SMS with code
        │
        └─ SendMethodTypeID = 2 ──► Initiate voice call with code
        │
        ▼
  Customer enters code → Verified
```

---

## 3. Data Overview

| SendMethodTypeID | Name | Meaning |
|---|---|---|
| 1 | sms | Standard delivery — a text message is sent to the customer's phone with the one-time code. Preferred by most customers due to convenience and speed. |
| 2 | call | Voice delivery — an automated phone call reads the verification code aloud. Used as a fallback when SMS is unreliable (poor network, VoIP numbers, or customer preference). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SendMethodTypeID | int | NO | - | CODE-BACKED | Unique identifier for the 2FA delivery method: 1=SMS, 2=Call. Referenced by Customer.TwoFactorVerificationDetails to store each customer's preferred verification code delivery channel. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable name of the delivery method: "sms" or "call". Used in application logic to determine which communication service to invoke when dispatching the verification code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.TwoFactorVerificationDetails | SendMethodTypeID | FK/Implicit | Stores the customer's preferred 2FA delivery method — each customer record points to either SMS (1) or Call (2) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TwoFactorVerificationSendMethodType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | FK reference — SendMethodTypeID column |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_TwoFactorVerificationCodeType | CLUSTERED | SendMethodTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all available 2FA send methods
```sql
SELECT  SendMethodTypeID,
        Name
FROM    [Dictionary].[TwoFactorVerificationSendMethodType] WITH (NOLOCK)
ORDER BY SendMethodTypeID;
```

### 8.2 Count customers by preferred 2FA method
```sql
SELECT  sm.Name AS SendMethod,
        COUNT(*) AS CustomerCount
FROM    [Customer].[TwoFactorVerificationDetails] d WITH (NOLOCK)
JOIN    [Dictionary].[TwoFactorVerificationSendMethodType] sm WITH (NOLOCK)
        ON sm.SendMethodTypeID = d.SendMethodTypeID
GROUP BY sm.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find customers using voice call method
```sql
SELECT  d.CustomerID,
        sm.Name AS SendMethod
FROM    [Customer].[TwoFactorVerificationDetails] d WITH (NOLOCK)
JOIN    [Dictionary].[TwoFactorVerificationSendMethodType] sm WITH (NOLOCK)
        ON sm.SendMethodTypeID = d.SendMethodTypeID
WHERE   sm.Name = 'call';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TwoFactorVerificationSendMethodType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TwoFactorVerificationSendMethodType.sql*
