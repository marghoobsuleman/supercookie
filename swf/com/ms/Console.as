package com.ms {	
	// Filename: console.as
	// Desc: call javascript console
	// Author: Marghoob Suleman
	// version: 1.0
	// Date: 20 July 2012	
	import flash.external.ExternalInterface;	
	public class Console {

		public function Console() {
			// constructor code
		}
		public static function log(param:*):void {
			ExternalInterface.call("console.log", param);
		}
		public static function debug(param:*):void {
			ExternalInterface.call("console.debug", param);
		}
		public static function winTrace(msg:String):void { //This will work if avaialble
			ExternalInterface.call("trace", "Flash Trace->  "+msg);
		}
	}
	
}
