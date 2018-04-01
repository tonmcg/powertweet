// adapted from  Chris Koester's blog
// for an example, see tonymcgovern.com/powerquery/twitter/get-token/
// for more details, see https://chris.koester.io/index.php/2015/07/16/get-data-from-twitter-api-with-power-query/ 
let
    Twitter.GetOAuthToken = (consumerKey as text, consumerSecret as text) as text =>
    let
        // Concatenates the Consumer Key & Consumer Secret and converts to base64
        authKey = "Basic " & Binary.ToText(Text.ToBinary(consumerKey & ":" & consumerSecret),0),
        url = "https://api.twitter.com/oauth2/token",
        // Uses the Twitter POST oauth2/token method to obtain a bearer token
        GetJson = Web.Contents(
            url,
            [
                Headers = 
                [
                    #"Authorization"=authKey,
                    #"Content-Type"="application/x-www-form-urlencoded;charset=UTF-8"
                ],
                Content = Text.ToBinary("grant_type=client_credentials") 
            ]
        ),
        FormatAsJson = Json.Document(GetJson),
        // Gets token from the Json response
        AccessToken = FormatAsJson[access_token],
        AccessTokenHeader = "bearer " & AccessToken
    in
        AccessTokenHeader
in
    Twitter.GetOAuthToken