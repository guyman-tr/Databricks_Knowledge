# Dictionary.AddressType

> Lookup table defining address classification types for customer address records, currently containing only "Mailing" as the single address type.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AddressTypeID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AddressType classifies the types of addresses stored for customers in Customer.Address. Each customer address record is tagged with an AddressTypeID to distinguish between different address purposes (mailing, billing, residential, etc.).

Currently the table contains only a single value (1=Mailing), suggesting the platform treats all customer addresses as mailing addresses. The table exists to support future expansion if additional address types (e.g., residential, business, billing) are needed without schema changes.

The address type is stored in Customer.Address and historically tracked in History.Address. The simplicity of the current data (single type) means most queries won't need to JOIN to this table, but it provides forward-compatibility for multi-address-type support.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-value lookup table with one address classification.

---

## 3. Data Overview

| AddressTypeID | Name | Meaning |
|---|---|---|
| 1 | Mailing | The customer's mailing/correspondence address. Used for physical mail, regulatory correspondence, and proof-of-address verification during KYC. Currently the only address type in use. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AddressTypeID | int | NO | - | CODE-BACKED | Primary key identifying the address type. Currently only value 1 (Mailing) exists. Referenced by Customer.Address.AddressTypeID and History.Address.AddressTypeID. |
| 2 | Name | varchar(255) | NO | - | CODE-BACKED | Human-readable address type name. Generous varchar(255) allocation suggests the schema was designed for potentially long descriptive names. Current value: 'Mailing'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.Address | AddressTypeID | Implicit | Customer address records tagged by type |
| History.Address | AddressTypeID | Implicit | Historical address record snapshots |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.Address | Table | Stores AddressTypeID per address |
| History.Address | Table | Historical address type tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryAddressType | CLUSTERED PK | AddressTypeID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryAddressType | PRIMARY KEY | Unique address type identifier on PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all address types
```sql
SELECT  AddressTypeID,
        Name
FROM    Dictionary.AddressType WITH (NOLOCK)
ORDER BY AddressTypeID;
```

### 8.2 Count customer addresses by type
```sql
SELECT  dat.Name            AS AddressType,
        COUNT(*)            AS AddressCount
FROM    Customer.Address ca WITH (NOLOCK)
JOIN    Dictionary.AddressType dat WITH (NOLOCK)
        ON ca.AddressTypeID = dat.AddressTypeID
GROUP BY dat.Name;
```

### 8.3 Get customer addresses with type name
```sql
SELECT  ca.CID,
        dat.Name            AS AddressType,
        ca.*
FROM    Customer.Address ca WITH (NOLOCK)
JOIN    Dictionary.AddressType dat WITH (NOLOCK)
        ON ca.AddressTypeID = dat.AddressTypeID
WHERE   ca.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AddressType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AddressType.sql*
