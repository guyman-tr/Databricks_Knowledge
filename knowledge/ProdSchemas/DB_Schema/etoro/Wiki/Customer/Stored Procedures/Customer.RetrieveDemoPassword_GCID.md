# Customer.RetrieveDemoPassword_GCID

> Retrieves the auto-login password for a demo account by GCID via the STS stored procedure STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid; uses the OUTPUT pattern rather than a direct function call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID INT - the global customer ID to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RetrieveDemoPassword_GCID` is the GCID-based variant of `Customer.RetrieveDemoPassword`. Where the username-based version calls the STS function directly, this procedure uses the STS stored procedure `dbo.STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid` with an OUTPUT parameter, then selects the result. This accommodates scenarios where only the GCID is available (not the username), which is common in the external-facing API layer where GCID is the primary identity.

The "OBtoWT" naming is legacy (OpenBook to WebTrader). The STS procedure call pattern (EXEC with OUTPUT vs. SELECT of function) differs from RetrieveDemoPassword but the semantic purpose is identical.

---

## 2. Business Logic

### 2.1 STS Auto-Login Password Retrieval by GCID

**What**: Retrieves the demo auto-login token using GCID as the identifier.

**Rules**:
- DECLARE @result NVARCHAR(512).
- EXEC `dbo.STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid @GCID, @result OUTPUT`.
- SELECT @result.
- Returns NULL if GCID not found.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID. Passed to STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid to retrieve the auto-login password. |

**Returned:**
- Single scalar: NVARCHAR(512) auto-login password; NULL if GCID not found.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | dbo.STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid | EXEC (cross-DB) | Retrieves auto-login token via OUTPUT parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | External call | Caller | Used to get demo auto-login credentials by GCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RetrieveDemoPassword_GCID (procedure)
└── dbo.STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid (cross-DB procedure) [EXEC OUTPUT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.STS_P_Get_OBtoWT_AutoLoginUserPasswordByGcid | Cross-DB Procedure | EXEC with OUTPUT - retrieves auto-login token |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Calls for GCID-based demo auto-login |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| STS dependency | External | Requires STS database connectivity |
| NVARCHAR(512) max | Design | @result limited to 512 characters - sufficient for any token format |

---

## 8. Sample Queries

### 8.1 Retrieve demo password for a GCID

```sql
EXEC Customer.RetrieveDemoPassword_GCID @GCID = 123456789
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RetrieveDemoPassword_GCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RetrieveDemoPassword_GCID.sql*
