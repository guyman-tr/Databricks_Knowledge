# Billing.GetCustomerRegulationByDepositId

> Resolves the regulatory jurisdiction (RegulationID) that governed a specific deposit by looking up the ProtocolMIDSettings record attached to that deposit - restricted to DepotID=12 deposits only. Used by payout/withdrawal processing to determine which regulatory ruleset applies when processing a payout linked to a prior deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID (filtered to DepotID=12 only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerRegulationByDepositId` resolves the regulatory jurisdiction identifier (RegulationID) for a deposit. It retrieves the `RegulationID` from `Billing.ProtocolMIDSettings` via the `ProtocolMIDSettingsID` foreign key stored in `Billing.Deposit`.

`Billing.ProtocolMIDSettings` is the payment routing configuration table - each row records the MID (Merchant ID) for a specific combination of (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID). When a deposit is processed, it is assigned a `ProtocolMIDSettingsID` that encodes which regulatory entity (e.g., CySEC, FCA, ASIC) processed the transaction. This SP extracts that regulatory jurisdiction back out for downstream use.

**DepotID=12 constraint**: The procedure includes a hardcoded `AND d.DepotID = 12` filter. It only returns results for deposits routed through depot 12. For deposits via other depots, the SP returns 0 rows. This was introduced as part of PAYUA-2586 (May 2021, Ryta B.) - a Ukraine-specific regulatory implementation, where depot 12 likely corresponds to a specific Ukrainian or Eastern European regulatory gateway.

Called by `PayoutUser` and `SQL_SecurePay` services - both related to payout processing and secure payment operations.

---

## 2. Business Logic

### 2.1 Regulation Lookup via ProtocolMIDSettings Join

**What**: Joins Billing.Deposit to Billing.ProtocolMIDSettings on ProtocolMIDSettingsID to extract the RegulationID that governed the deposit.

**Columns/Parameters Involved**: `@DepositID`, `d.ProtocolMIDSettingsID`, `s.RegulationID`, `d.DepotID`

**Rules**:
- `WHERE d.DepositID = @DepositID AND d.DepotID = 12`: Filters to the specific deposit and only if it was processed via depot 12.
- `INNER JOIN Billing.ProtocolMIDSettings s ON d.ProtocolMIDSettingsID = s.ID`: Resolves the MID settings record to get the RegulationID.
- If `@DepositID` belongs to a different depot, returns 0 rows (INNER JOIN with DepotID=12 filter excludes it).
- If `ProtocolMIDSettingsID` is NULL in Billing.Deposit, INNER JOIN returns 0 rows.
- Returns only `RegulationID` (single column scalar result).

**Diagram**:
```
@DepositID
     |
     v
Billing.Deposit (d) WHERE DepositID=@DepositID AND DepotID=12
     |
     INNER JOIN
     |
Billing.ProtocolMIDSettings (s) ON d.ProtocolMIDSettingsID = s.ID
     |
  SELECT s.RegulationID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The DepositID to resolve regulatory jurisdiction for. Must be a deposit with DepotID=12, otherwise 0 rows returned. |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | RegulationID | INT | YES | CODE-BACKED | Regulatory jurisdiction identifier from Billing.ProtocolMIDSettings. Identifies which regulatory entity (e.g., CySEC, FCA, ASIC) governed this deposit's processing. NULL if ProtocolMIDSettingsID on the deposit has no matching ProtocolMIDSettings row. Returns 0 rows if deposit is not DepotID=12. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID, ProtocolMIDSettingsID, DepotID | Billing.Deposit | Direct read (SELECT WHERE DepositID + DepotID=12) | Source deposit record - must have DepotID=12 |
| ProtocolMIDSettingsID -> ID, RegulationID | Billing.ProtocolMIDSettings | INNER JOIN | MID settings record containing the regulatory jurisdiction for this deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser | EXECUTE grant | Permission | Payout service resolves deposit regulation before processing payout |
| SQL_SecurePay | EXECUTE grant | Permission | Secure payment service uses regulation lookup during payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerRegulationByDepositId (procedure)
├── Billing.Deposit (table)
└── Billing.ProtocolMIDSettings (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | WHERE DepositID=@DepositID AND DepotID=12; provides ProtocolMIDSettingsID |
| Billing.ProtocolMIDSettings | Table | INNER JOIN on ID; source of RegulationID |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called directly by PayoutUser and SQL_SecurePay application services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| DepotID=12 hardcoded | Only returns results for deposits routed through depot 12. Returns empty for all other depots. Created for PAYUA-2586 - likely a Ukraine/Eastern Europe specific regulatory requirement. |
| NOLOCK | Billing.Deposit read with NOLOCK. Billing.ProtocolMIDSettings not explicitly hinted (generally read-heavy config table). |
| Returns 0 rows if not found | INNER JOIN means no row returned if deposit doesn't exist, is wrong depot, or has no matching ProtocolMIDSettings record. Callers must handle empty result. |

---

## 8. Sample Queries

### 8.1 Get regulation for a specific deposit

```sql
-- Returns RegulationID if deposit is DepotID=12; empty otherwise
EXEC [Billing].[GetCustomerRegulationByDepositId] @DepositID = 9876543
```

### 8.2 Verify which depot a deposit belongs to

```sql
-- Check if a deposit is eligible for this SP (must be DepotID=12):
SELECT DepositID, DepotID, ProtocolMIDSettingsID
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE DepositID = 9876543
-- If DepotID != 12, GetCustomerRegulationByDepositId will return empty
```

### 8.3 Direct regulation lookup (cross-depot equivalent)

```sql
-- For any depot, get regulation directly:
SELECT s.RegulationID
FROM [Billing].[Deposit] d WITH (NOLOCK)
INNER JOIN [Billing].[ProtocolMIDSettings] s ON d.ProtocolMIDSettingsID = s.ID
WHERE d.DepositID = 9876543
-- (Remove the DepotID=12 restriction for full coverage)
```

---

## 9. Atlassian Knowledge Sources

Jira ticket referenced in DDL comment:
- **PAYUA-2586** (2021-05-09, Ryta B.): Initial version - Ukraine-specific regulation lookup for deposits and withdrawals. Same ticket also created `GetCustomerRegulationByWithdrawId`.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comment) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerRegulationByDepositId | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerRegulationByDepositId.sql*
