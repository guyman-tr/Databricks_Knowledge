# Eligibility.CustomerValues

> Event-sourcing table that records every change to a customer's crypto eligibility status, capturing the old value, new value, source of the change, and correlation context.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + 1 unique nonclustered) |

---

## 1. Business Meaning

This table is the immutable event log for all customer-level crypto eligibility changes. Each row represents a single transition in a customer's access tier - from one eligibility status to another. The four possible statuses (BlockedFromAccess, ReadOnly, AllOperations, AllOperationsForExistingUsersOnly) determine what cryptocurrency operations a customer can perform on the platform.

This table exists because the platform needs a complete audit trail of every eligibility change for regulatory compliance, dispute resolution, and monitoring. Without it, there would be no way to trace when a customer's crypto access was restricted, who/what triggered the restriction, or what the previous state was. The Monitoring schema relies on it to detect anomalies like mismatched transitions or changes from unknown sources.

Data flows into this table exclusively through `Eligibility.SetCustomerValue`, which is called by the Eligibility Service whenever a customer's eligibility status changes. The change can originate from the BackOffice (manual compliance actions), the Banking system (automated based on fiat account events), the Crypto system (automated based on crypto portfolio rules), or an unknown/legacy source. The `Monitoring.FindValueMismatch` procedure reads this table to detect cases where consecutive records have discontinuous OldValue/NewValue pairs, and `Monitoring.GetCustomerValuesByUnknownSource` monitors for changes from unattributed sources.

---

## 2. Business Logic

### 2.1 Event Sourcing Pattern

**What**: Immutable append-only log where each row is a discrete state transition event.

**Columns/Parameters Involved**: `Id`, `Occured`, `OldValue`, `NewValue`

**Rules**:
- Rows are never updated or deleted - each change creates a new row via INSERT
- `OldValue` is NULL for initial assignments (first-time eligibility set for a customer) and populated for subsequent changes
- The `Occured` column has a UNIQUE index, enforcing that no two events can have the exact same timestamp (prevents ambiguous ordering)
- The latest row per `Gcid` (ordered by `Occured` DESC) represents the customer's current eligibility status

**Diagram**:
```
Customer 12345 Eligibility Timeline:
  [NULL] --BackOffice--> [BlockedFromAccess(0)]  -- initial assignment
         --Unknown----> [AllOperations(2)]       -- upgraded via auto-rule
         --BackOffice--> [ReadOnly(1)]           -- compliance restriction
```

### 2.2 Value Mismatch Detection

**What**: Monitoring logic that detects discontinuous transitions where a row's OldValue does not match the previous row's NewValue for the same customer.

**Columns/Parameters Involved**: `Gcid`, `Occured`, `OldValue`, `NewValue`

**Rules**:
- `Monitoring.FindValueMismatch` compares the latest two rows per customer
- If Row N's `OldValue` != Row N-1's `NewValue`, the transition is flagged as a mismatch
- Mismatches indicate either a race condition, a bug in the calling service, or an out-of-order event
- Only rows within a configurable lookback window (default 7 days) are checked

### 2.3 Change Source Attribution

**What**: Tracks which system or team triggered each eligibility change for audit and monitoring.

**Columns/Parameters Involved**: `ValueChangingSourceId`

**Rules**:
- Source 0 (Unknown) is monitored by `Monitoring.GetCustomerValuesByUnknownSource` as it indicates unattributed changes
- Source 1 (BackOffice) accounts for ~95% of all changes - manual compliance and support actions
- Source 2 (Banking) is defined but not currently observed in data
- Source 3 (Crypto) is extremely rare (3 records total)

---

## 3. Data Overview

