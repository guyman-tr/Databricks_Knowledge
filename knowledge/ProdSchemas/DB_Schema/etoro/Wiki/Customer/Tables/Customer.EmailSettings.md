# Customer.EmailSettings

> Per-customer email notification preferences: stores whether each customer has opted in or out of specific email template types, checked before sending marketing and transactional emails.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (CID, TemplateID) composite PK |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR=70) |
| **Indexes** | 1 (clustered composite PK only) |

---

## 1. Business Meaning

Customer.EmailSettings records each customer's explicit opt-in or opt-out decision for specific email notification templates. Where a row exists with IsEnabled=0, the system should suppress that email type for that customer. IsEnabled=1 (or no row) means the customer accepts that email type. This table represents customer-controlled notification preferences, not system-controlled spam limits (those live in Customer.EmailLimits).

The table exists to comply with customers' communication preferences - customers can choose to disable certain email notification types (e.g., referral notifications, promotional alerts) without disabling all emails. This is distinct from account-level communication blocks, which live in Customer.BlockedCustomerOperations.

Data flows: Customer.SetEmailSettings is called when a customer updates their notification preferences (via account settings UI). It accepts an XML list of (TemplateID, IsEnabled) pairs and upserts each. Customer.GetNotificationSettings reads current preferences for a given set of templates. Customer.IsNeedToAddMail checks a single template setting, likely used as a gate before queuing emails. Preferences are versioned only by DateModified (last change timestamp) - no history table.

---

## 2. Business Logic

### 2.1 Per-Template Opt-In/Out Preferences

**What**: Customers can independently enable or disable each of 7 specific email templates, giving granular control over their notification experience.

**Columns/Parameters Involved**: `CID`, `TemplateID`, `IsEnabled`

**Rules**:
- TemplateIDs tracked: 651, 652, 653, 655, 656, 657, 658 (overlapping with EmailLimits throttle set, suggesting these are the same high-frequency marketing/notification templates)
- Default state: no row = system assumes enabled (GetNotificationSettings returns no row if not set; callers interpret absence as enabled)
- IsEnabled=0: customer has opted out of this template type
- IsEnabled=1: customer has explicitly opted in (or was enrolled via bulk SetEmailSettings)
- Upsert pattern: SetEmailSettings checks EXISTS before deciding INSERT vs UPDATE - avoids duplicate rows
- Distribution: ~80% of preferences are IsEnabled=1, ~20% IsEnabled=0 - most customers have not opted out

### 2.2 Automatic Audit Timestamp via Trigger

**What**: The AFTER UPDATE trigger ensures DateModified is always the true last-modification time, preventing callers from accidentally leaving a stale timestamp.

**Columns/Parameters Involved**: `DateModified`

**Rules**:
- Trigger `tr_Update_CustomerEmailSettings` fires AFTER UPDATE
- Sets DateModified = GETUTCDATE() on any updated row, joining Inserted to find modified rows
- On INSERT: DateModified is set via DEFAULT constraint (GETUTCDATE()) at insert time
- On UPDATE: the DEFAULT does not re-apply; the trigger overrides any caller-supplied DateModified value
- Result: DateModified always accurately reflects the actual UTC time of the last preference change, regardless of what the calling procedure sets

---

## 3. Data Overview

| TemplateID | IsEnabled=0 (Opted Out) | IsEnabled=1 (Opted In) | Total | Opt-Out Rate |
|-----------|------------------------|------------------------|-------|-------------|
| 651 | 12,853 | 48,867 | 61,720 | 20.8% |
| 652 | 12,850 | 48,870 | 61,720 | 20.8% |
| 653 | 12,591 | 49,128 | 61,719 | 20.4% |
| 655 | 12,242 | 49,477 | 61,719 | 19.8% |
| 656 | 7,066 | 30,550 | 37,616 | 18.8% |
| 657 | 11,564 | 37,360 | 48,924 | 23.6% |
| 658 | 10,101 | 36,102 | 46,203 | 21.9% |

