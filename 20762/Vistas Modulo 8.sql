-- WITH ENCRYPTION

CREATE VIEW Purchasing.PurchaseOrderReject  
WITH ENCRYPTION  
AS  
SELECT PurchaseOrderID, ReceivedQty, RejectedQty,   
    RejectedQty / ReceivedQty AS RejectRatio, DueDate  
FROM Purchasing.PurchaseOrderDetail  
WHERE RejectedQty / ReceivedQty > 0  
AND DueDate > CONVERT(DATETIME,'20010630',101) ;  
GO  

-- DMV Para ver Referencias y Metadata de Vistas

	USE AdventureWorks2016;
	GO
	SELECT referenced_schema_name, referenced_entity_name, referenced_minor_name, 
	    referenced_class_desc, is_caller_dependent
	FROM sys.dm_sql_referenced_entities ('sales.vSalesPersonSalesByFiscalYears', 'OBJECT');
GO
	USE AdventureWorks2016;
	GO
	EXEC sp_helptext 'sales.vSalesPersonSalesByFiscalYears';
GO
	USE AdventureWorks2016;
	GO
	SELECT OBJECT_DEFINITION (OBJECT_ID(N'sales.vSalesPersonSalesByFiscalYears')) AS [View Definition]; 
GO