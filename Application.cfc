component {
	
	this.ormEnabled = true;
	this.ormSettings.datasource = "cfartgallery";
	this.ormSettings.dbcreate = "none";
	
	public void function onRequestStart() {
		param name="url.reload" default="false";
		if(url.reload){
			ormReload();
			writeDump("Reloaded");
		}
	}
	
	public void function onApplicationStart() {
		
	}
}