# BackOffice.UpdateCustomerWeekendFeePrecentage

> Sets the weekend overnight-fee percentage multiplier for a specific customer, allowing individual fee discounts relative to the standard 100% rate.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets Customer.CustomerStatic via Customer.Customer view |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateCustomerWeekendFeePrecentage` (note: intentional typo "Precentage" from original 2014 schema, matching the column name `WeekendFeePrecentage`) controls the overnight/weekend rollover fee rate applied to a specific customer's CFD positions. The standard rate is 100% (full fee applies); lower values grant the customer a proportional discount. This is a back-office lever for customer retention and VIP accommodation.

The procedure exists because certain customers (high-value, partner, or VIP clients) may negotiate reduced weekend fee rates. Since the standard fee is set at the platform level, a per-customer percentage override allows individual adjustments without changing the global fee schedule.

`WeekendFeePrecentage` is stored on `Customer.CustomerStatic` with a DEFAULT of 100 (full fee). A value of 50 would mean the customer pays 50% of the standard weekend fee; 0 would mean no weekend fee for this customer. The UPDATE is applied via the `Customer.Customer` view which routes through to `CustomerStatic`.

---

## 2. Business Logic

### 2.1 Per-Customer Weekend Fee Override

**What**: Sets a customer-specific percentage multiplier applied to the platform's standard weekend rollover fee.

**Columns/Parameters Involved**: `@WeekendFeePrecentage`, `Customer.CustomerStatic.WeekendFeePrecentage`

**Rules**:
- Default = 100 (full standard fee). Stored as TINYINT (0-255).
- Values < 100 grant a fee discount proportional to the percentage. Value of 0 = no weekend fee charged.
- Values > 100 would increase the fee above standard (unusual, but TINYINT allows it).
- No validation is performed - the caller is responsible for providing a valid percentage.
- The typo "Precentage" is preserved in both the SP name and the column name - do not confuse with correctly-spelled alternatives.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Identifies the customer in Customer.CustomerStatic (via Customer.Customer view) whose weekend fee percentage should be updated. |
| 2 | @WeekendFeePrecentage | tinyint | NO | - | CODE-BACKED | New weekend overnight fee percentage for this customer. 100=full standard fee (default for all customers), lower values=discount, 0=no weekend fee. TINYINT range: 0-255. Note: column and SP name both use the typo "Precentage" (not "Percentage"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer (view -> CustomerStatic) | UPDATE target | Sets WeekendFeePrecentage on the customer record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office application to adjust VIP or partner customer fee rates. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateCustomerWeekendFeePrecentage (procedure)
+-- Customer.Customer (view) [UPDATE target -> routes to Customer.CustomerStatic]
      +-- Customer.CustomerStatic (table) [WeekendFeePrecentage column, DEFAULT=100]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target - routes WeekendFeePrecentage write to Customer.CustomerStatic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from application layer for per-customer fee configuration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No range validation - caller must provide a valid TINYINT (0-255).

---

## 8. Sample Queries

### 8.1 Set a 50% weekend fee discount for a VIP customer

```sql
EXEC BackOffice.UpdateCustomerWeekendFeePrecentage
    @CID                   = 12345,
    @WeekendFeePrecentage  = 50;  -- 50% of standard weekend fee
```

### 8.2 Remove weekend fee entirely for a customer

```sql
EXEC BackOffice.UpdateCustomerWeekendFeePrecentage
    @CID                   = 12345,
    @WeekendFeePrecentage  = 0;   -- no weekend fee charged
```

### 8.3 Find customers with non-standard weekend fee rates

```sql
SELECT cs.CID, cs.WeekendFeePrecentage
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.WeekendFeePrecentage <> 100
ORDER BY cs.WeekendFeePrecentage ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateCustomerWeekendFeePrecentage | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateCustomerWeekendFeePrecentage.sql*
