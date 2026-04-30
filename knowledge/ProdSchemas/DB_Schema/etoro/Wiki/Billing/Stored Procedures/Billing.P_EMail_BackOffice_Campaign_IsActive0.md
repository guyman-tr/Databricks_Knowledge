# Billing.P_EMail_BackOffice_Campaign_IsActive0

> Sends an internal alert email when a BackOffice campaign is deactivated (IsActive set to 0), notifying the retention team of the deactivation event with the campaign ID and code.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID (primary identifier for the alert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.P_EMail_BackOffice_Campaign_IsActive0` is a campaign-deactivation notification procedure. It fires whenever a `BackOffice.Campaign` row has its `IsActive` flag set to 0 (disabled), alerting the retention and operations teams that a campaign has stopped running.

The procedure exists to give visibility into campaign lifecycle events. Bonus and retention campaigns run automatically - when one is disabled (either because its budget is exhausted, its user quota is reached, or its schedule is edited outside its active window), the operations team needs to know immediately. Without this alert, deactivated campaigns could go unnoticed, leaving customers in unexpected bonus states.

Originally (December 2016) the procedure used `msdb..sp_send_dbmail` directly. This was replaced with an asynchronous insert into `Internal.EmailsToSend` (FB 42811), which decouples the notification from the transaction and allows a separate email-dispatch service to send the actual message to `Retention@etoro.com` and `idanfe@etoro.com`.

---

## 2. Business Logic

### 2.1 Deactivation Triggers

**What**: This procedure is called at two deactivation points, both of which set Campaign.IsActive=0 before calling it.

**Parameters Involved**: `@CampaignID`, `@Code`

**Trigger 1 - Schedule change (BackOffice.CampaignEditActiveTime)**:
- When a campaign's start/end dates are edited such that the current UTC time falls outside the new window, `IsActive` is set to 0 and this procedure fires. Represents a manual administrative deactivation via schedule editing.

**Trigger 2 - Budget/quota exhaustion (Billing.AmountAddBonus)**:
- Multiple exit conditions in `AmountAddBonus` deactivate a campaign:
  - Bonus budget fully consumed (`BonusAmount >= MaxTotalBonusAmount`)
  - Maximum participant count reached (`ParticipatedUsers >= MaxNumberOfUsers`)
  - Users delta exhausted (`UsersDelta <= 0`)
- In all cases, `IsActive` is set to 0 and this procedure fires immediately after.

**Diagram**:
```
BackOffice.CampaignEditActiveTime          Billing.AmountAddBonus
  (schedule edit, campaign goes idle)        (budget / quota exhausted)
           |                                        |
           v                                        v
UPDATE BackOffice.Campaign SET IsActive=0    UPDATE BackOffice.Campaign SET IsActive=0
           |                                        |
           +-----> Billing.P_EMail_BackOffice_Campaign_IsActive0(@CampaignID)
                           |
                    Fetch @Code from BackOffice.Campaign (if not passed)
                           |
                    INSERT INTO Internal.EmailsToSend
                    (Recipients: Retention@etoro.com; idanfe@etoro.com)
                    (Subject: Table BackOffice.Campaign: IsActive changed to 0)
                    (Body: HTML with CampaignID and Code)
                           |
                    Email dispatch service sends alert
```

### 2.2 Email Routing

**Recipients**: `Retention@etoro.com` and `idanfe@etoro.com` (hardcoded)

**Subject**: `Table BackOffice.Campaign: IsActive changed to 0`

**Body**: HTML format - `CampaignID=X` and `Code=Y` rendered in bold.

**Delivery**: Via `Internal.EmailsToSend` queue (not direct SMTP). The original `sp_send_dbmail` call is preserved as a comment for reference.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | Int | NO | - | CODE-BACKED | The internal ID of the campaign that was just deactivated. Used to look up @Code from BackOffice.Campaign if not supplied, and included in the alert email body. |
| 2 | @Code | Varchar(15) | YES | NULL | CODE-BACKED | Optional human-readable campaign code (e.g., "SUMMER2016"). If NULL, the procedure looks it up from BackOffice.Campaign WHERE CampaignID = @CampaignID. Included in the alert body to identify the campaign by name in addition to ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID | BackOffice.Campaign | Lookup (SELECT) | Reads Campaign.Code when @Code parameter is NULL |
| INSERT target | Internal.EmailsToSend | WRITER | Queues the alert email for dispatch by the email service |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CampaignEditActiveTime | @CampaignID | EXEC caller | Fires when editing campaign dates deactivates the campaign |
| Billing.AmountAddBonus | @CampaignID | EXEC caller | Fires at budget/quota exhaustion (3 separate exit paths) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.P_EMail_BackOffice_Campaign_IsActive0 (procedure)
├── BackOffice.Campaign (table)
└── Internal.EmailsToSend (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | SELECT - retrieves Campaign.Code when @Code parameter is NULL |
| Internal.EmailsToSend | Table | INSERT - queues the alert notification for async email dispatch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignEditActiveTime | Procedure | Calls this after setting IsActive=0 due to schedule change |
| Billing.AmountAddBonus | Procedure | Calls this (up to 4 times in different exit paths) after exhausting campaign budget or quota |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses TRY/CATCH with THROW to propagate errors (e.g., if BackOffice.Campaign row is missing or Internal.EmailsToSend is unavailable).

---

## 8. Sample Queries

### 8.1 Manually trigger campaign deactivation alert for a specific campaign

```sql
EXEC Billing.P_EMail_BackOffice_Campaign_IsActive0
    @CampaignID = 1234;
-- @Code is auto-fetched from BackOffice.Campaign
```

### 8.2 Check pending campaign deactivation alerts in the email queue

```sql
SELECT TOP 20
    ets.Recipients,
    ets.Subject,
    ets.Body,
    ets.BodyFormat
FROM Internal.EmailsToSend ets WITH (NOLOCK)
WHERE ets.Subject LIKE '%IsActive changed to 0%'
ORDER BY ets.EmailsToSendID DESC;
```

### 8.3 Find campaigns that triggered deactivation alerts (via callers)

```sql
SELECT
    c.CampaignID,
    c.Code,
    c.IsActive,
    c.StartDate,
    c.EndDate,
    c.MaxTotalBonusAmount,
    c.ParticipatedUsers,
    c.MaxNumberOfUsers
FROM BackOffice.Campaign c WITH (NOLOCK)
WHERE c.IsActive = 0
ORDER BY c.CampaignID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.P_EMail_BackOffice_Campaign_IsActive0 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.P_EMail_BackOffice_Campaign_IsActive0.sql*
