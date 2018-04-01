let Table.Imputer = 
    (table as table, columnName as text, strategy as text, optional axis as number) as table =>
	let
		InputTable = Table.AddIndexColumn(table, "index", 0, 1),
		imputeList = 
			let
				list = Table.Column(InputTable,columnName)
			in
				list,
		imputeColumn = 
			let
				table = Table.FromList(imputeList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
				index = Table.AddIndexColumn(table, "index", 0, 1)
			in
				index,
		imputedColumn =
			let
				imputedList = 
					if strategy = "mean" then
						List.Average(imputeColumn[Column1])
					else if strategy = "median" then
						List.Median(imputeColumn[Column1])
					else if strategy = "mode" then
						List.Mode(imputeColumn[Column1])
					else
						"",
				imputedTable = Table.ReplaceValue(imputeColumn,null,imputedList,Replacer.ReplaceValue,{"Column1"})
			in
				imputedTable,
		renamedImputer = 
			let
				table = Table.RenameColumns(imputedColumn,{{"Column1", columnName}})
			in
				table,  
		finalImputer = 
			let
				table = Table.TransformColumnTypes(renamedImputer,{{columnName, type number}})
			in
				table,
		originalTable = 
			let
				table = Table.RemoveColumns(InputTable,{columnName})
			in
				table,
        MergedImputer = Table.NestedJoin(originalTable,{"index"},finalImputer,{"index"},"final",JoinKind.LeftOuter),
        ExpandedImputer = Table.ExpandTableColumn(MergedImputer, "final", {columnName}, {columnName}),
        Final = Table.RemoveColumns(ExpandedImputer,{"index"})
    in
        Final,

    DefineDocs = [
        Documentation.Name =  " Table.Imputer",
        Documentation.Description = " Imputation transformer for completing missing values after scikit-learn's sklearn.preprocessing.Imputer.",
        Documentation.LongDescription = " Imputation transformer for completing missing values. The columnName is the name of the column used for imputation. The strategy defines whether a ""mean"", ""median"", or ""mode"" should be applied to the values in the column. The optional axis value of 0 specifies that the imputation should be performed column-wise.",
        Documentation.Category = " Table.Transform",
        Documentation.Source = " After Python scikit-learn package",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Find the missing values in a column and replace with the computed mean.", 
                Code = " Table.Imputer(Table.FromRecords({[item = ""A"", value = 2],[item = ""B"", value = null],[item = ""C"", value = 3],[item = ""D"", value = 2],[item = ""C"", value = 2],[item = ""B"", value = null]), ""value"", ""mean"", 0)", 
                Result = "Table.FromRecords({[item = ""A"", value = 2],[item = ""B"", value = 2.25],[item = ""C"", value = 3],[item = ""D"", value = 2],[item = ""C"", value = 2],[item = ""B"", value = 2.25])"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        Table.Imputer, 
        Value.ReplaceMetadata(
            Value.Type(Table.Imputer), 
            DefineDocs
        )
    )