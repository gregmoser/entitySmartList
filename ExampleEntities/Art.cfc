component persistent="true" entityname="Art" accessors="true" table="Art" {
	property name="artid" type="numeric" generator="increment"; 
     
    property name="artname" default=""; 
    property name="description" default=""; 
    property name="price" default=0;
    property name="issold" default=0;
	
	property name="artist" cfc="Artist" fkcolumn="artistid" fieldtype="many-to-one" missingRowIgnored="true" inverse="true" cascade="all";
	
	property name="searchScore" persistent="false";
	
	public any function getArtist(){
		if(!isDefined("variables.artist")){
			variables.artist = entityNew("Artist");
		}
		return variables.artist;
	}
}