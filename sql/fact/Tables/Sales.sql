CREATE TABLE [fact].[Sales] (

	[SalesKey] bigint IDENTITY NOT NULL, 
	[TransactionNumber] varchar(50) NOT NULL, 
	[TransactionDateKey] int NOT NULL, 
	[TransactionHourKey] int NOT NULL, 
	[OrderDateKey] int NOT NULL, 
	[OrderHourKey] int NOT NULL, 
	[DeliveryDateKey] int NOT NULL, 
	[ChannelKey] bigint NOT NULL, 
	[CustomerKey] bigint NOT NULL, 
	[EmployeeKey] bigint NOT NULL, 
	[ProductKey] bigint NOT NULL, 
	[StoreKey] bigint NOT NULL, 
	[PromotionKey] bigint NOT NULL, 
	[Quantity] int NOT NULL, 
	[TaxAmount] decimal(10,2) NOT NULL, 
	[LineAmount] decimal(10,2) NOT NULL, 
	[Linediscountamount] decimal(10,2) NOT NULL, 
	[TransactionID] int NULL
);



GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT PK_Sales primary key NONCLUSTERED ([SalesKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_Customer FOREIGN KEY ([CustomerKey]) REFERENCES [dim].[Customer]([CustomerKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_DeliveryDate FOREIGN KEY ([DeliveryDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_Employee FOREIGN KEY ([EmployeeKey]) REFERENCES [dim].[Employee]([EmployeeKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_OrderDate FOREIGN KEY ([OrderDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_OrderHour FOREIGN KEY ([OrderHourKey]) REFERENCES [dim].[Time]([TimeKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_POSChannel FOREIGN KEY ([ChannelKey]) REFERENCES [dim].[POSChannel]([ChannelKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_Product FOREIGN KEY ([ProductKey]) REFERENCES [dim].[Product]([ProductKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_Promotion FOREIGN KEY ([PromotionKey]) REFERENCES [dim].[Promotion]([PromotionKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_Store FOREIGN KEY ([StoreKey]) REFERENCES [dim].[Store]([StoreKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_TransactionDate FOREIGN KEY ([TransactionDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Sales] ADD CONSTRAINT FK_Sales_TransactionHour FOREIGN KEY ([TransactionHourKey]) REFERENCES [dim].[Time]([TimeKey]);