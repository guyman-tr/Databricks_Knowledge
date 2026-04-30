# dbo.uFnStringToBase64

> Scalar utility function that converts a VARCHAR string to its Base64-encoded representation using XML-based binary conversion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns: VARCHAR(MAX) (Base64-encoded string) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a utility function that performs Base64 encoding of input strings. It converts a plain text VARCHAR value to its Base64-encoded equivalent using SQL Server's XML capabilities for binary-to-Base64 conversion. This pattern is commonly used for encoding sensitive data, generating authentication tokens, or preparing data for systems that require Base64 format.

In the WalletDB context, this function may be used for encoding wallet addresses, API tokens, or other values that need to be transmitted in Base64 format to blockchain providers or external services.

No stored procedures or views reference this function directly in the SSDT project. It may be called from application code or used in ad-hoc operations.

---

## 2. Business Logic

### 2.1 Base64 Encoding Algorithm

**What**: Converts string to binary, then encodes the binary as Base64 using XML conversion.

**Columns/Parameters Involved**: `@InputString` (input), return value (Base64 string)

**Rules**:
- Step 1: CAST input string to VARBINARY(MAX) to get raw bytes
- Step 2: Use XML xs:hexBinary to convert binary to hex representation
- Step 3: Use XML xs:base64Binary to convert hex to Base64
- Output is a standard Base64 string (A-Z, a-z, 0-9, +, /, = padding)
- Deterministic: same input always produces same output

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InputString (IN) | VARCHAR(MAX) | - | - | CODE-BACKED | The plain text string to encode. Can be any length. Will be converted to binary bytes then Base64-encoded. |
| 2 | (RETURN) | VARCHAR(MAX) | - | - | CODE-BACKED | Base64-encoded representation of the input string. Standard Base64 alphabet with = padding. Length is approximately 4/3 of input byte length. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure computation, no table access).

### 5.2 Referenced By (other objects point to this)

No references found in SSDT code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Encode a simple string
```sql
SELECT dbo.uFnStringToBase64('Hello World') AS Encoded
-- Returns: SGVsbG8gV29ybGQ=
```

### 8.2 Encode a wallet address
```sql
SELECT dbo.uFnStringToBase64('0x209251aac2b31f0952f5498c4828788cf8ce7871') AS EncodedAddress
```

### 8.3 Encode and verify round-trip
```sql
DECLARE @original VARCHAR(100) = 'TestValue123'
DECLARE @encoded VARCHAR(MAX) = dbo.uFnStringToBase64(@original)
SELECT @original AS Original, @encoded AS Encoded
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.uFnStringToBase64 | Type: Scalar Function | Source: WalletDB/dbo/Functions/dbo.uFnStringToBase64.sql*
