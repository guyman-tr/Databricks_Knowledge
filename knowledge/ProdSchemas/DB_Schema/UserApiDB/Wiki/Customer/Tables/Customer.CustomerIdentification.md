# Customer.CustomerIdentification

> Maps the three user identifiers (GCID, CID, DemoCID) and stores crypto custody wallet data (Tangany and DLT identifiers with statuses).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + unique filtered on TanganyID + NC on CID) |

---

## 1. Business Meaning

Customer.CustomerIdentification serves dual purposes: (1) it maps the three user identifier systems - GCID (global), CID (legacy real account), and DemoCID (demo account) - and (2) it stores crypto custody wallet identifiers and statuses for both Tangany (regulated custodian) and DLT (distributed ledger) systems.

The CID mapping is critical for backward compatibility. Legacy systems use CID (real account ID) while modern services use GCID. The DemoCID links to the user's practice/demo account. Crypto wallet fields (TanganyID/Status, DltID/Status) were added to support MiCA-compliant crypto custody.

---

## 2. Business Logic

### 2.1 Triple Identifier Mapping

**What**: Maps between three user ID systems.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- GCID is the primary key - one row per user
- CID is the legacy real-account identifier (indexed for fast lookup)
- DemoCID links to the demo/practice account
- All three are non-null - every user has all three IDs

---

## 3. Data Overview

N/A - transactional table with millions of rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID - the modern universal identifier. |
| 2 | CID | int | NO | - | CODE-BACKED | Legacy real-account Customer ID. Used by older trading systems. Indexed for fast CID-to-GCID lookup. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Demo/practice account Customer ID. Links to the user's virtual-money account. |
| 4 | TanganyID | uniqueidentifier | YES | - | CODE-BACKED | Tangany crypto custody wallet GUID. Uniquely indexed (filtered, non-null only). NULL if user has no Tangany wallet. |
| 5 | UpdateDate | datetime | NO | getdate() | CODE-BACKED | Last modification timestamp for this record. Default: current datetime. |
| 6 | TanganyStatusID | tinyint | YES | - | CODE-BACKED | FK to Dictionary.TanganyStatus. Wallet lifecycle state: 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. See [Tangany Status](_glossary.md#tangany-status). |
| 7 | DltID | uniqueidentifier | YES | - | CODE-BACKED | DLT (Distributed Ledger Technology) identifier for blockchain operations. NULL if user has no DLT setup. |
| 8 | DltStatusID | tinyint | YES | - | CODE-BACKED | FK to Dictionary.DltStatus. DLT verification state: 1=Pending, 2=Ongoing, 3=Failed, 4=Passed, 5=Inactive. See [DLT Status](_glossary.md#dlt-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TanganyStatusID | Dictionary.TanganyStatus | Explicit FK | Tangany wallet lifecycle state |
| DltStatusID | Dictionary.DltStatus | Explicit FK | DLT verification state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CreateTanganyID | GCID | SP writes | Creates Tangany wallet |
| Customer.UpdateTanganyStatus | GCID | SP writes | Updates wallet status |
| Customer.UpdateDltStatus | GCID | SP writes | Updates DLT status |
| Customer.GetDltData | GCID | SP reads | Returns DLT data |
| Customer.GetTanganyData | GCID | SP reads | Returns Tangany data |
| Customer.GetLinkedCustomer | CID | SP reads | CID-to-GCID lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerIdentification (table)
  +-- Dictionary.TanganyStatus (table) [done]
  +-- Dictionary.DltStatus (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TanganyStatus | Table | FK: TanganyStatusID |
| Dictionary.DltStatus | Table | FK: DltStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CreateTanganyID | Stored Procedure | Writes TanganyID/Status |
| Customer.UpdateTanganyStatus | Stored Procedure | Updates TanganyStatusID |
| Customer.GetLinkedCustomer | Stored Procedure | CID-GCID lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerIdentification | CLUSTERED PK | GCID | - | - | Active (PAGE compressed) |
| IDX_CustomerIdentification_TanganyID | NC UNIQUE | TanganyID | - | WHERE TanganyID IS NOT NULL | Active |
| IDX_Customer_CustomerIdentification_CID | NONCLUSTERED | CID | DemoCID | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_CustomerIdentification_UpdateDate | DEFAULT | getdate() |
| FK_CustomerIdentification_DltStatusID | FOREIGN KEY | DltStatusID -> Dictionary.DltStatus |
| FK_CustomerIdentification_TanganyStatusID | FOREIGN KEY | TanganyStatusID -> Dictionary.TanganyStatus |

---

## 8. Sample Queries

### 8.1 Look up GCID from CID
```sql
SELECT GCID, DemoCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE CID = @CID
```

### 8.2 Get crypto wallet status
```sql
SELECT ci.GCID, ci.TanganyID, ts.Name AS TanganyStatus, ci.DltID, ds.Name AS DltStatus
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
LEFT JOIN Dictionary.TanganyStatus ts WITH (NOLOCK) ON ci.TanganyStatusID = ts.TanganyStatusID
LEFT JOIN Dictionary.DltStatus ds WITH (NOLOCK) ON ci.DltStatusID = ds.DltStatusID
WHERE ci.GCID = @GCID
```

### 8.3 Find users with active Tangany wallets
```sql
SELECT GCID, TanganyID FROM Customer.CustomerIdentification WITH (NOLOCK)
WHERE TanganyStatusID IN (3, 5, 6) -- Customer, MicaCustomer, ConsentCustomer
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.CustomerIdentification | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.CustomerIdentification.sql*
