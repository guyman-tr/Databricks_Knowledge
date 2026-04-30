# Trade.Alert_LiquidityProviderContracts

> Monitoring alert that detects unexpected instruments configured for the ZBFX liquidity provider and sends an email notification to the dealing team.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - parameterless alert procedure) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an operational alert that monitors the `Trade.LiquidityProviderContracts` table for instruments incorrectly assigned to the ZBFX liquidity provider (LiquidityProviderID = 69). ZBFX is expected to handle only a specific whitelist of instruments (IDs 600, 1971, 601-610). If any other instrument is found mapped to ZBFX, the procedure sends an HTML email alert to the dealing team and a specific person.

Without this alert, instruments could be misconfigured to route through the wrong liquidity provider, potentially causing failed trades, incorrect pricing, or unhedged exposure. The alert provides a safety net for the instrument-to-LP configuration process.

The procedure runs as a scheduled check (likely via SQL Agent). It first checks if any non-whitelisted instruments exist for LP 69; if none, it returns immediately. If violations are found, it builds an HTML table listing the offending contracts and emails it via `msdb.dbo.sp_send_dbmail`.

---

## 2. Business Logic

### 2.1 ZBFX Instrument Whitelist Check

**What**: Validates that only approved instruments are configured for the ZBFX liquidity provider.

**Columns/Parameters Involved**: `LiquidityProviderContracts.LiquidityProviderID`, `LiquidityProviderContracts.InstrumentID`

**Rules**:
- ZBFX is identified by LiquidityProviderID = 69
- Approved ZBFX instruments: 600, 1971, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610
- The email query excludes a slightly different set (600, 1971, 1186) for display purposes - 1186 is excluded from the alert body but not from the trigger check
- If NO unapproved instruments exist for LP 69, the procedure returns immediately with no email
- Historical comment indicates the whitelist was changed on 04/09/2016 (previously only excluded instruments 35, 37)

### 2.2 Email Notification

**What**: Sends an HTML-formatted alert email with contract details.

**Rules**:
- Recipients: `dealing_alerts_prod@etoro.com` and `pinikr@etoro.com`
- Subject format: "Unknown instruments were configured to ZBFX found at : {date}"
- Body: HTML table with ContractID, LiquidityProviderID, InstrumentID, FromDate, ToDate
- Uses `msdb.dbo.sp_send_dbmail` with HTML body format

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It is a parameterless scheduled alert. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/EXISTS | Trade.LiquidityProviderContracts | READER | Checks for instruments assigned to ZBFX (LP 69) outside the whitelist |
| EXEC | msdb.dbo.sp_send_dbmail | System call | Sends HTML email alert when violations are detected |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | - | Scheduler | Likely called on a schedule to periodically check LP configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Alert_LiquidityProviderContracts (procedure)
+-- Trade.LiquidityProviderContracts (table)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | SELECT - checks for unapproved instrument-to-LP mappings |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends email alert when violations found |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SQL-level dependents found) | - | Called by SQL Agent schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Preview what the alert would detect

```sql
SELECT  ContractID, LiquidityProviderID, InstrumentID, FromDate, ToDate
FROM    Trade.LiquidityProviderContracts WITH (NOLOCK)
WHERE   LiquidityProviderID = 69
        AND InstrumentID NOT IN (600, 1971, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610);
```

### 8.2 Check all ZBFX contracts

```sql
SELECT  ContractID, InstrumentID, FromDate, ToDate
FROM    Trade.LiquidityProviderContracts WITH (NOLOCK)
WHERE   LiquidityProviderID = 69
ORDER BY InstrumentID;
```

### 8.3 Run the alert manually

```sql
EXEC Trade.Alert_LiquidityProviderContracts;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Alert_LiquidityProviderContracts | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Alert_LiquidityProviderContracts.sql*
