# Dictionary.ClientRequestType

> Lookup table defining client API request types — currently contains only 1 value (AddACHAccount) for ACH bank account addition requests.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ClientRequestType classifies the types of client-initiated requests that require special processing or tracking in the platform. Currently the table contains a single entry for ACH bank account addition — the process by which US customers link their bank accounts for deposit/withdrawal via the ACH (Automated Clearing House) payment network.

The narrow scope (only 1 value) suggests this table was created for a specific feature (ACH bank account linking) and may expand in the future as new client request types are added. The request type classification allows the system to route, validate, and track different kinds of client requests through their respective processing pipelines.

No FK references or procedure consumers were found in the SSDT project, suggesting this table is consumed by application-layer code rather than stored procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-value lookup with straightforward ID-to-name mapping.

---

## 3. Data Overview

| ID | ClientRequestTypeName | Meaning |
|---|---|---|
| 1 | AddACHAccount | Request to link a US bank account via ACH (Automated Clearing House) — enables direct bank-to-platform transfers for deposits and withdrawals. Required for US customers using bank transfer funding instead of credit cards or PayPal. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the client request type. Currently only value 1 (AddACHAccount). Manually assigned (not identity). |
| 2 | ClientRequestTypeName | varchar(30) | YES | - | VERIFIED | Name of the client request type (e.g., 'AddACHAccount'). Used by application code to identify the processing pipeline for each request type. Nullable but the single production row has a value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK references found in the SSDT project. Consumed by application-layer code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryClientRequestType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all client request types
```sql
SELECT  ID,
        ClientRequestTypeName
FROM    Dictionary.ClientRequestType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find ACH-related request types
```sql
SELECT  ID,
        ClientRequestTypeName
FROM    Dictionary.ClientRequestType WITH (NOLOCK)
WHERE   ClientRequestTypeName LIKE '%ACH%';
```

### 8.3 Check for new request types
```sql
SELECT  ID,
        ClientRequestTypeName
FROM    Dictionary.ClientRequestType WITH (NOLOCK)
WHERE   ID > 1
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClientRequestType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClientRequestType.sql*
