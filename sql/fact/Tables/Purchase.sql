CREATE TABLE [fact].[Purchase] (

	[PurchaseKey] bigint IDENTITY NOT NULL, 
	[TransactionNumber] varchar(50) NOT NULL, 
	[TransactionDateKey] int NOT NULL, 
	[OrderDateKey] int NOT NULL, 
	[DeliveryDateKey] int NOT NULL, 
	[ShipDateKey] int NOT NULL, 
	[VendorKey] bigint NOT NULL, 
	[EmployeeKey] bigint NOT NULL, 
	[ProductKey] bigint NOT NULL, 
	[StoreKey] bigint NOT NULL, 
	[Quantity] int NOT NULL, 
	[TaxAmount] decimal(10,2) NOT NULL, 
	[LineAmount] decimal(10,2) NOT NULL, 
	[TransactionID] int NULL
);



GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT PK_Purchase primary key NONCLUSTERED ([PurchaseKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_DeliveryDate FOREIGN KEY ([DeliveryDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_Employee FOREIGN KEY ([EmployeeKey]) REFERENCES [dim].[Employee]([EmployeeKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_OrderDate FOREIGN KEY ([OrderDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_Product FOREIGN KEY ([ProductKey]) REFERENCES [dim].[Product]([ProductKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_ShipDate FOREIGN KEY ([ShipDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_Store FOREIGN KEY ([StoreKey]) REFERENCES [dim].[Store]([StoreKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_TransactionDate FOREIGN KEY ([TransactionDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Purchase] ADD CONSTRAINT FK_Purchase_Vendor FOREIGN KEY ([VendorKey]) REFERENCES [dim].[Vendor]([VendorKey]);