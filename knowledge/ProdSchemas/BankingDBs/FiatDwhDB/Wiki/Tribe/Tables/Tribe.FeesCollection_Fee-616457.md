# Tribe.FeesCollection_Fee-616457

> Primary child table storing individual fee records from Tribe fee collection files, containing transaction amounts, reconciliation data, merchant info, and fee details.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

FeesCollection_Fee-616457 stores individual fee records from Tribe. Contains transaction/reconciliation amounts in multiple currencies, merchant terminal info, function codes, and fee-specific fields. Parent: FeesCollection-301527.

---

## 2. Business Logic

### 2.1 Multi-Currency Fee Record

**Key Column Groups**: HolderId, AccountId, TransactionAmount/CurrencyCode, ReconciliationAmount/CurrencyCode/Rate, FunctionCode, MerchantTerminalId, CycleFileId.

---

## 3. Data Overview

N/A - raw provider fee data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @FeesCollection@Id-301527 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | HolderId | nvarchar(max) | YES | - | CODE-BACKED | Tribe holder ID. |
| 5 | TransactionAmount | nvarchar(max) | YES | - | CODE-BACKED | Fee amount (as string). |
| 6 | TransactionCurrencyAlpha | nvarchar(max) | YES | - | CODE-BACKED | Fee currency. |
| 7 | ReconciliationAmount | nvarchar(max) | YES | - | CODE-BACKED | Reconciliation amount. |
| 8 | FunctionCode | nvarchar(max) | YES | - | CODE-BACKED | Fee function code. |
| 9 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(30+ additional columns - see DDL)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FeesCollection@Id-301527 | Tribe.FeesCollection-301527 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.FeesCollection_Fee-616457 (table)
└── Tribe.FeesCollection-301527 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.FeesCollection-301527 | Table | Parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK | CLUSTERED | @Id ASC | - | - | Active |
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent fee records
```sql
SELECT TOP 10 [@Id], HolderId, AccountId, TransactionAmount, TransactionCurrencyAlpha, FunctionCode, Created
FROM Tribe.[FeesCollection_Fee-616457] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.HolderId, c.TransactionAmount, c.TransactionCurrencyAlpha
FROM Tribe.[FeesCollection-301527] p WITH (NOLOCK)
JOIN Tribe.[FeesCollection_Fee-616457] c WITH (NOLOCK) ON c.[@FeesCollection@Id-301527] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[FeesCollection_Fee-616457] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.FeesCollection_Fee-616457 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.FeesCollection_Fee-616457.sql*
