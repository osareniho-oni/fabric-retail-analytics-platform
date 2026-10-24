CREATE TABLE [fact].[POSDeviceChange] (

	[POSDeviceChangeKey] bigint IDENTITY NOT NULL, 
	[DateKey] int NOT NULL, 
	[ChannelKey] bigint NOT NULL, 
	[ChangeType] varchar(50) NOT NULL, 
	[OldSerialNumber] varchar(255) NULL, 
	[NewSerialNumber] varchar(255) NULL
);



GO

ALTER TABLE [fact].[POSDeviceChange] ADD CONSTRAINT PK_POSDeviceChange primary key NONCLUSTERED ([POSDeviceChangeKey]);

GO

ALTER TABLE [fact].[POSDeviceChange] ADD CONSTRAINT FK_POSDeviceChange_POSChannel FOREIGN KEY ([ChannelKey]) REFERENCES [dim].[POSChannel]([ChannelKey]);