CREATE TABLE [dim].[Promotion] (

	[PromotionKey] bigint IDENTITY NOT NULL, 
	[PromotionID] int NOT NULL, 
	[PromotionName] varchar(50) NOT NULL, 
	[StartDate] date NOT NULL, 
	[EndDate] date NOT NULL, 
	[DiscountPercent] decimal(5,2) NOT NULL
);



GO

ALTER TABLE [dim].[Promotion] ADD CONSTRAINT PK_Promotion primary key NONCLUSTERED ([PromotionKey]);