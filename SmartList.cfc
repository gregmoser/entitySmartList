/*
	Copyright (c) 2010, Greg Moser

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
component displayname="Smart List" accessors="true" persistent="false" {
	
	property name="entityName" type="string" hint="This is the base entity that the list is based on.";
	property name="entityMetaData" type="struct" hint="This is the meta data of the base entity.";

	property name="selects" type="struct" hint="This struct holds any selects that are to be used in creating the records array";
	property name="filters" type="struct" hint="This struct holds any filters that are set on the entities properties";
	property name="ranges" type="struct" hint="This struct holds any ranges set on any of the entities properties";
	property name="orders" type="array" hint="This struct holds the display order specification based on property";
	
	property name="keywordProperties" type="struct" hint="This struct holds the properties that searches reference and their relative weight";
	property name="keywords" type="array" hint="This array holds all of the keywords that were searched for";
	
	property name="entityStart" type="numeric" hint="This represents the first record to display and it is used in paging.";
	property name="entityShow" type="numeric" hint="This is the total number of entities to display";
	property name="entityEnd" type="numeric" hint="This represents the last record to display and it is used in paging.";
	property name="totalEntities" type="numeric";
	
	property name="currentPage" type="numeric" hint="This is the current page that the smart list is displaying worth of entities";
	property name="totalPages" type="numeric" hint="This is the total number of pages worth of entities";

	property name="queryRecords" type="query" hint="This is the raw query records.  Either this is used or the entityRecords is uesed";
	property name="entityRecords" type="array" hint="This is the raw array of records.  Either this is used or the queryRecords is used";
	
	property name="entityArray" type="array" hint="This is the completed array of entities after filter, range, order, keywords and paging.";	

	property name="fillTime" type="numeric";
	property name="searchTime" type="numeric";

	public any function init(struct rc, required string entityName) {
		// Set defaults for the main properties
		setSelects(structNew());
		setFilters(structNew());
		setRanges(structNew());
		setOrders(arrayNew(1));
		setKeywordProperties(structNew());
		setKeywords(arrayNew(1));
		setEntityStart(1);
		setEntityShow(10);
		setEntityMetaData(structNew());
		setRecords(arrayNew(1));
		setSearchTime(0);
		
		setQueryRecords(queryNew('empty'));
		setEntityRecords(arrayNew(1));
		
		// Set entity name based on whatever
		setEntityName(arguments.entityName);
		
		if(isDefined("arguments.rc")) {
			applyRC(rc=arguments.RC);
		}
		
		variables.HQLWhereParams = structNew();
				
		return this;
	}
	
	public numeric function getEntityEnd() {
		variables.entityEnd = getEntityStart() + getEntityShow() - 1;
		if(variables.entityEnd > arrayLen(variables.records)) {
			variables.entityEnd = arrayLen(variables.records);
		}
		
		return variables.entityEnd;
		
	}
	
	public numeric function getCurrentPage() {
		return ceiling(getEntityStart() / getEntityShow());
	}
	
	public numeric function getEntityStart() {
		if(isDefined("variables.currentPage")) {
			variables.entityStart = ((variables.currentPage - 1) * getEntityShow()) + 1;
		}
		return variables.entityStart;
	}
	
	public numeric function getTotalEntities() {
		return arrayLen(variables.records);
	}
	
	public numeric function getTotalPages() {
		variables.totalPages = ceiling(getTotalEntities() / getEntityShow());
		return variables.totalPages;
	}
	
	public void function addSelect(required string rawProperty, required string aliase) {
		var selectProperty = getValidHQLProperty(rawProperty=arguments.rawProperty);
		if(selectProperty != "") {
			if(structKeyExists(variables.selects, selectProperty)) {
				variables.selects[selectProperty] = arguments.aliase;
			} else {
				structInsert(variables.selects, selectProperty, arguments.aliase);
			}
		}
	}
	
	public void function addFilter(required string rawProperty, required string value) {
		var filterProperty = getValidHQLProperty(rawProperty=arguments.rawProperty);
		if(filterProperty != "") {
			for(var i=1; i <= listLen(arguments.value, "^"); i++) {
				var filterValue = getValidHQLPropertyValue(rawProperty=arguments.rawProperty, value=listGetAt(arguments.value, i, "^"));
				if(filterValue != "") {
					if(structKeyExists(variables.filters, filterProperty)) {
						variables.filters[filterProperty] = "#variables.filters[filterProperty]#^#filterValue#";
					} else {
						structInsert(variables.filters, filterProperty, filterValue);
					}
				}
			}
		}
	}
	
	public void function addRange(required string rawProperty, required string value) {
		var rangeProperty = getValidHQLProperty(rawProperty=arguments.rawProperty);
		if(rangeProperty != "") {
			if(Find("^", arguments.value)) {
				var lowerRange = getValidHQLPropertyValue(rawProperty=arguments.rawProperty, value=Left(arguments.value, Find("^", arguments.value)-1));
				var upperRange = getValidHQLPropertyValue(rawProperty=arguments.rawProperty, value=Right(arguments.value, Len(arguments.value) - Find("^", arguments.value)));
				if(isNumeric(lowerRange) && isNumeric(upperRange) && lowerRange <= upperRange) {
					if(structKeyExists(variables.ranges, rangeProperty)) {
						variables.ranges[rangeProperty] = "#lowerRange#^#upperRange#";
					} else {
						structInsert(variables.ranges, rangeProperty, "#lowerRange#^#upperRange#");
					}
				}
			}
		}
	}
	
	public void function addOrder(required string orderStatement, numeric position) {
		var orderStruct = structNew();
		var orderProperty = getValidHQLProperty(rawProperty=Left(arguments.orderStatement, Find("|", arguments.orderStatement)-1));
		
		if(orderProperty != "") {
			var orderDirection = Right(arguments.orderStatement, Len(arguments.orderStatement) - Find("|", arguments.orderStatement));
			if(orderDirection == "A" || orderDirection == "ASC") {
				orderDirection = "ASC";
			} else if(orderDirection == "D" || orderDirection == "DESC") {
				orderDirection = "DESC";
			} else {
				orderDirection = "";
			}
			if(orderDirection != "") {
				ordertStruct.property = orderProperty;
				ordertStruct.direction = orderDirection;
				if(isDefined("arguments.position") && arguments.position < arrayLen(variables.orders)) {
					arrayInsertAt(variables.orders, ordertStruct, arguments.propertyOrder);
				} else {
					arrayAppend(variables.orders, Duplicate(ordertStruct));
				}
			}
		}
	}
	
	public void function addKeywordProperty(required string rawProperty, required numeric weight) {
		var keywordProperty = getValidHQLProperty(arguments.rawProperty);
		if(keywordProperty != "" && isNumeric(arguments.weight)) {
			if(structKeyExists(variables.keywordProperties, keywordProperty)) {
				variables.keywordProperties[keywordProperty] = arguments.weight;
			} else {
				structInsert(variables.keywordProperties, keywordProperty, arguments.weight);
			}
		}
	}
	
	public void function applyRC(required struct rc) {
		for(i in arguments.rc) {
			if(findNoCase("F_",i)) {
				addFilter(rawProperty=ReplaceNoCase(i,"F_", ""), value=arguments.rc[i]);
			} else if(findNoCase("R_",i)) {
				addRange(rawProperty=ReplaceNoCase(i,"R_", ""), value=arguments.rc[i]);
			} else if(findNoCase("E_Show",i) || findNoCase("P_Show",i)) {
				if(isNumeric(arguments.rc[i])){
					setEntityShow(arguments.rc[i]);
				}
			} else if(findNoCase("E_Start",i)) {
				if(isNumeric(arguments.rc[i])){
					setEntityStart(arguments.rc[i]);
				}
			} else if(findNoCase("P_Current", i)){
				if(isNumeric(arguments.rc[i])){
					setCurrentPage(arguments.rc[i]);
				}
			} else if(findNoCase("OrderBy",i)) {
				for(var ii=1; ii <= listLen(arguments.rc[i], "^"); ii++ ) {
					addOrder(orderStatement=listGetAt(arguments.rc[i], ii, "^"));
				}
			}
			
		}
		if(isDefined("rc.Keyword")){
			var KeywordList = Replace(arguments.rc.Keyword," ","^","all");
			KeywordList = Replace(KeywordList,"%20","^","all");
			KeywordList = Replace(KeywordList,"+","^","all");
			KeywordList = Replace(KeywordList,"'","","all");
			KeywordList = Replace(KeywordList,"-","","all");
			for(var i=1; i <= listLen(KeywordList, "^"); i++) {
				arrayAppend(variables.Keywords, listGetAt(KeywordList, i, "^"));
			}
		}
	}
	
	
	public struct function getEntityMetaData(required string entityName) {
		if(!structKeyExists(variables.entityMetaData, arguments.entityName)) {
			variables.entityMetaData[arguments.entityName] = getMetadata(entityNew("#arguments.EntityName#"));
		}
		return variables.entityMetaData[arguments.entityName];
	}
	
	private string function getValidHQLProperty(required string rawProperty) {
		var returnProperty = "";
		var entityPropertyArray = ListToArray(arguments.rawProperty, "_");
		var currentEntityName = getEntityName();
		
		for(var i=1; i <= arrayLen(entityPropertyArray); i++){
			var entityProperty = getValidEntityProperty(entityPropertyArray[i], currentEntityName);
			if(entityProperty != ""){
				if(i==1){
					returnProperty &= "a#currentEntityName#.#entityProperty#";
				} else {
					returnProperty &= ".#entityProperty#";
				}
				currentEntityName = "#entityProperty#";
			} else {
				returnProperty = "";
			}
		}
		return returnProperty;
	}
			
	private string function getValidHQLPropertyValue(required string rawProperty, required any value) {
		var returnValue = "";
		var entityPropertyArray = ListToArray(arguments.rawProperty, "_");
		var currentEntityName = getEntityName();
		
		for(var i=1; i <= arrayLen(entityPropertyArray); i++){
			var entityProperty = getValidEntityProperty(entityPropertyArray[i], currentEntityName);
			if(entityProperty != ""){
				if(i == arrayLen(entityPropertyArray)) {
					returnValue = getValidEntityPropertyValue(entityProperty, arguments.value, currentEntityName);
				} else {
					currentEntityName = "#entityProperty#";
				}
			}
		}
		return returnValue;
	}
	
	private string function getValidEntityProperty(required string rawProperty, entityName) {
		var returnProperty = "";
		var entityProperties = getEntityMetaData(entityName=arguments.entityName).properties;
		
		for(var i=1; i <= arrayLen(entityProperties); i++){
			if (entityProperties[i].name == arguments.rawProperty) {
				returnProperty = entityProperties[i].name;
				break;
			}
		}
		return returnProperty;
	}
	
	private string function getValidEntityPropertyValue(required string rawProperty, required string value, entityName) {
		var returnValue = "";
		var entityProperties = getEntityMetaData(entityName=arguments.entityName).properties;
		
		for(var i=1; i <= arrayLen(entityProperties); i++){
			if (entityProperties[i].name == arguments.rawProperty) {
				var thisProperty = entityProperties[i];
				if(isDefined("thisProperty.type")) {
					if(entityProperties[i].type == "string") {
						returnValue = arguments.value;
					} else if (entityProperties[i].type == "numeric" && isNumeric(arguments.value)) {
						returnValue = arguments.value;
					} else if (entityProperties[i].type == "boolean" && (arguments.value == 1 || arguments.value == true || arguments.value == "yes")) {
						returnValue = 1;
					} else if (entityProperties[i].type == "boolean" && (arguments.value == 0 || arguments.value == false || arguments.value == "no")) {
						returnValue = 0;
					}
				} else {
					returnValue = arguments.value;
				}
				break;
			}
		}
		return returnValue;
	}
	
	public any function getHQLWhereParams() {
		return variables.HQLWhereParams;
	}
	
	public string function getHQLSelect () {
		var returnSelect = "";
		var currentSelect = 0;
		if(structCount(variables.selects)) {
			returnSelect = "SELECT ";
			for(select in variables.selects) {
				currentSelect = currentSelect + 1;
				returnSelect &= "#select# as '#variables.selects[select]#'";
				if(currentSelect < structCount(variables.selects)) {
					returnSelect &= ", ";
				}
			}
		}
		
		return returnSelect;
	}
	
	public string function getHQLWhereOrder(boolean suppressWhere) {
		var returnWhereOrder = "";
		
		// Check to see if any Filters, Ranges or Keyword requirements exist.  If not, don't create a where
		if(structCount(variables.Filters) || structCount(variables.Ranges) || (arrayLen(variables.Keywords) && structCount(variables.keywordProperties))) {
			
			var currentFilter = 0;
			var currentFilterValue = 0;
			var currentRange = 0;
			var currentKeywordProperty = 0;
			var currentKeyword = 0;
			
			if(isDefined("arguments.suppressWhere") && arguments.suppressWhere) {
				returnWhereOrder = "AND";
			} else {
				returnWhereOrder = "WHERE";
			}
			
			// Add any filters to the returnWhereOrder
			for(filter in variables.filters) {
				currentFilter = currentFilter + 1;
				currentFilterValue = 0;
				
				for(var i=1; i <= listLen(variables.filters[filter], "^"); i++) {
				
					var filterValue = listGetAt(variables.filters[filter], i, "^");
					currentFilterValue = currentFilterValue + 1;
				
					if(currentFilter > 1 && currentFilterValue == 1) {
						returnWhereOrder &= " AND (";
					} else if (currentFilterValue == 1) {
						returnWhereOrder &= " (";
					} else if (currentFilterValue > 1) {
						returnWhereOrder &= " OR ";
					}
				
					returnWhereOrder &= "#filter# = :F_#currentFilter#_#i#";
					variables.HQLWhereParams["F_#currentFilter#_#i#"] = filterValue;
					
					if (currentFilterValue == listLen(variables.filters[filter], "^")) {
						returnWhereOrder &= ")";
					}
				}
			}
			
			// Add Keywords to returnWhereOrder
			if(arrayLen(variables.keywords)) {
				for(keywordProperty in variables.keywordProperties) {
					currentKeywordProperty = currentKeywordProperty + 1;
					currentKeyword = 0;
					
					if(currentKeywordProperty == 1 && currentFilter > 0) {
						returnWhereOrder &= " AND (";
					} else if (currentKeywordProperty == 1 && currentFilter == 0) {
						returnWhereOrder &= " (";
					} 
					
					for(var i=1; i <= arrayLen(variables.keywords); i++) {
						currentKeyword = currentKeyword + 1;
						if (currentKeyword > 1 or currentKeywordProperty > 1) {
							returnWhereOrder &= " OR ";
						}
						returnWhereOrder &= "#keywordProperty# LIKE :K_#i#";
						variables.HQLWhereParams["K_#i#"] = "%#variables.keywords[i]#%";
					}
					
					if (currentKeywordProperty == structCount(variables.keywordProperties)) {
						returnWhereOrder &= ")";
					}
				}
			}
			
			// Add any ranges to returnWhereOrder
			for(range in variables.ranges) {
				if(Find("^", variables.ranges[range])) {
					var lowerRange = Left(variables.ranges[range], Find("^", variables.ranges[range])-1);
					var upperRange = Right(variables.ranges[range], Len(variables.ranges[range]) - Find("^", variables.ranges[range]));
					currentRange = currentRange + 1;
					if(currentRange > 1 || currentFilter > 0 || currentKeywordProperty > 0) {
						returnWhereOrder &= " AND";
					}
					returnWhereOrder &= " (#range# >= :RL_#currentRange# and #range# <= :RU_#currentRange#)";
					variables.HQLWhereParams["RL_#currentRange#"] = lowerRange;
					variables.HQLWhereParams["RU_#currentRange#"] = upperRange;
				}
			}
		}
		
		// Add Order to returnWhereOrder
		if(arrayLen(variables.orders)) {
			returnWhereOrder &= " ORDER BY ";
			for(var i=1; i <= arrayLen(variables.orders); i++) {
				returnWhereOrder &= " #variables.orders[i].property# #variables.orders[i].direction#";
				if(i < arrayLen(variables.orders)) {
					returnWhereOrder &= ",";
				}
			}
		}
		
		return returnWhereOrder;
	}

	public void function setRecords(required any records) {
		variables.records = arrayNew(1);
		
		if(isArray(arguments.records)) {
			variables.records = arguments.records;
		} else if (isQuery(arguments.records)) {
			for(var i=1; i <= arguments.records.recordcount; i++) {
				var entity = entityNew(getEntityName());
				entity.set(arguments.records[i]);
				arrayAppend(variables.records, entity);
			}
		}
		
		// Apply Search Score to Entites
		if(arrayLen(variables.keywords)) {
			applySearchScore();
		}
	}
	
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
	
	private void function fillFromDefaultHQL(boolean returnEntities=true) {
		var fillTimeStart = getTickCount();
		if(!returnEntities && structCount(variables.selects)) {
			var HQL = "#getHQLSelect()# from #getEntityName()# a#getEntityName()# #getHQLWhereOrder()#";
		} else  {
			var HQL = " from #getEntityName()# a#getEntityName()# #getHQLWhereOrder()#";
		}
		setRecords(ormExecuteQuery(HQL, getHQLWhereParams(), false, {ignoreCase="true"}));
		setFillTime(getTickCount() - fillTimeStart);
	}
	
	public array function getEntityArray(boolean refresh=false) {
		if(!isDefined("variables.entityArray") || arrayLen(variables.entityArray) == 0 || arguments.refresh == true) {
			if(!isDefined("variables.records") || arrayLen(variables.records) == 0){
				fillFromDefaultHQL();
			}
			variables.entityArray = arrayNew(1);
			for(var i=getEntityStart(); i<=getEntityEnd(); i++) {
				arrayAppend(variables.entityArray, variables.records[i]);
			}
		}
		return variables.entityArray;
	}
	
	public array function getRecordsArray(boolean refresh=false) {
		if(!isDefined("variables.recordsArray") || arrayLen(variables.recordsArray) == 0 || arguments.refresh == true) {
			if(!isDefined("variables.records") || arrayLen(variables.records) == 0){
				fillFromDefaultHQL(false);
			}
			variables.entityArray = duplicate(variables.records);
		}
		return variables.entityArray;
	}
	
}