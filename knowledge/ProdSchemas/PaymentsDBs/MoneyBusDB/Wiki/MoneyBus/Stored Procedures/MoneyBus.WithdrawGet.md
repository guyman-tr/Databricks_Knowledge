# MoneyBus.WithdrawGet

> Retrieves a single withdrawal record by ID, returning all columns including exchange rate, USD amount, status descriptions, and error details.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Withdrawals by PK |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawGet retrieves the complete details of a single withdrawal by its ID. This is the primary read path for the withdrawal service when it needs to check the current state of a withdrawal, display withdrawal details to the user, or resume pipeline processing.

The procedure returns all Withdrawals columns including the exchange rate data (ExchangeRate, AmountInUsd), status description fields (StatusReasonDescription, ErrorDescription), and audit fields. Uses TRY/CATCH with RAISERROR for error propagation and returns 0 for success, -1 for error.

---

## 2. Business Logic

No complex business logic. This is a simple PK lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint | NO | - | CODE-BACKED | The Withdrawals.ID to look up. Clustered PK lookup - optimal performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.Withdrawals | Reader | Reads single withdrawal by PK |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawGet (procedure)
└── MoneyBus.Withdrawals (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | SELECT FROM - reads withdrawal by PK |

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

### 8.1 Get withdrawal by ID
```sql
EXEC MoneyBus.WithdrawGet @ID = 773487;
```

### 8.2 Get with resolved status names
```sql
DECLARE @result TABLE (ID bigint, StatusID int, StatusReasonID int, Amount money, CurrencyID int);
INSERT INTO @result EXEC MoneyBus.WithdrawGet @ID = 773487;
SELECT r.*, ws.Name AS Status, wsr.Name AS StatusReason
FROM @result r
JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = r.StatusID
JOIN Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK) ON wsr.ID = r.StatusReasonID;
```

### 8.3 Direct equivalent query
```sql
SELECT * FROM MoneyBus.Withdrawals WITH (NOLOCK) WHERE ID = 773487;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawGet.sql*
