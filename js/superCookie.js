/**************************/
// SuperCookie - SuperCookie.js
// author: Marghoob Suleman
// Date: 11 Nov, 2012
// Version: 1.2
// Revision: 4
/*
*/
function SuperCookie(obj) {
	// Check HTML 5 Cookie
	// If Yes - use it
	// If No or cross domain or extended- createFlashCookie
	var settings = {swfURL:"swf/supercookie.swf", expressInstaller:"js/swfobject/expressInstall.swf", cookieName:window.location.host, crossDomain:false, extended:false, onReady:[], onError:null};
	var internal = {flashId:"msCookieswf", divid:"msCookieDiv"};
	var mergeProp = function(source, target) {
		for(var i in source) {
			source[i] = (target && target[i]) || source[i];
		};
		return source;
	};	
	var css = "position:absolute;border:2px solid #c3c3c3;top:10px;left:10px;display:block; padding:10px; visibility:visible; background:#fff";
	settings = mergeProp(settings, obj); //merge it
	settings.crossDomain = (settings.extended === true) ? true : settings.crossDomain;
	var thisClass = this;	
	var ua = navigator.userAgent, isIE = ua.match(/msie/i),	win = window, doc = document, isFlash=false;
	var cookieObj;
	this.isReady = false;
	this.remainingSpace; //Return the remaining storage space in bytes, for the storage object - not implemented in this version
	this.length = function() { //Returns the length of number of items	
		return (isFlash===true) ? getLength() : cookieObj.length;
	};
	this.getItem = function(key) { //Get the value of item passed as key to the method
		var val;
		try {
			val = cookieObj.getItem(key);
		} catch(e) {
			thisClass.on_error(e);
		};
		return val;
	};
	this.clear = function()  {//Remove all the key/value pairs from DOM Storage
		try {
			cookieObj.clear();
		} catch(e) {
			thisClass.on_error(e);
		};
	};
	this.key = function(index) { //Retrieves the key at specified index
		var key;
		try {
			key = cookieObj.key(index);
		} catch(e) {
			thisClass.on_error(e);
		};
		return key;
	};
	this.removeItem = function(key) { //Remove the key/value pair from DOM Storage		
		try {
			cookieObj.removeItem(key);
		} catch(e) {
			thisClass.on_error(e);
		};
	};
	this.setItem = function(key, value) { //Sets a key/value pair
		try {
			cookieObj.setItem(key, value);
		} catch(e) {			
			if(isFlash===false) {
				thisClass.on_error(e.message, true);
			};
		};
	};		
	/***************** for flash ***************************/
	this.on_ready = function(fn) {
		var fashid = internal.flashId;
		cookieObj = (isIE) ? win[fashid] : doc[fashid];
		afterInit();
	};
	this.on_error = function(msg, showError) {
		var divid = 'msCrossDomainDivError';
		if(showError==true) {			
			var div = doc.getElementById(divid);
			if(!div) {
				div = doc.createElement("div");
				div.id = divid;
				document.body.appendChild(div);
			};
			div.style.cssText = css;
			div.innerHTML = msg + " <a href='javascript:void(0)' onclick='document.getElementById(\""+divid+"\").style.display=\"none\"'>Close</a>";
		};
		//console.log(msg);
		if(settings.onError != null) {
			settings.onError.apply(this, arguments);
		};
	};
	this.show_panel = function() {
		var fls = doc.getElementById(internal.flashId);
		fls.style.cssText = css;
		fls.style.padding = 0;
	};
	this.hide_panel = function() {
		var fls = doc.getElementById(internal.flashId);
		fls.style.top = "-218px";
	};
	/********************************************/
	this.onError = function(fn) {		
		if(typeof fn == "function") {
			settings.onError = fn;
		};
	};
	this.onReady = function(fn) {
		settings.onReady.push(fn);
	};
	//fallback - create flash cookie
	var createFlash = function() {
		var swfUrl = settings.swfURL;
		isFlash = true;
		var fashid = internal.flashId;
		var divid = internal.divid;
		var flashvars = {baseURL:window.location.host, cookieName:settings.cookieName};
		var params = {salign:"center", AllowScriptAccess:"always", menu:"false", wmode:"transparent"};
		var attributes = {id:fashid, name:fashid, style:"position:absolute;"};
		var fpversion = "10.3";
		swfobject.embedSWF(swfUrl, divid, "215", "138", fpversion, settings.expressInstaller, flashvars, params, attributes,function(res) {						
			if(res.success===false) {
				var fls = document.getElementById(divid);
				var msg = "A compatibale flash player "+fpversion+" is required for the superCookie...";
				thisClass.on_error(msg);
				fls.style.cssText = css;
				fls.innerHTML = msg + "<a href='javascript:void(0)' onclick='document.getElementById(\""+divid+"\").style.display=\"none\"'>Close</a>";
			} else {
				thisClass.hide_panel();
			};
		});	
	};
	var getLength = function() {
		var val;
		try {
			val = (isFlash==true) ? cookieObj.getLength() : cookieObj.length;
		} catch(e) {
			thisClass.on_error(e);
		};
		return val;
	};
	var afterInit = function() {
		thisClass.isReady = true;
		if(settings.onReady.length>0) {
			for(var i=0;i<settings.onReady.length;i++) {
				var fn = settings.onReady[i];
				fn.apply(thisClass, arguments);
			};
		};
		settings.onReady = [];
	};
	var init = function() {	
		if(window.localStorage && settings.crossDomain===false) {
			cookieObj = window.localStorage;
			afterInit();
		} else {
			createFlash(); //afterInit will be called via flash
		};
	};
	init();
};
try {
	var superCookieSetup = superCookieSetup || {};
	window.superCookie = new SuperCookie(superCookieSetup); //make it static
} catch(e) {
	alert(e);
};
/*
//usage
if(superCookie.isReady) {
	superCookie.setItem("test", "Its working... ");
	console.log(superCookie.getItem("test"));
} else {
	superCookie.onReady(function() {
		superCookie.setItem("test", "Cookie item has been added on "+window.location.host);
		console.log(superCookie.getItem("test"));
	})
}
*/