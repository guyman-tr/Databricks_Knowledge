# Monitoring.GetAllC2PConversions

> Retrieves all completed crypto-to-position conversions (EtoroPosition target) with full details, the counterpart to GetAllC2FConversions for position-targeted conversions.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Completed C2P conversions with full details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAllC2PConversions is the C2P counterpart to GetAllC2FConversions. By default it returns TargetPlatformId=3 (EtoroPosition) - conversions where fiat proceeds were used to open trading positions. The query structure is identical to GetAllC2FConversions, differing only in the default platform filter.

Used by operations to monitor position-targeted conversions specifically, which represent a different business flow from bank withdrawals.

---

## 2. Business Logic

### 2.1 C2P-Specific Platform Filter

**What**: Returns completed conversions targeting positions by default.

**Columns/Parameters Involved**: `@TargetPlatformId`

**Rules**:
- Default (NULL): TargetPlatformId = 3 (EtoroPosition only)
- With value: TargetPlatformId = @TargetPlatformId (override)
- Otherwise identical to GetAllC2FConversions (same JOINs, same status filter, same output)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TargetPlatformId | tinyint | YES | NULL | VERIFIED | Optional platform filter. NULL = EtoroPosition (3). Value overrides default. |

**Return Columns:** Same as Monitoring.GetAllC2FConversions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Primary table |
| - | C2F.ConversionStatuses | OUTER APPLY | Latest status |
| - | C2F.FiatTransactions | LEFT JOIN | Fiat amounts |
| - | C2F.CryptoTransactions | LEFT JOIN | Blockchain tx |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetAllC2PConversions (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
├── C2F.FiatTransactions (table)
└── C2F.CryptoTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - filtered by platform=3 |
| C2F.ConversionStatuses | Table | OUTER APPLY - latest status |
| C2F.FiatTransactions | Table | LEFT JOIN |
| C2F.CryptoTransactions | Table | LEFT JOIN |

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

### 8.1 Get all completed C2P conversions
```sql
EXEC Monitoring.GetAllC2PConversions
```

### 8.2 Override to specific platform
```sql
EXEC Monitoring.GetAllC2PConversions @TargetPlatformId = 3
```

### 8.3 Count C2P conversions
```sql
SELECT COUNT(*) FROM C2F.Conversions WITH (NOLOCK) WHERE TargetPlatformId = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetAllC2PConversions | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetAllC2PConversions.sql*
