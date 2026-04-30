# Customer.IsTestAccount

> Returns a BIT output parameter indicating whether a given CID belongs to a test account (PlayerLevelID=4), enabling services to exclude internal test users from business operations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> @Result (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsTestAccount checks whether a given CID is a test/internal account by verifying that the customer's PlayerLevelID equals 4. PlayerLevelID=4 is the designation for test accounts in eToro's classification system - these are internal employee test accounts, QA automation accounts, or platform monitoring accounts that should not be included in real business metrics, CRM flows, affiliate attribution, or compliance reporting.

This procedure is used by services that need to skip or filter out test accounts - for example, email dispatch (don't send marketing to test accounts), lead attribution (don't credit affiliates for test registrations), and analytics (don't count test account activity in business metrics). The Ins_HistoryLoginOpenBook procedure uses the same PlayerLevelID<>4 check to exclude test accounts from Service Broker lead events.

---

## 2. Business Logic

### 2.1 Test Account Detection via PlayerLevelID

**What**: Identifies test accounts using the PlayerLevelID=4 sentinel value.

**Columns/Parameters Involved**: `Customer.Customer.PlayerLevelID`

**Rules**:
- PlayerLevelID = 4 = test account (internal/QA/monitoring)
- @Result = 1 if EXISTS(CID with PlayerLevelID=4) -> test account
- @Result = 0 (default) if no matching row or PlayerLevelID != 4 -> regular customer
- Consistent with Ins_HistoryLoginOpenBook: `IF @PlayerLevelID <> 4` (not a test user) before sending leads

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal Customer ID of the account to test. Checked against Customer.Customer WHERE CID=@CID AND PlayerLevelID=4. |
| 2 | @Result | bit (OUTPUT) | NO | 0 | VERIFIED | Output parameter: 1 = the customer is a test account (PlayerLevelID=4); 0 = regular customer account or CID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + PlayerLevelID=4 | Customer.Customer | Reader (EXISTS) | Checks if the CID has PlayerLevelID=4 (test account designation) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for test account filtering in reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsTestAccount (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS check - filters by CID and PlayerLevelID=4 |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a customer is a test account
```sql
DECLARE @isTest BIT = 0;
EXEC Customer.IsTestAccount @CID = 12345678, @Result = @isTest OUTPUT;
SELECT @isTest AS IsTestAccount;  -- 1 = test, 0 = real
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.Customer WITH (NOLOCK)
    WHERE CID = 12345678 AND PlayerLevelID = 4
) THEN 1 ELSE 0 END AS IsTestAccount;
```

### 8.3 Count all test accounts in the system
```sql
SELECT COUNT(*) AS TestAccountCount
FROM Customer.Customer WITH (NOLOCK)
WHERE PlayerLevelID = 4;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsTestAccount | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsTestAccount.sql*
