let Table.GetDummies = 
    (sourceTable as table, columnName as text) as table =>
    let
        distinctTable = 
            let 
                source = Table.Distinct(Table.FromList(Table.Column(sourceTable, columnName), Splitter.SplitByNothing(), null, null, ExtraValues.Error)),
                addIndex = Table.AddIndexColumn(source, "index", 0, 1)
            in
                addIndex,
        origTable = 
            let 
                source = Table.AddKey(Table.FromList(Table.Column(sourceTable, columnName), Splitter.SplitByNothing(), null, null, ExtraValues.Error), {"Column1"}, false),
                addIndex = Table.AddIndexColumn(source, "index", 0, 1)
            in
                addIndex,
        // get unique items
        valuesList = List.Distinct(distinctTable[Column1]),
        // get number of unique items
        numberItems = List.NonNullCount(valuesList),
        AddColumn = (n as number, currentTable as table) =>
            let
                currentValue = valuesList{n},
                currentColumnNames = Table.ColumnNames(currentTable),
                newTable = Table.AddColumn(currentTable, currentValue, each if [index] = n then 1 else 0, Int64.Type),
                nextTable = newTable
            in
                if n < (numberItems - 1) then
                    @AddColumn(n + 1, nextTable)
                else
                    nextTable,
        // Recursively add columns for each distinct list item
        encodedTable = AddColumn(0, distinctTable),
        // Merge results back with original source table
        MergedCategories = Table.NestedJoin(origTable,{"Column1"},encodedTable,{"Column1"},"Output",JoinKind.FullOuter),
        ExpandedCategories = Table.ExpandTableColumn(MergedCategories, "Output", valuesList, valuesList),
        SortedCategories = Table.Sort(ExpandedCategories,{{"index", Order.Ascending}}),
        SelectedValues = Table.SelectColumns(SortedCategories,valuesList)
    in
        SelectedValues,
        
    DefineDocs = [
        Documentation.Name =  " Table.GetDummies",
        Documentation.Description = " Convert categorical variable into dummy/indicator variables after pandas get_dummies method.",
        Documentation.LongDescription = " Convert categorical variable into dummy/indicator variables. The table is the source table for the method. The columnName is the name of the column containing categorical values.",
        Documentation.Category = " Table.Transform",
        Documentation.Source = " After Python pandas package",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Convert categorical variable into dummy/indicator variables.", 
                Code = " GetDummies(Table.FromRecords({[category = ""Germany""],[category = ""United Kingdom""],[category = ""France""],[category = ""Portugal""], ""category"")", 
                Result = "Table.FromRecords({[Germany = 1, United Kingdom = 0, France = 0, Portugal = 0], [Germany = 0, United Kingdom = 1, France = 0, Portugal = 0], [Germany = 0, United Kingdom = 0, France = 1, Portugal = 0], [Germany = 0, United Kingdom = 0, France = 0, Portugal = 1])"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        Table.GetDummies, 
        Value.ReplaceMetadata(
            Value.Type(Table.GetDummies), 
            DefineDocs
        )
    )