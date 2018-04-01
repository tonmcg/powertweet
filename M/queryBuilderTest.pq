let
	count = 100,
	q = Uri.EscapeDataString("powerquery"),
	baseUri = "https://api.twitter.com",
	relativeUri = "1.1/search/tweets.json",
	fullUri = Uri.Combine(baseUri,relativeUri),
	initial_query = [q = q, count = Number.ToText(count)],
	next_results = "?max_id=780312123578716159&q=powerquery&count=100&include_entities=1",
	refresh_url = "?since_id=780344917721649152&q=powerquery&include_entities=1",
	next_query = Uri.Parts(Text.Combine({fullUri,next_results},""))[Query]
in
	next_query