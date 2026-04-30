# Billing.GetDepositFundingType

> Returns the FundingTypeID (payment method type) for a given deposit, by joining Billing.Deposit to Billing.Funding. Created PAYUS-2979 (May 2021) for the Payments API read separation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: FundingTypeID (INT) for the specified deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositFundingType` is a focused single-purpose lookup that answers: "what payment method type was used for this deposit?" Given a `DepositID`, it joins to `Billing.Funding` (to resolve `FundingID` -> `FundingTypeID`) and returns the funding type (e.g., CreditCard, WireTransfer, PayPal).

Created in May 2021 (PAYUS-2979) as part of the Billing Service Database Readonly Separation initiative, which created read-only access patterns for the Payments API service. This SP encapsulates the minimum required read for funding type resolution - the `PamentsAPIUser` service account does not need full deposit details, just the funding type.

---

## 2. Business Logic

### 2.1 Funding Type Resolution for a Deposit

**What**: Deposits store a `FundingID` (specific payment instrument) but not a `FundingTypeID` directly. The funding type must be resolved via the payment instrument registry.

**Columns/Parameters Involved**: `@DepositID`, `Billing.Deposit.FundingID`, `Billing.Funding.FundingTypeID`

**Rules**:
- `Billing.Deposit.FundingID` -> INNER JOIN `Billing.Funding.FundingID` -> `Billing.Funding.FundingTypeID`
- `SELECT TOP(1)` guards against edge cases (in normal operation, each DepositID maps to exactly one FundingID, which maps to exactly one FundingTypeID)
- FundingTypeID values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 7=MoneyBookers/Skrill, 17=ACH (from Dictionary.FundingType)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | Primary key of the deposit to look up. Maps to Billing.Deposit.DepositID. |
| 2 | FundingTypeID (output) | INT | NO | - | CODE-BACKED | Payment method type used for this deposit. Resolved via JOIN: Billing.Deposit.FundingID -> Billing.Funding.FundingTypeID. References Dictionary.FundingType. Values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit.DepositID | Lookup | Retrieves FundingID for the specified deposit |
| FundingID | Billing.Funding.FundingID | JOIN | Resolves FundingID to FundingTypeID |
| FundingTypeID | Dictionary.FundingType | Implicit | The returned FundingTypeID references the payment method type registry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PamentsAPIUser | GRANT EXECUTE | Permission | Payments API service uses this SP for read-only funding type resolution (PAYUS-2979 Billing Service DB Readonly Separation) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositFundingType (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ NOLOCK - provides FundingID for the given DepositID |
| Billing.Funding | Table | READ NOLOCK - INNER JOIN to resolve FundingID -> FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PamentsAPIUser (Payments API service) | DB User | Calls to resolve funding type for a deposit as part of read-separated API pattern |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SELECT TOP(1) | Safety | Returns at most one row; normal operation has exactly one FundingTypeID per deposit |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Get funding type for a deposit

```sql
EXEC Billing.GetDepositFundingType @DepositID = 987654;
```

### 8.2 Inline equivalent

```sql
SELECT TOP(1) F.FundingTypeID
FROM Billing.Deposit D WITH (NOLOCK)
INNER JOIN Billing.Funding F WITH (NOLOCK) ON F.FundingID = D.FundingID
WHERE D.DepositID = 987654;
```

### 8.3 Get funding type with the type name

```sql
SELECT TOP(1)
    F.FundingTypeID,
    FT.FundingType AS FundingTypeName
FROM Billing.Deposit D WITH (NOLOCK)
INNER JOIN Billing.Funding F WITH (NOLOCK) ON F.FundingID = D.FundingID
INNER JOIN Dictionary.FundingType FT WITH (NOLOCK) ON FT.FundingTypeID = F.FundingTypeID
WHERE D.DepositID = 987654;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Billing Service Database Readonly Separation](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/8635220045) | Confluence | Documents the 2021 initiative (PAYUS-2979) to create read-only SP access for the Payments API service - context for why this SP was created |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.8/10 (Elements: 10/10, Logic: 3/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers (PamentsAPIUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositFundingType.sql*
