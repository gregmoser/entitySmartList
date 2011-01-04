<!--- Create The Smart List Componente and Pass in the Entity List you want and the location of input variables (ie. form or url) --->
<cfset SmartList = createObject("Component","SmartList").init(entityName="Art", rc=url) />

<!--- Set the weight for any properties you would like keywords to search on --->
<cfset SmartList.addKeywordProperty(rawProperty="artist_firstname", weight=1) />
<cfset SmartList.addKeywordProperty(rawProperty="artist_lastname", weight=2) />
<cfset SmartList.addKeywordProperty(rawProperty="artname", weight=5) />

<html>
	<head>
		<title>Entity Smart List Examples</title>
	</head>
	<body style="font-family:arial;">
	<cfoutput>
		<h1>Example Using CF Art Gallery</h1>
		<hr />
		<table style="width:100%;">
			<tr style="font-weight:bold;">
				<cfif arrayLen(SmartList.getKeywords())><td>Search Score</td></cfif>
				<td>Artist Name</td>
				<td>Art Name</td>
				<td>Art Price</td>
				<td>Sold</td>
				<td>City</td>
			</tr>
			<cfloop array="#SmartList.getEntityArray()#" index="Art">
				<tr>
					<cfif arrayLen(SmartList.getKeywords())><td>#Art.getSearchScore()#</td></cfif>
					<td>#Art.getArtist().getFirstname()# #Art.getArtist().getLastname()#</td>
					<td>#Art.getArtName()#</td>
					<td>#DollarFormat(Art.getPrice())#</td>
					<td><cfif Art.getIsSold()>Yes<cfelse>No</cfif></td>
					<td>#Art.getArtist().getCity()#</td>
				</td>
			</cfloop>
		</table>
		<hr />
		<strong>Entity Start:</strong> #SmartList.getEntityStart()#<br />
		<strong>Entity End:</strong> #SmartList.getEntityEnd()#<br />
		<strong>Entities Per Page:</strong> #SmartList.getEntityShow()#<br />
		<strong>Total Entities:</strong> #SmartList.getTotalEntities()#<br />
		<strong>Current Page:</strong> #SmartList.getCurrentPage()#<br />
		<strong>Total Pages:</strong> #SmartList.getTotalPages()#<br />
		<strong>Fill Time:</strong> #SmartList.getFillTime()# ms<br />
		<cfif arrayLen(SmartList.getKeywords())>
			<strong>List Search Time:</strong> #SmartList.getSearchTime()# ms<br />
		</cfif>
		<hr />
		<hr />
		<h2>Overview</h2>
		<p>The above results display the default settings of the smart list.  This smart list is currently confugured to pull the setup information out of the url string, but it could easily be used to work with the form or both.</p>
		<p>The entities used for the example are "Art" and "Artists" and it used the built in cfartgallery datasource where one artist has multiple peices of art,  However this list is displaying all art.</p>
		<p><em><strong>Note:</strong> Because this example uses the cfartgallery datasource it is case sensitive.</em></p>
		<h3>Filters</h3>
		<p>To filter a list based on any of the entities properties, all you need to do is add it to the url string with a "F_" prefix, for example: <a href="?f_artname=Sky">?f_artname=Sky</a></p>
		<p>Filter on a sub entity by seperating the entities with an undersore, for example: <a href="?f_artist_firstname=Elicia">?f_artist_firstname=Elicia</a></p>
		<p>Feel free to combine filters as well, for example: <a href="?f_artist_firstname=Elicia&f_issold=YES">?f_artist_firstname=Elicia&f_issold=YES</a>.  Another thing to note about this example is that when filtering by a boolean, you can enter a value of (1/0) or (true/flase) or (Yes/No).</p>
		<p>You can also set a filter to use multipe values, much like an OR statement.  To do this seperate the values by a ^ charecter, for example: <a href="?f_artist_city=Denver^Tulsa">?f_artist_city=Denver^Tulsa</a></p>
		<h3>Ranges</h3>
		<p>Adding a range is similar to a filter but the prefix is "R_", in addition you need to include both an upper and lower of the range, for example: <a href="?r_price=8000^11000">?r_price=8000^11000</a></p>
		<h3>Orders</h3>
		<p>You can easily arrange your data by order using the "OrderBy" attribute,  in addition you can specify if you would like it to be ascending or desending using a "|A" or "|D" at the end for example: <a href="?OrderBy=artname|A">?OrderBy=artname|A</a></p>
		<p>Again like filters and ranges you can add multiple columns using the ^ charecter, for example: <a href="?OrderBy=price|A&artist_lastname|D">?OrderBy=price|A^artist_lastname|D</a></p>
		<h3>Keywords</h3>
		<p>You can easily search for keywords as well by using the "Keyword" attrubute, for example: <a href="?Keyword=House">?Keyword=House</a></p>
		<p>In a keyword search the properties that get searched are setup and weighted in you setup of the smart list.  Then a Search Score is applied to each entity in your list, and the list is re-ordered by search score.  Here is a look at multiple search words: <a href="?Keyword=Space%20Kim%20Elicia%20Austin%20Do">?Keyword=Space%20Kim%20Elicia%20Austin%20Do</a></p>
		<h3>Paging</h3>
		<p>You can easily change the number of entities that are shown per page, for example: <a href="?e_show=30">?e_show=30</a></p>
		<p>You can also specify which entity you would like your list to start with, for example: <a href="?e_start=10">?e_start=10</a></p>
		<p>If you prefer, you can set up the start page instead of the start entity, for example: <a href="?p_current=3">?p_current=3</a></p>
		<br />
		<br />
		<br />
		<br />
		<br />
		<br />
		<br />
	</cfoutput>
	</body>
</html>
