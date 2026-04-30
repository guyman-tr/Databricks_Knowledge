# AffiliateCommission.UpdateFromAppsflyer

> Sets the NonOrganicUpdated timestamp on all three event tables for a customer after receiving Appsflyer attribution data, triggering commission reprocessing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets NonOrganicUpdated = GETUTCDATE() on CreditEvent, ClosedPositionEvent, and RegistrationEvent by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is specifically designed for the Appsflyer integration flow. When Appsflyer (a mobile attribution platform) provides new attribution data for a customer - indicating they were referred through a mobile app install tracked by an affiliate - this procedure flags all existing events for that customer for commission reprocessing.

The procedure is functionally identical to UpdateEvents but exists as a separate entry point to distinguish Appsflyer-driven reattribution from other organic-to-non-organic reclassification scenarios. This separation allows the system to track and audit the source of reattribution triggers separately.

By updating all three event tables (CreditEvent, ClosedPositionEvent, RegistrationEvent) in a single call, the procedure ensures that all commission-eligible activity for the customer is consistently flagged for reprocessing after Appsflyer data arrives, regardless of which commission domain the events belong to.

---

## 2. Business Logic

### 2.1 Appsflyer-Triggered NonOrganic Flag

**What**: Sets NonOrganicUpdated = GETUTCDATE() on all three event tables for events belonging to a specific customer that have not yet been flagged.

**Columns/Parameters Involved**: @CID, CreditEvent.NonOrganicUpdated, ClosedPositionEvent.NonOrganicUpdated, RegistrationEvent.NonOrganicUpdated

**Rules**:
- Updates CreditEvent, ClosedPositionEvent, and RegistrationEvent in sequence
- Only updates rows WHERE CID = @CID AND NonOrganicUpdated IS NULL
- Uses GETUTCDATE() as the timestamp (UTC time of execution)
- Idempotent for previously flagged events - NULL check prevents re-flagging
- Functionally identical to UpdateEvents but called from the Appsflyer integration path

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID whose events need to be flagged after Appsflyer attribution |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.CreditEvent | UPDATE target | Sets NonOrganicUpdated timestamp |
| @CID | AffiliateCommission.ClosedPositionEvent | UPDATE target | Sets NonOrganicUpdated timestamp |
| @CID | AffiliateCommission.RegistrationEvent | UPDATE target | Sets NonOrganicUpdated timestamp |

### 5.2 Referenced By (other objects point to this)

Called by the Appsflyer integration service when new mobile attribution data is received for a customer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateFromAppsflyer
  --> AffiliateCommission.CreditEvent (UPDATE)
  --> AffiliateCommission.ClosedPositionEvent (UPDATE)
  --> AffiliateCommission.RegistrationEvent (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | UPDATE target - sets NonOrganicUpdated |
| AffiliateCommission.ClosedPositionEvent | Table | UPDATE target - sets NonOrganicUpdated |
| AffiliateCommission.RegistrationEvent | Table | UPDATE target - sets NonOrganicUpdated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Appsflyer integration service | Application | Calls this SP when mobile attribution data arrives |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Flag events for a customer after Appsflyer data
```sql
EXEC AffiliateCommission.UpdateFromAppsflyer @CID = 500001;
```

### 8.2 Check NonOrganicUpdated status for a customer
```sql
SELECT 'CreditEvent' AS Domain, CreditID AS EventID, NonOrganicUpdated
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE CID = 500001
UNION ALL
SELECT 'ClosedPositionEvent', ClosedPositionID, NonOrganicUpdated
FROM AffiliateCommission.ClosedPositionEvent WITH (NOLOCK)
WHERE CID = 500001
UNION ALL
SELECT 'RegistrationEvent', RegistrationID, NonOrganicUpdated
FROM AffiliateCommission.RegistrationEvent WITH (NOLOCK)
WHERE CID = 500001;
```

### 8.3 Find recently flagged events from Appsflyer processing
```sql
SELECT CID, COUNT(*) AS FlaggedEvents
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE NonOrganicUpdated >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2440: New SP Add support to new CPA revenue (04/01/2024)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateFromAppsflyer | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateFromAppsflyer.sql*
