# Billing.GenTransactionID

> Utility view that generates a random 6-character hexadecimal token using NEWID(), used as a lightweight transaction ID generator for billing operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | Value (computed) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GenTransactionID` is a single-column, zero-base-table utility view that returns a new random 6-character alphanumeric token on every SELECT. The token is derived by taking characters 30-35 (0-indexed) of a GUID string (e.g., from "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" format, characters at position 30-35 are in the last segment), producing values like "AAE80D" or "F3C291".

The view exists as a simple, query-compatible way to generate short unique-ish identifiers for billing transaction records without requiring a sequence object, IDENTITY column, or application-side generation. Callers SELECT from this view to get one token, then embed it in a transaction record. The related function `Billing.GetTransactionID` likely provides similar functionality.

Note: NEWID() generates a UUID v4 (random). Taking 6 chars from position 30 gives 16^6 = ~16.7 million possible values - sufficient for short-lived transaction tokens but NOT globally unique at high volume. Collisions are possible with high concurrency.

---

## 2. Business Logic

### 2.1 Token Generation Algorithm

**What**: Derives a 6-character hex-like token from a GUID's last segment.

**Columns/Parameters Involved**: `Value`

**Rules**:
- `NEWID()` generates a new UUID (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- `CONVERT(VARCHAR(36), NEWID())` converts to the standard 36-char UUID string with hyphens
- `SUBSTRING(..., 30, 6)` extracts characters 30-35 (1-indexed) from the UUID string
- UUID position 30 falls in the last segment (characters 25-36 after the last hyphen at position 24)
- Example: `"550e8400-e29b-41d4-a716-446655440000"` -> position 30-35 = `"446655"` (6 chars from the last segment)
- The result contains hex characters 0-9 and A-F (uppercase from CONVERT)
- Each SELECT call returns a different value (NEWID() is non-deterministic)

---

## 3. Data Overview

| Value | Meaning |
|-------|---------|
| AAE80D | Example generated token - a 6-character hex string from positions 30-35 of a random GUID. Each SELECT returns a new value. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Value | varchar(6) | NO | - | CODE-BACKED | A random 6-character hexadecimal-like token. Computed as `SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 30, 6)`. Returns a new value on every SELECT. Contains characters 0-9 and A-F. ~16.7M possible values. Used as a short transaction identifier in billing operations. NOT globally unique at high volume - collisions possible. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It uses NEWID() (a system function) with no base tables.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetTransactionID | (related function) | Related | The function of the same purpose in the Billing schema; may call or mirror this view's logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GenTransactionID (view)
  (leaf - no base tables, uses NEWID() system function only)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| No dependencies | - | Uses only NEWID() system function |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetTransactionID | Function | Related token generation function; may share same pattern |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Non-deterministic: SELECT returns different Value each call. Cannot be indexed or materialized. Not suitable as a reliable unique key for high-volume concurrent inserts (collision probability: 1/(16^6) = ~0.000006% per pair). For guaranteed uniqueness, use NEWID() directly.

---

## 8. Sample Queries

### 8.1 Generate a single transaction ID token

```sql
SELECT Value FROM Billing.GenTransactionID
-- Returns e.g. 'AAE80D' - a new random value each call
```

### 8.2 Generate multiple tokens (requires CROSS JOIN trick - view returns 1 row)

```sql
-- Each SELECT of the view produces a new token
SELECT Value AS Token1 FROM Billing.GenTransactionID
UNION ALL
SELECT Value FROM Billing.GenTransactionID
UNION ALL
SELECT Value FROM Billing.GenTransactionID
```

### 8.3 Use in INSERT to generate a transaction code

```sql
DECLARE @TransactionCode VARCHAR(6)
SELECT @TransactionCode = Value FROM Billing.GenTransactionID
-- Use @TransactionCode as a short transaction reference
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GenTransactionID | Type: View | Source: etoro/etoro/Billing/Views/Billing.GenTransactionID.sql*
