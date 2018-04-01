let 
    List.RandomSelection = (sourceList as list) as text =>
        let
            Selection = sourceList{Number.RoundDown(Number.RandomBetween(0, List.Count(sourceList)))}
        in
            Selection,

    DefineDocs = [
        Documentation.Name =  " List.RandomSelection",
        Documentation.Description = " Randomly select a value from a list.",
        Documentation.LongDescription = " Randomly select a value from a list. The sourceList provides a list of values, either numerical or character.",
        Documentation.Category = " List.Transform",
        Documentation.Source = " ",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Randomly select a value from a list of countries.", 
                Code = " RandomSelection({""Portugal"", ""United Kingdom"", ""Germany"", ""New Zealand"", ""Australia"", ""Belgium"", ""France""}", 
                Result = "Germany"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        List.RandomSelection, 
        Value.ReplaceMetadata(
            Value.Type(List.RandomSelection), 
            DefineDocs
        )
    )