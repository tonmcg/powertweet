let 
    Html.GetTables = (url as text) =>
    let
        DOM = Text.FromBinary(Web.Contents(url)),
        DOCTYPE = "<!" & Text.BetweenDelimiters(DOM, "<!", ">") & ">",
        HTMLOpeningTag = "<html" & Text.BetweenDelimiters(DOM, "<html", ">") & ">",
        HEAD = "<head" & Text.BetweenDelimiters(DOM, "<head", "</head>") & "</head>",
        BODYOpeningTag = "<body>",
        ScrapeTables = (n as number) =>
			let
				CurrentTable = Text.BetweenDelimiters(DOM, "<table", "</table>", n)
			in
				if CurrentTable = "" then 
					""
				else
					Text.Combine({ "<table", CurrentTable, "</table>", @ScrapeTables(n+1) }),
        TableText = ScrapeTables(0),
        HTML = Text.Combine({DOCTYPE, HTMLOpeningTag, HEAD, BODYOpeningTag, TableText, "</body></html>"}),
        Page = Web.Page(HTML),
        Tables = Table.SelectRows(Page, each ([Source] = "Table"))
    in
        Tables,

    DefineDocs = [
        Documentation.Name =  " Html.GetTables",
        Documentation.Description = " Returns the contents of all table nodes within the HTML document broken into its constituent structures",
        Documentation.LongDescription = " Returns the contents of all table nodes within the HTML document broken into its constituent structures of a user-supplied URL.",
        Documentation.Category = " Html.Modification",
        Documentation.Source = " Inspired by solutions after Imke Feldmann",
        Documentation.Author = " Tony McGovern: www.emdata.ai",
        Documentation.Examples = {
            [
                Description =  "", 
                Code = " GetTables(""https://www.census.gov/geo/reference/ansi_statetables.html"")", 
                Result = ""
            ]
        }
    ] 
in 
    Value.ReplaceType(
        Html.GetTables, 
        Value.ReplaceMetadata(
            Value.Type(Html.GetTables), 
            DefineDocs
        )
    )