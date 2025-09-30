--Aging Report Query--

SELECT  C.CustomerID
       ,CONCAT(C.FirstName,' ',C.LastName) AS FullName
       ,CASE WHEN C.CompanyName = '' THEN 'RESIDENT' ELSE C.CompanyName END AS CompanyName
	   ,C.CustomerType
	   ,A.AccountID
	   ,A.ServiceAddress
	   ,SUM(CASE WHEN DATEDIFF(DAY, D.FullDate, GETDATE()) BETWEEN 0 AND 30 
				 THEN
					 CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					+CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END
				 ELSE 0 
			END) AS [0-30]
       ,SUM(CASE WHEN DATEDIFF(DAY, D.FullDate, GETDATE()) <=60
				 THEN
					 CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					+CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END
				 ELSE 0 
			END) AS [31-60]
	   ,SUM(CASE WHEN DATEDIFF(DAY, D.FullDate, GETDATE()) <=90
				 THEN
					 CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					+CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END
				 ELSE 0 
			END) AS [61-90]
       ,SUM(CASE WHEN DATEDIFF(DAY, D.FullDate, GETDATE()) > 90
				 THEN
					 CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					-CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END
					+CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END
				 ELSE 0 
			END) AS [90+]
	   ,SUM(CASE WHEN F.TransactionTypeID IN (1,4) THEN F.TransactionAmount + ISNULL(F.TDUAmount,0)
				 WHEN F.TransactionTypeID IN (2,3) THEN -(F.TransactionAmount + F.TDUAmount)
                 ELSE 0
             END) AS TotalAmountDue
FROM FactUsage F
JOIN DimAccount A ON F.AccountID = A.AccountID
JOIN DimCustomer C ON A.CustomerID = C.CustomerID
JOIN DimDate D ON F.DateID = D.DateID
WHERE F.TransactionTypeID IN (1,2,3,4)
GROUP BY C.CustomerID
        ,C.FirstName
		,C.LastName
        ,C.CompanyName 
		,C.CustomerType
	    ,A.AccountID
	    ,A.ServiceAddress
HAVING SUM(CASE WHEN F.TransactionTypeID IN (1,4) THEN F.TransactionAmount + ISNULL(F.TDUAmount,0)
				 WHEN F.TransactionTypeID IN (2,3) THEN -(F.TransactionAmount + F.TDUAmount)
                 ELSE 0
             END) > 0 
ORDER BY C.CustomerID, A.AccountID DESC
