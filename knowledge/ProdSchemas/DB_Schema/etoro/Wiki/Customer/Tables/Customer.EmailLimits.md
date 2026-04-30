# Customer.EmailLimits

> Anti-spam throttle table that limits how many times specific email templates can be sent to a customer per day; enforced by Maintenance.SendMail for 7 high-frequency marketing and transactional templates.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (CID, TemplateID, LastDateSent) composite PK |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR=70) |
| **Indexes** | 1 (clustered composite PK only) |

---

## 1. Business Meaning

Customer.EmailLimits is a per-customer, per-template daily send counter. Before Maintenance.SendMail dispatches an email for a protected template, it checks this table: if the customer has already received the maximum allowed sends for that template today, the procedure returns immediately without sending. This prevents email spam for high-frequency marketing and transactional templates.

The table exists because certain email templates (referral incentives, password reset, account status notifications) can be triggered many times in rapid succession - for example, a customer clicking "Forgot Password" multiple times, or multiple referral events firing on the same day. Without this guard, customers would receive duplicate emails, damaging trust and triggering spam filters.

Data flows: Maintenance.SendMail is the sole consumer. On each call for a protected template (IDs 650-658), it SELECTs the existing row for (CID, TemplateID). If no row exists, it INSERTs with count=1. If a row exists and LastDateSent = today, it compares NumTimesSent against the template's daily limit - blocking the send if exceeded or incrementing the count if allowed. If LastDateSent is from a prior day, it resets NumTimesSent to 1 and advances LastDateSent to today (effectively replacing the old daily record). Note: data in this table is from 2013-2017, suggesting the active email templates covered by this limit may have been retired or the enforcement moved elsewhere since then.

---

## 2. Business Logic

### 2.1 Daily Send Throttle by Template Tier

**What**: Two tiers of daily send limits apply to 7 protected templates, preventing email spam while allowing legitimate resends within the same day.

**Columns/Parameters Involved**: `TemplateID`, `NumTimesSent`, `LastDateSent`

**Rules**:
- Tier 1 (limit = 1/day): TemplateIDs 651, 655, 650, 654 - one send per customer per day maximum
- Tier 2 (limit = 3/day): TemplateIDs 656, 652, 658 - three sends per customer per day maximum
- Blocking condition: `LastDateSent = today AND NumTimesSent >= limit` -> Maintenance.SendMail returns immediately (email suppressed)
- On allowed send: if LastDateSent exists, UPDATE sets NumTimesSent = (same day: +1, new day: reset to 1) and LastDateSent = today
- On first send ever: INSERT with NumTimesSent=1, LastDateSent=today
- Error handling: the entire block is wrapped in TRY/CATCH with PRINT 'Do nothing' in CATCH - errors in limit tracking do NOT block email delivery

**Diagram**:
```
Maintenance.SendMail called with @CID, @TemplateID
        |
        v
TemplateID IN (651,655,656,650,654,652,658)?
        |YES                          |NO
        v                             v
SELECT from EmailLimits           Skip limit check, proceed
WHERE CID=@CID AND TemplateID=@TemplateID
        |
        +--[No row found]-> INSERT (count=1, date=today) -> proceed to send
        |
        +--[Row found, LastDateSent = today]
              |
              +--[count >= limit (1 or 3)] -> RETURN (suppressed)
              |
              +--[count < limit] -> UPDATE (count+1) -> proceed to send
        |
        +--[Row found, LastDateSent != today]
              -> UPDATE (count=1, date=today) -> proceed to send
```

---

## 3. Data Overview

| CID | TemplateID | NumTimesSent | LastDateSent | Meaning |
|-----|-----------|-------------|--------------|---------|
| 3126836 | 651 | 1 | 2017-05-11 | Template 651 sent once to this customer on 2017-05-11; daily limit of 1 was reached |
| 3396386 | 655 | 1 | 2017-05-10 | Template 655 (Tier 1) sent once; this is the most recent recorded send |
| 1835170 | 651 | 1 | 2017-05-07 | Standard single-send record for TemplateID 651 |
| 3736180 | 655 | 1 | 2017-04-13 | Same template, earlier period |
| 3126836 | - | - | - | Note: CID 3126836 appears for multiple templates - each gets its own row |

