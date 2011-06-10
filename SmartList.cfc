/*
	Copyright (c) 2010, Greg Moser
	
	Version: 1.1
	Documentation: http://www.github.com/gregmoser/entitySmartList/wiki

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/
component displayname="Smart List" accessors="true" persistent="false" output="false" {
	
	property name="baseEntityName" type="string";
	
	property name="entities" type="struct";
	property name="selects" type="struct" hint="This struct holds any selects that are to be used in creating the records array";
	property name="whereGroups" type="array" hint="this holds all filters and ranges";
	property name="orders" type="array" hint="This struct holds the display order specification based on property";
	
	property name="keywordProperties" type="struct" hint="This struct holds the properties that searches reference and their relative weight";
	property name="keywords" type="array" hint="This array holds all of the keywords that were searched for";

	property name="hqlParams" type="struct";
	
	property name="pageRecordsStart" type="numeric" hint="This represents the first record to display and it is used in paging.";
	property name="pageRecordsShow" type="numeric" hint="This is the total number of entities to display";
	
	property name="searchTime" type="numeric";
	
	// Delimiter Settings
	variables.subEntityDelimiter = "_";
	variables.valueDelimiter = ",";
	variables.orderDirectionDelimiter = "|";
	variables.orderPropertyDelimiter = ",";
	variables.dataKeyDelimiter = ":";
	variables.currentURL = "";
	variables.currentPageDeclaration = 1;
	variables.entityJoinOrder = [];
	
	public any function init(required string entityName, struct data, numeric pageRecordsStart=1, numeric pageRecordsShow=10, string currentURL="") {
		// Set defaults for the main properties
		setSelects({});
		setWhereGroups([]);
		setOrders([]);
		setKeywordProperties({});
		setKeywords([]);
		setSearchTime(0);
		setEntities({});
		setHQLParams({});
		
		// Set currentURL from the arguments
		variables.currentURL = arguments.currentURL;
		
		// Set paging defaults
		setPageRecordsStart(arguments.pageRecordsStart);
		setPageRecordsShow(arguments.pageRecordsShow);
		
		var baseEntity = entityNew("#arguments.entityName#");
		var baseEntityMeta = getMetaData(baseEntity);
		
		setBaseEntityName(arguments.entityName);
		
		addEntity(
			entityName=arguments.entityName,
			entityAlias="a#lcase(arguments.entityName)#",
			entityFullName=baseEntityMeta.fullName,
			entityProperties=getPropertiesStructFromEntityMeta(baseEntityMeta)
		);
		
		if(structKeyExists(arguments, "data")) {
			applyData(data=arguments.data);	
		}
				
		return this;
	}
		
	private void function confirmWhereGroup(required numeric whereGroup) {
		for(var i=1; i<=arguments.whereGroup; i++) {
			if(arrayLen(variables.whereGroups) < i) {
				arrayAppend(variables.whereGroups, {filters={},likeFilters={},ranges={}});
			}
		}
	}
	
	private struct function getPropertiesStructFromEntityMeta(required struct meta) {
		var propertyStruct = {};
		var hasExtendedComponent = true;
		var currentEntityMeta = arguments.meta;
		
		do {
			if(structKeyExists(currentEntityMeta, "properties")) {
				for(var i=1; i<=arrayLen(currentEntityMeta.properties); i++) {
					if(!structKeyExists(propertyStruct, currentEntityMeta.properties[i].name)) {
						propertyStruct[currentEntityMeta.properties[i].name] = duplicate(currentEntityMeta.properties[i]);	
					}
				}
			}
			
			hasExtendedComponent = false;
			
			if(structKeyExists(currentEntityMeta, "extends")) {
				currentEntityMeta = currentEntityMeta.extends;
				if(structKeyExists(currentEntityMeta, "persistent") && currentEntityMeta.persistent) {
					hasExtendedComponent = true;	
				}
			}
		} while (hasExtendedComponent);
		
		return propertyStruct;
	}
	
	public string function joinRelatedProperty(required string parentEntityName, required string relatedProperty, string joinType="", boolean fetch) {
		var parentEntityFullName = variables.entities[ arguments.parentEntityName ].entityFullName;
		if(listLen(variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].cfc,".") < 2) {
			var newEntityCFC = Replace(parentEntityFullName, listLast(parentEntityFullName,"."), variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].cfc);	
		} else {
			var newEntityCFC = variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].cfc;
		}
		var newEntity = createObject("component","#newEntityCFC#");
		var newEntityMeta = getMetaData(newEntity);
		
		if(structKeyExists(newEntityMeta, "entityName")) {
			var newEntityName = newEntityMeta.entityName;
		} else {
			var newEntityName = listLast(newEntityMeta.fullName,".");
		}
		
		var newEntityAlias = "a#lcase(newEntityName)#";
		
		// Check to see if this is a Self Join, and setup appropriatly.
		if(newEntityAlias == variables.entities[ arguments.parentEntityName ].entityAlias) {
			newEntityAlias = "b#lcase(newEntityName)#";
			newEntityName = "#lcase(newEntityName)#_B";
			arguments.fetch = false;
		}
		
		if(!structKeyExists(variables.entities,newEntityName)) {
			arrayAppend(variables.entityJoinOrder, newEntityName);
			
			if(variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].fieldtype == "many-to-one" && !structKeyExists(arguments, "fetch") && arguments.parentEntityName == getBaseEntityName()) {
				arguments.fetch = true;
			} else if(!structKeyExists(arguments, "fetch")) {
				arguments.fetch = false;
			}
			
			addEntity(
				entityName=newEntityName,
				entityAlias=newEntityAlias,
				entityFullName=newEntityMeta.fullName,
				entityProperties=getPropertiesStructFromEntityMeta(newEntityMeta),
				parentAlias=variables.entities[ arguments.parentEntityName ].entityAlias,
				parentRelationship=variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].fieldtype,
				parentRelatedProperty=variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].name,
				fkColumn=variables.entities[ arguments.parentEntityName ].entityProperties[ arguments.relatedProperty ].fkcolumn,
				joinType=arguments.joinType,
				fetch=arguments.fetch
			);
		} else {
			if(arguments.joinType != "") {
				variables.entities[newEntityName].joinType = arguments.joinType;
			}
			if(structKeyExists(arguments, "fetch")) {
				variables.entities[newEntityName].fetch = arguments.fetch;
			}
		}
		
		return newEntityName;
	}
	
	// This method is still in development and doesn't work yet.
	/*
	public string function joinEntity(required string parentEntityName, required string parentJoinKey, required string entityName, required string joinKey, string joinType="", boolean fetch=false) {
		var entity = entityNew(arguments.entityName);
		var newEntityName = arguments.entityName;
		var newEntityMeta = getMetaData(entity);
		var newEntityAlias = "a#lcase(newEntityName)#";
		
		addEntity(
			entityName=newEntityName,
			entityAlias=newEntityAlias,
			entityFullName=newEntityMeta.fullName,
			entityProperties=getPropertiesStructFromMetaArray(newEntityMeta.properties),
			parentAlias=variables.entities[ arguments.parentEntityName ].entityAlias,
			parentRelationship="",
			parentRelatedProperty="",
			fkColumn="",
			joinType=arguments.joinType,
			joinOn="#variables.entities[ arguments.parentEntityName ].entityAlias#.#arguments.parentJoinKey# = #newEntityAlias#.#arguments.joinKey#",
			fetch=arguments.fetch
		);
	}
	*/
	
	private void function addEntity(required string entityName, required string entityAlias, required string entityFullName, required struct entityProperties, string parentAlias="", string parentRelationship="",string parentRelatedProperty="", string fkColumn="", string joinType="") {
		variables.entities[arguments.entityName] = duplicate(arguments);
	}
	
	private string function getAliasedProperty(required string propertyIdentifier) {
		var entityName = getBaseEntityName();
		var entityAlias = variables.entities[getBaseEntityName()].entityAlias;
		for(var i=1; i<listLen(arguments.propertyIdentifier, variables.subEntityDelimiter); i++) {
			entityName = joinRelatedProperty(parentEntityName=entityName, relatedProperty=listGetAt(arguments.propertyIdentifier, i, variables.subEntityDelimiter));
			entityAlias = variables.entities[entityName].entityAlias;
		}
		return "#entityAlias#.#variables.entities[entityName].entityProperties[listLast(propertyIdentifier, variables.subEntityDelimiter)].name#";
	}
	
	public void function addSelect(required string propertyIdentifier, required string alias) {
		variables.selects[getAliasedProperty(propertyIdentifier=arguments.propertyIdentifier)] = arguments.alias;
	}
	
	public void function addFilter(required string propertyIdentifier, required string value, numeric whereGroup=1) {
		confirmWhereGroup(arguments.whereGroup);
		var aliasedProperty = getAliasedProperty(propertyIdentifier=arguments.propertyIdentifier);
		
		if(structKeyExists(variables.whereGroups[arguments.whereGroup].filters, aliasedProperty)) {
			variables.whereGroups[arguments.whereGroup].filters[aliasedProperty] &= variables.valueDelimiter & arguments.value;
		} else {
			variables.whereGroups[arguments.whereGroup].filters[aliasedProperty] = arguments.value;
		}
	}
	
	public void function addLikeFilter(required string propertyIdentifier, required string value, numeric whereGroup=1) {
		confirmWhereGroup(arguments.whereGroup);
		var aliasedProperty = getAliasedProperty(propertyIdentifier=arguments.propertyIdentifier);
		
		if(structKeyExists(variables.whereGroups[arguments.whereGroup].likeFilters, aliasedProperty)) {
			variables.whereGroups[arguments.whereGroup].likeFilters[aliasedProperty] &= variables.valueDelimiter & arguments.value;
		} else {
			variables.whereGroups[arguments.whereGroup].likeFilters[aliasedProperty] = arguments.value;
		}
	}
	
	public void function addRange(required string propertyIdentifier, required string value, numeric whereGroup=1) {
		confirmWhereGroup(arguments.whereGroup);
		var aliasedProperty = getAliasedProperty(propertyIdentifier=arguments.propertyIdentifier);
		
		variables.whereGroups[arguments.whereGroup].ranges[aliasedProperty] = arguments.value;
	}
	
	public void function addOrder(required string orderStatement, numeric position) {
		var propertyIdentifier = listFirst(arguments.orderStatement, variables.orderDirectionDelimiter);
		var orderDirection = listLast(arguments.orderStatement, variables.orderDirectionDelimiter);
		var aliasedProperty = getAliasedProperty(propertyIdentifier=propertyIdentifier);
		
		if(orderDirection == "A") {
			orderDirection == "ASC";
		} else if (orderDirection == "D") {
			orderDirection == "DESC";
		}
		arrayAppend(variables.orders, {property=aliasedProperty, direction=orderDirection});
	}

	public void function addKeywordProperty(required string propertyIdentifier, required numeric weight) {
		variable.keywordProperties[getAliasedProperty(propertyIdentifier=arguments.propertyIdentifier)] = arguments.weight;
	}
	
	public void function applyData(required struct data) {
		var currentPage = 1;
		
		for(var i in arguments.data) {
			if(left(i,2) == "F#variables.dataKeyDelimiter#") {
				addFilter(propertyIdentifier=right(i, len(i)-2), value=arguments.data[i]);
			} else if(left(i,2) == "R#variables.dataKeyDelimiter#") {
				addRange(propertyIdentifier=right(i, len(i)-2), value=arguments.data[i]);
			} else if(i == "OrderBy") {
				for(var ii=1; ii <= listLen(arguments.data[i], variables.orderPropertyDelimiter); ii++ ) {
					addOrder(orderStatement=listGetAt(arguments.data[i], ii, variables.orderPropertyDelimiter));
				}
			} else if(i == "P#variables.dataKeyDelimiter#Show") {
				if(arguments.data[i] == "ALL") {
					setPageRecordsShow(1000000000);
				} else if (isNumeric(arguments.data[i])) {
					setPageRecordsShow(arguments.data[i]);	
				}
			} else if(i == "P#variables.dataKeyDelimiter#Start" && isNumeric(arguments.data[i])) {
				setPageRecordsStart(arguments.data[i]);
			} else if(i == "P#variables.dataKeyDelimiter#Current" && isNumeric(arguments.data[i])) {
				variables.currentPageDeclaration = arguments.data[i];
			}
		}
		if(structKeyExists(arguments.data, "keyword")){
			var KeywordList = Replace(arguments.data.Keyword," ","^","all");
			KeywordList = Replace(KeywordList,"%20","^","all");
			KeywordList = Replace(KeywordList,"+","^","all");
			for(var i=1; i <= listLen(KeywordList, "^"); i++) {
				arrayAppend(variables.Keywords, listGetAt(KeywordList, i, "^"));
			}
		}
	}
	
	public void function addHQLParam(required string paramName, required string paramValue) {
		variables.hqlParams[ arguments.paramName ] = arguments.paramValue;
	}
	
	public struct function getHQLParams() {
		return duplicate(variables.hqlParams);
	}

	public string function getHQLSelect () {
		var hqlSelect = "";
		
		if(structCount(variables.selects)) {
			hqlSelect = "SELECT new map(";
			for(var select in variables.selects) {
				hqlSelect &= " #select# as #variables.selects[select]#,";
			}
			hqlSelect = left(hqlSelect, len(hqlSelect)-1) & ")";
		} else {
			hqlSelect &= "SELECT DISTINCT #variables.entities[getBaseEntityName()].entityAlias#";
		}
		
		return hqlSelect;
	}
	
	public string function getHQLFrom(boolean supressFrom=false) {
		var hqlFrom = "";
		if(!arguments.supressFrom) {
			hqlFrom &= " FROM";	
		}
		hqlFrom &= " #getBaseEntityName()# as #variables.entities[getBaseEntityName()].entityAlias#";

		for(var i in variables.entityJoinOrder) {
			if(i != getBaseEntityName()) {
				var joinType = variables.entities[i].joinType;
				if(!len(joinType)) {
					joinType = "inner";
				}
				
				var fetch = "";
				if(variables.entities[i].fetch) {
					fetch = "fetch";
				}
				
				hqlFrom &= " #joinType# join #fetch# #variables.entities[i].parentAlias#.#variables.entities[i].parentRelatedProperty# as #variables.entities[i].entityAlias#";	
			}
		}
		return hqlFrom;
	}

	public string function getHQLWhere(boolean suppressWhere=false) {
		var hqlWhere = "";
		
		// Loop over where groups
		for(var i=1; i<=arrayLen(variables.whereGroups); i++) {
			if( structCount(variables.whereGroups[i].filters) || structCount(variables.whereGroups[i].likeFilters) || structCount(variables.whereGroups[i].ranges) ) {
				if(len(hqlWhere) == 0) {
					if(!arguments.suppressWhere) {
						hqlWhere &= " WHERE";
					}
					hqlWhere &= " (";
				} else {
					hqlWhere &= " OR";
				}
				
				// Open A Where Group
				hqlWhere &= " (";
				
				// Add Where Group Filters
				for(var filter in variables.whereGroups[i].filters) {
					if(listLen(variables.whereGroups[i].filters[filter], variables.valueDelimiter) gt 1) {
						hqlWhere &= " (";
						for(var ii=1; ii<=listLen(variables.whereGroups[i].filters[filter], variables.valueDelimiter); ii++) {
							var paramID = "F#replace(filter, ".", "", "all")##i##ii#";
							addHQLParam(paramID, listGetAt(variables.whereGroups[i].filters[filter], ii, variables.valueDelimiter));
							hqlWhere &= " #filter# = :#paramID# OR";
						}
						hqlWhere = left(hqlWhere, len(hqlWhere)-2) & ") AND";
					} else {
						var paramID = "F#replace(filter, ".", "", "all")##i#";
						addHQLParam(paramID, variables.whereGroups[i].filters[filter]);
						hqlWhere &= " #filter# = :#paramID# AND";
					}
				}
				
				// Add Where Group Like Filters
				for(var likeFilter in variables.whereGroups[i].likeFilters) {
					if(listLen(variables.whereGroups[i].likeFilters[likeFilter], variables.valueDelimiter) gt 1) {
						hqlWhere &= " (";
						for(var ii=1; ii<=listLen(variables.whereGroups[i].likeFilters[likeFilter], variables.valueDelimiter); ii++) {
							var paramID = "LF#replace(likeFilter, ".", "", "all")##i##ii#";
							addHQLParam(paramID, listGetAt(variables.whereGroups[i].likeFilters[likeFilter], ii, variables.valueDelimiter));
							hqlWhere &= " #likeFilter# LIKE :#paramID# OR";
						}
						hqlWhere = left(hqlWhere, len(hqlWhere)-2) & ") AND";
					} else {
						var paramID = "LF#replace(likeFilter, ".", "", "all")##i#";
						addHQLParam(paramID, variables.whereGroups[i].likeFilters[likeFilter]);
						hqlWhere &= " #likeFilter# LIKE :#paramID# AND";
					}
				}
				
				// Add Where Group Ranges
				for(var range in variables.whereGroups[i].ranges) {
					var paramIDupper = "R#replace(range, ".", "", "all")##i#upper";
					var paramIDlower = "R#replace(range, ".", "", "all")##i#lower";
					addHQLParam(paramIDlower, listGetAt(variables.whereGroups[i].ranges[range], 1, variables.valueDelimiter));
					addHQLParam(paramIDupper, listGetAt(variables.whereGroups[i].ranges[range], 2, variables.valueDelimiter));
					
					hqlWhere &= " #range# >= :#paramIDlower# AND #range# <= :#paramIDupper# AND";
					
				}
				
				// Close Where Group
				hqlWhere = left(hqlWhere, len(hqlWhere)-3)& ")";
				if( i == arrayLen(variables.whereGroups)) {
					hqlWhere &= " )";
				}
			}
		}
		
		if( arrayLen(variables.Keywords) && structCount(variables.keywordProperties) ) {
			if(len(hqlWhere) == 0) {
				if(!arguments.suppressWhere) {
					hqlWhere &= " WHERE";
				}
			} else {
				hqlWhere &= " AND";
			}
			hqlWhere &= " (";
			for(var keywordProperty in variables.keywordProperties) {
				for(var ii=1; ii<=arrayLen(variables.Keywords); ii++) {
					var paramID = "K#replace(keywordProperty, ".", "", "all")##ii#";
					addHQLParam(paramID, "%#variables.Keywords[ii]#%");
					hqlWhere &= " #keywordProperty# LIKE :#paramID# AND";
				}
			}
			hqlWhere = left(hqlWhere, len(hqlWhere)-3 ) & ")";
		}
		
		return hqlWhere;
	}
	
	public string function getHQLOrder(boolean supressOrderBy=false) {
		var hqlOrder = "";
		if(arrayLen(variables.orders)){
			if(!arguments.supressOrderBy) {
				var hqlOrder &= " ORDER BY";
			}
			for(var i=1; i<=arrayLen(variables.orders); i++) {
				var hqlOrder &= " #variables.orders[i].property# #variables.orders[i].direction#,";
			}
			hqlOrder = left(hqlOrder, len(hqlOrder)-1);
		}
		return hqlOrder;
	}
	
	public string function getHQL() {
		return "#getHQLSelect()##getHQLFrom()##getHQLWhere()##getHQLOrder()#";
	}

	/* This Needs To Be Refactored
	public void function applySearchScore(){
		var searchStart = getTickCount();
		var structSort = structNew();
		var randomID = 0;
		
		for(var i=1; i <= arrayLen(variables.records); i++) {
			var score = 0;
			for(property in keywordProperties) {
				var propertyArray = listToArray(property, ".");
				var evalString = "variables.records[i]";
				for(var pi=2; pi <= arrayLen(propertyArray); pi++) {
					evalString &= ".get#propertyArray[pi]#()";
				}
				var data = evaluate("#evalString#");
				for(var ki=1; ki <= arrayLen(variables.keywords); ki++) {
					var findValue = FindNoCase(variables.keywords[ki], data, 0);
					while(findValue > 0) {
						var score = score + (len(variables.keywords[ki]) * variables.keywordProperties[property]);
						findValue = FindNoCase(variables.keywords[ki],  data, findValue+1);
					}
				}
			}
			variables.records[i].setSearchScore(score);
			randomID = rand();
			if(find(".", score)) {
				randomID = right(randomID, len(randomID)-2);
			}
			structSort[ score & randomID ] = variables.records[i];
		}
		var scoreArray = structKeyArray(structSort);
		
		arraySort(scoreArray, "numeric", "desc");
		variables.records = arrayNew(1);
		for(var i=1; i <= arrayLen(scoreArray); i++) {
			arrayAppend(variables.records, structSort[scoreArray[i]]);
		}
		
		setSearchTime(getTickCount()-searchStart);
	}
	*/
	
	public void function setRecords(required any records) {
		variables.records = arrayNew(1);
		
		if(isArray(arguments.records)) {
			variables.records = arguments.records;
		} else if (isQuery(arguments.records)) {
			// TODO: add the ability to pass in a query.
			throw("Passing in a query is a feature that hasn't been finished yet");
		} else {
			throw("You must either pass an array of records, or a query or records");
		}
		
		// Apply Search Score to Entites
		if(arrayLen(variables.keywords)) {
			applySearchScore();
		}
	}
	
	public array function getRecords(boolean refresh=false) {
		if( !structKeyExists(variables, "records") || arguments.refresh == true) {
			variables.records = ormExecuteQuery(getHQL(), getHQLParams(), false, {ignoreCase="true"});
		}
		return variables.records;
	}
	
	public numeric function getRecordsCount() {
		return arrayLen(getRecords());
	}
	
	// Paging Methods
	public array function getPageRecords(boolean refresh=false) {
		if( !structKeyExists(variables, "pageRecords")) {
			var records = getRecords(arguments.refresh);
			variables.pageRecords = arrayNew(1);
			for(var i=getPageRecordsStart(); i<=getPageRecordsEnd(); i++) {
				arrayAppend(variables.pageRecords, records[i]);
			}
		}
		return variables.pageRecords;
	}
	
	public numeric function getPageRecordsStart() {
		if(variables.currentPageDeclaration > 1) {
			variables.pageRecordsStart = ((variables.currentPageDeclaration-1)*getPageRecordsShow()) + 1;
		}
		return variables.pageRecordsStart;
	}
	
	public numeric function getPageRecordsEnd() {
		var pageRecordEnd = getPageRecordsStart() + getPageRecordsShow() - 1;
		if(pageRecordEnd > getRecordsCount()) {
			pageRecordEnd = getRecordsCount();
		}
		return pageRecordEnd;
	}
	
	public numeric function getCurrentPage() {
		return ceiling(getPageRecordsStart() / getPageRecordsShow());
	}
	
	public any function getTotalPages() {
		return ceiling(getRecordsCount() / getPageRecordsShow());
	}
	
	public string function buildURL(required string queryAddition, boolean appendValues=true, boolean toggleKeys=true, string currentURL=variables.currentURL) {
		// Generate full URL if one wasn't passed in
		if(arguments.currentURL == "") {
			arguments.currentURL &= CGI.SCRIPT_NAME;
			if(CGI.PATH_INFO != "" && CGI.PATH_INFO neq CGI.SCRIPT_NAME) {
				arguments.currentURL &= CGI.PATH_INFO;	
			}
			if(len(cgi.query_string)) {
				arguments.currentURL &= "?" & CGI.QUERY_STRING;	
			}
		}

		// Setup the base of the new URL
		var modifiedURL = listFirst(arguments.currentURL, "?") & "?";
		
		// Turn the old query string into a struct
		var oldQueryKeys = {};
		
		if(listLen(arguments.currentURL, "?") == 2) {
			for(var i=1; i<=listLen(listLast(arguments.currentURL, "?"), "&"); i++) {
				var keyValuePair = listGetAt(listLast(arguments.currentURL, "?"), i, "&");
				oldQueryKeys[listFirst(keyValuePair,"=")] = listLast(keyValuePair,"=");
			}	
		}
		
		// Turn the added query string to a struct
		var newQueryKeys = {};
		for(var i=1; i<=listLen(arguments.queryAddition, "&"); i++) {
			var keyValuePair = listGetAt(arguments.queryAddition, i, "&");
			newQueryKeys[listFirst(keyValuePair,"=")] = listLast(keyValuePair,"=");
		}
		
		
		// Get all keys and values from the old query string added
		for(var key in oldQueryKeys) {
			if(key != "P#variables.dataKeyDelimiter#Current" && key != "P#variables.dataKeyDelimiter#Start" && key != "P#variables.dataKeyDelimiter#Show") {
				if(!structKeyExists(newQueryKeys, key)) {
					modifiedURL &= "#key#=#oldQueryKeys[key]#&";
				} else {
					if(arguments.toggleKeys && structKeyExists(oldQueryKeys, key) && structKeyExists(newQueryKeys, key) && oldQueryKeys[key] == newQueryKeys[key]) {
						structDelete(newQueryKeys, key);
					} else if(arguments.appendValues) {
						for(var i=1; i<=listLen(newQueryKeys[key], variables.valueDelimiter); i++) {
							var thisVal = listGetAt(newQueryKeys[key], i, variables.valueDelimiter);
							var findCount = listFind(oldQueryKeys[key], thisVal, variables.valueDelimiter);
							if(findCount) {
								newQueryKeys[key] = listDeleteAt(newQueryKeys[key], i, variables.valueDelimiter);
								if(arguments.toggleKeys) {
									oldQueryKeys[key] = listDeleteAt(oldQueryKeys[key], findCount);
								}
							}
						}
						if(len(oldQueryKeys[key]) && len(newQueryKeys[key])) {
							modifiedURL &= "#key#=#oldQueryKeys[key]##variables.valueDelimiter##newQueryKeys[key]#&";	
						} else if(len(oldQueryKeys[key])) {
							modifiedURL &= "#key#=#oldQueryKeys[key]#&";
						}
						structDelete(newQueryKeys, key);
					}
				}
			}
		}
		
		// Get all keys and values from the additional query string added 
		for(var key in newQueryKeys) {
			if(key != "P#variables.dataKeyDelimiter#Current" && key != "P#variables.dataKeyDelimiter#Start" && key != "P#variables.dataKeyDelimiter#Show") {
				modifiedURL &= "#key#=#newQueryKeys[key]#&";
			}
		}
		
		if(!structKeyExists(newQueryKeys, "P#variables.dataKeyDelimiter#Show") || newQueryKeys["P#variables.dataKeyDelimiter#Show"] == getPageRecordsShow()) {
			// Add the correct page start
			if( structKeyExists(newQueryKeys, "P#variables.dataKeyDelimiter#Start") ) {
				modifiedURL &= "P#variables.dataKeyDelimiter#Start=#newQueryKeys[ 'P#variables.dataKeyDelimiter#Start' ]#&";
			} else if( structKeyExists(newQueryKeys, "P#variables.dataKeyDelimiter#Current") ) {
				modifiedURL &= "P#variables.dataKeyDelimiter#Current=#newQueryKeys[ 'P#variables.dataKeyDelimiter#Current' ]#&";
			} else if( structKeyExists(oldQueryKeys, "P#variables.dataKeyDelimiter#Start") ) {
				modifiedURL &= "P#variables.dataKeyDelimiter#Start=#oldQueryKeys[ 'P#variables.dataKeyDelimiter#Start' ]#&";
			} else if( structKeyExists(oldQueryKeys, "P#variables.dataKeyDelimiter#Current") ) {
				modifiedURL &= "P#variables.dataKeyDelimiter#Current=#oldQueryKeys[ 'P#variables.dataKeyDelimiter#Current' ]#&";
			}
		}
		
		// Add the correct page show
		if( structKeyExists(newQueryKeys, "P#variables.dataKeyDelimiter#Show") ) {
			modifiedURL &= "P#variables.dataKeyDelimiter#Show=#newQueryKeys[ 'P#variables.dataKeyDelimiter#Show' ]#&";
		} else if( structKeyExists(oldQueryKeys, "P#variables.dataKeyDelimiter#Show") ) {
			modifiedURL &= "P#variables.dataKeyDelimiter#Show=#oldQueryKeys[ 'P#variables.dataKeyDelimiter#Show' ]#&";
		}
	
		return left(modifiedURL, len(modifiedURL)-1);
	}
}