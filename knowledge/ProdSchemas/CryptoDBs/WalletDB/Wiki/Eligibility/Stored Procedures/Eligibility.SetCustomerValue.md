# Eligibility.SetCustomerValue

> Records a customer eligibility status change event by inserting a new row into the CustomerValues event-sourcing table.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Eligibility.CustomerValues |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the sole writer to `Eligibility.CustomerValues` - the only way a customer's eligibility status change is recorded. Every call to this procedure creates an immutable event record capturing who changed the status, what it changed from, what it changed to, and the correlation context for tracing.

The procedure is called by the Eligibility Service whenever a set-status request passes the transition validation (checked via `GetAllowedUpdateCustomerValuesStatuses`). It timestamps the event with `GETUTCDATE()` and appends it to the event log. The customer's current eligibility status is always the `NewValue` of their most recent row.

---

## 2. Business Logic

### 2.1 Append-Only Event Creation

**What**: Creates an immutable event record for a customer eligibility change.

**Columns/Parameters Involved**: All parameters map directly to columns.

**Rules**:
- No validation is performed in this procedure - transition validation happens upstream in the Eligibility Service via `GetAllowedUpdateCustomerValuesStatuses`
- `Occured` is set to `GETUTCDATE()` (not passed as parameter) ensuring server-side timestamp consistency
- `@OldValue` defaults to NULL, meaning the caller may omit it for initial assignments
- No duplicate checking - calling this twice with the same parameters creates two identical events

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | VERIFIED | Global Customer ID whose eligibility status is being changed. |
| 2 | @ValueChangingSourceId | TINYINT (IN) | NO | - | VERIFIED | Source system triggering this change. FK to Dictionary.CustomerValueEligibilityChangingSource: 0=Unknown, 1=BackOffice, 2=Banking, 3=Crypto. |
| 3 | @OldValue | TINYINT (IN) | YES | NULL | VERIFIED | Previous eligibility status before this change. NULL for initial assignments. FK to Dictionary.EligibilityStatuses. |
| 4 | @NewValue | TINYINT (IN) | NO | - | VERIFIED | New eligibility status being assigned. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. |
| 5 | @CorrelationId | UNIQUEIDENTIFIER (IN) | NO | - | CODE-BACKED | Trace correlation identifier for linking this change to the originating operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT INTO | Eligibility.CustomerValues | WRITER | Creates a new event-sourced eligibility change record |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service after transition validation.

---

## 6. Dependencies

```
Eligibility.SetCustomerValue (procedure)
+-- Eligibility.CustomerValues (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.CustomerValues | Table | INSERT target for eligibility change events |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record an initial eligibility assignment
```sql
EXEC Eligibility.SetCustomerValue
    @Gcid = 12345678, @ValueChangingSourceId = 1,
    @NewValue = 0, @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
-- OldValue defaults to NULL (initial assignment)
```

### 8.2 Record a status upgrade
```sql
EXEC Eligibility.SetCustomerValue
    @Gcid = 12345678, @ValueChangingSourceId = 1,
    @OldValue = 0, @NewValue = 2, @CorrelationId = 'B2C3D4E5-F6A7-8901-BCDE-F12345678901'
-- OldValue = 0 (BlockedFromAccess) -> NewValue = 2 (AllOperations)
```

### 8.3 Verify the event was recorded
```sql
SELECT TOP 1 * FROM Eligibility.CustomerValues WITH (NOLOCK)
WHERE Gcid = 12345678 ORDER BY Occured DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Confirms this procedure writes to the "CustomerValuesEventSourcing" table (renamed to CustomerValues). The HLD describes the event sourcing pattern and identifies the Eligibility Service as the sole caller. |

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.SetCustomerValue | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.SetCustomerValue.sql*
