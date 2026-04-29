# BI_DB_dbo.BI_DB_W8_Users_Status — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_W8_Users_Status` — daily TRUNCATE+INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| External_etoro_BackOffice_CustomerDocument | External | W8-BEN document dates (ExpiryDate, SignedDate) |
| External_etoro_BackOffice_CustomerDocumentToDocumentType | External | Filter DocumentTypeID=12 (W8-BEN) |
| DWH_dbo.Dim_Customer | DWH_dbo | RealCID, GCID, CountryID, PlayerStatusID, PlayerLevelID, VerificationLevelID, IsDepositor, IsValidCustomer, PlayerStatusReasonID, PlayerStatusSubReasonID |
| DWH_dbo.Dim_Country | DWH_dbo | Country name (KYC_Country) |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | PlayerStatus name |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Club name |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | PlayerStatusReason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | PlayerStatusSubReasonName |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Last login (ActionTypeID=14) |
| External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | External | GAP requirements (RequirementID IN 14,16,17) |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Open positions count, US stocks detection |
| DWH_dbo.Dim_Instrument | DWH_dbo | InstrumentTypeID IN 5,6, ISINCountryCode='US' |
| DWH_dbo.V_Liabilities | DWH_dbo | RealizedEquity, Equity (ActualNWA+Liabilities) |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | BI_DB_dbo | Previous player status fields |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| ExpiryDate | External_etoro_BackOffice_CustomerDocument | ExpiryDate | passthrough (latest W8-BEN doc, DocumentTypeID=12) |
| SignedDate | External_etoro_BackOffice_CustomerDocument | SignedDate | passthrough (latest W8-BEN doc) |
| RN_W8SignDate | (computed) | — | ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ExpiryDate DESC) — always 1 (latest doc only) |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough |
| KYC_Country | DWH_dbo.Dim_Country | Name | dim-lookup via Dim_Customer.CountryID |
| last_Log_IN | DWH_dbo.Fact_CustomerAction | — | MAX datetime WHERE ActionTypeID=14 |
| W8BEN_Gap_Required | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=14 AND OverviewStatusID=1, else 0 |
| W8Ben_TIN_change_Required | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=16 AND OverviewStatusID=1, else 0 |
| W8BenExpired_Gap_Required | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=17 AND OverviewStatusID=1, else 0 |
| W8BEN_Gap_Completed | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=14 AND OverviewStatusID=6, else 0 |
| W8Ben_TIN_change_Completed | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=16 AND OverviewStatusID=6, else 0 |
| W8BenExpired_Gap_Completed | External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben | OverviewStatusID | 1 if RequirementID=17 AND OverviewStatusID=6, else 0 |
| Open_Pos | BI_DB_dbo.BI_DB_PositionPnL | — | COUNT of open positions |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | passthrough |
| W8_Group_Status_ID | (computed) | — | CASE: ExpiryDate < year-end → 1 (expired), = year-end → 2 (expiring), > year-end → 3 (valid) |
| UpdateDate | (computed) | — | GETDATE() |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup via Dim_Customer.PlayerStatusID |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | passthrough |
| Equity | DWH_dbo.V_Liabilities | ActualNWA, Liabilities | ActualNWA + Liabilities |
| Club | DWH_dbo.Dim_PlayerLevel | Name | dim-lookup via Dim_Customer.PlayerLevelID |
| Group | (computed) | — | CASE: Platinum+ → 'C', Bronze/Silver/Gold with activity → 'B', without activity → 'A', else 'Other' |
| Has_Open_US_Stocks_Position | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | — | 1 if open position with InstrumentTypeID IN (5,6) AND ISINCountryCode='US' |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | dim-lookup via Dim_Customer.PlayerStatusReasonID |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | dim-lookup via Dim_Customer.PlayerStatusSubReasonID |
| Previous_PlayerStatus | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Previous_PlayerStatus | passthrough |
| Previous_PlayerStatus_Reason | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Previous_PlayerStatus_Reason | passthrough |
| Previous_PlayerStatus_Sub_Reason | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Previous_PlayerStatus_Sub_Reason | passthrough |

**PHASE 10B CHECKPOINT: PASS**
