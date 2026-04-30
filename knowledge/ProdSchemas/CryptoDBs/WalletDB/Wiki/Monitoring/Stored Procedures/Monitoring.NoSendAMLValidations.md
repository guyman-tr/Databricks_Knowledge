# Monitoring.NoSendAMLValidations

> Alerts when zero send-side AML validations have been created within the lookback window, indicating a potential AML pipeline outage for outgoing transactions.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count only when zero send AML validations exist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.NoSendAMLValidations is the send-side counterpart to NoReceiveAMLValidations. It checks that outgoing transaction AML validations (IsSend=1) are being created. A zero count indicates the send-side AML screening may be down.

Same HAVING COUNT(*) = 0 pattern - returns a row only when there's a problem.

---

## 2. Business Logic

### 2.1 Zero-Activity Alert

**What**: Alerts when no send AML validations exist in the window.

**Columns/Parameters Involved**: `IsSend`, `Created`, `@Hours`

**Rules**:
- Counts AmlValidations where IsSend=1 AND Created within @Hours
- HAVING COUNT(*) = 0 triggers alert
- Default: 24 hours

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
| Query body | Wallet.AmlValidations | FROM (read) | Counts send-side AML records |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.NoSendAMLValidations (procedure)
  └── Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | FROM - send AML validation count |

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
EXEC Monitoring.NoSendAMLValidations;
```

### 8.2 Check last 4 hours
```sql
EXEC Monitoring.NoSendAMLValidations @Hours = 4;
```

### 8.3 Count recent send AML validations
```sql
SELECT COUNT(*) AS RecentSendAml
FROM Wallet.AmlValidations WITH (NOLOCK)
WHERE IsSend = 1 AND Created >= DATEADD(HOUR, -24, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.NoSendAMLValidations | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.NoSendAMLValidations.sql*
