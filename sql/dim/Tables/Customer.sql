CREATE TABLE [dim].[Customer] (

	[CustomerKey] bigint IDENTITY NOT NULL, 
	[CustomerID] int NOT NULL, 
	[CustomerName] varchar(50) NOT NULL, 
	[CustomerAddress] varchar(100) NOT NULL, 
	[City] varchar(50) NOT NULL, 
	[State] varchar(50) NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL
);



GO

ALTER TABLE [dim].[Customer] ADD CONSTRAINT PK_Customer primary key NONCLUSTERED ([CustomerKey]);