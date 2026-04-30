# BackOffice.SetWorldCheckStatus

> Updates the world-check (PEP/sanctions screening) status identifier on a customer's BackOffice profile, linking the customer to their most recent screening result from the external compliance screening service.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetWorldCheckStatus records the outcome of a PEP (Politically Exposed Person) and sanctions screening check on a customer's BackOffice record. The WorldCheckID links the customer to their entry in the screening system (dbo.Screening_UserScreening / world-check provider data), enabling compliance staff to trace which screening run produced the current risk classification.

This procedure is called when the screening service returns a result for a customer - either on initial onboarding, on a periodic re-screen, or when a compliance officer triggers a manual check. The WorldCheckID value is then consumed by BackOffice.SetRiskClassificationNew (the AML risk scoring engine) as one of its 14 scoring dimensions (Parameter 7: PEP/Screening status).

The procedure is intentionally minimal: no validation, no transaction, no return code check. The caller (screening service integration) owns the responsibility for passing a valid WorldCheckID.

---

## 2. Business Logic

### 2.1 Direct Single-Column Update

**What**: Sets WorldCheckID on the customer's BackOffice record.

**Columns/Parameters Involved**: `@CID`, `@WorldCheckID`

**Rules**:
- UPDATE BackOffice.Customer SET WorldCheckID=@WorldCheckID WHERE CID=@CID
- No transaction wrapping, no error handling, no @@ROWCOUNT check
- If @CID not found: 0 rows affected, silent no-op
- No validation of @WorldCheckID against the screening table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose world-check status is being updated. Must correspond to a CID in BackOffice.Customer. Invalid CID results in a 0-row silent no-op. |
| 2 | @WorldCheckID | INT | NO | - | VERIFIED | The identifier from the external screening system (world-check / PEP screening service) for this customer's most recent screening result. Written to BackOffice.Customer.WorldCheckID. Consumed by SetRiskClassificationNew as scoring Parameter 7 (PEP/Screening status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER (UPDATE WorldCheckID) | Records the screening result reference on the customer profile |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance screening service integration | - | Caller | Called when PEP/sanctions screening returns a result for a customer |
| BackOffice.SetRiskClassificationNew | WorldCheckID | Consumer (indirect) | Reads WorldCheckID from BackOffice.Customer to compute the PEP/Screening dimension score (Parameter 7) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetWorldCheckStatus (procedure)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: SET WorldCheckID=@WorldCheckID WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetRiskClassificationNew | Stored Procedure | Reads WorldCheckID (set by this procedure) to score the PEP/Screening risk dimension |
| Compliance screening integration | External | Sets the WorldCheckID after each screening run |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Minimal Implementation Note

Unlike most BackOffice write procedures, SetWorldCheckStatus has no TRY/CATCH, no BEGIN TRAN, no RETURN @@ERROR, and no @@ROWCOUNT validation. This reflects its role as a lightweight integration stub called by an automated screening pipeline that handles retry and error tracking externally.

---

## 8. Sample Queries

### 8.1 Set the world-check status for a customer
```sql
EXEC BackOffice.SetWorldCheckStatus
    @CID         = 12345678,
    @WorldCheckID = 9001   -- ID from the screening service result
```

### 8.2 Find customers with a specific world-check status
```sql
SELECT CID, WorldCheckID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE WorldCheckID = 9001
```

### 8.3 Find customers with no world-check record
```sql
SELECT CID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE WorldCheckID IS NULL
  AND RegulationID IS NOT NULL
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetWorldCheckStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetWorldCheckStatus.sql*
