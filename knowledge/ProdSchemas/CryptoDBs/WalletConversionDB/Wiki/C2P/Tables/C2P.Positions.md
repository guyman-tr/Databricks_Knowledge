# C2P.Positions

> Links crypto-to-fiat conversions to the trading positions opened with the converted fiat proceeds, recording the position identifier created on the eToro trading platform.

| Property | Value |
|----------|-------|
| **Schema** | C2P |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

C2P.Positions is the bridge between the crypto conversion system (C2F schema) and the eToro trading platform. When a customer converts crypto with TargetPlatformId=3 (EtoroPosition), the fiat proceeds are used to open a trading position. This table records which position was created for which conversion, establishing the end-to-end traceability from crypto sell to position open.

Without this table, there would be no way to trace a trading position back to its originating crypto conversion. This is essential for reconciliation, customer support, and audit - answering "which crypto conversion funded this position?"

Rows are created by `C2P.InsertPosition` after the position open step completes in the saga pipeline. The table has 2,415 rows, broadly aligning with the ~2,815 EtoroPosition-targeted conversions in C2F.Conversions (difference due to conversions that failed before reaching the position step). Data starts from 2025-12-11, suggesting this schema was added later than the C2F schema (which has data from 2023).

---

## 2. Business Logic

### 2.1 Conversion-to-Position Link

**What**: Each row creates a 1:1 mapping between a C2F conversion and a trading position.

**Columns/Parameters Involved**: `ConversionId`, `PositionId`

**Rules**:
- ConversionId references C2F.Conversions.Id (implicit cross-schema FK, no constraint)
- PositionId is a GUID string identifying the position on the trading platform
- InsertPosition enforces uniqueness on (ConversionId, PositionId) via NOT EXISTS check
- Only conversions with TargetPlatformId=3 (EtoroPosition) should have entries here

---

## 3. Data Overview

| Id | ConversionId | PositionId | Occurred | Meaning |
|----|-------------|------------|----------|---------|
| 2415 | 17039 | bd637018-99fc-40ad-a466-773d7274f16c | 2026-04-15 09:04:56 | Most recent - links conversion 17039 to position GUID. Position created ~2 minutes after conversion started. |
| 2414 | 17032 | df5271ba-0b0e-4aec-8cb1-a3c33178b3f8 | 2026-04-15 06:08:04 | Another conversion-to-position link. Each position has a unique GUID from the trading platform. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | References C2F.Conversions.Id (implicit cross-schema FK, no constraint). Links this position record to the crypto conversion that funded it. Only conversions with TargetPlatformId=3 (EtoroPosition) have entries here. |
| 3 | PositionId | nvarchar(255) | NO | - | CODE-BACKED | Trading platform position identifier (GUID format in live data). Identifies the specific position opened on the eToro platform with the converted fiat proceeds. Wide nvarchar(255) accommodates different ID formats. |
| 4 | Occurred | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the position record was created. Set to GETUTCDATE() by InsertPosition. Represents when the position open was recorded in this DB, not necessarily when the position was opened on the trading platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | C2F.Conversions | Implicit FK (cross-schema) | Links to the conversion that funded this position |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2P.InsertPosition | Stored Procedure | WRITER - creates position link rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_C2P_Positions | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_C2P_Positions | PRIMARY KEY | Identity PK. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 Get position for a conversion
```sql
SELECT p.PositionId, p.Occurred
FROM C2P.Positions p WITH (NOLOCK)
WHERE p.ConversionId = @ConversionId
```

### 8.2 Full conversion-to-position trace
```sql
SELECT c.Id AS ConversionId, c.Gcid, c.CryptoAmount, c.CorrelationId,
       p.PositionId, p.Occurred AS PositionCreated
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2P.Positions p WITH (NOLOCK) ON p.ConversionId = c.Id
ORDER BY c.Id DESC
```

### 8.3 Conversions targeting positions but missing position records
```sql
SELECT c.Id, c.Gcid, c.CorrelationId, c.Occurred
FROM C2F.Conversions c WITH (NOLOCK)
LEFT JOIN C2P.Positions p WITH (NOLOCK) ON p.ConversionId = c.Id
WHERE c.TargetPlatformId = 3 AND p.Id IS NULL
ORDER BY c.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2P.Positions | Type: Table | Source: WalletConversionDB/C2P/Tables/C2P.Positions.sql*
