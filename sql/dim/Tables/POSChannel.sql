CREATE TABLE [dim].[POSChannel] (

	[ChannelKey] bigint IDENTITY NOT NULL, 
	[ChannelID] int NOT NULL, 
	[ChannelNumber] varchar(50) NOT NULL, 
	[DeviceModel] varchar(100) NOT NULL, 
	[SerialNumber] varchar(100) NOT NULL, 
	[InstallationDate] date NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL
);



GO

ALTER TABLE [dim].[POSChannel] ADD CONSTRAINT PK_POSChannel primary key NONCLUSTERED ([ChannelKey]);