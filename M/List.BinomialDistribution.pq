let
    Bernoulli = (n as number, p as number) =>
    let
        q = 1 - p,
        tableType = type table [x = number],
        binomial = Table.FromList(
            List.Generate(
                ()=>
                    [
                        x = 0,
                        y = Number.Factorial(n) / (Number.Factorial(x) * (Number.Factorial(n - x))) * Number.Power(p,x) * Number.Power(q,n - x)
                    ],
                each [x] <= n,
                each 
                    [
                        x = [x] + 1,
                        y = Number.Factorial(n) / (Number.Factorial(x) * (Number.Factorial(n - x))) * Number.Power(p,x) * Number.Power(q,n - x)                
                    ],
                each [[x],[y]]
            ),
            Splitter.SplitByNothing(), {"distribution"}, null, ExtraValues.Error
        ),
        expandedDistribution = Table.ExpandRecordColumn(binomial, "distribution", {"y"}, {"y"}),
        final = Value.ReplaceType(expandedDistribution,tableType)
    in
        final 
in
    Bernoulli