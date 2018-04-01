let
    Twitter.SearchTweets = (
        q as text, 
        optional n as number,
        optional result_type as text,
        optional geocode as text,
        optional lang as text,
        optional locale as text,
        optional until as text,
        optional since_id as text,
        optional max_id as text,
        optional include_entities as logical) as any =>
        let
            q = Uri.EscapeDataString(q),
            count = if n is null then 100 else n, // endpoint allows for up to 100 items to be returned per request
            max_requests = 450, // Twitter-provided max for app authorized calls
            number_requests = if count > 45000 then max_requests else Number.RoundUp(count/100,0), // 45,000 is the maximum number of items that can be returned in a 15-minute period
            result_type = if result_type is null then "recent" else result_type,
            baseUri = "https://api.twitter.com",
            relativeUri = "1.1/search/tweets.json",
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
            tableType = type table [statuses.created_at = text,statuses.id = number,statuses.id_str = text,statuses.text = text,statuses.truncated = logical,statuses.metadata.iso_language_code = text,statuses.metadata.result_type = text,statuses.source = text,statuses.in_reply_to_status_id = number,statuses.in_reply_to_status_id_str = text,statuses.in_reply_to_user_id = number,statuses.in_reply_to_user_id_str = text,statuses.in_reply_to_screen_name = text,statuses.user.id = number,statuses.user.id_str = text,statuses.user.name = text,statuses.user.screen_name = text,statuses.user.location = text,statuses.user.description = text,statuses.user.url = text,statuses.user.protected = logical,statuses.user.followers_count = number,statuses.user.friends_count = number,statuses.user.listed_count = number,statuses.user.created_at = text,statuses.user.favourites_count = number,statuses.user.utc_offset = number,statuses.user.time_zone = text,statuses.user.geo_enabled = logical,statuses.user.verified = logical,statuses.user.statuses_count = number,statuses.user.lang = text,statuses.user.contributors_enabled = logical,statuses.user.is_translator = logical,statuses.user.is_translation_enabled = logical,statuses.user.profile_background_color = text,statuses.user.profile_background_image_url = text,statuses.user.profile_background_image_url_https = text,statuses.user.profile_background_tile = logical,statuses.user.profile_image_url = text,statuses.user.profile_image_url_https = text,statuses.user.profile_banner_url = text,statuses.user.profile_link_color = text,statuses.user.profile_sidebar_border_color = text,statuses.user.profile_sidebar_fill_color = text,statuses.user.profile_text_color = text,statuses.user.profile_use_background_image = logical,statuses.user.has_extended_profile = logical,statuses.user.default_profile = logical,statuses.user.default_profile_image = logical,statuses.user.following = any,statuses.user.follow_request_sent = any,statuses.user.notifications = any,statuses.user.translator_type = text,statuses.geo = any,statuses.coordinates = any,statuses.place = any,statuses.contributors = any,statuses.is_quote_status = logical,statuses.retweet_count = number,statuses.favorite_count = number,statuses.favorited = logical,statuses.retweeted = logical,statuses.lang = text,statuses.possibly_sensitive = logical,statuses.quoted_status_id = number,statuses.quoted_status_id_str = text], 
            searchRecords = Table.FromList(
                List.Generate(
                    ()=> 
                        [
                            // first request to a Twitter timeline endpoint should not specify a max_id or since_id
                            n = 0, // counter
                            count = count,
                            remaining = if (n + 2) * 100 > count then count - ((n + 1) * 100) else 100, // count the remaining number of items for the next call; if greater than 100 then 100 else remaining
                            query = [q = q, count = Number.ToText(count), result_type = result_type], // specify query, count, and result_type as the only parameters
                            // response payload
                            response = try Json.Document(GetResponse(query)) otherwise null, // type  record
                            search_metadata = response[search_metadata], // record
                            next_results = try search_metadata[next_results] otherwise null,
                            next_query = Record.AddField( Record.RemoveFields( Uri.Parts(Text.Combine({fullUri,next_results},""))[Query], "count"), "count", Number.ToText(remaining)) //type record
/*                          Uncomment for debugging and testing   
                            statuses = response[statuses], // list
                            completed_in = search_metadata[completed_in], // type number
                            max_id = search_metadata[max_id], // type number
                            max_id_str = search_metadata[max_id_str],
                            refresh_url = search_metadata[refresh_url],
                            since_id = search_metadata[since_id], // type number
                            since_id_str = search_metadata[since_id_str] */
                        ], // initial
                    each [n] < number_requests, // condition
                    //each [next_results] <> null, // condition
                    each 
                        [
                            // subsequent requests should specify a max_id or since_id and adjust the remaining count items
                            n = [n] + 1,
                            count = count,
                            remaining = if (n + 2) * 100 > count then count - ((n + 1) * 100) else 100, // count the remaining number of items for the next call; if greater than 100 then 100 else remaining
                            // response payload
                            response = try Json.Document(GetResponse([next_query])) otherwise null, // type  record
                            search_metadata = response[search_metadata], // record
                            next_results = try search_metadata[next_results] otherwise null,
                            next_query = Record.AddField( Record.RemoveFields( Uri.Parts(Text.Combine({fullUri,next_results},""))[Query], "count"), "count", Number.ToText(remaining)) //type record
/*                          Uncomment for debugging and testing   
                            statuses = response[statuses], // list
                            completed_in = search_metadata[completed_in], // type number
                            max_id = search_metadata[max_id], // type number
                            max_id_str = search_metadata[max_id_str],
                            refresh_url = search_metadata[refresh_url],
                            since_id = search_metadata[since_id], // type number
                            since_id_str = search_metadata[since_id_str] */
                        ], // next
                    each [[n],[count],[remaining],[next_query],[response]] // selector
                ),
                Splitter.SplitByNothing(), {"search"}, null, ExtraValues.Error
            ),
            expandedSearch = Table.ExpandRecordColumn(searchRecords, "search", {"response"}, {"response"}),
            expandedResponse = Table.ExpandRecordColumn(expandedSearch, "response", {"statuses"}, {"statuses"}),
            expandedStatusList = Table.ExpandListColumn(expandedResponse, "statuses"),
            expandedStatuses = Table.ExpandRecordColumn(expandedStatusList, "statuses", {"created_at", "id", "id_str", "text", "truncated", "metadata", "source", "in_reply_to_status_id", "in_reply_to_status_id_str", "in_reply_to_user_id", "in_reply_to_user_id_str", "in_reply_to_screen_name", "user", "geo", "coordinates", "place", "contributors", "is_quote_status", "retweet_count", "favorite_count", "favorited", "retweeted", "lang", "possibly_sensitive", "quoted_status_id", "quoted_status_id_str"}, {"statuses.created_at", "statuses.id", "statuses.id_str", "statuses.text", "statuses.truncated", "statuses.metadata", "statuses.source", "statuses.in_reply_to_status_id", "statuses.in_reply_to_status_id_str", "statuses.in_reply_to_user_id", "statuses.in_reply_to_user_id_str", "statuses.in_reply_to_screen_name", "statuses.user", "statuses.geo", "statuses.coordinates", "statuses.place", "statuses.contributors", "statuses.is_quote_status", "statuses.retweet_count", "statuses.favorite_count", "statuses.favorited", "statuses.retweeted", "statuses.lang", "statuses.possibly_sensitive", "statuses.quoted_status_id", "statuses.quoted_status_id_str"}),
            expandedStatusMetadata = Table.ExpandRecordColumn(expandedStatuses, "statuses.metadata", {"iso_language_code", "result_type"}, {"statuses.metadata.iso_language_code", "statuses.metadata.result_type"}),
            expandedStatusUser = Table.ExpandRecordColumn(expandedStatusMetadata, "statuses.user", {"id", "id_str", "name", "screen_name", "location", "description", "url", "protected", "followers_count", "friends_count", "listed_count", "created_at", "favourites_count", "utc_offset", "time_zone", "geo_enabled", "verified", "statuses_count", "lang", "contributors_enabled", "is_translator", "is_translation_enabled", "profile_background_color", "profile_background_image_url", "profile_background_image_url_https", "profile_background_tile", "profile_image_url", "profile_image_url_https", "profile_banner_url", "profile_link_color", "profile_sidebar_border_color", "profile_sidebar_fill_color", "profile_text_color", "profile_use_background_image", "has_extended_profile", "default_profile", "default_profile_image", "following", "follow_request_sent", "notifications", "translator_type"}, {"statuses.user.id", "statuses.user.id_str", "statuses.user.name", "statuses.user.screen_name", "statuses.user.location", "statuses.user.description", "statuses.user.url", "statuses.user.protected", "statuses.user.followers_count", "statuses.user.friends_count", "statuses.user.listed_count", "statuses.user.created_at", "statuses.user.favourites_count", "statuses.user.utc_offset", "statuses.user.time_zone", "statuses.user.geo_enabled", "statuses.user.verified", "statuses.user.statuses_count", "statuses.user.lang", "statuses.user.contributors_enabled", "statuses.user.is_translator", "statuses.user.is_translation_enabled", "statuses.user.profile_background_color", "statuses.user.profile_background_image_url", "statuses.user.profile_background_image_url_https", "statuses.user.profile_background_tile", "statuses.user.profile_image_url", "statuses.user.profile_image_url_https", "statuses.user.profile_banner_url", "statuses.user.profile_link_color", "statuses.user.profile_sidebar_border_color", "statuses.user.profile_sidebar_fill_color", "statuses.user.profile_text_color", "statuses.user.profile_use_background_image", "statuses.user.has_extended_profile", "statuses.user.default_profile", "statuses.user.default_profile_image", "statuses.user.following", "statuses.user.follow_request_sent", "statuses.user.notifications", "statuses.user.translator_type"}),
            Final = Value.ReplaceType(expandedStatusUser,tableType)
        in
            Final
in
    Twitter.SearchTweets