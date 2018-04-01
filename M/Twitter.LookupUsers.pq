let
    Twitter.LookupUsers = (user_ids as text) as any =>
        let
            id_list = Text.Split(user_ids, ","),
            id_count = List.Count(id_list),
            max_requests = 300, // Twitter-provided max for app authorized calls
            number_requests = if id_count > 30000 then max_requests else Number.RoundUp(id_count / 100), // 30,000 is the maximum number of items that can be returned in a 15-minute period
            //id_count = Text.Length(user_ids) - Text.Length(Text.Replace(user_ids,",","")) + 1,
            baseUri = "https://api.twitter.com",
            relativeUri = "1.1/users/lookup.json",
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
            tableType = type table [id = text, id_str = text, name = text, screen_name = text, location = text, description = text, url = text, entities = any, protected = logical, followers_count = number, friends_count = number, listed_count = number, created_at = text, favourites_count = number, utc_offset = number, time_zone = text, geo_enabled = logical, verified = logical, statuses_count = number, lang = text, status = any, contributors_enabled = logical, is_translator = logical, is_translation_enabled = logical, profile_background_color = text, profile_background_image_url = text, profile_background_image_url_https = text, profile_background_tile = logical, profile_image_url = text, profile_image_url_https = text, profile_link_color = text, profile_sidebar_border_color = text, profile_sidebar_fill_color = text, profile_text_color = text, profile_use_background_image = logical, has_extended_profile = logical, default_profile = logical, default_profile_image = logical, following = logical, follow_request_sent = any, notifications = any, translator_type = text, profile_banner_url = text], 
            usersRecords = Table.FromList(
                List.Generate(
                    ()=> 
                        [
                            n = 0,
                            multiple = 100 * n,
                            current_user_list = List.Range(id_list, multiple, 100),
                            current_users = Text.Combine(current_user_list,","),
                            current_query = [user_id = current_users,include_entities = "false",tweet_mode = "false"],
                            response = Json.Document(GetResponse(current_query))
                        ], // initial
                    each [n] < number_requests, // condition
                    each 
                        [
                            n = [n] + 1,
                            multiple = 100 * n,
                            current_user_list = List.Range(id_list, multiple, 100),
                            current_users = Text.Combine(current_user_list,","),
                            current_query = [user_id = current_users,include_entities = "false",tweet_mode = "false"],
                            response = Json.Document(GetResponse(current_query))
                        ], // next
                    each [[response]] // selector
                ),
                Splitter.SplitByNothing(), {"users"}, null, ExtraValues.Error
            ),
            ExpandedusersRecords = Table.ExpandRecordColumn(usersRecords, "users", {"response"}, {"response"}),
            ExpandedusersList = Table.ExpandListColumn(ExpandedusersRecords, "response"),
            Final = Value.ReplaceType(Table.ExpandRecordColumn(ExpandedusersList, "response", {"id", "id_str", "name", "screen_name", "location", "description", "url", "entities", "protected", "followers_count", "friends_count", "listed_count", "created_at", "favourites_count", "utc_offset", "time_zone", "geo_enabled", "verified", "statuses_count", "lang", "status", "contributors_enabled", "is_translator", "is_translation_enabled", "profile_background_color", "profile_background_image_url", "profile_background_image_url_https", "profile_background_tile", "profile_image_url", "profile_image_url_https", "profile_banner_url", "profile_link_color", "profile_sidebar_border_color", "profile_sidebar_fill_color", "profile_text_color", "profile_use_background_image", "has_extended_profile", "default_profile", "default_profile_image", "following", "follow_request_sent", "notifications", "translator_type"}, {"id", "id_str", "name", "screen_name", "location", "description", "url", "entities", "protected", "followers_count", "friends_count", "listed_count", "created_at", "favourites_count", "utc_offset", "time_zone", "geo_enabled", "verified", "statuses_count", "lang", "status", "contributors_enabled", "is_translator", "is_translation_enabled", "profile_background_color", "profile_background_image_url", "profile_background_image_url_https", "profile_background_tile", "profile_image_url", "profile_image_url_https", "profile_banner_url", "profile_link_color", "profile_sidebar_border_color", "profile_sidebar_fill_color", "profile_text_color", "profile_use_background_image", "has_extended_profile", "default_profile", "default_profile_image", "following", "follow_request_sent", "notifications", "translator_type"}), tableType)
        in
            Final            
in
    Twitter.LookupUsers