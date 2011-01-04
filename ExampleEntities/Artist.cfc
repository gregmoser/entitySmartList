component persistent="true" entityname="Artist" table="Artists" {
	property name="artistid" type="numeric" generator="increment"; 
    property name="firstname" default=""; 
    property name="lastname" default=""; 
    property name="address" default=""; 
    property name="city" default="";
    property name="state" default="";
    property name="postalcode" default=""; 
    property name="email" default="";
    property name="phone" default=""; 
    property name="fax" default="";
    property name="thepassword";
	
	property name="art" type="array" cfc="Art" fkcolumn="artistid" fieldtype="one-to-many" cascade="all";
	
	property name="searchScore" persistent="false";

}