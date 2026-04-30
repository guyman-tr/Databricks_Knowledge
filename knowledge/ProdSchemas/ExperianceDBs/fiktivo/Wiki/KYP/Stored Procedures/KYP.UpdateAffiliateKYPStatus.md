# KYP.UpdateAffiliateKYPStatus

> Updates the KYP verification status, progress, and lifecycle timestamps for an affiliate, with status transition guards and optimistic concurrency protection.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (identifies target), returns updated status via EXEC GetAffiliateKYPStatus |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYP.UpdateAffiliateKYPStatus manages KYP verification status transitions for an affiliate. It is the controlled way to change KYPStatusID, Progress, TicketID, SubmittedOn, CanceledOn, and PopupDismissed. The procedure enforces two critical guards: (1) the current status must be in the allowed transitions list (@AllowedKYPStatusIDs), and (2) no significant change (SubmittedOn or CanceledOn) has occurred after a specified cutoff time (@AllowWhenNoSignificantChangeAfter).

This procedure is called by the application when the compliance team reviews or transitions a KYP submission (e.g., moving from "In Progress" to "Submitted", or from "Submitted" to "Verified"). The guards prevent race conditions where two reviewers try to transition the same affiliate simultaneously.

After a successful update, the procedure calls `KYP.GetAffiliateKYPStatus` to return the new state to the caller. If the update affects 0 rows (guards not met), it THROWs error 51000 with the current KYPStatusID in the message.

Created by Ran Ovadia (11/08/2020). Updated (12/10/2021) for detailed error messages.

---

## 2. Business Logic

### 2.1 Status Transition Guards

**What**: Prevents invalid or concurrent KYP status changes.

**Columns/Parameters Involved**: `@AllowedKYPStatusIDs`, `@AllowWhenNoSignificantChangeAfter`

**Rules**:
- @AllowedKYPStatusIDs (IDTableType TVP): the current KYPStatusID must be IN this list for the update to proceed. This enforces the state machine - e.g., only allow transition FROM "In Progress" to "Submitted"
- @AllowWhenNoSignificantChangeAfter: if provided, the update only proceeds if BOTH SubmittedOn and CanceledOn are NULL or older than this timestamp. This is optimistic concurrency - prevents updating a record that was modified by another process after the caller read it
- If @@ROWCOUNT = 0 after UPDATE: THROW 51000 with message "Allowed conditions not met, CurrentKYPStatusID {current}"
- ISNULL pattern: only non-NULL parameters overwrite existing values (partial update support)

**Diagram**:
```
Application reads affiliate status
    |
    v
Application calls UpdateAffiliateKYPStatus
    |
    v
WHERE AffiliateID = @ID
  AND KYPStatusID IN (@AllowedKYPStatusIDs)     <-- State machine guard
  AND (no change after @AllowWhenNo...)          <-- Concurrency guard
    |
    +--> 0 rows affected --> THROW 51000
    |
    +--> 1 row affected --> EXEC GetAffiliateKYPStatus (return new state)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Target affiliate to update. |
| 2 | @StatusID | int (IN) | YES | NULL | CODE-BACKED | New KYPStatusID. NULL = keep current value. Maps to Dictionary.KYPStatus (1-7). |
| 3 | @Progress | int (IN) | YES | NULL | CODE-BACKED | New progress percentage. NULL = keep current value. |
| 4 | @TicketID | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Compliance ticket ID. NULL = keep current value. |
| 5 | @SubmittedOn | datetime (IN) | YES | NULL | CODE-BACKED | Submission timestamp. Set when affiliate submits KYP for review. |
| 6 | @CanceledOn | datetime (IN) | YES | NULL | CODE-BACKED | Cancellation timestamp. Set when a submitted KYP is canceled back to editable. |
| 7 | @PopupDismissed | bit (IN) | YES | NULL | CODE-BACKED | Popup dismissal flag. NULL = keep current value. |
| 8 | @AllowedKYPStatusIDs | IDTableType (IN, READONLY) | NO | - | CODE-BACKED | State machine guard: the affiliate's current KYPStatusID must be in this set for the update to proceed. Enforces valid transitions. |
| 9 | @AllowWhenNoSignificantChangeAfter | datetime (IN) | YES | NULL | CODE-BACKED | Optimistic concurrency guard. If provided, the update only proceeds if SubmittedOn and CanceledOn are both NULL or older than this timestamp. NULL = skip this guard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | KYP.Affiliate | UPDATE (MODIFIER) | Updates status/progress fields with guards |
| - | KYP.GetAffiliateKYPStatus | EXEC call | Returns updated status after successful update |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.UpdateAffiliateKYPStatus (procedure)
├── KYP.Affiliate (table)
└── KYP.GetAffiliateKYPStatus (procedure)
      └── KYP.Affiliate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | UPDATE with status transition guards |
| KYP.GetAffiliateKYPStatus | SP | EXEC to return updated status |
| IDTableType | UDT (dbo) | TVP for allowed status IDs |

### 6.2 Objects That Depend On This

No dependents found in the KYP schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Transition affiliate from In Progress to Submitted
```sql
DECLARE @Allowed IDTableType
INSERT @Allowed VALUES (3) -- Only allow transition FROM In Progress
EXEC KYP.UpdateAffiliateKYPStatus
    @AffiliateID = 60062, @StatusID = 5, @Progress = 100,
    @SubmittedOn = '2026-04-13', @AllowedKYPStatusIDs = @Allowed
```

### 8.2 Dismiss popup without changing status
```sql
DECLARE @Allowed IDTableType
INSERT @Allowed VALUES (2), (3), (4), (5), (6), (7) -- Allow from any status
EXEC KYP.UpdateAffiliateKYPStatus
    @AffiliateID = 60062, @PopupDismissed = 1, @AllowedKYPStatusIDs = @Allowed
```

### 8.3 Check what would fail (view current status)
```sql
SELECT AffiliateID, KYPStatusID, SubmittedOn, CanceledOn
FROM KYP.Affiliate WITH (NOLOCK)
WHERE AffiliateID = 60062
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.UpdateAffiliateKYPStatus | Type: Stored Procedure | Source: fiktivo/KYP/Stored Procedures/KYP.UpdateAffiliateKYPStatus.sql*
