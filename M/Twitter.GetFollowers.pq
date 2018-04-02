let
    Twitter.GetFollowers = (screen_name as text, number as number, optional cursor as text) as any =>
        let
            initial_cursor = if cursor is null then "-1" else cursor,
            max_tweets = 5000, // endpoint allows for up to 5000 items to be returned per request
            count = if number is null then max_tweets else number,
            max_requests = 15, // Twitter-provided max for app authorized calls
            number_requests = if count > max_tweets * max_requests then max_requests else Number.RoundUp(count / max_requests), // 75,000 is the maximum number of items that can be returned in a 15-minute period
            baseUri = "https://api.twitter.com",
            relativeUri = "1.1/followers/ids.json",
            fullUri = Uri.Combine(baseUri,relativeUri),
            token = GetOAuthToken(consumer_key, consumer_secret),
            GetResponse = let 
                responseCall = (query as record) =>
                    let
                        call = Web.Contents(
                            baseUri,
                            [
                                Headers = 
                                [
                                    #"Authorization" = token
                                ],
                                RelativePath = relativeUri,
                                Query = query
                            ]
                        )
                    in
                        call
            in
                responseCall,
            tableType = type table [id = text], 
            followerRecords = Table.FromList(
                List.Generate(
                    ()=> 
                        [
                            n = 0,
                            query = [screen_name = screen_name,cursor = initial_cursor,stringify_ids = "true",count = Number.ToText(count)],
                            response = Json.Document(GetResponse(query)),
                            ids = response[ids],
                            prev_cursor = initial_cursor,
                            next_cursor = response[next_cursor_str]
                        ], // initial
                    each [prev_cursor] <> "0", // condition
                    each 
                        [
                            n = [n] + 1,
                            query = [screen_name = screen_name,cursor = [next_cursor],stringify_ids = "true",count = Number.ToText(count)],
                            response = Json.Document(GetResponse(query)),
                            ids = response[ids],
                            prev_cursor = if n = max_requests then "0" else response[previous_cursor_str],
                            next_cursor = response[next_cursor_str]
                        ], // next
                    each [[ids], [n], [prev_cursor], [next_cursor]] // selector
                ),
                Splitter.SplitByNothing(), {"Followers"}, null, ExtraValues.Error
            ),
            followerLists = Table.ExpandRecordColumn(followerRecords, "Followers", {"ids"}, {"id"}),
            followersTable = Table.ExpandListColumn(followerLists, "id"),
            followersFinal = Value.ReplaceType(followersTable,tableType)
        in
            followersFinal
in
    Twitter.GetFollowers