# Trade.GetCustomerDataAndRestrictions

> Composite procedure that returns customer static data, mirror/copy-trade configuration (including minimum amount and mirror type), and customer operation restrictions in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 3 result sets: customer static, mirror config, restrictions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a comprehensive customer context needed for copy-trading operations. It returns the customer's static data (identity, country), their mirror/copy-trade configuration (minimum copy amount and mirror type based on whether they're a fund account), and their active operation restrictions. This is typically called during copy-trade setup or validation.

The mirror type determines how copy-trading operates for the customer: regular customers use MirrorType=1, while fund accounts (AccountTypeID=9 in BackOffice.Customer) use MirrorType=4, which has different minimum amounts and rules.

Data flow: Copy-trading service provides a CID -> procedure queries Customer.CustomerStatic for static data -> reads Maintenance.Feature for mirror validation XML config -> checks BackOffice.Customer for fund status -> parses minimum mirror amount from XML -> calls Trade.GetCustomerRestrictionsForAPI for restrictions -> returns 3 result sets.

---

## 2. Business Logic

### 2.1 Fund Account Detection and Mirror Type

**What**: Determines whether the customer is a fund account, which changes the mirror type and associated rules.

**Columns/Parameters Involved**: `BackOffice.Customer.AccountTypeID`, `@MirrorType`

**Rules**:
- Default MirrorType = 1 (regular customer)
- If BackOffice.Customer.AccountTypeID = 9 for this CID -> MirrorType = 4 (fund account)
- MirrorType determines which XML node to read for minimum mirror amount

### 2.2 XML-Based Minimum Mirror Amount

**What**: The minimum copy amount is stored in an XML configuration feature and varies by mirror type.

**Columns/Parameters Involved**: `Maintenance.Feature.XMLValue`, `FeatureID=23`, `MirrorType`

**Rules**:
- FeatureID=23 contains mirror validation rules as XML
- XPath query extracts MinMirrorAmountAbsolute for the applicable MirrorType
- This minimum amount is the lowest amount a copier can allocate when copying a trader
- Result is returned as MinMirrorAmount + MirrorTypeID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve data and restrictions for. |

### Return Columns (Result Set 1 - Customer Static)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 2 | GCID | INT | - | - | CODE-BACKED | Global Customer ID (cross-regional identifier). |
| 3 | UserName | VARCHAR | - | - | CODE-BACKED | Customer's username on the platform. |
| 4 | CountryID | INT | - | - | CODE-BACKED | Customer's country of residence. FK to Dictionary.Country. |

### Return Columns (Result Set 2 - Mirror Configuration)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MinMirrorAmount | dtPrice | - | - | CODE-BACKED | Minimum amount required to copy/mirror a trader. Extracted from XML config based on customer's mirror type. |
| 2 | MirrorTypeID | INT | - | - | CODE-BACKED | Mirror type: 1=regular customer, 4=fund account. Determines copy-trading rules and minimum amounts. |

### Return Columns (Result Set 3 - Restrictions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-4 | (Same as Trade.GetCustomerRestrictionsForAPI) | - | - | - | CODE-BACKED | CID, OperationTypeID, Occurred, BlockReasonID - see Trade.GetCustomerRestrictionsForAPI documentation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Read | Customer identity and country data |
| FeatureID=23 | Maintenance.Feature | Read | Mirror validation XML configuration |
| @CID | BackOffice.Customer | Read | Fund account detection (AccountTypeID=9) |
| @CID | Trade.GetCustomerRestrictionsForAPI | EXEC | Delegates restriction retrieval |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Copy Trading Service | EXEC | Caller | Comprehensive customer context for copy-trade operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerDataAndRestrictions (procedure)
├── Customer.CustomerStatic (table)
├── Maintenance.Feature (table)
├── BackOffice.Customer (table)
└── Trade.GetCustomerRestrictionsForAPI (procedure)
    └── Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Customer static data (CID, GCID, UserName, CountryID) |
| Maintenance.Feature | Table | XML-based mirror validation configuration (FeatureID=23) |
| BackOffice.Customer | Table | Fund account detection (AccountTypeID=9) |
| Trade.GetCustomerRestrictionsForAPI | Procedure | Called to get customer operation restrictions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy Trading Service | External | Customer context for copy-trade operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- XML parsing uses XQuery with sql:variable for mirror type injection
- Returns 3 separate result sets

---

## 8. Sample Queries

### 8.1 Execute for a specific customer

```sql
EXEC Trade.GetCustomerDataAndRestrictions @CID = 12345;
```

### 8.2 Check mirror configuration directly

```sql
SELECT XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MinMirrorAmountAbsolute)[1]', 'decimal(18,8)') AS RegularMinAmount,
       XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="4"]/@MinMirrorAmountAbsolute)[1]', 'decimal(18,8)') AS FundMinAmount
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 23;
```

### 8.3 Find all fund accounts

```sql
SELECT bc.CID, cs.GCID, cs.UserName
FROM BackOffice.Customer bc WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON bc.CID = cs.CID
WHERE bc.AccountTypeID = 9;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerDataAndRestrictions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerDataAndRestrictions.sql*
