# Dictionary.ProtocolParameter

> Configuration table storing 49 named parameters for payment protocols — API keys, URLs, merchant IDs, secrets — used by the billing engine to configure PSP connections.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ParamID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (PK nonclustered + NCI on ProtocolID) |

---

## 1. Business Meaning

Dictionary.ProtocolParameter defines the configuration parameters needed by each payment protocol to communicate with its PSP. These are the metadata keys (not values) — parameter names like "apiUsername", "merchantID", "secret", "requestUrl". The actual values are stored in the billing configuration system and mapped to these parameter definitions at runtime.

This table exists because each PSP requires different configuration parameters. Xor needs a terminal number and validation key; PayPal needs API username, password, and signature; Neteller needs a merchant ID and key. By storing parameter names in the database, the billing engine dynamically builds PSP-specific configurations.

Referenced by billing configuration procedures and loaded via Billing.LoadProtocols as part of protocol initialization.

---

## 2. Business Logic

### 2.1 Protocol-Specific Parameters

**What**: Each protocol has its own set of named parameters that define its PSP connection configuration.

**Columns/Parameters Involved**: `ParamID`, `ProtocolID`, `ParamName`

**Rules**:
- Parameters are grouped by ProtocolID — each protocol has 3-11 parameters.
- Protocol 1 (Xor 1): 11 params (command, version, language, transactionType, creditType, transactionCode, validation, terminalNumber, requestUrl, userName, password)
- Protocol 2 (PayPal): 9 params (apiUsername, apiPassword, environment, returnUrl, cancelUrl, signature, paymentActionCodeType, redirectUrl, command)
- Protocol 7 (Neteller): 7 params (url, version, merchant_id, merch_key, merch_name, merch_account, test)
- Parameter names are NOT values — they define the schema of each protocol's configuration.

---

## 3. Data Overview

| ParamID | ProtocolID | ParamName | Meaning |
|---|---|---|---|
| 1 | 1 (Xor 1) | command | Transaction command type for Xor PSP |
| 8 | 1 (Xor 1) | terminalNumber | Virtual POS terminal identifier |
| 12 | 2 (PayPal) | apiUsername | PayPal API authentication username |
| 17 | 2 (PayPal) | signature | PayPal API request signature |
| 23 | 7 (Neteller) | merchant_id | Neteller merchant account identifier |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParamID | int | NO | - | VERIFIED | Primary key. Sequential ID for each parameter definition across all protocols (1-49). |
| 2 | ProtocolID | int | NO | - | VERIFIED | FK → Dictionary.Protocol. Groups parameters by payment protocol. Indexed for efficient lookup. |
| 3 | ParamName | varchar(50) | NO | - | VERIFIED | Configuration parameter key name (e.g., "apiUsername", "merchantID", "secret"). Used by the billing engine to build PSP-specific connection configurations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | FK Constraint | Description |
|-------------------|---------|---------------|-------------|
| Dictionary.Protocol | ProtocolID | FK_DPRT_DPRP | Parent payment protocol |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers — parameters are resolved at runtime by the billing engine.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ProtocolParameter
└── Dictionary.Protocol (FK)
    ├── Billing.PaymentService (FK)
    └── Dictionary.ProtocolDirection (FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK — parent protocol definition |

### 6.2 Objects That Depend On This

No known dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPPM | NONCLUSTERED PK | ParamID ASC | - | - | Active (FF=90) |
| DPPM_PROTOCOL | NONCLUSTERED | ProtocolID ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPPM | PRIMARY KEY | Unique parameter identifier |
| FK_DPRT_DPRP | FOREIGN KEY | ProtocolID → Dictionary.Protocol |

---

## 8. Sample Queries

### 8.1 List parameters by protocol
```sql
SELECT  p.Name AS ProtocolName,
        pp.ParamID,
        pp.ParamName
FROM    [Dictionary].[ProtocolParameter] pp WITH (NOLOCK)
JOIN    [Dictionary].[Protocol] p WITH (NOLOCK) ON pp.ProtocolID = p.ProtocolID
ORDER BY p.Name, pp.ParamID;
```

### 8.2 Count parameters per protocol
```sql
SELECT  p.Name AS ProtocolName,
        COUNT(*) AS ParamCount
FROM    [Dictionary].[ProtocolParameter] pp WITH (NOLOCK)
JOIN    [Dictionary].[Protocol] p WITH (NOLOCK) ON pp.ProtocolID = p.ProtocolID
GROUP BY p.Name
ORDER BY ParamCount DESC;
```

### 8.3 Find protocols with a specific parameter
```sql
SELECT  p.ProtocolID,
        p.Name
FROM    [Dictionary].[ProtocolParameter] pp WITH (NOLOCK)
JOIN    [Dictionary].[Protocol] p WITH (NOLOCK) ON pp.ProtocolID = p.ProtocolID
WHERE   pp.ParamName = 'merchantID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ProtocolParameter | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ProtocolParameter.sql*
