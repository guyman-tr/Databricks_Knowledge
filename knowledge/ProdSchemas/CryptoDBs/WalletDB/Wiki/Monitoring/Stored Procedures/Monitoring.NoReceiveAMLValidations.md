# Monitoring.NoReceiveAMLValidations

> Alerts when zero receive-side AML validations have been created within the lookback window, indicating a potential AML pipeline outage for incoming transactions.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count only when zero receive AML validations exist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.NoReceiveAMLValidations is a heartbeat check for the receive-side AML screening pipeline. Under normal operation, new receive AML validations (IsSend=0) are created continuously as customers receive crypto. If the count drops to zero within the window, the AML provider integration may be down.

The HAVING COUNT(*) = 0 clause means this procedure returns a result ONLY when there's a problem (zero validations). If the pipeline is healthy, the query returns no rows.

---

## 2. Business Logic

### 2.1 Zero-Activity Alert

**What**: Alerts when no receive AML validations exist in the window.

**Columns/Parameters Involved**: `IsSend`, `Created`, `@Hours`

**Rules**:
- Counts AmlValidations where IsSend=0 AND Created within @Hours
- HAVING COUNT(*) = 0 triggers the alert (returns a row with Count=0)
- If count > 0 -> no rows returned (healthy)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Count | INT | NO | - | CODE-BACKED | Always 0 when returned (via HAVING). No rows returned when healthy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.AmlValidations | FROM (read) | Counts receive-side AML records |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.NoReceiveAMLValidations (procedure)
  └── Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | FROM - receive AML validation count |

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
EXEC Monitoring.NoReceiveAMLValidations;
```

### 8.2 Check last 4 hours
```sql
EXEC Monitoring.NoReceiveAMLValidations @Hours = 4;
```

### 8.3 Count recent receive AML validations
```sql
SELECT COUNT(*) AS RecentReceiveAml
FROM Wallet.AmlValidations WITH (NOLOCK)
WHERE IsSend = 0 AND Created >= DATEADD(HOUR, -24, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.NoReceiveAMLValidations | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.NoReceiveAMLValidations.sql*
