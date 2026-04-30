# Monitoring.NoC2FRequestsForLongTime

> Alerts when no crypto-to-fiat (C2F) conversion requests have been submitted for longer than the specified threshold, detecting potential pipeline outages.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns status 1 (alert) or 0 (OK) based on C2F request recency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.NoC2FRequestsForLongTime is a "heartbeat" check for the crypto-to-fiat conversion pipeline. Under normal operation, C2F requests (RequestTypeId=7) are submitted regularly. If the most recent C2F request is older than the threshold (default 7 days/168 hours), it suggests the C2F feature may be broken or disabled.

This is a low-frequency check suitable for weekly monitoring cadence, hence the 7-day default.

---

## 2. Business Logic

### 2.1 Pipeline Heartbeat Check

**What**: Verifies C2F requests are still being submitted.

**Columns/Parameters Involved**: `@Hours`, `RequestTypeId`, `Timestamp`

**Rules**:
- Finds MAX(Timestamp) for RequestTypeId = 7 (ConversionToFiat)
- If NULL (no C2F requests ever) or older than threshold -> Status = 1 (Alert)
- Otherwise -> Status = 0 (OK)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 168 | CODE-BACKED | Threshold in hours since last C2F request. Default 168 (7 days). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Status | INT | NO | - | CODE-BACKED | 1 = Alert (no recent C2F requests), 0 = OK (C2F pipeline active). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Checks for recent C2F requests (TypeId=7) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.NoC2FRequestsForLongTime (procedure)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - MAX(Timestamp) for RequestTypeId=7 |

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

### 8.1 Check with default 7-day threshold
```sql
EXEC Monitoring.NoC2FRequestsForLongTime;
```

### 8.2 Check with 24-hour threshold
```sql
EXEC Monitoring.NoC2FRequestsForLongTime @Hours = 24;
```

### 8.3 View latest C2F request
```sql
SELECT TOP 1 * FROM Wallet.Requests WITH (NOLOCK)
WHERE RequestTypeId = 7 ORDER BY Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.NoC2FRequestsForLongTime | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.NoC2FRequestsForLongTime.sql*
