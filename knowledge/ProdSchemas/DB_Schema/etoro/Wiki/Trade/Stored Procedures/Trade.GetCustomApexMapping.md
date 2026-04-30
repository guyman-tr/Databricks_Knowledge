# Trade.GetCustomApexMapping

> Looks up customer CID, GCID, and ApexID mappings by either Apex IDs or CIDs (or both), used for cross-system customer identification between the trading platform and the Apex clearing system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CID/GCID/ApexID mappings filtered by ApexIDs or CIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex is the external clearing system used for real stock settlement. Each customer who trades real stocks has an Apex account identified by an ApexID. This procedure provides bidirectional lookup between the eToro customer identifiers (CID, GCID) and the Apex identifier, enabling integration between the two systems.

The procedure supports three modes: lookup by ApexIDs, lookup by CIDs, or both simultaneously. This flexibility is needed because different integration points have different starting identifiers.

Data flow: Clearing/settlement services provide either ApexIDs or CIDs as comma-separated strings -> procedure splits and joins to Customer.CustomerStatic -> returns the mapping result set(s).

---

## 2. Business Logic

### 2.1 Dual-Filter Lookup

**What**: Supports independent filtering by ApexIDs, CIDs, or both.

**Columns/Parameters Involved**: `@ApexIDsInput`, `@CIDsInput`

**Rules**:
- If ApexIDs are provided: returns one result set matching by ApexID
- If CIDs are provided: returns one result set matching by CID
- If both are provided: returns TWO separate result sets (one per filter)
- Uses STRING_SPLIT for CSV parsing
- Empty input string still creates the temp table but EXISTS check returns false, skipping that filter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ApexIDsInput | VARCHAR(8000) | NO | - | CODE-BACKED | Comma-separated list of Apex clearing system IDs to look up (e.g., '3ER25056,3ER25013'). |
| 2 | @CIDsInput | VARCHAR(8000) | NO | - | CODE-BACKED | Comma-separated list of eToro Customer IDs to look up (e.g., '5,15'). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | eToro Customer ID. |
| 2 | GCID | INT | - | - | CODE-BACKED | Global Customer ID (cross-regional identifier). |
| 3 | ApexID | VARCHAR | YES | - | CODE-BACKED | Apex clearing system account identifier. May be NULL for customers without Apex accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ApexID / CID | Customer.CustomerStatic | Read | Looks up customer identifiers for cross-system mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Clearing/Settlement Integration | EXEC | Caller | Cross-system customer ID resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomApexMapping (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Source of CID, GCID, and ApexID mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Clearing Integration | External | Apex-to-eToro customer mapping |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses STRING_SPLIT (SQL Server 2016+)
- May return 0, 1, or 2 result sets depending on input
- VARCHAR(8000) limits input to ~400-800 IDs depending on ID length

---

## 8. Sample Queries

### 8.1 Look up by Apex IDs

```sql
EXEC Trade.GetCustomApexMapping @ApexIDsInput = '3ER25056,3ER25013', @CIDsInput = '';
```

### 8.2 Look up by CIDs

```sql
EXEC Trade.GetCustomApexMapping @ApexIDsInput = '', @CIDsInput = '5,15';
```

### 8.3 Query Apex mappings directly

```sql
SELECT CID, GCID, ApexID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE ApexID IS NOT NULL
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomApexMapping | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomApexMapping.sql*
