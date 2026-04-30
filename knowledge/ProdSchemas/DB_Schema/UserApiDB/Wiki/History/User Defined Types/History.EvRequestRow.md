# History.EvRequestRow (UDT)

> Table-valued parameter type for passing EV request/response XML pairs for batch insertion into History.EvRequest.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Request + Response (XML columns) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

History.EvRequestRow is a TVP for batch-inserting Electronic Verification request/response pairs into History.EvRequest. Each row contains the XML request sent to an EV provider and the XML response received. Used by Ev schema procedures when recording verification attempt history.

---

## 2. Business Logic

No complex business logic. Data transport type for XML pairs.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Request | xml | NO | - | CODE-BACKED | XML payload sent to the EV provider. Contains user identity data for verification. |
| 2 | Response | xml | YES | - | CODE-BACKED | XML response from the EV provider. NULL if request failed or timed out. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ev schema procedures | Parameter | Parameter Type | TVP for batch EV request history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Ev schema procedures (external).

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Requests History.EvRequestRow
INSERT INTO @Requests (Request, Response) VALUES ('<req>data</req>', '<resp>result</resp>')
```

### 8.2 Inspect
```sql
DECLARE @R History.EvRequestRow
INSERT INTO @R VALUES ('<req/>', '<resp/>')
SELECT * FROM @R
```

### 8.3 Multiple rows
```sql
DECLARE @R History.EvRequestRow
INSERT INTO @R VALUES ('<req1/>', '<resp1/>'), ('<req2/>', NULL)
SELECT * FROM @R
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: History.EvRequestRow | Type: User Defined Type | Source: UserApiDB/UserApiDB/History/User Defined Types/History.EvRequestRow.sql*
