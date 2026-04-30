# Wallet.ConversionStatuses

> Event-sourced status history for crypto-to-crypto conversions, tracking each lifecycle transition from pending through completion or failure.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the lifecycle of each conversion operation from `Wallet.Conversions`. Each row represents a status transition event (Pending -> Failed or Completed). See [Conversion Status](../../_glossary.md#conversion-status) for value definitions.

Rows are created by `Wallet.InsertConversionStatus`.

---

## 2. Business Logic

No complex logic. Simple status event log with 3 states: 1=Pending, 2=Failed, 3=Completed.

---

## 3. Data Overview

N/A for status event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | Parent conversion. FK to Wallet.Conversions.Id. |
| 3 | ConversionStatusId | tinyint | NO | - | VERIFIED | Status: 1=Pending, 2=Failed, 3=Completed. See [Conversion Status](../../_glossary.md#conversion-status). FK to Dictionary.ConversionStatuses. |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this status transition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | Wallet.Conversions | FK | Parent conversion |
| ConversionStatusId | Dictionary.ConversionStatuses | FK | Status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertConversionStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ConversionStatuses (table)
├── Wallet.Conversions (table)
└── Dictionary.ConversionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | FK target for ConversionId |
| Dictionary.ConversionStatuses | Table | FK target for ConversionStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertConversionStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...ConversionId_WalletId | NC UNIQUE | ConversionId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...ConversionId | FK | -> Wallet.Conversions.Id |
| FK_...ConversionStatusId | FK | -> Dictionary.ConversionStatuses.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a conversion
```sql
SELECT cs.ConversionStatusId, dcs.Name AS Status, cs.Occurred
FROM Wallet.ConversionStatuses cs WITH (NOLOCK)
JOIN Dictionary.ConversionStatuses dcs WITH (NOLOCK) ON cs.ConversionStatusId = dcs.Id
WHERE cs.ConversionId = 50268
ORDER BY cs.Id
```

### 8.2 Find failed conversions
```sql
SELECT cs.ConversionId, cs.Occurred FROM Wallet.ConversionStatuses cs WITH (NOLOCK)
WHERE cs.ConversionStatusId = 2 ORDER BY cs.Occurred DESC
```

### 8.3 Latest status per conversion
```sql
SELECT cs.ConversionId, dcs.Name AS Status, cs.Occurred
FROM Wallet.ConversionStatuses cs WITH (NOLOCK)
JOIN Dictionary.ConversionStatuses dcs WITH (NOLOCK) ON cs.ConversionStatusId = dcs.Id
WHERE cs.Occurred = (SELECT MAX(cs2.Occurred) FROM Wallet.ConversionStatuses cs2 WITH (NOLOCK) WHERE cs2.ConversionId = cs.ConversionId)
  AND cs.ConversionId > 50260
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ConversionStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ConversionStatuses.sql*
