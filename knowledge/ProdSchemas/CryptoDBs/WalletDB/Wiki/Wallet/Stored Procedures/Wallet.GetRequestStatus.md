# Wallet.GetRequestStatus

> Retrieves the current status from the legacy RequestStatus table for a specific customer, cryptocurrency, and request type combination.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns status value from legacy RequestStatus table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure reads from a legacy `Wallet.RequestStatus` table (note: singular, not the `RequestStatuses` table used by the newer request pipeline). It retrieves the current status for a specific combination of customer (Gcid), cryptocurrency (CryptoId), and request type. This appears to be a legacy status-tracking mechanism from before the formal Requests/RequestStatuses pipeline was implemented.

The procedure provides a quick answer to "what is the current status of this type of operation for this customer and crypto?" - for example, "is customer X currently in the middle of a BTC send?"

Note: This references `Wallet.RequestStatus` (singular) which is distinct from `Wallet.RequestStatuses` (plural). The singular table is likely a legacy simplified status tracker, while the plural table is the newer event-sourced status history.

---

## 2. Business Logic

### 2.1 Legacy Status Lookup

**What**: Simple three-key lookup on the legacy RequestStatus table.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@RequestType`, `RequestStatus.Status`

**Rules**:
- Direct WHERE filter on Gcid, CryptoId, and RequestType
- Returns the Status column value
- No NOLOCK hint (consistent reads)
- May return empty result if no matching record exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID to look up status for. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency identifier. FK to Wallet.CryptoTypes. |
| 3 | @RequestType | tinyint | NO | - | CODE-BACKED | Type of request to check status for (e.g., send, conversion, payment). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Status | (varies) | YES | - | NAME-INFERRED | Current status value for the specified Gcid/CryptoId/RequestType combination from the legacy RequestStatus table. Exact values depend on the RequestType context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.RequestStatus | FROM | Legacy status tracking table (singular) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Likely called from legacy application code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRequestStatus (procedure)
└── Wallet.RequestStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatus | Table | Direct SELECT by composite key (Gcid, CryptoId, RequestType) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Legacy procedure, likely called from older app code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No NOLOCK | Read isolation | Uses default read consistency (no NOLOCK hint) |

---

## 8. Sample Queries

### 8.1 Check request status for a customer
```sql
EXEC Wallet.GetRequestStatus @Gcid = 12345678, @CryptoId = 1, @RequestType = 1;
```

### 8.2 Manual lookup on the legacy RequestStatus table
```sql
SELECT Gcid, CryptoId, RequestType, Status
FROM Wallet.RequestStatus WITH (NOLOCK)
WHERE Gcid = 12345678;
```

### 8.3 Compare legacy vs new request status tracking
```sql
-- Legacy (singular table)
SELECT Status FROM Wallet.RequestStatus WITH (NOLOCK)
WHERE Gcid = 12345678 AND CryptoId = 1 AND RequestType = 1;

-- New pipeline (Requests + RequestStatuses)
SELECT TOP 1 rs.RequestStatusId
FROM Wallet.Requests r WITH (NOLOCK)
    JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON rs.RequestId = r.Id
WHERE r.Gcid = 12345678 AND r.CryptoId = 1 AND r.RequestTypeId = 1
ORDER BY rs.Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRequestStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetRequestStatus.sql*