*~340K total rows across 7 TemplateIDs. Opt-out rates range 19-24%. Template 651 and 652 have identical row counts (61,720), suggesting they were toggled together in a bulk operation. Templates 656-658 have fewer total rows, possibly added later or covering a narrower customer segment.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. Part of composite PK. FK to Customer.CustomerStatic(CID). One row per (customer, template) pair. |
| 2 | TemplateID | int | NO | - | VERIFIED | Email template identifier. Part of composite PK. Implicit FK to BackOffice.MailTemplates. The 7 active template IDs tracked are: 651, 652, 653, 655, 656, 657, 658. Each represents a distinct category of email notification that customers can individually opt out of. |
| 3 | IsEnabled | bit | NO | - | VERIFIED | Customer's preference for this template: 1 = opt-in (allow sending), 0 = opt-out (suppress sending). Read by Customer.IsNeedToAddMail as a pre-send gate. No row for a (CID, TemplateID) pair implies the default (enabled) state. |
| 4 | DateModified | datetime | YES | getutcdate() | VERIFIED | UTC timestamp of the last preference change. Set by DEFAULT on INSERT (getutcdate()); overridden by trigger tr_Update_CustomerEmailSettings on every UPDATE to ensure accuracy. Nullable - NULL indicates the preference was never updated since initial INSERT (though the DEFAULT normally prevents NULL on insert). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_EmailSettingsCID) | Every preference record must belong to a valid customer |
| TemplateID | BackOffice.MailTemplates | Implicit (no FK enforced) | TemplateID values correspond to mail template IDs in BackOffice; the 7 active template IDs are managed in application logic |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetEmailSettings | CID, TemplateID, IsEnabled | Writer + Modifier | Upserts preferences from an XML list; called when customer updates notification settings |
| Customer.GetNotificationSettings | CID, TemplateID | Reader | Returns (TemplateID, IsEnabled) pairs for a given CID and list of templates; used to populate the customer's settings UI |
| Customer.IsNeedToAddMail | CID, TemplateID | Reader | Returns IsEnabled for a single (CID, TemplateID); used as a pre-send gate to check if customer wants this email type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.EmailSettings (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetEmailSettings | Stored Procedure | Writer + Modifier - upserts customer notification preferences |
| Customer.GetNotificationSettings | Stored Procedure | Reader - returns preferences for a set of template IDs |
| Customer.IsNeedToAddMail | Stored Procedure | Reader - single-template opt-in check (pre-send gate) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK unnamed) | Clustered PK | CID ASC, TemplateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_CustomerEmailSettings | DEFAULT | DateModified = getutcdate() on INSERT |
| FK_EmailSettingsCID | FK | CID -> Customer.CustomerStatic(CID) |
| tr_Update_CustomerEmailSettings | TRIGGER (AFTER UPDATE) | Sets DateModified = GETUTCDATE() on any update, ensuring the timestamp is always accurate |

---

## 8. Sample Queries

### 8.1 Get all email preferences for a specific customer
```sql
SELECT
    es.CID,
    es.TemplateID,
    es.IsEnabled,
    es.DateModified
FROM Customer.EmailSettings es WITH (NOLOCK)
WHERE es.CID = 12345
ORDER BY es.TemplateID;
```

### 8.2 Find customers who have opted out of at least one template
```sql
SELECT
    es.CID,
    COUNT(*) AS OptOutCount,
    MAX(es.DateModified) AS LastPreferenceChange
FROM Customer.EmailSettings es WITH (NOLOCK)
WHERE es.IsEnabled = 0
GROUP BY es.CID
HAVING COUNT(*) >= 1
ORDER BY OptOutCount DESC;
```

### 8.3 Check opt-out rates per template
```sql
SELECT
    es.TemplateID,
    SUM(CASE WHEN es.IsEnabled = 1 THEN 1 ELSE 0 END) AS OptedIn,
    SUM(CASE WHEN es.IsEnabled = 0 THEN 1 ELSE 0 END) AS OptedOut,
    COUNT(*) AS Total,
    CAST(100.0 * SUM(CASE WHEN es.IsEnabled = 0 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS OptOutPct
FROM Customer.EmailSettings es WITH (NOLOCK)
GROUP BY es.TemplateID
ORDER BY es.TemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (SetEmailSettings, GetNotificationSettings, IsNeedToAddMail) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.EmailSettings | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.EmailSettings.sql*
