let 
    Table.CreateAmortization = let 
        AmortizationFunction = (initialAmount as number, interestRate as number, numberOfPeriods as number, periodicity as text, optional date as any, optional balloonPayment as number) as table =>
        let
            CompoundingMap = {{"Daily",365}, {"Monthly",12}, {"Quarterly",4}, {"Semi-annual",2}, {"Annual",1}},
            CompoundingPeriod = List.First(List.Select(CompoundingMap, each _{0} = periodicity)){1},
            Balloon = if balloonPayment is null then 0 else balloonPayment,
            PeriodicInterest = interestRate / CompoundingPeriod,
            TotalPeriods = numberOfPeriods * CompoundingPeriod,
            Annuity = initialAmount * ((PeriodicInterest) * Number.Power(1 + (PeriodicInterest), TotalPeriods)) / (Number.Power(1 + (PeriodicInterest), TotalPeriods) - 1) - Balloon * (-PeriodicInterest) / ((1 + PeriodicInterest) - (Number.Power(1 + PeriodicInterest, TotalPeriods + 1))),
            ColumnNames = 
                if date is null then 
                    {"n", "BegBalance", "Interest", "Principal", "Payment", "EndBalance"} 
                else 
                    {"n", "Date", "BegBalance", "Interest", "Principal", "Payment", "EndBalance"},
            AmortTable = 
                if date is null then 
                    type table [n = Int64.Type, BegBalance = number, Interest = number, Principal = number, Payment = number, EndBalance = number]
                else
                    type table [n = Int64.Type, Date = date, BegBalance = number, Interest = number, Principal = number, Payment = number, EndBalance = number],
            Schedule = Table.FromList(
                List.Generate(
                    ()=> 
                        if date is null then 
                            [n = 0, BegBalance = null, Interest = null, Principal = null, Payment = null, EndBalance = initialAmount] 
                        else 
                            [n = 0, Date = date, BegBalance = null, Interest = null, Principal = null, Payment = null, EndBalance = initialAmount],
                    each [n] <= TotalPeriods,
                    each [
                        n = [n] + 1,
                        Date = 
                            if date is null then 
                                null 
                            else 
                                if periodicity = "Daily" then
                                    Date.AddDays(date, n)
                                else if periodicity = "Monthly" then
                                    Date.AddMonths(date, n)
                                else if periodicity = "Quarterly" then
                                    Date.AddQuarters(date, n)
                                else if periodicity = "Semi-annual" then
                                    Date.AddMonths(date, n * 6)
                                else 
                                    Date.AddYears(date, n),
                        BegUPB = initialAmount * (Number.Power(1 + (PeriodicInterest), TotalPeriods) - Number.Power(1 + (PeriodicInterest), [n])) / (Number.Power(1 + (PeriodicInterest), TotalPeriods) - 1),
                        Int = PeriodicInterest * BegBalance,
                        Prin = if Annuity - Interest > BegBalance then BegBalance else Annuity - Interest,
                        Pay = Annuity,
                        EndUPB = BegBalance - Principal,
                        BegBalance = Number.Round(BegUPB, 2),
                        Interest = Number.Round(Int, 2),
                        Principal = Number.Round(Prin, 2),
                        Payment = Number.Round(Pay, 2),
                        EndBalance = Number.Round(EndUPB, 2)
                    ],
                    each 
                        if date is null then 
                            [[n], [BegBalance], [Interest], [Principal], [Payment], [EndBalance]] 
                        else 
                            [[n], [Date], [BegBalance], [Interest], [Principal], [Payment], [EndBalance]]
                ),
                Splitter.SplitByNothing(), {"Amortization"}, null, ExtraValues.Error
            ),
            Result = Table.ExpandRecordColumn(Schedule, "Amortization", ColumnNames, ColumnNames),
            Final = Value.ReplaceType(Result, AmortTable)
        in
            Final,
        ParameterTypes = type function(
            initialAmount as number,
            interestRate as number,
            numberOfPeriods as number,
            periodicity as (
                type text meta [ 
                    Documentation.AllowedValues = {"Daily", "Monthly", "Quarterly", "Semi-annual", "Annual"}
                ]
            ),
            optional date as any,
            optional balloonPayment as number
        ) as table meta        
        [
            Documentation.Name =  " Table.CreateAmortization",
            Documentation.Description = " Create an amortization schedule.",
            Documentation.LongDescription = " Create an amortization schedule from a geometric series of periodic payments, including interest and principal payments.",
            Documentation.Category = " Table.Transform",
            Documentation.Source = " ",
            Documentation.Author = " Tony McGovern: www.emdata.ai",
            Documentation.Examples = {
                [
                    Description =  "Create an amortization schedule with a 1000 initial amount, 5% interest rate, for 5 years, is compounded semi-annually, and starts on January 1, 2018.", 
                    Code = " CreateAmortization(1000, 0.05, 5, ""Semi-annual"", #date(2018,1,1))", 
                    Result = "Table.FromRecords({[n = 0, Date = 1/1/18, BegBalance = null, Interest = null, Principal = null, Payment = null, EndBalance = 1000], [n = 1, Date = 7/1/18, BegBalance = 1000, Interest = 22.77, Principal = 89.26, Payment = 114.26, EndBalance = 910.74], [n = ..., Date = ..., BegBalance = ..., Interest = ..., Principal = ..., Payment = ..., EndBalance = ...], [n = 10, Date = 1/1/23, BegBalance = 111.47, Interest = 2.79, Principal = 111.47, Payment = 114.26, EndBalance = 0])"
                ]
            }
        ] 
    in 
        Value.ReplaceType(AmortizationFunction, ParameterTypes)
in
    Table.CreateAmortization