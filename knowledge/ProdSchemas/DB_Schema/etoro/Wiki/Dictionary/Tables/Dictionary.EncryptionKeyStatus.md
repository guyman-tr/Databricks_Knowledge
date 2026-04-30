# Dictionary.EncryptionKeyStatus

## 1. Business Meaning

### What It Is
A lookup table defining the lifecycle states of encryption keys used for data protection within the platform.

### Why It Exists
Encryption key management follows a lifecycle: keys are created (New), activated for use (Active), and eventually retired (Inactive). This table provides the standard states for key lifecycle tracking, supporting key rotation and compliance with data security standards.

### How It's Used
Standalone dictionary table with no direct FK references found in the codebase. Likely consumed by application-level encryption key management services or external security infrastructure that references key states by ID.

---

## 2. Business Logic

### Key Lifecycle
```
New (2) ────── Key created, not yet in use (pending activation)
  │
  ▼
Active (1) ─── Key currently in use for encryption/decryption
  │
  ▼
Inactive (3) ── Key retired, no longer used for new encryption (may still decrypt historical data)
```

> **Note**: The ID ordering (1=Active, 2=New, 3=Inactive) does not match the lifecycle order. Active is ID 1 because it's the most common/default state.

---

## 3. Data Overview

| KeyStatusID | KeyStatus |
|------------|-----------|
| 1 | Active |
| 2 | New |
| 3 | Inactive |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **KeyStatusID** | `int` | NO | Key status identifier (1=Active, 2=New, 3=Inactive). No PK constraint defined. | `MCP` |
| **KeyStatus** | `nvarchar(50)` | YES | Status label. Uses nvarchar (Unicode-capable) unlike most Dictionary tables. | `MCP` |

---

## 5. Relationships

### Referenced By
No explicit FK references found in the SSDT codebase. Likely consumed by application-layer encryption services.

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
None found in SSDT. Application-layer dependency suspected.

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | None defined (heap table) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 3 |
| **Identity** | No |
| **Temporal** | No |

> **Note**: This table has **no primary key** — unusual for a Dictionary table. It also uses `nvarchar` for the status column instead of the standard `varchar`. Both suggest this was added by a different team or at a different time than the core Dictionary tables.

---

## 8. Sample Queries

```sql
-- Get all encryption key statuses
SELECT  KeyStatusID,
        KeyStatus
FROM    Dictionary.EncryptionKeyStatus WITH (NOLOCK)
ORDER BY KeyStatusID;

-- Find active encryption keys (application-level query pattern)
SELECT  KeyStatusID
FROM    Dictionary.EncryptionKeyStatus WITH (NOLOCK)
WHERE   KeyStatus = N'Active';
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.0 | Phases: DDL ✓ MCP ✓ Codebase ✓*
