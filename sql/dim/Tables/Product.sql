CREATE TABLE [dim].[Product] (

	[ProductKey] bigint IDENTITY NOT NULL, 
	[ProductID] int NOT NULL, 
	[ProductName] varchar(50) NOT NULL, 
	[ProductNumber] varchar(50) NOT NULL, 
	[Department] varchar(50) NOT NULL, 
	[UnitPrice] decimal(10,2) NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL, 
	[IsRebranded] bit NULL
);



GO

ALTER TABLE [dim].[Product] ADD CONSTRAINT PK_Product primary key NONCLUSTERED ([ProductKey]);