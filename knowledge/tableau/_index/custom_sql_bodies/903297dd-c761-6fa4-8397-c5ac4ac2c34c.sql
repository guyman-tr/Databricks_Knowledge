SELECT c1.[Dump Lead Tier], CASE WHEN c1.VerificationLevelID=0 THEN 'Dump Lead VO'
WHEN c1.VerificationLevelID=1 THEN 'Dump Lead V1'
WHEN c1.VerificationLevelID=2 THEN 'Dump Lead V2'
WHEN c1.VerificationLevelID=3 THEN 'Dump Lead V3'
 END AS LSD
,SUM(CASE WHEN a.LSD='Dump Lead' THEN 1 ELSE 0 END) AS Jan2024_DumpLead,
SUM(CASE WHEN a1.LSD='Lead' OR b.LSD='Lead' OR c.LSD='Lead' OR d.LSD='Lead'     THEN 1 ELSE 0 END) AS [Lead],
SUM(CASE WHEN a1.IsFunded=1 OR b.IsFunded=1 OR c.IsFunded=1 OR d.IsFunded=1 THEN 1 ELSE 0 END) AS [Funded]
FROM #Dump a
LEFT JOIN #customer c1 ON a.RealCID = c1.RealCID
LEFT JOIN #LSD a1 ON a1.RealCID=a.RealCID AND 20240229 BETWEEN a1.DateID AND a1.ToDateID
LEFT JOIN #LSD b ON a.RealCID=b.RealCID AND 20240331 BETWEEN b.DateID AND b.ToDateID
LEFT JOIN #LSD c ON a.RealCID=c.RealCID AND 20240430 BETWEEN c.DateID AND c.ToDateID
LEFT JOIN #LSD d ON a.RealCID=d.RealCID AND 20240531 BETWEEN d.DateID AND d.ToDateID
GROUP BY c1.[Dump Lead Tier], CASE WHEN c1.VerificationLevelID=0 THEN 'Dump Lead VO'
WHEN c1.VerificationLevelID=1 THEN 'Dump Lead V1'
WHEN c1.VerificationLevelID=2 THEN 'Dump Lead V2'
WHEN c1.VerificationLevelID=3 THEN 'Dump Lead V3'
 END