# dbo.GetAffiliateIDByUsername

> Returns the AffiliateID for an affiliate whose eToro trading account username (PaymentMethodID = 4) matches the supplied username across any of their three payment detail slots.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Username (eToro trading account, payment method 4) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves an affiliate's AffiliateID from their eToro trading account username. Affiliates can have up to three payment detail records (PaymentDetailsID, PaymentDetails2ID, PaymentDetails3ID). PaymentMethodID = 4 indicates an eToro trading account payout method, and the Username column on the payment detail stores the eToro platform login name. This lookup is used when an upstream system identifies an affiliate by their trading username and needs to map it to the affiliate management system's AffiliateID. Created by Gonen Frim (Nov 2015), updated by Geri Reshef (Jan 2016, ticket 32340).

---

## 2. Business Logic

- Joins tblaff_Affiliates to all three payment detail tables (PD1, PD2, PD3) via LEFT JOIN on PaymentDetailsID, PaymentDetails2ID, PaymentDetails3ID respectively.
- WHERE clause uses OR across all three payment slots: any slot where PaymentMethodID = 4 AND Username = @UserName qualifies.
- No NOCOUNT or SET options configured (missing from this older SP).
- Returns only the AffiliateID column.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @UserName | NVARCHAR(50) | IN | (required) | High | eToro trading account username to search across payment details |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_Affiliates | Read | Source of AffiliateID |
| LEFT JOIN | dbo.tblaff_PaymentDetails (x3) | Read | Payment detail records (all three slots) searched for the username |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateIDByUsername
  ├── dbo.tblaff_Affiliates       (READ)
  └── dbo.tblaff_PaymentDetails   (READ, joined 3 times as PD1, PD2, PD3)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Core affiliate record providing AffiliateID |
| dbo.tblaff_PaymentDetails | Table | Joined three times to check all payment slots for the username |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Find affiliate ID for an eToro trading account username
EXEC dbo.GetAffiliateIDByUsername @UserName = N'trader_john';

-- Use result to load full affiliate profile
DECLARE @AffID INT;
SELECT @AffID = AffiliateID FROM dbo.tblaff_Affiliates A
LEFT JOIN dbo.tblaff_PaymentDetails PD1 ON PD1.PaymentDetailsID = A.PaymentDetailsID
WHERE PD1.PaymentMethodID = 4 AND PD1.Username = N'trader_john';
EXEC dbo.GetAffiliateById @Id = @AffID;

-- Check if a given eToro username is registered as an affiliate
EXEC dbo.GetAffiliateIDByUsername @UserName = N'my_etoro_account';
-- Returns empty result set if not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author notes: Gonen Frim, 30/11/2015; Geri Reshef, 24/01/2016, ticket 32340.)*

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateIDByUsername | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateIDByUsername.sql*
