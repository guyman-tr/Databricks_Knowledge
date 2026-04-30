# Monitoring.GetAllC2FConversions

> Retrieves all completed crypto-to-fiat conversions (IbanAccount and EtoroPlatform targets) with full details including status, fiat amounts, and blockchain transaction IDs for operational monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Completed C2F conversions with full details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAllC2FConversions provides a comprehensive view of all completed crypto-to-fiat conversions. By default it returns TargetPlatformId IN (1, 2) - IbanAccount and EtoroPlatform targets (excluding C2P/EtoroPosition). The optional @TargetPlatformId parameter allows filtering to a specific platform. Only completed conversions (StatusId=3) are returned.

Used by operations dashboards to monitor conversion activity and by support teams to investigate specific conversions.

---

## 2. Business Logic

### 2.1 Platform-Filtered Completed Conversions

**What**: Returns completed conversions for C2F-type targets, with optional platform override.

**Columns/Parameters Involved**: `@TargetPlatformId`

**Rules**:
- Default (NULL): TargetPlatformId IN (1, 2) - IbanAccount + EtoroPlatform
- With value: TargetPlatformId = @TargetPlatformId (any specific platform)
- Status filter: cs.StatusId = 3 (Completed only)
- Uses OUTER APPLY for latest status (TOP 1 ORDER BY cs.Id DESC)
- LEFT JOINs FiatTransactions and CryptoTransactions (may be NULL for edge cases)
- Ordered by Occurred DESC (most recent first)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TargetPlatformId | tinyint | YES | NULL | VERIFIED | Optional platform filter. NULL = IbanAccount + EtoroPlatform (1,2). Specific value overrides default filter. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | Conversion ID |
| 2 | Gcid | bigint | VERIFIED | Customer ID |
| 3 | CorrelationId | uniqueidentifier | VERIFIED | Saga correlation ID |
| 4 | Occurred | datetime2 | VERIFIED | Conversion creation time |
| 5 | TargetPlatformId | tinyint | VERIFIED | Fiat destination type |
| 6 | CryptoId | int | VERIFIED | Source crypto asset |
| 7 | FiatId | int | VERIFIED | Target fiat currency |
| 8 | CryptoAmount | decimal | VERIFIED | Crypto quantity converted |
| 9 | ConversionFeePercentage | decimal | VERIFIED | Fee rate applied |
| 10 | Status | tinyint | VERIFIED | Current status (always 3=Completed due to filter) |
| 11 | FiatAmount | decimal | CODE-BACKED | Actual fiat amount (from FiatTransactions) |
| 12 | UsdAmount | decimal | CODE-BACKED | Actual USD amount |
| 13 | BlockchainTransactionId | varchar | CODE-BACKED | On-chain transaction hash |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Primary table |
| - | C2F.ConversionStatuses | OUTER APPLY | Latest status lookup |
| - | C2F.FiatTransactions | LEFT JOIN | Actual fiat amounts |
| - | C2F.CryptoTransactions | LEFT JOIN | Blockchain transaction details |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetAllC2FConversions (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
├── C2F.FiatTransactions (table)
└── C2F.CryptoTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - filtered by platform and status |
| C2F.ConversionStatuses | Table | OUTER APPLY - latest status |
| C2F.FiatTransactions | Table | LEFT JOIN - fiat amounts |
| C2F.CryptoTransactions | Table | LEFT JOIN - blockchain tx |

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

### 8.1 Get all completed C2F conversions
```sql
EXEC Monitoring.GetAllC2FConversions
```

### 8.2 Get only IbanAccount conversions
```sql
EXEC Monitoring.GetAllC2FConversions @TargetPlatformId = 1
```

### 8.3 Count by platform
```sql
SELECT TargetPlatformId, COUNT(*) FROM C2F.Conversions WITH (NOLOCK)
WHERE TargetPlatformId IN (1, 2) GROUP BY TargetPlatformId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetAllC2FConversions | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetAllC2FConversions.sql*
