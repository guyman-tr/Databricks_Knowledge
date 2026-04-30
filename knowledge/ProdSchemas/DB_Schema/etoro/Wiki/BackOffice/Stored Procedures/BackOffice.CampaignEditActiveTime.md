# BackOffice.CampaignEditActiveTime

> Updates a campaign's time window (StartDate/EndDate) and automatically determines IsActive based on whether the current UTC time falls within the new window; triggers an admin notification email when the campaign becomes inactive.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the time-window management operation for marketing campaigns. When a BackOffice operator needs to adjust when a campaign runs, they call this procedure to set new StartDate and EndDate values. The procedure then automatically computes the new IsActive state based on whether the current UTC time falls within the updated window - campaigns that should be running right now are immediately activated; campaigns outside their window are deactivated. When a campaign becomes inactive (IsActive=0), an automated notification email is sent via `Billing.P_EMail_BackOffice_Campaign_IsActive0`.

The procedure enforces strict time-window business rules: all three date validations must pass before any update occurs. The ticket reference (42551, Dec 2016) confirms this was built specifically to support "Alert On backoffice.Campaign.IsActive" - the ability to trigger alerts/notifications when campaign active status changes.

The @IsActive parameter is OUTPUT and marked as deprecated - it was likely used by earlier callers to check the computed active state but modern callers should determine IsActive from BackOffice.Campaign after the update.

---

## 2. Business Logic

### 2.1 Date Window Validation (Three Guards)

**What**: Three sequential validations must pass before any update. All use GETUTCDATE() - campaign times are UTC.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`

**Rules**:
- Guard 1: `@StartDate >= @EndDate` -> RAISERROR 60024, "start date later than End date". Return 60024.
- Guard 2: `DATEDIFF(mi, GETUTCDATE(), @EndDate) < 60` -> RAISERROR 60024, "difference between NOW And EndDate less than 60 minutes". Prevents setting an EndDate that expires within the next hour.
- Guard 3: `DATEDIFF(mi, @StartDate, @EndDate) < 60` -> RAISERROR 60024, "difference between start And End less than 60 minutes". Campaign must have a minimum 1-hour duration.

**Diagram**:
```
@StartDate >= @EndDate?          ->  ERROR 60024 (invalid window)
EndDate - NOW < 60 min?          ->  ERROR 60024 (expiring too soon)
EndDate - StartDate < 60 min?    ->  ERROR 60024 (window too narrow)
All pass -> compute IsActive -> UPDATE Campaign -> optional email
```

### 2.2 IsActive Auto-Determination

**What**: IsActive is set based on whether the current UTC time falls within the new time window.

**Columns/Parameters Involved**: `@IsActive`, `BackOffice.Campaign.IsActive`, `StartDate`, `EndDate`

**Rules**:
- If `@StartDate < GETUTCDATE() < @EndDate`: campaign is currently in its active window -> `@IsActive = 1`
- Otherwise: campaign is future-scheduled or already ended -> `@IsActive = 0`
- When `@IsActive = 0`: calls `EXEC Billing.P_EMail_BackOffice_Campaign_IsActive0 @CampaignID` (sends admin notification)

### 2.3 Error Handling and Transaction Management

**What**: TRY/CATCH handles unexpected errors, with transaction management to prevent partial updates.

**Rules**:
- On success: RETURN 0
- On CATCH: prints error context string (server, DB, procedure, line, message) to output
- If `@@TranCount=1`: ROLLBACK (was in a transaction - abort)
- If `@@TranCount>1`: COMMIT (was in a nested transaction context - commit inner)
- Calls `Internal.CallRaiseError` to re-raise the error and returns the error number

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | CODE-BACKED | Campaign identifier. PK of BackOffice.Campaign. The campaign whose time window is being updated. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | New campaign start datetime (UTC). Must be before @EndDate and at least 60 minutes before @EndDate. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | New campaign end datetime (UTC). Must be at least 60 minutes from now (GETUTCDATE()) and at least 60 minutes after @StartDate. |
| 4 | @IsActive | BIT | NO | - | CODE-BACKED | OUTPUT parameter (deprecated). Set to 1 if GETUTCDATE() falls within [@StartDate, @EndDate]; otherwise 0. Marked deprecated - callers should read IsActive from BackOffice.Campaign directly after the call. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 5 | RETURN | INT | 0 on success; 60024 on date validation failure; error number from Internal.CallRaiseError on unexpected error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID | BackOffice.Campaign | MODIFIER | Updates StartDate, EndDate, IsActive WHERE CampaignID=@CampaignID |
| @CampaignID (when IsActive=0) | Billing.P_EMail_BackOffice_Campaign_IsActive0 | EXEC call | Sends admin notification email when campaign becomes inactive |
| - | Internal.CallRaiseError | EXEC call | Re-raises caught errors via centralized error handler |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from BackOffice campaign management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignEditActiveTime (procedure)
|- BackOffice.Campaign (table) [UPDATE target - StartDate, EndDate, IsActive]
|- Billing.P_EMail_BackOffice_Campaign_IsActive0 (procedure) [called when IsActive=0]
+-- Internal.CallRaiseError (procedure) [error re-raise in CATCH block]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | UPDATE: sets StartDate, EndDate, IsActive WHERE CampaignID=@CampaignID |
| Billing.P_EMail_BackOffice_Campaign_IsActive0 | Procedure | EXEC when @IsActive=0 - sends admin notification email |
| Internal.CallRaiseError | Procedure | EXEC in CATCH block to re-raise the caught error |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice campaign management UI | External | Calls this to reschedule or adjust a campaign's time window |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error 60024 | Business | Three date validation rules; raised as RAISERROR(60024,16,1) on any violation |
| UTC dates | Design | All time comparisons use GETUTCDATE() - campaign datetimes are UTC |
| Minimum duration | Business | Campaign window must be at least 60 minutes; prevents one-time flash events shorter than 1 hour |
| EndDate expiry buffer | Business | EndDate must be at least 60 minutes from now; prevents setting a campaign that would immediately expire |
| @IsActive deprecated | Design | OUTPUT parameter retained for backward compatibility; computed internally, not passed in |

---

## 8. Sample Queries

### 8.1 Reschedule a campaign to next week

```sql
DECLARE @IsActive BIT
EXEC BackOffice.CampaignEditActiveTime
    @CampaignID = 1234,
    @StartDate = '2026-03-24 00:00:00',
    @EndDate = '2026-03-31 00:00:00',
    @IsActive = @IsActive OUTPUT
SELECT @IsActive AS ComputedIsActive -- 0 (not yet active), 1 (currently active)
```

### 8.2 Extend an active campaign's end date

```sql
DECLARE @IsActive BIT
EXEC BackOffice.CampaignEditActiveTime
    @CampaignID = 5678,
    @StartDate = '2026-03-15 08:00:00', -- keep same start
    @EndDate = '2026-04-15 08:00:00',   -- extend end by 1 month
    @IsActive = @IsActive OUTPUT
```

### 8.3 Verify campaign time window and status after update

```sql
SELECT CampaignID, Code, StartDate, EndDate, IsActive,
    CASE WHEN GETUTCDATE() BETWEEN StartDate AND EndDate THEN 'Currently Active' ELSE 'Inactive' END AS CurrentStatus
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE CampaignID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignEditActiveTime | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignEditActiveTime.sql*
