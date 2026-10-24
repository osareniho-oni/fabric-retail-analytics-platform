[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Append"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared DefaultDestination = Fabric.Warehouse([CreateNavigationProperties = false]){[workspaceId = "9a956fbf-7953-54e6-8798-f4f4de1ae6f8"]}[Data]{[warehouseId = "3b98741a-ab49-5348-82ea-4a28aba16d13"]}[Data];
[BindToDefaultDestination = true]
shared Date = let
  // Define the start date
  StartDate = #date(2014, 1, 1),
  // Dynamically get the current year's end date
  CurrentYear = Date.Year(DateTime.LocalNow()),
  EndDate = #date(CurrentYear, 12, 31),
  // Calculate the total number of days between start and end dates
  Duration = Duration.Days(EndDate - StartDate) + 1,
  // Genegarte the list of dates
  DateList = List.Dates(StartDate, Duration, #duration(1, 0, 0, 0)),
  // Convert the list into a table
  #"Converted to Table" = Table.FromList(DateList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  // Rename the column and change its datatype to date
  #"Renamed Columns" = Table.RenameColumns(#"Converted to Table", {{"Column1", "FullDate"}}),
  #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns", {{"FullDate", type date}}),
  #"Inserted year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([FullDate]), type nullable number),
  #"Changed column type" = Table.TransformColumnTypes(#"Inserted year", {{"Year", Int64.Type}}),
  #"Inserted quarter" = Table.AddColumn(#"Changed column type", "Quarter", each Date.QuarterOfYear([FullDate]), type nullable number),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Inserted quarter", {{"Quarter", Int64.Type}}),
  #"Inserted month" = Table.AddColumn(#"Changed column type 1", "Month", each Date.Month([FullDate]), type nullable number),
  #"Changed column type 2" = Table.TransformColumnTypes(#"Inserted month", {{"Month", Int64.Type}}),
  #"Inserted month name" = Table.AddColumn(#"Changed column type 2", "Month name", each Date.MonthName([FullDate]), type nullable text),
  #"Inserted day" = Table.AddColumn(#"Inserted month name", "Day", each Date.Day([FullDate]), type nullable number),
  #"Changed column type 3" = Table.TransformColumnTypes(#"Inserted day", {{"Day", Int64.Type}}),
  #"Inserted day of week" = Table.AddColumn(#"Changed column type 3", "Day of week", each Date.DayOfWeek([FullDate]), type nullable number),
  #"Changed column type 4" = Table.TransformColumnTypes(#"Inserted day of week", {{"Day of week", Int64.Type}}),
  #"Inserted day name" = Table.AddColumn(#"Changed column type 4", "Day name", each Date.DayOfWeekName([FullDate]), type nullable text),
  #"Inserted Merged Column" = Table.AddColumn(#"Inserted day name", "QuarterName", each Text.Combine({"Q", Text.From([Quarter], "en-US")}), type text),
  #"Added custom" = Table.AddColumn(#"Inserted Merged Column", "YearQuarter", each Text.From([Year]) & "-" & Text.From([QuarterName]),
    type text),
  #"Added custom 1" = Table.AddColumn(
    #"Added custom",
    "DayType",
    each if List.Contains({0,6}, Date.DayOfWeek([FullDate]))
        then "Weekend"
        else "Weekday",
    type text
),
  #"Renamed columns 1" = Table.RenameColumns(#"Added custom 1", {{"Month name", "MonthName"}, {"Day of week", "DayOfWeek"}, {"Day name", "DayName"}}),
  #"Added custom 2" = Table.AddColumn(
    #"Renamed columns 1",
    "DateKey",
    each Date.Year([FullDate]) * 10000 +
         Date.Month([FullDate]) * 100 +
         Date.Day([FullDate]),
    Int64.Type
)
,
  #"Reordered columns" = Table.ReorderColumns(#"Added custom 2", {"DateKey", "FullDate", "Year", "Quarter", "Month", "MonthName", "Day", "DayOfWeek", "DayName", "QuarterName", "YearQuarter", "DayType"})

in
  #"Reordered columns";
