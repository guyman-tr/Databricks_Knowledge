# Customer.GetFtdDate

> Returns the First Time Deposit (FTD) date for a customer - the date when the customer made their first approved real-money deposit.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PaymentDate of the FTD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetFtdDate retrieves the date of a customer's First Time Deposit (FTD). The FTD is a critical business milestone - it marks when a user transitions from a registered/demo user to an active funded user. This date is used for analytics (time-to-FTD metrics), compliance reporting, bonus eligibility calculations, and affiliate commission tracking.

The FTD concept is fundamental to eToro's business model: registration is free, but the platform monetizes when users deposit and trade real money. The FTD date determines the user's "activation" in the revenue funnel.

The procedure reads from dbo.Deposit (the payments/deposit table) joined to dbo.Real_Customer, filtering for `IsFTD = 1` (the deposit flagged as the first-time deposit).

---

## 2. Business Logic

### 2.1 FTD Identification

**What**: The first deposit is flagged in the Deposit table with IsFTD=1, and this procedure returns its payment date.

**Columns/Parameters Involved**: `IsFTD`, `PaymentDate`

**Rules**:
- Only one deposit per customer should have IsFTD=1
- Returns PaymentDate of that specific deposit
- If the customer has no FTD (never deposited), returns empty result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID to look up the FTD date for. |
| 2 | PaymentDate (output) | datetime | YES | - | CODE-BACKED | Date and time of the customer's first approved real-money deposit. NULL/empty if no FTD exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | Resolves GCID to CID for deposit lookup |
| CID | dbo.Deposit | JOIN | The payments/deposit table containing FTD flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called for analytics, compliance, and activation metrics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetFtdDate (procedure)
+-- dbo.Deposit (table)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Deposit | Table | FROM - reads PaymentDate where IsFTD=1 |
| dbo.Real_Customer | Table | JOIN on GCID - resolves CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get FTD date
```sql
EXEC Customer.GetFtdDate @gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT d.PaymentDate
FROM dbo.Deposit d WITH (NOLOCK)
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.CID = d.CID
WHERE rc.GCID = @gcid AND d.IsFTD = 1
```

### 8.3 Check if customer has made FTD
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM dbo.Deposit d WITH (NOLOCK)
    JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.CID = d.CID
    WHERE rc.GCID = @gcid AND d.IsFTD = 1
) THEN 1 ELSE 0 END AS HasFTD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetFtdDate | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetFtdDate.sql*
