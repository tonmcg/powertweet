let 
    List.RandomSelections = (sourceList as list, numberSelections as number) as list =>
        let
            list = List.Buffer(sourceList),
            count = List.Count(list),
            Selection = List.Generate(
                () => 1, 
                each _ <= numberSelections, 
                each _ + 1,
                each list{Number.RoundDown(
                    Number.RandomBetween(0, count)
                )}
            )
        in
            Selection,
            
    DefineDocs = [
        Documentation.Name =  " List.RandomSelections",
        Documentation.Description = " Randomly select values from a list an n-number of times.",
        Documentation.LongDescription = " Randomly select values from a list an n-number of times. The sourceList provides a list of values, either numerical or character. The numberSelections defines the total number of random selections in the output list.",
        Documentation.Category = " List.Transform",
        Documentation.Source = " ",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Randomly select values from a list of countries that results in an output list of 1,000,000 items.", 
                Code = " RandomSelections({""Portugal"", ""United Kingdom"", ""Germany"", ""New Zealand"", ""Australia"", ""Belgium"", ""France""}, 1000000)", 
                Result = "{""United Kingdom"", ""Zealand"", ""Australia"", ..., ""New Zealand""}"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        List.RandomSelections, 
        Value.ReplaceMetadata(
            Value.Type(List.RandomSelections), 
            DefineDocs
        )
    )