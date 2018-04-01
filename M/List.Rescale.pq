let
    list = {-500.5,100.1,0,00.1,900.9},
    min = List.Min(list),
    max = List.Max(list),
    Rescale = List.Generate(
        ()=> [n = 0],
        each [n] < List.Count(list),
        each [n = [n] + 1],
        each (list{[n]} - min) / (max - min)
    )
in
    Rescale