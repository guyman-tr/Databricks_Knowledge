# DWH_dbo.Vw_STS_User_Operations_Data_History — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Base Table** | DWH_dbo.STS_User_Operations_Data_History |
| **Production Database** | STS_Audit |
| **Production Schema** | StsAudit |
| **Production Table** | UserOperations |
| **View Transform** | CAST(ClientDeviceId AS nvarchar(max)) — type widening only |
| **Upstream Wiki** | STS_User_Operations_Data_History.md (Batch 11) |

## Column Lineage

| # | View Column | Base Table Column | Transform | Notes |
|---|-----------|------------------|-----------|-------|
| 1 | Gcid | Gcid | None | Passthrough |
| 2 | RealCid | RealCid | None | Passthrough |
| 3 | DemoCid | DemoCid | None | Passthrough |
| 4 | ApplicationIdentifier | ApplicationIdentifier | None | Passthrough |
| 5 | ApplicationVersion | ApplicationVersion | None | Passthrough |
| 6 | ClientIp | ClientIp | None | Passthrough |
| 7 | ClientName | ClientName | None | Passthrough |
| 8 | CreatedAt | CreatedAt | None | Passthrough |
| 9 | UserAgent | UserAgent | None | Passthrough |
| 10 | AccessTokenHashed | AccessTokenHashed | None | Passthrough |
| 11 | ClientDeviceId | ClientDeviceId | CAST(nvarchar(50) → nvarchar(max)) | Only transform in view |
| 12 | ParentSessionId | ParentSessionId | None | Passthrough |
| 13 | AccountTypeName | AccountTypeName | None | Passthrough |
| 14 | LoginTypeName | LoginTypeName | None | Passthrough |
| 15 | SessionId | SessionId | None | Passthrough |
| 16 | GatewayAppId | GatewayAppId | None | Passthrough |
| 17 | DateID | DateID | None | Passthrough |
| 18 | UpdateDate | UpdateDate | None | Passthrough |
| 19 | ProxyType | ProxyType | None | Passthrough |
| 20 | CountryISOCode | CountryISOCode | None | Passthrough |
| 21 | AdditionalData | AdditionalData | None | Passthrough |

## Columns Lost (Base Table → View)

None — all 21 base table columns are exposed.

## Columns Added (View-specific)

None — no additional columns.
