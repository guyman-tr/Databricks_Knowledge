# dbo.AddBalanceReports

> Inserts a balance reconciliation snapshot capturing calculated, provider, and CUG balances for an account.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Simple INSERT into BalanceReports |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddBalanceReports records a point-in-time balance reconciliation snapshot for an account. It accepts all three balance sources (Calc, Provider, CUG) for both available and settled amounts, inserting them into dbo.BalanceReports for discrepancy detection.

Called periodically by the balance reconciliation process to capture the current state of all three balance sources. Provider values are in minor units (cents); CUG values default to NULL for backward compatibility.

---

## 2. Business Logic

### 2.1 Three-Source Balance Capture

**What**: Captures calculated, provider, and CUG balances in a single snapshot.

**Columns/Parameters Involved**: `@CalcAvailable`, `@CalcSettled`, `@ProviderAvailable`, `@ProviderSettled`, `@CugAvailable`, `@CugSettled`

**Rules**:
- Provider values are in MINOR UNITS (cents) - divide by 100 for comparison with Calc/CUG
- CUG parameters default to NULL for calls from systems that don't provide CUG data
- No deduplication logic - every call creates a new snapshot row

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. |
| 2 | @CurrencyIson | nvarchar(128) | NO | - | CODE-BACKED | ISO numeric currency code (e.g., "978" for EUR). |
| 3 | @CalcAvailable | decimal(36,18) | NO | - | CODE-BACKED | Platform-calculated available balance (major units). |
| 4 | @CalcSettled | decimal(36,18) | NO | - | CODE-BACKED | Platform-calculated settled balance (major units). |
| 5 | @CalcReserved | decimal(36,18) | NO | - | CODE-BACKED | Platform-calculated reserved amount (major units). |
| 6 | @ProviderAvailable | decimal(36,18) | NO | - | VERIFIED | Provider available balance in MINOR UNITS. Divide by 100 for major units. |
| 7 | @ProviderSettled | decimal(36,18) | NO | - | VERIFIED | Provider settled balance in MINOR UNITS. |
| 8 | @ProviderReserved | decimal(36,18) | NO | - | CODE-BACKED | Provider reserved amount in MINOR UNITS. |
| 9 | @Created | datetime2 | NO | - | CODE-BACKED | Timestamp of this balance snapshot. |
| 10 | @CugAvailable | decimal(36,18) | YES | NULL | CODE-BACKED | CUG available balance (major units). Defaults to NULL. |
| 11 | @CugSettled | decimal(36,18) | YES | NULL | CODE-BACKED | CUG settled balance (major units). Defaults to NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | dbo.BalanceReports | Write | Inserts reconciliation snapshot |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddBalanceReports (procedure)
└── dbo.BalanceReports (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.BalanceReports | Table | INSERT target |

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

### 8.1 Call the procedure
```sql
EXEC dbo.AddBalanceReports @AccountId = 410569, @CurrencyIson = '978',
    @CalcAvailable = 0, @CalcSettled = 998.17, @CalcReserved = 0,
    @ProviderAvailable = 99817, @ProviderSettled = 99817, @ProviderReserved = 0,
    @Created = '2026-04-14T13:52:00', @CugAvailable = 998.17, @CugSettled = 998.17;
```

### 8.2 Verify the snapshot
```sql
SELECT TOP 1 * FROM dbo.BalanceReports WITH (NOLOCK) WHERE AccountId = 410569 ORDER BY Created DESC;
```

### 8.3 Check for discrepancies after insert
```sql
SELECT TOP 1 CalcSettled, ProviderSettled/100 AS ProviderMajor, CugSettled,
       CASE WHEN (ProviderSettled/100) = CugSettled THEN 'OK' ELSE 'DISCREPANCY' END AS Status
FROM dbo.BalanceReports WITH (NOLOCK) WHERE AccountId = 410569 ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | BalanceReports discrepancy query confirms Provider values in minor units (ProviderSettled/100) |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddBalanceReports | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddBalanceReports.sql*
