# Dictionary.WithdrawCancellationSources

> Lookup table identifying who or what initiated the cancellation of a withdrawal request in the MoneyBus payment system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 (PK CLUSTERED + UNIQUE NONCLUSTERED on Name) |

---

## 1. Business Meaning

Dictionary.WithdrawCancellationSources classifies the origin of withdrawal cancellation requests. When a withdrawal is canceled, the system records not just that it was canceled, but who or what initiated the cancellation. This distinction is critical for audit trails, compliance reporting, and operational analytics - knowing whether a user voluntarily canceled versus backoffice intervening versus the system aborting enables different downstream actions and reporting.

This table exists because cancellation accountability is a regulatory and operational requirement. User-initiated cancellations have different compliance implications than system-forced aborts (which may indicate payment failures requiring investigation). Without this classification, the operations team cannot distinguish voluntary from involuntary cancellations in withdrawal reports.

Data flow: This is a static reference table maintained via schema migrations. It is read indirectly through the MoneyBus.WithdrawCancelRequest table, where the CancellationSource column references these IDs. The WithdrawCancelRequestAdd procedure inserts new cancellation requests with a CancellationSource value, and WithdrawCancelRequestGet reads them back.

---

## 2. Business Logic

### 2.1 Cancellation Source Classification

**What**: Each withdrawal cancellation is attributed to one of four sources, enabling audit and operational differentiation of cancellation types.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- ID=0 (None) is the default/null-safe value used when a withdrawal has not been canceled
- ID=1 (User) means the end user actively requested cancellation through the platform
- ID=2 (BackOffice) means operations staff intervened to cancel the withdrawal via admin tools
- ID=3 (Abort) means the system's automated abort workflow triggered the cancellation (e.g., payout reversal failure)
- The UNIQUE constraint on Name ensures no duplicate cancellation source labels can be created

**Diagram**:
```
Withdrawal Cancellation Sources:

  [0] None        -- Default: withdrawal not canceled
  [1] User        -- End user requested cancellation
  [2] BackOffice  -- Operations staff intervened
  [3] Abort       -- System automated abort workflow
```

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 0 | None | Default value for non-canceled withdrawals. When a WithdrawCancelRequest record exists but the withdrawal was not actually canceled (or the cancellation source was not specified), this serves as the null-safe default |
| 1 | User | Cancellation initiated by the end user through the platform UI or API. The user voluntarily chose to cancel their pending withdrawal before it was processed |
| 2 | BackOffice | Cancellation initiated by backoffice/operations staff via admin tools. Typically used when compliance, fraud detection, or operational issues require manual intervention to stop a withdrawal |
| 3 | Abort | Cancellation triggered by the system's automated abort workflow. This occurs when a payout fails or a reversal is needed, and the system automatically cancels the withdrawal to release held funds |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying each cancellation source. Explicitly assigned (not IDENTITY). Referenced as CancellationSource in MoneyBus.WithdrawCancelRequest. Values: 0=None, 1=User, 2=BackOffice, 3=Abort. See [Withdraw Cancellation Source](../../_glossary.md#withdraw-cancellation-source) for full business definitions. |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Human-readable label for the cancellation source. Has a UNIQUE constraint ensuring no duplicates. Used for display in cancellation reports and audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.WithdrawCancelRequest | CancellationSource | Implicit Lookup | Identifies who/what initiated the withdrawal cancellation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawCancelRequest | Table | CancellationSource column references WithdrawCancellationSources.ID |
| MoneyBus.WithdrawCancelRequestAdd | Stored Procedure | Receives @CancellationSource parameter and INSERTs into WithdrawCancelRequest |
| MoneyBus.WithdrawCancelRequestGet | Stored Procedure | Reads CancellationSource from WithdrawCancelRequest |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |
| UQ (unnamed) | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ on Name | UNIQUE | Ensures no two cancellation sources can share the same label |

---

## 8. Sample Queries

### 8.1 List all cancellation sources
```sql
SELECT ID, Name
FROM Dictionary.WithdrawCancellationSources WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count cancellation requests by source
```sql
SELECT wcs.Name AS CancellationSource, COUNT(*) AS RequestCount
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawCancellationSources wcs WITH (NOLOCK) ON wcs.ID = wcr.CancellationSource
GROUP BY wcs.Name
ORDER BY RequestCount DESC
```

### 8.3 View recent cancellation requests with source names
```sql
SELECT TOP 10 wcr.*, wcs.Name AS CancellationSourceName
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawCancellationSources wcs WITH (NOLOCK) ON wcs.ID = wcr.CancellationSource
ORDER BY wcr.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawCancellationSources | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.WithdrawCancellationSources.sql*
