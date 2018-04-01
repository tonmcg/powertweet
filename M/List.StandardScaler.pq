let 
    List.StandardScaler = (initialList as list) as list =>
        let
            list = List.Buffer(initialList),
            count = List.Count(list),
            sd = List.StandardDeviation(list),
            m = List.Average(list),
            Scaler = List.Generate(
                ()=> [n = 0],
                each [n] < count,
                each [n = [n] + 1],
                each (list{[n]} - m) / sd
            )
        in
            Scaler,
    DefineDocs = [
        Documentation.Name =  " List.StandardScaler",
        Documentation.Description = " Rescale list values to have a mean of 0 and a standard deviation of 1 after Python scikit-learn 'preprocessing.StandardScaler' method.",
        Documentation.LongDescription = " Rescale list values to have a mean of 0 and a standard deviation of 1. The initialList is the source list for the method.",
        Documentation.Category = " List.Transform",
        Documentation.Source = " After Python scikit-learn package",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "Rescale list values to have a mean of 0 and a standard deviation of 1", 
                Code = " StandardScaler({1,2,3,4,5,6,7,8,9})", 
                Result = "{-1.460593487,-1.095445115,-0.730296743,-0.365148372,0,0.365148372,0.730296743,1.095445115,1.460593487}"
            ]
        }
    ] 
in 
    Value.ReplaceType(
        List.StandardScaler, 
        Value.ReplaceMetadata(
            Value.Type(List.StandardScaler), 
            DefineDocs
        )
    )