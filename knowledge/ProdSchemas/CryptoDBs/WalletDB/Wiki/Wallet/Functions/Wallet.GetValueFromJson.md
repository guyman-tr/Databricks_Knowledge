# Wallet.GetValueFromJson

> Scalar utility function that safely extracts a named value from a JSON string, returning NULL if the input is empty, null, or not valid JSON.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) - extracted JSON value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetValueFromJson is a defensive JSON extraction helper used throughout the Wallet schema to safely pull individual property values out of JSON strings stored in database columns. It wraps SQL Server's native `JSON_VALUE` with null/empty/validity checks to prevent runtime errors on malformed or missing JSON.

This function exists because many Wallet tables store semi-structured data in JSON columns (e.g., `DetailsJson` on RequestStatuses, Requests). Rather than repeating the same null-check + ISJSON + JSON_VALUE pattern in every procedure, this function centralizes the safe extraction logic.

The function is called by stored procedures such as `Wallet.GetWalletsByMultiGcids` to extract specific error codes from JSON detail payloads (e.g., extracting `$.Code` to check for wallet-related error codes like `WL.0102` and `WL.0105`).

---

## 2. Business Logic

### 2.1 Defensive JSON Extraction

**What**: Safely extracts a single scalar value from a JSON string by property name, with three-layer null protection.

**Columns/Parameters Involved**: `@Json`, `@ValueName`

**Rules**:
- If `@Json` is NULL or empty string, returns NULL (no error thrown)
- If `@Json` is not valid JSON per `ISJSON()`, returns NULL (no error thrown)
- If `@Json` is valid JSON, extracts `$.<@ValueName>` using `JSON_VALUE` and returns the scalar string value
- Only top-level properties are extracted (JSON_VALUE with `$.` prefix) - nested paths require the caller to pass the full path as `@ValueName`

**Diagram**:
```
@Json input
  |
  v
[Is NULL or empty?] --YES--> return NULL
  |
  NO
  v
[Is valid JSON?] --NO--> return NULL
  |
  YES
  v
[JSON_VALUE(@Json, '$.' + @ValueName)] --> return extracted value
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Json | varchar(max) | YES | - | CODE-BACKED | The JSON string to extract a value from. Typically sourced from `DetailsJson` columns on tables like Wallet.RequestStatuses. May be NULL, empty, or invalid JSON - all cases handled safely. |
| 2 | @ValueName | varchar(100) | NO | - | CODE-BACKED | The name of the top-level JSON property to extract. Appended to `$.` to form the JSON path. In practice, callers pass values like `'Code'` to extract error codes from request status detail payloads. |
| 3 | RETURN | varchar(max) | YES | - | CODE-BACKED | The extracted scalar value as a string, or NULL if the JSON is missing/invalid or the property does not exist. Callers typically compare the result against known code constants (e.g., `'WL.0102'`, `'WL.0105'`). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetWalletsByMultiGcids | DetailsJson | Function Call | Calls GetValueFromJson to extract error codes (`$.Code`) from RequestStatuses.DetailsJson for wallet status classification |
| Wallet.GetWalletsByMultiGcids_Temp | DetailsJson | Function Call | Same usage pattern as GetWalletsByMultiGcids - temp/development variant |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetWalletsByMultiGcids | Stored Procedure | Calls this function to extract `$.Code` from JSON for wallet error classification |
| Wallet.GetWalletsByMultiGcids_Temp | Stored Procedure | Same usage - temp variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Extract a specific JSON property safely
```sql
SELECT Wallet.GetValueFromJson('{"Code":"WL.0102","Message":"Wallet not found"}', 'Code')
-- Returns: 'WL.0102'
```

### 8.2 Handle NULL and invalid JSON gracefully
```sql
SELECT Wallet.GetValueFromJson(NULL, 'Code')          -- Returns: NULL
SELECT Wallet.GetValueFromJson('', 'Code')             -- Returns: NULL
SELECT Wallet.GetValueFromJson('not json', 'Code')     -- Returns: NULL
```

### 8.3 Usage pattern from wallet status classification
```sql
SELECT
    rs.RequestId,
    Wallet.GetValueFromJson(rs.DetailsJson, 'Code') AS ErrorCode
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON drs.Id = rs.RequestStatusId
WHERE drs.Name = 'Error'
  AND Wallet.GetValueFromJson(rs.DetailsJson, 'Code') IN ('WL.0102', 'WL.0105')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetValueFromJson | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.GetValueFromJson.sql*