| Id | Occured | Gcid | ValueChangingSourceId | OldValue | NewValue | Meaning |
|---|---|---|---|---|---|---|
| 821635 | 2026-04-15 10:40 | 36156975 | 1 | NULL | 1 | Initial eligibility assignment by BackOffice: customer granted ReadOnly crypto access. NULL OldValue confirms this is the customer's first eligibility record. |
| 821628 | 2026-04-15 10:36 | 47593487 | 0 | 1 | 2 | Eligibility upgrade from ReadOnly to AllOperations by an unknown/unattributed source. The OldValue=1 confirms the previous state, and the Unknown source (0) would be flagged by monitoring. |
| 821634 | 2026-04-15 10:39 | 27829827 | 1 | NULL | 0 | Initial eligibility assignment by BackOffice: customer blocked from crypto access. Most common pattern - ~87% of all assignments set BlockedFromAccess as the initial status. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Each row represents one eligibility change event. Used for ordering when timestamps collide (though the unique index on Occured prevents this). |
| 2 | Occured | datetime2(7) | NO | - | VERIFIED | UTC timestamp of when the eligibility change occurred. Set to `GETUTCDATE()` by `Eligibility.SetCustomerValue` on INSERT. Has a UNIQUE nonclustered index enforcing no duplicate timestamps. Used by monitoring procedures to scope lookback windows and detect recent mismatches. Per HLD: "when the change occurred." |
| 3 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID identifying the customer whose eligibility changed. ~750K distinct customers have eligibility records. Most customers have a single record (initial assignment); some have up to 64 changes over time. |
| 4 | ValueChangingSourceId | tinyint | NO | - | VERIFIED | Source system that triggered this eligibility change. FK to Dictionary.CustomerValueEligibilityChangingSource: 0=Unknown (unattributed, monitored by `Monitoring.GetCustomerValuesByUnknownSource`), 1=BackOffice (95.4% of changes - manual compliance/support actions), 2=Banking (automated fiat system - defined but not observed), 3=Crypto (automated crypto rules - extremely rare). See [Customer Value Eligibility Changing Source](../_glossary.md#customer-value-eligibility-changing-source). |
| 5 | OldValue | tinyint | YES | - | VERIFIED | Previous eligibility status before this change. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. NULL when this is the customer's first eligibility assignment (95.3% of records). Non-NULL values indicate a status transition. Used by `Monitoring.FindValueMismatch` to validate continuity with the prior record's NewValue. |
| 6 | NewValue | tinyint | NO | - | VERIFIED | New eligibility status after this change. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess (87.4% - most common initial assignment), 1=ReadOnly (11.3%), 2=AllOperations (1.2%), 3=AllOperationsForExistingUsersOnly (0.01%). Represents the customer's eligibility state going forward until the next change event. |
| 7 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Trace correlation identifier linking this eligibility change to the broader operation that triggered it. Enables tracing the change back through the Eligibility Service, Crypto Gateway, or BackOffice action that initiated it. Each change event has a unique correlation ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NewValue | Dictionary.EligibilityStatuses | FK | The new eligibility tier assigned to the customer. Resolves to one of 4 access levels (0-3). |
| OldValue | Dictionary.EligibilityStatuses | FK | The previous eligibility tier before this change. NULL for initial assignments. |
| ValueChangingSourceId | Dictionary.CustomerValueEligibilityChangingSource | FK | The system or team that triggered this change (Unknown/BackOffice/Banking/Crypto). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.SetCustomerValue | INSERT target | WRITER | The only procedure that creates rows in this table. Inserts a new event with GETUTCDATE() as the timestamp. |
| Monitoring.FindValueMismatch | FROM source | READER | Reads the last two rows per customer to detect OldValue/NewValue discontinuities. |
| Monitoring.GetCustomerValuesByUnknownSource | FROM source | READER | Reads recent rows where ValueChangingSourceId=0 to monitor unattributed changes. |

---

## 6. Dependencies

This object has no code-level dependencies. All FK targets are Dictionary tables (external schema).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EligibilityStatuses | Table | FK target for NewValue and OldValue columns |
| Dictionary.CustomerValueEligibilityChangingSource | Table | FK target for ValueChangingSourceId column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.SetCustomerValue | Stored Procedure | WRITER - inserts new eligibility change events |
| Monitoring.FindValueMismatch | Stored Procedure | READER - detects value mismatch anomalies |
| Monitoring.GetCustomerValuesByUnknownSource | Stored Procedure | READER - monitors unattributed source changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerValues | CLUSTERED | Id ASC | - | - | Active |
| UQ_CustomerValues_Occured | NONCLUSTERED (UNIQUE) | Occured ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CustomerValues_NewValue | FOREIGN KEY | NewValue -> Dictionary.EligibilityStatuses(Id). Ensures new status is a valid eligibility tier. |
| FK_CustomerValues_OldValue | FOREIGN KEY | OldValue -> Dictionary.EligibilityStatuses(Id). Ensures old status (when present) is a valid eligibility tier. |
| FK_CustomerValues_ValueChangingSourceId | FOREIGN KEY | ValueChangingSourceId -> Dictionary.CustomerValueEligibilityChangingSource(Id). Ensures change source is a known system. |

---

## 8. Sample Queries

### 8.1 Get latest eligibility status for a customer
```sql
SELECT TOP 1 cv.NewValue, es.Name AS CurrentStatus, cv.Occured
FROM Eligibility.CustomerValues cv WITH (NOLOCK)
JOIN Dictionary.EligibilityStatuses es WITH (NOLOCK) ON es.Id = cv.NewValue
WHERE cv.Gcid = @Gcid
ORDER BY cv.Occured DESC
```

### 8.2 Get full eligibility change history for a customer with source attribution
```sql
SELECT cv.Id, cv.Occured,
    oldEs.Name AS OldStatus, newEs.Name AS NewStatus,
    cs.ChangingSource
FROM Eligibility.CustomerValues cv WITH (NOLOCK)
LEFT JOIN Dictionary.EligibilityStatuses oldEs WITH (NOLOCK) ON oldEs.Id = cv.OldValue
JOIN Dictionary.EligibilityStatuses newEs WITH (NOLOCK) ON newEs.Id = cv.NewValue
JOIN Dictionary.CustomerValueEligibilityChangingSource cs WITH (NOLOCK) ON cs.Id = cv.ValueChangingSourceId
WHERE cv.Gcid = @Gcid
ORDER BY cv.Occured DESC
```

### 8.3 Find customers with multiple eligibility changes (volatile accounts)
```sql
SELECT TOP 20 Gcid, COUNT(*) AS ChangeCount,
    MIN(Occured) AS FirstChange, MAX(Occured) AS LastChange
FROM Eligibility.CustomerValues WITH (NOLOCK)
GROUP BY Gcid
HAVING COUNT(*) > 5
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Architecture HLD (July 2024) describing the eligibility refactoring. Confirms event sourcing pattern, identifies CustomerValues as the event log (originally named "CustomerValuesEventSourcing"). Provides the full status resolution matrix between group-level and customer-level statuses. Documents that the Eligibility Service is the "single point of truth" for user status determination. |

---

*Generated: 2026-04-15 | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.CustomerValues | Type: Table | Source: WalletDB/Eligibility/Tables/Eligibility.CustomerValues.sql*