*~547K total rows across 5 TemplateIDs. TemplateID 650: 332K rows (last sent 2014-03-23), 651: 112K (last sent 2017-05-11), 656: 71K (last sent 2013-08-26), 654: 21K (last sent 2014-03-23), 655: 11K (last sent 2017-05-10). All data is from 2013-2017 - this table is currently inactive, suggesting the covered email templates have been retired or send-limiting moved to a newer system.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. Part of composite PK. FK to Customer.CustomerStatic(CID). Identifies which customer the send-limit record belongs to. |
| 2 | NumTimesSent | smallint | NO | - | VERIFIED | Count of how many times the template has been sent to this customer on the LastDateSent date. Incremented by Maintenance.SendMail on each allowed send the same day; reset to 1 when LastDateSent advances to a new day. Never exceeds the template's daily cap (1 for Tier 1 templates, 3 for Tier 2). Live data shows max observed value of 3. |
| 3 | LastDateSent | datetime | NO | - | VERIFIED | The calendar date (truncated to midnight via DATEADD/DATEDIFF) of the most recent send for this customer-template pair. Part of the composite PK. Updated in-place when sends occur on a new day, advancing the PK date value. Used to determine if the current call is within the same day (same-day check: LastDateSent = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0)). |
| 4 | TemplateID | int | NO | - | VERIFIED | Identifies the email template being throttled. Part of composite PK. Implicit FK to BackOffice.MailTemplates (no enforced constraint). Protected TemplateIDs: 650, 651, 654, 655 (Tier 1: limit 1/day); 652, 656, 658 (Tier 2: limit 3/day). Each protected template gets its own row per customer per active day. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_EmailLimitsCID) | Every throttle record must belong to a valid customer |
| TemplateID | BackOffice.MailTemplates | Implicit (no FK enforced) | TemplateID values correspond to MailTemplateID values in BackOffice.MailTemplates; the 7 throttled templates are hardcoded in Maintenance.SendMail |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.SendMail | CID, TemplateID | Reader + Writer + Modifier | The sole consumer: reads to check limit, inserts on first send, updates on subsequent sends. Only called for the 7 throttled TemplateIDs. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.EmailLimits (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID - ensures customer exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.SendMail | Stored Procedure | MIXED (Reader + Writer + Modifier) - anti-spam gate for 7 email templates; reads to check daily limit, inserts or updates the counter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer_EmailLimits | Clustered PK | CID ASC, TemplateID ASC, LastDateSent ASC | - | - | Active |

*FILLFACTOR=70 leaves 30% of each page free - anticipates frequent UPDATE operations (advancing LastDateSent forward in the PK key order causes page splits without this headroom).*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EmailLimitsCID | FK | CID -> Customer.CustomerStatic(CID) |

---

## 8. Sample Queries

### 8.1 Check current daily send status for a customer across all protected templates
```sql
SELECT
    el.CID,
    el.TemplateID,
    el.NumTimesSent,
    el.LastDateSent,
    CASE WHEN el.TemplateID IN (651,655,650,654) THEN 1
         WHEN el.TemplateID IN (656,652,658) THEN 3
         ELSE NULL END AS DailyLimit,
    CASE WHEN el.LastDateSent = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0) THEN 'Today'
         ELSE 'Prior day' END AS DateStatus
FROM Customer.EmailLimits el WITH (NOLOCK)
WHERE el.CID = 12345
ORDER BY el.TemplateID;
```

### 8.2 Find templates hitting their daily limits most frequently
```sql
SELECT
    el.TemplateID,
    CASE WHEN el.TemplateID IN (651,655,650,654) THEN 1
         WHEN el.TemplateID IN (656,652,658) THEN 3
         ELSE NULL END AS DailyLimit,
    COUNT(*) AS TotalCustomersTracked,
    MAX(el.NumTimesSent) AS MaxSentInOneDay,
    MAX(el.LastDateSent) AS MostRecentSend
FROM Customer.EmailLimits el WITH (NOLOCK)
GROUP BY el.TemplateID
ORDER BY TotalCustomersTracked DESC;
```

### 8.3 Identify customers who hit the daily limit (were potentially blocked today)
```sql
DECLARE @Today DATETIME = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0);
SELECT
    el.CID,
    el.TemplateID,
    el.NumTimesSent,
    el.LastDateSent,
    cs.Email
FROM Customer.EmailLimits el WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = el.CID
WHERE el.LastDateSent = @Today
  AND (
      (el.TemplateID IN (651,655,650,654) AND el.NumTimesSent >= 1)
   OR (el.TemplateID IN (656,652,658) AND el.NumTimesSent >= 3)
  )
ORDER BY el.LastDateSent DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Maintenance.SendMail) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.EmailLimits | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.EmailLimits.sql*
