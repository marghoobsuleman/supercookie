package  {
	import flash.display.LoaderInfo
	import flash.display.MovieClip;
	import flash.events.NetStatusEvent;
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
	import flash.external.ExternalInterface;
	import com.ms.Console;
	import flash.system.Security;
	import flash.net.URLLoader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.events.ContextMenuEvent;
	import flash.net.navigateToURL;

	public class SuperCookie extends MovieClip {
		private var _length:Number = 0;
		private var _cookieName:String;
		private var _cookieObj:SharedObject;
		private var _totalCount:Number = 0;
		private var _swfLoaderInfo:Array;
		private var _isAllowed:Boolean = true;		
		private var _saveInterval;
		public function SuperCookie() {					
			if (stage) {
				if(ExternalInterface.available) {
					addEventsCallback();					
					var swfURL = loaderInfo.url;
					swfURL = swfURL.split("//");
					_swfLoaderInfo = swfURL;
					//trace(_swfLoaderInfo);
					swfURL = swfURL[1].toString().split("/");
					swfURL = swfURL[0];				
					_swfLoaderInfo.push(swfURL);
					var baseURL:String = loaderInfo.parameters.baseURL;	
					if(swfURL != baseURL) {
						addAccess();
					} else {
						init();
					}					
				} else {
					trace("ExternalInterface.available is false");					
					status_txt.text = "ExternalInterface is not available...";
				}
				this.addCopyright();
			}			
		}	
		private function init() {
			var cookieName:String = loaderInfo.parameters.cookieName;
			if(cookieName) {
				this._cookieName = cookieName.replace(/\./g, "");
				
				try {					
					if(_isAllowed===false) {
						this.checkIsAllowed();
					} 
					_cookieObj = SharedObject.getLocal(this._cookieName);
					
				} catch(e) {
					//silent - stack overflow error will come
				}
			}											
			ExternalInterface.call("superCookie.on_ready");
		}
		//crossdomain.xml is not working by loadPolicyFile - this is hack. Will check on next version
		private function addAccess() {
			var xmlLoader:URLLoader = new URLLoader();			
			xmlLoader.addEventListener(Event.COMPLETE, function(e) {
									   XML.ignoreWhitespace = true; 
									   var domains:XML = new XML(e.target.data);
									   //trace(songs["allow-access-from"].length());
									    var i:Number;
										_isAllowed = false;
										var baseURL:String = loaderInfo.parameters.baseURL;	
										for (i=0; i < domains["allow-access-from"].length(); i++) {
											var dname = domains["allow-access-from"][i].@domain;
											Security.allowDomain(dname);
											trace("dname "+dname)
											if(dname=="*" || dname.toLowerCase()==baseURL.toLowerCase()) { //base URL
												_isAllowed = true;
											}
										}
										
									   init();
									   });
			
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e) {
									  // trace(e.type)
										ExternalInterface.call("superCookie.on_error", "Cross domain file is missing...", true);   
									   });
			if(_swfLoaderInfo[0].toString().indexOf("file:")>=0) {
				ExternalInterface.call("superCookie.on_error", "Cross domain needs at least a domain :)");
			} else {
				xmlLoader.load(new URLRequest(_swfLoaderInfo[0]+"//"+_swfLoaderInfo[_swfLoaderInfo.length-1]+"/crossdomain.xml"));
			}
			
		}
		private function checkIsAllowed() {
			if(_isAllowed===false) {
				trace("*** Security Sandbox Violation ***")
				ExternalInterface.call("superCookie.on_error", "*** Security Sandbox Violation ***", true);   
			}			
		}
		public function getItem(key:String):* { //Get the value of item passed as key to the method	
				try {
					return _cookieObj.data[key] || undefined;
				} catch(e) {
					trace(e);
				}			
		}
		public function clear():void { //Remove all the key/value pairs 
			_cookieObj.clear()
			updateCount();
		}
		public function key(index:Number):* { //Retrieves the key at specified index
			var all = this.getAll();
			var cnt = 0;
			for(var i in all) {
				if(cnt==index) {
					return i;
				}
				cnt++;
			}
			return null;
		}
		public function updateCount():void {
			var all = this.getAll();
			var cnt = 0;
			for(var i in all) {				
				cnt++;
			}
			_totalCount = cnt;
			ExternalInterface.call("superCookie.updateProp", "length", cnt);
		}
		public function removeItem(key:String):void {  //Remove the key/value pair
			delete _cookieObj.data[key]; 
		}
		public function setItem(key:String, value:*):void { //Sets a key/value pair
			this.saveCookie(key, value);			
		}		
		
		public function get length():Number {
			this.updateCount();
			return _totalCount;
		}
		public function get remainingSpace() { //not implemented
			return 0;
		}
		public function getAll():Object {
			return _cookieObj.data;
		}
		
		public function getLength():Number {
			this.updateCount();
			return _totalCount;
		}
		
		private function addEventsCallback():void {			
			ExternalInterface.addCallback("getItem", getItem);
			ExternalInterface.addCallback("clear", clear);
			ExternalInterface.addCallback("key", key);
			ExternalInterface.addCallback("removeItem", removeItem);
			ExternalInterface.addCallback("setItem", setItem);
			ExternalInterface.addCallback("getLength", getLength);			
		}
		
		/********************** cookie ****************/
		//215 x138 
		public function saveCookie(key:String, val:*) {
			_cookieObj.data[key] = val;
			var flushStatus:String = null;
			if(_saveInterval) {
				clearTimeout(_saveInterval);
			}
			_saveInterval = setTimeout(savenow, 1000);
			function savenow() {
				trace("Saving now");
				try {
					flushStatus = _cookieObj.flush();
				} catch (error:Error) {
					trace("Error...Could not write SharedObject to disk");
					ExternalInterface.call("superCookie.on_error", "Error... Could not write SharedObject to disk", true);
				}
				if (flushStatus != null) {
					switch (flushStatus) {
						case SharedObjectFlushStatus.PENDING:
							trace("show panel");
							ExternalInterface.call("superCookie.show_panel");
							_cookieObj.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
							break;
						case SharedObjectFlushStatus.FLUSHED:							
							//success							
						break;
					}
				}
			}
		}
		
		private function onFlushStatus(event:NetStatusEvent):void {            
            switch (event.info.code) {
                case "SharedObject.Flush.Success":
                	//greate its saved    
					ExternalInterface.call("superCookie.hide_panel");
                break;
                case "SharedObject.Flush.Failed":
                 	//sorry user has denied to save it
					ExternalInterface.call("superCookie.hide_panel");
					ExternalInterface.call("superCookie.on_error", "Sorry, user has denied to save it.", true);
                break;
            }            
            _cookieObj.removeEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
        }
		/********************** copyright ******************/
		private function addCopyright() {
			var cMenu:ContextMenu = new ContextMenu();
			var powered:ContextMenuItem = new ContextMenuItem("Powered by marghoobsuleman.com");			
			var author:ContextMenuItem = new ContextMenuItem("Author: Marghoob Suleman");
			author.enabled = false;						
			cMenu.customItems.push(powered,author);			
			powered.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(evt:ContextMenuEvent) {
								   navigateToURL(new URLRequest("http://www.marghoobsuleman.com"));
								   });			
			cMenu.hideBuiltInItems();
			this.contextMenu = cMenu;			
			
		}

	}	
}
