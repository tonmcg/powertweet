let 
    List.MinMaxScaler = (initialList as list, optional outputRange as list) as list =>
        let
            featureRange = if outputRange is null then {0,1} else outputRange,
            list = List.Buffer(initialList),
            count = List.Count(list),
            min = List.Min(list),
            max = List.Max(list),
            a = featureRange{0},
            b = featureRange{1},
            Scaler = List.Generate(
                ()=> [n = 0],
                each [n] < count,
                each [n = [n] + 1],
                each (b - a) * ((list{[n]} - min) / (max - min)) + a
            )
        in
            Scaler,
    DefineDocs = [
        Documentation.Name =  " List.MinMaxScaler",
        Documentation.Description = " Rescale list values between 0 and 1 (default) after Python scikit-learn 'preprocessing.MinMaxScaler' method.",
        Documentation.LongDescription = " Rescale list values between 0 and 1 (default). The initialList is the source list for the method. The optional outputRange allows for alternate scaling ranges.",
        Documentation.Category = " List.Transform",
        Documentation.Source = " After Python scikit-learn package",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Rescale list values between -1 and 1.", 
                Code = " MinMaxScaler({1,2,3,4,5,6,7,8,9}, {-1,1})", 
                Result = "{-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1}"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        List.MinMaxScaler, 
        Value.ReplaceMetadata(
            Value.Type(List.MinMaxScaler), 
            DefineDocs
        )
    )