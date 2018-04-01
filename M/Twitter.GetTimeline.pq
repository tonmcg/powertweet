let
    Twitter.GetTimeline = (
        screen_name as text, 
        optional n as number,
        optional since_id as text,
        optional max_id as text,
        optional trim_user as logical,
        optional exclude_replies as logical,
        optional include_rts as logical) as any =>
        let
            trim_user = if trim_user is null then true else false,
            exclude_replies = if exclude_replies is null then true else false,
            include_rts = if include_rts is null then "1" else true,
            max_tweets = 200, // endpoint allows for up to 200 items to be returned per request
            count = if n is null then max_tweets else n, 
			max_requests = 1500, // Twitter-provided max for app authorized calls
            number_requests = if count > max_tweets * max_requests then max_requests else Number.RoundUp(count/max_tweets,0), // 300,000 is the maximum number of items that can be returned in a 15-minute period
            baseUri = "https://api.twitter.com",
            relativeUri = "1.1/statuses/user_timeline.json",
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
			tableType = type table [created_at = text,id = number,id_str = text,text = text,truncated = logical,source = text,in_reply_to_status_id = number,in_reply_to_status_id_str = text,in_reply_to_user_id = number,in_reply_to_user_id_str = text,in_reply_to_screen_name = text,geo = any,coordinates = any,place = any,contributors = any,is_quote_status = logical,retweet_count = number,favorite_count = number,favorited = logical,retweeted = logical,possibly_sensitive = logical,lang = text,quoted_status_id = number,quoted_status_id_str = number,quoted_status = any],
            //tableType = type table [statuses.created_at = text,statuses.id = number,statuses.id_str = text,statuses.text = text,statuses.truncated = logical,statuses.metadata.iso_language_code = text,statuses.metadata.result_type = text,statuses.source = text,statuses.in_reply_to_status_id = number,statuses.in_reply_to_status_id_str = text,statuses.in_reply_to_user_id = number,statuses.in_reply_to_user_id_str = text,statuses.in_reply_to_screen_name = text,statuses.user.id = number,statuses.user.id_str = text,statuses.user.name = text,statuses.user.screen_name = text,statuses.user.location = text,statuses.user.description = text,statuses.user.url = text,statuses.user.protected = logical,statuses.user.followers_count = number,statuses.user.friends_count = number,statuses.user.listed_count = number,statuses.user.created_at = text,statuses.user.favourites_count = number,statuses.user.utc_offset = number,statuses.user.time_zone = text,statuses.user.geo_enabled = logical,statuses.user.verified = logical,statuses.user.statuses_count = number,statuses.user.lang = text,statuses.user.contributors_enabled = logical,statuses.user.is_translator = logical,statuses.user.is_translation_enabled = logical,statuses.user.profile_background_color = text,statuses.user.profile_background_image_url = text,statuses.user.profile_background_image_url_https = text,statuses.user.profile_background_tile = logical,statuses.user.profile_image_url = text,statuses.user.profile_image_url_https = text,statuses.user.profile_banner_url = text,statuses.user.profile_link_color = text,statuses.user.profile_sidebar_border_color = text,statuses.user.profile_sidebar_fill_color = text,statuses.user.profile_text_color = text,statuses.user.profile_use_background_image = logical,statuses.user.has_extended_profile = logical,statuses.user.default_profile = logical,statuses.user.default_profile_image = logical,statuses.user.following = any,statuses.user.follow_request_sent = any,statuses.user.notifications = any,statuses.user.translator_type = text,statuses.geo = any,statuses.coordinates = any,statuses.place = any,statuses.contributors = any,statuses.is_quote_status = logical,statuses.retweet_count = number,statuses.favorite_count = number,statuses.favorited = logical,statuses.retweeted = logical,statuses.lang = text,statuses.possibly_sensitive = logical,statuses.quoted_status_id = number,statuses.quoted_status_id_str = text], 
            searchRecords = Table.FromList(
                List.Generate(
                    ()=> 
                        [
                            // first request to a Twitter timeline endpoint should not specify a max_id or since_id
                            n = 0, // counter
                            remaining = if (n + 1) < number_requests then if (n + 2) * max_tweets > count then count - ((n + 1) * max_tweets) else max_tweets else 0, // count the remaining number of items for the next call; if greater than 200 then 200 else remaining
                            query = [screen_name = screen_name, count = Number.ToText(remaining),include_rts = include_rts], // don't include since_id or max_id in the initial call
                            // response payload
                            response = try Json.Document(GetResponse(query)) otherwise null // type  record
                        ], // initial
                    each [n] < number_requests, // condition
                    //each [next_results] <> null, // condition
                    each 
                        [
                            // subsequent requests should specify a max_id or since_id and adjust the remaining count items
                            n = [n] + 1,
                            query = Record.AddField( Record.RemoveFields( [query], "count"), "count", Number.ToText(remaining)), //type record
							// response payload
                            response = try Json.Document(GetResponse([query])) otherwise null, // type  record
                            remaining = if (n + 1) < number_requests then if (n + 2) * max_tweets > count then count - ((n + 1) * max_tweets) else max_tweets else 0 // count the remaining number of items for the next call; if greater than 200 then 200 else remaining
                        ], // next
                    each [[remaining],[query],[response]] // selector
                ),
                Splitter.SplitByNothing(), {"search"}, null, ExtraValues.Error
            ),
			expandedSearch = Table.ExpandRecordColumn(searchRecords, "search", {"response"}, {"response"}),
			expandedResponseList = Table.ExpandListColumn(expandedSearch, "response"),
			expandedResponse = Table.ExpandRecordColumn(expandedResponseList, "response", {"created_at", "id", "id_str", "text", "truncated", "source", "in_reply_to_status_id", "in_reply_to_status_id_str", "in_reply_to_user_id", "in_reply_to_user_id_str", "in_reply_to_screen_name", "geo", "coordinates", "place", "contributors", "is_quote_status", "retweet_count", "favorite_count", "favorited", "retweeted", "possibly_sensitive", "lang", "quoted_status_id", "quoted_status_id_str", "quoted_status"}, {"created_at", "id", "id_str", "text", "truncated", "source", "in_reply_to_status_id", "in_reply_to_status_id_str", "in_reply_to_user_id", "in_reply_to_user_id_str", "in_reply_to_screen_name", "geo", "coordinates", "place", "contributors", "is_quote_status", "retweet_count", "favorite_count", "favorited", "retweeted", "possibly_sensitive", "lang", "quoted_status_id", "quoted_status_id_str", "quoted_status"}),
            Final = Value.ReplaceType(expandedResponse,tableType)
        in
            Final
in
    Twitter.GetTimeline