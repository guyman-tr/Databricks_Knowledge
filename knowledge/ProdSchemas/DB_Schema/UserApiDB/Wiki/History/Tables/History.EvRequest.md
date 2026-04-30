# History.EvRequest

> Stores Electronic Verification request/response history, linking each verification attempt to a provider, customer result, and GCID.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | RequestId (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

History.EvRequest stores the raw XML request/response data for every Electronic Verification attempt. Each row links a verification to a GCID, provider (Dictionary.EvProvider), funnel, and customer EV result (Ev.CustomerResult). This is the detailed EV audit trail for compliance and debugging.

---

## 2. Business Logic

No complex multi-column business logic. EV attempt audit log.

---

## 3. Data Overview

N/A - audit log table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestId | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. EV request record ID. |
| 2 | GCID | int | NO | - | CODE-BACKED | User being verified. |
| 3 | FunnelId | int | NO | - | CODE-BACKED | Which verification funnel/flow triggered this request. |
| 4 | ProviderId | int | NO | - | CODE-BACKED | FK to Dictionary.EvProvider. Which EV provider was used. See [EV Provider](_glossary.md#ev-provider). |
| 5 | RequestDate | datetime | NO | - | CODE-BACKED | When the request was sent. |
| 6 | Request | xml | NO | - | CODE-BACKED | Full XML request payload sent to the provider. |
| 7 | Response | xml | YES | - | CODE-BACKED | Full XML response from the provider. NULL if no response (timeout/error). |
| 8 | CustomerEvResultId | int | NO | - | CODE-BACKED | FK to Ev.CustomerResult. Links to the overall EV result record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.EvProvider | Explicit FK | EV provider used |
| CustomerEvResultId | Ev.CustomerResult | Explicit FK | Overall EV result record |

### 5.2 Referenced By (other objects point to this)

Populated by Ev schema procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.EvRequest (table)
  +-- Dictionary.EvProvider (table) [done]
  +-- Ev.CustomerResult (table, external - Ev schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvProvider | Table | FK: ProviderId |
| Ev.CustomerResult | Table | FK: CustomerEvResultId |

### 6.2 Objects That Depend On This

Ev schema procedures write to this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryEvRequest | CLUSTERED PK | RequestId | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_HistoryEvRequestCustomerEvResultId | FOREIGN KEY | CustomerEvResultId -> Ev.CustomerResult |
| FK_HistoryEvRequestProviderId | FOREIGN KEY | ProviderId -> Dictionary.EvProvider |

---

## 8. Sample Queries

### 8.1 EV history for a user
```sql
SELECT r.RequestId, ep.Name AS Provider, r.RequestDate, r.CustomerEvResultId
FROM History.EvRequest r WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON r.ProviderId = ep.EvProviderId
WHERE r.GCID = @GCID ORDER BY r.RequestDate DESC
```

### 8.2 Recent EV requests
```sql
SELECT TOP 50 RequestId, GCID, ProviderId, RequestDate FROM History.EvRequest WITH (NOLOCK) ORDER BY RequestDate DESC
```

### 8.3 Requests by provider
```sql
SELECT ep.Name, COUNT(*) AS RequestCount FROM History.EvRequest r WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON r.ProviderId = ep.EvProviderId GROUP BY ep.Name ORDER BY RequestCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.EvRequest | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.EvRequest.sql*
