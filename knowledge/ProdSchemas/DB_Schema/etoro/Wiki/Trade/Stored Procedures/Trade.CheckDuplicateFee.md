# Trade.CheckDuplicateFee

> Monitoring procedure that detects positions charged multiple end-of-week fees within the same fee window over the last 5 days, and sends an email alert listing duplicates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckDuplicateFee is a data integrity monitoring procedure that identifies positions charged more than once for end-of-week (overnight/weekend) fees within the same fee window. End-of-week fees (CreditTypeID=14) are charged once per position per fee period. If a position shows multiple charges in the same window, it indicates a billing bug that needs investigation and potential refund.

The procedure scans History.ActiveCredit for CreditTypeID=14 entries over the last 5 days, groups by PositionID+CID+Description+FeeDate, and flags any group with count > 1. Dividend-related payments (Description='Payment caused by dividend') are excluded. If duplicates are found, an HTML email is sent to the address configured in Maintenance.Feature (FeatureID=105).

---

## 2. Business Logic

### 2.1 Fee Window Definition

**What**: Each fee day runs from 23:00 to 22:00 the next day.

**Columns/Parameters Involved**: `#feedate.Fromdate`, `#feedate.Todate`, `#feedate.FeeDate`

**Rules**:
- Fee window: 23:00 on day N to 22:00 on day N+1
- Scans last 5 days of fee windows
- A position should have exactly one CreditTypeID=14 entry per fee window

### 2.2 Duplicate Detection

**What**: Groups fee charges by position and fee date to find duplicates.

**Columns/Parameters Involved**: `PositionID`, `CID`, `Description`, `FeeDate`, `CreditTypeID`

**Rules**:
- GROUP BY PositionID, CID, Description, FeeDate HAVING COUNT(*) > 1
- Excludes Description = 'Payment caused by dividend'
- Joins back to get individual CreditID, Payment, and Occurred for each duplicate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | History.ActiveCredit | SELECT | Scans fee charges (CreditTypeID=14) over last 5 days |
| (reads) | Maintenance.Feature | SELECT | Gets email recipient address (FeatureID=105) |
| (sends) | msdb.dbo.sp_send_dbmail | EXEC | Sends HTML email alert with duplicate details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | (external) | EXEC | Daily monitoring job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckDuplicateFee (procedure)
+-- History.ActiveCredit (table)
+-- Maintenance.Feature (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | SELECT fee charges |
| Maintenance.Feature | Table | SELECT email recipient (FeatureID=105) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job | External | Daily duplicate fee monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table clustered index | Performance | #History_Credit gets clustered index on Occurred |
| Email alert | Notification | HTML-formatted email with PositionID, CID, Description, FeeDate, total, Occurred, Payment, CreditID |

---

## 8. Sample Queries

### 8.1 Run the duplicate fee check

```sql
EXEC Trade.CheckDuplicateFee;
```

### 8.2 Manually check for duplicate fees on a specific position

```sql
SELECT PositionID, Description, CAST(Occurred AS DATE) AS FeeDate, COUNT(*) AS ChargeCount
FROM   History.ActiveCredit WITH (NOLOCK)
WHERE  CreditTypeID = 14
       AND PositionID = @PositionID
       AND Occurred > GETDATE() - 5
GROUP BY PositionID, Description, CAST(Occurred AS DATE)
HAVING COUNT(*) > 1;
```

### 8.3 Check configured email recipient

```sql
SELECT FeatureID, Value
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID = 105;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckDuplicateFee | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckDuplicateFee.sql*
