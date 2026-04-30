# Dictionary.NotificationTrigger

> Defines the business events that trigger outbound customer notifications, mapping system events like processed cashouts and margin calls to notification workflows.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NotificationTriggerID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.NotificationTrigger enumerates the business events that cause the platform to send automated notifications to customers. Each trigger represents a specific scenario (withdrawal processed, withdrawal rejected, negative equity warning) that activates the notification engine.

Without this table, the notification system could not map system events to notification templates, making it impossible to configure which events generate customer communications.

The five triggers cover critical customer-facing events: cashout lifecycle notifications and equity protection warnings.

---

## 2. Business Logic

### 2.1 Trigger Event Categories

**What**: Five trigger events spanning withdrawal lifecycle and equity protection.

**Columns/Parameters Involved**: `NotificationTriggerID`, `Name`

**Rules**:
- ProcessedCashout (1): Withdrawal has been completed — funds sent to customer
- RejectedCashout (2): Withdrawal request was denied — customer needs to know why
- CanceledCashout (3): Withdrawal was cancelled (by customer or system)
- NegativeEquityInformant (4): Customer's equity has gone negative — informational warning
- NegativeEquityMarginCall (5): Customer's equity has gone critically negative — margin call requiring action

**Diagram**:
```
Trigger Events:
  Cashout Lifecycle ──> ProcessedCashout (1)
                    ──> RejectedCashout (2)
                    ──> CanceledCashout (3)
  
  Equity Protection ──> NegativeEquityInformant (4) [warning]
                    ──> NegativeEquityMarginCall (5) [urgent action required]
```

---

## 3. Data Overview

| NotificationTriggerID | Name | Meaning |
|---|---|---|
| 1 | ProcessedCashout | Customer's withdrawal has been successfully processed and funds are on their way — triggers confirmation notification |
| 2 | RejectedCashout | Customer's withdrawal request was rejected by compliance or system rules — triggers explanation notification |
| 3 | CanceledCashout | Customer's withdrawal was cancelled (either by the customer or automatically) — triggers cancellation confirmation |
| 4 | NegativeEquityInformant | Customer's account equity has gone negative but not critically — sends informational warning about potential risks |
| 5 | NegativeEquityMarginCall | Customer's equity has breached the margin call threshold — sends urgent notification requiring the customer to deposit funds or close positions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationTriggerID | int | NO | - | CODE-BACKED | Unique identifier for the trigger event: 1=ProcessedCashout, 2=RejectedCashout, 3=CanceledCashout, 4=NegativeEquityInformant, 5=NegativeEquityMarginCall. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable trigger event name. Used to configure notification-to-template mappings and in notification audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Notification engine | NotificationTriggerID | Implicit | Notification configuration maps triggers to templates |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase beyond the DDL itself. Consumed by application-level notification services.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | NotificationTriggerID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all notification triggers
```sql
SELECT  NotificationTriggerID,
        Name
FROM    [Dictionary].[NotificationTrigger] WITH (NOLOCK)
ORDER BY NotificationTriggerID;
```

### 8.2 Find cashout-related triggers
```sql
SELECT  *
FROM    [Dictionary].[NotificationTrigger] WITH (NOLOCK)
WHERE   Name LIKE '%Cashout%';
```

### 8.3 Equity protection triggers
```sql
SELECT  NotificationTriggerID,
        Name,
        CASE
            WHEN NotificationTriggerID = 4 THEN 'Warning - Informational'
            WHEN NotificationTriggerID = 5 THEN 'Critical - Action Required'
        END AS Severity
FROM    [Dictionary].[NotificationTrigger] WITH (NOLOCK)
WHERE   Name LIKE '%Equity%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationTrigger | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NotificationTrigger.sql*
