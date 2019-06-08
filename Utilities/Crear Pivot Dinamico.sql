DECLARE @Years VARCHAR(500)

SELECT @Years = ISNULL(@Years+',','')+'['+CAST(OrderYear AS VARCHAR)+']'

FROM (SELECT DISTINCT OrderYear FROM uvVentasPorCateg) C

SELECT @Years

DECLARE @sqlQuery NVARCHAR(MAX)

SET @sqlQuery = '

SELECT categoryname,'+@Years+'

FROM (SELECT categoryname,OrderYear,Total FROM uvVentasPorCateg) C

PIVOT(SUM(Total) FOR OrderYear IN ('+@Years+')) p'

EXEC sp_executesql @sqlQuery