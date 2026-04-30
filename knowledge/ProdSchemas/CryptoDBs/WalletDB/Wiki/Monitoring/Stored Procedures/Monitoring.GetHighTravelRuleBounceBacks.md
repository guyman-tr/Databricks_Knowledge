# Monitoring.GetHighTravelRuleBounceBacks

> Counts travel rule bounce-back (cancelled) transactions within a time window, alerting when the count exceeds expected thresholds for compliance monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of travel rule bouncebacks in time window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetHighTravelRuleBounceBacks monitors the volume of travel rule bounce-backs (cancellations). Travel rules require cryptocurrency exchanges to share sender/receiver information for transactions above certain thresholds. When travel rule verification fails or is rejected, the transaction is "bounced back" (cancelled, TravelRuleStatusId=2). A high number of bounce-backs may indicate systemic issues with the travel rule verification process or counterparty problems.

Without this procedure, the compliance team would have no automated way to detect spikes in travel rule rejections that could signal broader compliance infrastructure problems.

---

## 2. Business Logic

### 2.1 Bounceback Volume Alert

**What**: Counts travel rule cancellations within a time window for threshold-based alerting.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `@HoursBack`

**Rules**:
- TravelRuleStatusId = 2 identifies CANCELLED/BOUNCE_BACK status
- Count is within the @HoursBack window from current UTC time
- External monitoring tool compares the count against configured thresholds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TravelRuleBounceBacks | INT | NO | - | CODE-BACKED | Total count of travel rule cancellations within the window. |
| 2 | InHoursBack | INT | NO | - | CODE-BACKED | Echo of the @HoursBack parameter for context in alert messages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleStatuses | FROM (read) | Source of travel rule status events |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetHighTravelRuleBounceBacks (procedure)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | FROM - travel rule status events |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetHighTravelRuleBounceBacks;
```

### 8.2 Check last 4 hours for recent spike
```sql
EXEC Monitoring.GetHighTravelRuleBounceBacks @HoursBack = 4;
```

### 8.3 Travel rule status distribution
```sql
SELECT ttrs.TravelRuleStatusId, COUNT(*) AS Count
FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK)
WHERE ttrs.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ttrs.TravelRuleStatusId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetHighTravelRuleBounceBacks | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetHighTravelRuleBounceBacks.sql*
