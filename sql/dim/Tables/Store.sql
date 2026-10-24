CREATE TABLE [dim].[Store] (

	[StoreKey] bigint IDENTITY NOT NULL, 
	[StoreID] int NOT NULL, 
	[StoreName] varchar(100) NOT NULL, 
	[StreetAddress] varchar(255) NOT NULL, 
	[City] varchar(50) NOT NULL, 
	[State] varchar(50) NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL
);



GO

ALTER TABLE [dim].[Store] ADD CONSTRAINT PK_Store primary key NONCLUSTERED ([StoreKey]);