# MoneyBus.WithdrawCancelRequestAdd

> Creates a cancellation request for a withdrawal, recording who or what initiated the cancellation (user, back-office, or system abort) with optional manager ID and comments.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into WithdrawCancelRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawCancelRequestAdd creates a cancellation request record when a withdrawal needs to be canceled. Called by the withdrawal service during user-initiated cancellations, back-office manual interventions, or automated abort workflows. The unique constraint on WithdrawID in the target table ensures each withdrawal can only have one cancellation request.

The procedure inserts the WithdrawID, CancellationSource (1=User, 2=BackOffice, 3=Abort), optional ManagerID (for back-office actions), and optional Comments. The Created column defaults to SYSUTCDATETIME() via the table default.

---

## 2. Business Logic

No complex business logic. Direct INSERT. The table's unique constraint on WithdrawID prevents duplicate cancellations.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | bigint | NO | - | CODE-BACKED | The withdrawal to cancel. Must match an existing Withdrawals.ID. Unique constraint prevents duplicate cancel requests. |
| 2 | @ManagerID | int | YES | NULL | CODE-BACKED | Back-office manager ID if cancellation is manager-initiated. NULL for user and system abort cancellations. |
| 3 | @CancellationSource | int | NO | - | CODE-BACKED | Who initiated: 1=User, 2=BackOffice, 3=Abort. See [Withdraw Cancellation Source](../../_glossary.md#withdraw-cancellation-source). Required. |
| 4 | @Comments | varchar(200) | YES | NULL | CODE-BACKED | Free-text reason for cancellation. For aborts: "cancel by abort". For users: user-provided text. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | MoneyBus.WithdrawCancelRequest | Writer | Creates cancellation request |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawCancelRequestAdd (procedure)
└── MoneyBus.WithdrawCancelRequest (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawCancelRequest | Table | INSERT INTO - creates cancellation record |

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

### 8.1 Create a user-initiated cancellation
```sql
EXEC MoneyBus.WithdrawCancelRequestAdd
    @WithdrawID = 773487, @CancellationSource = 1,
    @Comments = 'User changed their mind';
```

### 8.2 Create a system abort cancellation
```sql
EXEC MoneyBus.WithdrawCancelRequestAdd
    @WithdrawID = 773480, @CancellationSource = 3,
    @Comments = 'cancel by abort';
```

### 8.3 Create a back-office cancellation with manager
```sql
EXEC MoneyBus.WithdrawCancelRequestAdd
    @WithdrawID = 773459, @ManagerID = 42,
    @CancellationSource = 2, @Comments = 'Compliance hold - suspicious activity';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawCancelRequestAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawCancelRequestAdd.sql*
