# Staking.GetStakingExternalAddress

> Retrieves the currently active staking pool blockchain address for a given cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: active external staking address for a CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the active staking pool address for a given cryptocurrency, enabling the staking service to know where to send user assets for delegation. It is a simple lookup that reads from Staking.StakingExternalAddress with filters on CryptoId and IsActive=1.

Without this procedure, the application would not know the blockchain destination for staking transfers. It is called before initiating a staking transfer to obtain the correct pool address.

The procedure returns four columns: Id, ExternalAddress, CryptoId, and IsActive. Only the row where IsActive=1 for the requested CryptoId is returned, relying on the unique index (CryptoId, IsActive) in StakingExternalAddress.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The procedure is a simple filtered read.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | INT (IN) | NO | - | VERIFIED | The cryptocurrency to look up the staking pool address for. Corresponds to Wallet.CryptoTypes.CryptoID (e.g., 2=ETH). Filters StakingExternalAddress by CryptoId AND IsActive=1. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | Id | int | StakingExternalAddress record ID |
| 2 | ExternalAddress | varchar(100) | The blockchain address of the active staking pool |
| 3 | CryptoId | int | The cryptocurrency (echoed back) |
| 4 | IsActive | bit | Always 1 (only active addresses returned) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.StakingExternalAddress | SELECT FROM | Reads the active staking address |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the staking application service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingExternalAddress (procedure)
+-- Staking.StakingExternalAddress (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingExternalAddress | Table | SELECT FROM - reads active staking address |

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

### 8.1 Call the procedure for ETH
```sql
EXEC Staking.GetStakingExternalAddress @CryptoId = 2
```

### 8.2 Equivalent direct query
```sql
SELECT Id, ExternalAddress, CryptoId, IsActive
FROM Staking.StakingExternalAddress WITH (NOLOCK)
WHERE CryptoId = 2 AND IsActive = 1
```

### 8.3 Check all active staking addresses
```sql
SELECT ea.Id, ea.ExternalAddress, ct.Name AS CryptoName
FROM Staking.StakingExternalAddress ea WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = ea.CryptoId
WHERE ea.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking pools are managed by eToro centrally; users delegate to these pools |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingExternalAddress | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingExternalAddress.sql*
