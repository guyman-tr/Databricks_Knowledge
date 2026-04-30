# Wallet.GetHostingCompanies

> Stored procedure that returns all hosting company configurations used for wallet infrastructure organization.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Wallet.HostingCompanies |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetHostingCompanies returns the list of hosting companies configured in the wallet system. Hosting companies represent the infrastructure providers or organizational entities that manage wallet server infrastructure. Each company has a display order (OrderIndex) for consistent UI presentation.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Id, Name, OrderIndex from Wallet.HostingCompanies with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key of the hosting company record. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Display name of the hosting company. |
| 3 | OrderIndex | int | YES | - | CODE-BACKED | Sort order for UI display of hosting companies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.HostingCompanies | FROM | Reads all hosting company configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Hosting company configuration loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetHostingCompanies (procedure)
+-- Wallet.HostingCompanies (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.HostingCompanies | Table | FROM with NOLOCK |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all hosting companies
```sql
EXEC Wallet.GetHostingCompanies
```

### 8.2 Hosting companies ordered for display
```sql
SELECT Id, Name, OrderIndex FROM Wallet.HostingCompanies WITH (NOLOCK) ORDER BY OrderIndex
```

### 8.3 Count wallets per hosting company
```sql
SELECT hc.Name, COUNT(w.Id) AS WalletCount
FROM Wallet.HostingCompanies hc WITH (NOLOCK)
LEFT JOIN Wallet.Wallets w WITH (NOLOCK) ON w.HostingCompanyId = hc.Id
GROUP BY hc.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetHostingCompanies | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetHostingCompanies.sql*
