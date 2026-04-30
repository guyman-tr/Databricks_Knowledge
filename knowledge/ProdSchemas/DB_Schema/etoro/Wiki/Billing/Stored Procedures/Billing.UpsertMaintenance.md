# Billing.UpsertMaintenance

> MERGE upsert that sets the operational status (Active or UnderMaintenance) for a payment method in Billing.Maintenance, immediately controlling its visibility in the deposit and withdrawal UI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpsertMaintenance` is the runtime write path for `Billing.Maintenance`, the table that controls whether each payment method (FundingTypeID) is operational or under maintenance. When called with `@StatusID=3` (UnderMaintenance), the payment method is immediately hidden from the deposit and withdrawal UI - no new transactions can be initiated. When called with `@StatusID=1` (Active), it is restored.

The procedure performs a MERGE on `FundingTypeID`: if a Maintenance record already exists, it updates the StatusID, always resets ScheduledFrom/ScheduledTo to NULL, and sets the Description. If no record exists, it inserts one. This ensures exactly one row per payment method.

The Maintenance table is read by `Billing.GetCustomerDepositInfo` when assembling the deposit page context. Every write to `Billing.Maintenance` is automatically archived to `History.Maintenance` via trigger `Tr_Billing_Maintenance`, providing a full history of payment method availability changes.

This SP is typically called by Back Office operators or automated monitoring systems to toggle payment method availability during provider outages or planned maintenance windows.

---

## 2. Business Logic

### 2.1 MERGE Upsert on FundingTypeID

**What**: Atomically inserts or updates the maintenance status for a given payment method type.

**Columns/Parameters Involved**: `@FundingTypeID`, `@StatusID`, `@Description`, `Billing.Maintenance`

**Rules**:
- MERGE target: `Billing.Maintenance`
- MERGE source: single-row inline `SELECT @FundingTypeID AS FundingTypeID`
- Match condition: `target.FundingTypeID = source.FundingTypeID`
- WHEN MATCHED (record exists): Updates `StatusID = @StatusID`, `ScheduledFrom = NULL`, `ScheduledTo = NULL`, `Description = @Description`
- WHEN NOT MATCHED (no record): Inserts `(FundingTypeID, StatusID, ScheduledFrom, ScheduledTo, Description)` with NULLs for the scheduled fields
- Wrapped in TRY/CATCH with explicit COMMIT/ROLLBACK

**Diagram**:
```
@FundingTypeID, @StatusID, @Description
  -> MERGE Billing.Maintenance ON FundingTypeID

  MATCHED (exists)   -> UPDATE StatusID=@StatusID, ScheduledFrom=NULL, ScheduledTo=NULL, Description=@Description
  NOT MATCHED        -> INSERT (FundingTypeID, @StatusID, NULL, NULL, @Description)

  -> Tr_Billing_Maintenance trigger -> INSERT to History.Maintenance (automatic, async)
```

### 2.2 StatusID Values

**What**: Controls payment method visibility in the deposit/withdrawal UI.

**Rules** (Source: DDL comment + Billing.Maintenance docs):

| StatusID | Meaning | UI Behavior |
|----------|---------|-------------|
| 1 | Active | Payment method shown in deposit/cashout UI; transactions allowed |
| 3 | UnderMaintenance | Payment method hidden from UI; no new transactions allowed |
| 5 | InActive | Reserved for decommissioned methods (no rows currently use this) |

### 2.3 ScheduledFrom / ScheduledTo Always Reset to NULL

**What**: The MERGE always sets ScheduledFrom and ScheduledTo to NULL, even when updating an existing record.

**Rules**:
- Historical Billing.Maintenance rows show scheduled maintenance windows (dates from 2017 and 2021) set via direct SQL
- This SP does NOT support scheduling - it applies changes immediately with NULL schedule fields
- If a scheduled maintenance window must be set, it requires a direct UPDATE on Billing.Maintenance, not this SP
- The Description parameter is optional (NVARCHAR(500), default NULL) and captures a human-readable note (e.g., "Start", "End", reason for maintenance)

### 2.4 Transaction and Error Handling

**Rules**:
- `BEGIN TRANSACTION` / `COMMIT TRANSACTION` wraps the MERGE
- CATCH: `IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION` + `THROW` re-propagates
- Note: ROLLBACK without the @@TRANCOUNT=1 check is safe here since the SP does not support nested transactions (single-layer TRY/CATCH)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | The payment method type identifier. FK to `Billing.FundingType.FundingTypeID`. Used as the MERGE key - one status row per FundingTypeID. Examples: 1=CreditCard, 2=WireTransfer, 10=WebMoney, 21=Yandex, 35=Trustly. |
| 2 | @StatusID | INT | NO | - | CODE-BACKED | The new operational status: 1=Active (shown in UI), 3=UnderMaintenance (hidden from UI). DDL comment confirms these two primary values. Value 5=Inactive is reserved but unused. |
| 3 | @Description | NVARCHAR(500) | YES | NULL | CODE-BACKED | Optional human-readable note for the status change (e.g., "Provider outage", "Scheduled maintenance", "Start"). Stored in Billing.Maintenance.Description. NULL is acceptable for automated calls. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Billing.Maintenance | MERGE (UPDATE or INSERT) | Upserts the maintenance status row for this payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back Office (application) | Maintenance management tools | Application call | Operators toggle payment method availability |
| Automated monitoring (application) | Payment provider health checks | Application call | Systems call to put methods under maintenance on provider errors |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpsertMaintenance (procedure)
+-- Billing.Maintenance (table) [MERGE - UPDATE or INSERT]
    +-- Tr_Billing_Maintenance (trigger) -> History.Maintenance [INSERT - automatic history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Maintenance | Table | MERGE target: upserts payment method status by FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back Office / operations tooling (application) | Application | Calls to manage payment method availability at runtime |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ScheduledFrom/To always NULL | Design | Scheduling via this SP is not supported; date window updates require direct SQL |
| History via trigger | Design | All writes auto-archived to History.Maintenance by Tr_Billing_Maintenance; no explicit history INSERT needed in this SP |
| Single-layer transaction | Design | No nested transaction support (uses IF @@TRANCOUNT > 0 ROLLBACK, not @@TRANCOUNT = 1) |

---

## 8. Sample Queries

### 8.1 Put a payment method under maintenance
```sql
EXEC Billing.UpsertMaintenance
    @FundingTypeID = 35,           -- Trustly
    @StatusID      = 3,            -- UnderMaintenance
    @Description   = N'Provider outage - circuit breaker triggered';
```

### 8.2 Restore a payment method to active
```sql
EXEC Billing.UpsertMaintenance
    @FundingTypeID = 35,           -- Trustly
    @StatusID      = 1,            -- Active
    @Description   = N'Provider restored';
```

### 8.3 Check all payment methods currently under maintenance
```sql
SELECT
    m.ID,
    m.FundingTypeID,
    m.StatusID,
    CASE m.StatusID
        WHEN 1 THEN 'Active'
        WHEN 3 THEN 'UnderMaintenance'
        WHEN 5 THEN 'Inactive'
        ELSE 'Unknown'
    END AS StatusLabel,
    m.Description,
    m.ScheduledFrom,
    m.ScheduledTo
FROM Billing.Maintenance m WITH (NOLOCK)
WHERE m.StatusID = 3
ORDER BY m.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpsertMaintenance | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpsertMaintenance.sql*
