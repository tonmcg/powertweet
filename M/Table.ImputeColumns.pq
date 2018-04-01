let
    Source = let func =  
		(Table as table, Operation as text, optional ColumnName, optional ReplaceColumnName, optional horizontal) =>
			let
				Columns = List.Buffer(Table.ColumnNames(Table)),
				FunctionRecord = [Average=List.Average, Median=List.Median, Mode=List.Mode, First=List.First, Last=List.Last, Min=List.Min, Max=List.Max, Sum=List.Sum, Product=List.Sum],
				AggregationFunction = Record.Field(FunctionRecord, Operation),
				ReplacerFunction =  (RTable as table, RColumnName) =>
					Table.ReplaceValue(RTable,
					null,
					//Expression.Evaluate("List."&Operation&"(List.Select(Table.Column(RTable, RColumnName), each _<> null))", #shared&[RTable=RTable, RColumnName=RColumnName, Operation=Operation]),
					AggregationFunction(List.Select(Table.Column(RTable, RColumnName), each _<> null)),
					Replacer.ReplaceValue,
				{RColumnName}),

ResultStandard = if ColumnName = null then List.Accumulate(Columns, Table, (state, current) => ReplacerFunction(state,current))
                              else if ReplaceColumnName = null then ReplacerFunction(Table, ColumnName)
                                   else Table.ReplaceValue(Table, null, each Record.Field(_,ReplaceColumnName), Replacer.ReplaceValue, {ColumnName}),

//Adding logic for horizontal replacements
AddColumnH = Table.AddColumn(Table, "RowAggregation", each AggregationFunction(List.Select(Record.FieldValues(_), (x) => x<>null))),
ReplaceH = Table.ReplaceValue(AddColumnH,null,each [RowAggregation], Replacer.ReplaceValue, Table.ColumnNames(Table)),
ResultHorizontal = Table.RemoveColumns(ReplaceH, {"RowAggregation"}),

Result = if horizontal = null then ResultStandard else ResultHorizontal

in
Result,
fnType = type function
	(Table as table,
	Operation as (type text meta [ Documentation.AllowedValues = {"Average", "Median", "Mode", "First", "Last", "Min", "Max", "Sum", "Product"}]),
        optional ColumnName as any,
        optional ReplaceColumnName as any,
        optional horizontal as any
	) as table meta
	[
		Documentation.Name =  " Table.ImputerColumn.pq
		", Documentation.Description = " Replaces null values in a column with an aggregation of its existing values. Options: Replace nulls in all columns (leave the 3rd param. blank), replace with a figure from a different column (columns names goes into 4th param.), take row-aggregation instead/horizontal (use 1 in 5th param.).
		" , Documentation.LongDescription = " Replaces null values in a column with an aggregation of its existing values. Options: Replace nulls in all columns (leave the 3rd param. blank), replace with a figure from a different column (columns names goes into 4th param.), take row-aggregation instead/horizontal (use 1 in 5th param.)..
		", Documentation.Category = " Table Transformation
		", Documentation.Source = " Inspired by Tony McGovern: https://gist.github.com/tonmcg/bfe788104176fbd27aa171783ddc476b .
		", Documentation.Author = " Imke Feldmann: www.TheBIccountant.com .
		", Documentation.Examples = {[Description =  "Find the missing values in a column and replace with the computed max.", 
                Code = " Table.ImputerColumn.pq(Table.FromRecords({[item = ""A"", value = 2],[item = ""B"", value = null],[item = ""C"", value = 3],[item = ""D"", value = 2],[item = ""C"", value = 2],[item = ""B"", value = null]}), ""value"", ""Max"")", 
                Result = "Table.FromRecords({[item = ""A"", value = 2],[item = ""B"", value = 3],[item = ""C"", value = 3],[item = ""D"", value = 2],[item = ""C"", value = 2],[item = ""B"", value = 3])"
]}] 
 in 
  Value.ReplaceType(func, fnType)
in
    Source