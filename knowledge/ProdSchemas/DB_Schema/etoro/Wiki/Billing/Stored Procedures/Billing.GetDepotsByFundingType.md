# Billing.GetDepotsByFundingType

> Returns the list of payment gateway depots (with their active status) for a given funding type - used by the provider recovery service to enumerate available depots for a payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DepotID + IsActive for all depots with FundingTypeID = @FundingTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepotsByFundingType` is a simple depot catalog lookup: given a funding type (payment method category), return all payment gateways (depots) that support that method along with their active/inactive status.

Used by the `ProviderRecoveryServiceUser` account - the provider recovery service, which is responsible for re-routing or recovering failed payments. Knowing which depots are available for a funding type enables the service to find alternative processing routes when one depot fails.

---

## 2. Business Logic

### 2.1 Depot Enumeration by Funding Type

**What**: Returns all depots configured for a specific payment method type.

**Rules**:
- `WHERE FundingTypeID = @FundingTypeID` - filters Billing.Depot to depots of the specified type
- Returns both active and inactive depots (no IsActive filter) - caller decides which to use
- `IsActive` column in output: 1=active (accepting payments), 0=inactive (disabled or in maintenance)
- Common FundingTypeID values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH
- `WITH (NOLOCK)` - dirty reads; depot configuration changes infrequently

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method category to look up. Filters Billing.Depot.FundingTypeID. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH. |
| 2 | DepotID (output) | INT | NO | - | CODE-BACKED | Primary key of the payment gateway depot. |
| 3 | IsActive (output) | BIT | NO | - | CODE-BACKED | Whether the depot is currently active. 1=active (accepting payments), 0=inactive (disabled/maintenance). Caller uses this to filter to usable depots for recovery routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Billing.Depot.FundingTypeID | Filter | Retrieves depots of this payment type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ProviderRecoveryServiceUser | GRANT EXECUTE | Permission | Provider recovery service uses to enumerate available depots for re-routing failed payments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepotsByFundingType (procedure)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | READ NOLOCK - filtered by FundingTypeID; returns DepotID and IsActive |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ProviderRecoveryServiceUser (recovery service) | DB User | Enumerates depots for payment recovery routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No IsActive filter | Design | Returns all depots including inactive; the provider recovery service is responsible for filtering by IsActive when selecting a recovery route |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Get all credit card depots

```sql
EXEC Billing.GetDepotsByFundingType @FundingTypeID = 1;
```

### 8.2 Get active wire transfer depots

```sql
-- Get all, then filter in application for active only
EXEC Billing.GetDepotsByFundingType @FundingTypeID = 2;
-- Application filters results: WHERE IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 8/10, Logic: 5/10, Relationships: 5/10, Sources: 0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (ProviderRecoveryServiceUser) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepotsByFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepotsByFundingType.sql*
