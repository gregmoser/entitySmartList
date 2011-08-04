component {
	
	this.ormEnabled = true;
	this.ormSettings.datasource = "cfartgallery";
	this.ormSettings.dbcreate = "none";
	
	public void function onRequestStart() {
		if(structKeyExists(url, "reload")) {
			applicationStop();
		}
	}
	
	public void function onApplicationStart() {
		
	}
}