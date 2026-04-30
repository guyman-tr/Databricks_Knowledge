# Customer.SetLabel

> Assigns a white-label / partner brand (LabelID) to a customer's account after validating the label exists, controlling the branding and cashier experience the customer sees.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to update; @LabelID - validated against Dictionary.Label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetLabel assigns a white-label brand identifier (LabelID) to a customer. LabelID controls which partner brand the customer is associated with - this affects the logo shown in the cashier, the branded experience, and partner attribution. eToro operated under multiple white-label partnerships (e.g., ICMarkets, JCLyons, RetailFX, eToroUSA), and each partner has a distinct LabelID in Dictionary.Label.

The procedure exists to enforce referential integrity: before writing the LabelID to Customer.Customer, it validates that the LabelID is present in Dictionary.Label. A customer with an invalid LabelID would have a broken cashier experience (missing logo URL), so the validation prevents this.

Data flow: called from account management flows when a customer's brand assignment needs to change (e.g., migrating a customer between partner brands, or correcting a mis-assigned label). Reads Dictionary.Label for existence check, then UPDATE Customer.Customer.LabelID. No history tracking.

---

## 2. Business Logic

### 2.1 LabelID Validation Before Update

**What**: Ensures only valid brand IDs from Dictionary.Label are assigned to customers, preventing broken branding.

**Columns/Parameters Involved**: `@LabelID`, Dictionary.Label.LabelID

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Dictionary.Label WHERE LabelID = @LabelID) -> RAISERROR 60000, RETURN 60000
- Only if the LabelID is valid does the UPDATE proceed
- Dictionary.Label contains: 0=eToro, 1=eToro, 2=RetailFX, 10=JCLyons, 11=ICMarkets, 12=BT, 13=Euroforex, 14=eToroUSA, and other white-label partners
- The check is a simple existence check - the procedure does not validate that the label is active or appropriate for the customer

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. The customer whose LabelID will be updated in Customer.Customer. |
| 2 | @LabelID | int | NO | - | CODE-BACKED | White-label / partner brand identifier. Must exist in Dictionary.Label (Name, URL, CashierLogoURL). Active values include: 0/1=eToro, 2=RetailFX, 10=JCLyons, 11=ICMarkets, 12=BT, 13=Euroforex, 14=eToroUSA. Controls cashier branding and partner attribution for the customer. Validated before update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LabelID | Dictionary.Label | Lookup (validated) | LabelID is validated to exist in Dictionary.Label before the UPDATE runs |
| @CID | Customer.Customer | Modifier | Updates LabelID column for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from account management services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetLabel (procedure)
├── Dictionary.Label (table - validation lookup)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Label | Table | Existence check for @LabelID validation |
| Customer.Customer | View | UPDATE target for LabelID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LabelID validation | Business rule | IF NOT EXISTS in Dictionary.Label -> RAISERROR(60000, 16, 1) + RETURN 60000 |
| TRY/CATCH | Error handling | Any UPDATE error raises error 60000 |

---

## 8. Sample Queries

### 8.1 Assign a customer to the ICMarkets white-label brand
```sql
EXEC Customer.SetLabel @CID = 12345, @LabelID = 11;
```

### 8.2 Find all customers under a specific label
```sql
SELECT c.CID, c.LabelID, l.[Name] AS LabelName
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.Label l WITH (NOLOCK) ON c.LabelID = l.LabelID
WHERE c.LabelID = 11
ORDER BY c.CID;
```

### 8.3 List all available labels for assignment
```sql
SELECT LabelID, [Name], URL, CashierLogoURL
FROM Dictionary.Label WITH (NOLOCK)
ORDER BY LabelID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetLabel | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetLabel.sql*
