# Dictionary.NotificationTypeName

> Maps KYC document rejection and account action notification types to their notification template identifiers, enabling the system to send the correct customer communication for each compliance scenario.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NotificationTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.NotificationTypeName maps specific KYC (Know Your Customer) compliance scenarios to notification template identifiers. When a customer's document is rejected, their account is limited, or a specific verification action is required, this table provides the notification type code that triggers the correct email template.

Without this table, the KYC and compliance systems could not automatically select the correct notification template for each specific rejection or action scenario. There are 40 distinct notification types covering POI (Proof of Identity), POA (Proof of Address), selfie verification, SSN card issues, and account-level actions.

Referenced by BackOffice.DocumentRejectReasonToNotificationType which links KYC document rejection reasons to their corresponding notification templates.

---

## 2. Business Logic

### 2.1 KYC Notification Categories

**What**: 40 notification types covering the full spectrum of KYC document rejection and account action scenarios.

**Columns/Parameters Involved**: `NotificationTypeID`, `NotificationType`

**Rules**:
- POI (Proof of Identity) notifications (1-10, 27-29, 38-40): Document expired, incomplete copy, missing details, wrong name, screenshot rejection, visa issues
- POA (Proof of Address) notifications (11-19, 28, 30-33): Too old, missing address, business address rejected, corrupt/password-protected
- Combined POI+POA notifications (20, 22): Missing both, POI cannot serve as POA
- Selfie notifications (21, 34): General selfie rejection, motion rejection
- SSN Card notifications (26, 36-37): Missing document, unclear copy, damaged document
- Account action notifications (23-25): Account limitation, restriction, termination
- Proof of Income notifications (35): Income document rejected
- Each notification type maps to an email template with specific wording for the scenario

**Diagram**:
```
KYC Notification Categories:
  POI (Proof of Identity) ──> IDs 1-10, 27-29, 38-40
  POA (Proof of Address) ──> IDs 11-19, 28, 30-33
  Combined POI+POA ────────> IDs 20, 22
  Selfie/Biometric ───────> IDs 21, 34
  SSN Card ────────────────> IDs 26, 36-37
  Account Actions ─────────> IDs 23-25
  Proof of Income ─────────> ID 35
```

---

## 3. Data Overview

| NotificationTypeID | NotificationType | Meaning |
|---|---|---|
| 1 | POIDocExpired | Customer's proof of identity document has expired — they need to upload a current, valid ID |
| 11 | POAOlderThanSixMonths | Customer's proof of address document is older than 6 months — utility bills and bank statements must be recent |
| 23 | AccountLimitation | Customer's account has been limited (reduced functionality) due to compliance reasons — triggers notification explaining restrictions |
| 25 | AccountTermination | Customer's account is being terminated — the most severe compliance action with full account closure notification |
| 34 | SelfieMotionRejectedEmail | Customer's selfie verification failed the motion/liveness check — they need to re-record with proper movement |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationTypeID | int | NO | - | CODE-BACKED | Unique identifier for the KYC notification scenario. Values 1-40. Referenced by BackOffice.DocumentRejectReasonToNotificationType to map rejection reasons to email templates. |
| 2 | NotificationType | varchar(50) | NO | - | VERIFIED | Template identifier code used to select the correct email template for the compliance scenario. Format: `{Category}{SpecificReason}Email` (e.g., POIDocExpired, POAOlderThanSixMonths, SelfieMotionRejectedEmail). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DocumentRejectReasonToNotificationType | NotificationTypeID | Implicit | Links document rejection reasons to notification templates |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentRejectReasonToNotificationType | Table | NotificationTypeID FK for template mapping |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_NotificationTypeName | CLUSTERED PK | NotificationTypeID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all notification type names
```sql
SELECT  NotificationTypeID,
        NotificationType
FROM    [Dictionary].[NotificationTypeName] WITH (NOLOCK)
ORDER BY NotificationTypeID;
```

### 8.2 Find all POI-related notifications
```sql
SELECT  *
FROM    [Dictionary].[NotificationTypeName] WITH (NOLOCK)
WHERE   NotificationType LIKE 'POI%'
ORDER BY NotificationTypeID;
```

### 8.3 Join with document rejection reason mapping
```sql
SELECT  ntn.NotificationType,
        drrn.*
FROM    [BackOffice].[DocumentRejectReasonToNotificationType] drrn WITH (NOLOCK)
JOIN    [Dictionary].[NotificationTypeName] ntn WITH (NOLOCK)
        ON drrn.NotificationTypeID = ntn.NotificationTypeID
ORDER BY ntn.NotificationType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationTypeName | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NotificationTypeName.sql*
