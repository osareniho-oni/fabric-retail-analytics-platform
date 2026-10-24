CREATE TABLE [dim].[Vendor] (

	[VendorKey] bigint IDENTITY NOT NULL, 
	[VendorID] int NOT NULL, 
	[VendorNumber] varchar(50) NOT NULL, 
	[VendorName] varchar(100) NOT NULL, 
	[RegistrationNumber] varchar(50) NOT NULL, 
	[VendorAddress] varchar(255) NOT NULL, 
	[City] varchar(50) NOT NULL, 
	[State] varchar(50) NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL
);



GO

ALTER TABLE [dim].[Vendor] ADD CONSTRAINT PK_Vendor primary key NONCLUSTERED ([VendorKey]);