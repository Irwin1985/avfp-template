/*

   mvc.js
   Helper functions for the MVC REST Service
   
   Author: V. Espina
   Date: Jul 2014
   
   
   NOI Quality Software - 2014
   
   
*/


// Global var
var mvc = new mvcHelper();



// mvcHelper (Class)
// Helper class for MVC REST Service access
//
function mvcHelper(baseUrl, targetId) {

 this.version = "1.0";
 this.baseUrl = baseUrl;
 this.targetId = targetId;
 this.cache = new mvcCache();
 this.trace = false;

 this.view = null;              // current view
 this.lastView = null;          // last view
 this.controller = null;        // current controller
 this.loadViewCallback = null;  // Callback function for loadView
 this.loadLastResult = null;    // Result of the last loadView call
 this.cached = false;           // Indicates if last loaded view were cached or not
 

  // loadView (Method)
  // Load a given view from server (or the cache) and show it
  // on the configured target element
  //
  // view: view name
  // callback: (optional) callback function
  //
  this.loadView = function(view, callback) {
 
     if (mvc.trace) console.log("[mvc.loadview] Loading " + view);

	   // Unload current view
	   if (mvc.view) {
      mvc.lastView = mvc.view;
      mvc.disposeCurrentView();
     }
	   
	   // Load the new view	   
     mvc.cached = false;
	   if (mvc.cache.exists(view)) {
       if (mvc.trace) console.log("[mvc.loadview] Cached!");
       mvc.cached = true;
		   mvc.loadViewUI(view, mvc.cache.get(view));
       mvc.loadViewController(view, callback);
	   } else {
		   mvc.requestViewFromServer(view, callback);
	   } 
 
  }


  // Back (Method)
  // Go back to the previous view
  //
  this.back = function(callback) {
    if (!mvc.lastView) return;
    mvc.loadView(mvc.lastView, function() {
      mvc.lastView = null;
      if (callback) callback();      
    });
  }


  // reloadCurrentView (Method)
  // Reload current view from server
  //
  this.reloadCurrentView = function(callback) {
     if (!mvc.view) return;
     
     var currentView = mvc.view;

     mvc.disposeCurrentView();
     mvc.cached = false;
     mvc.requestViewFromServer(currentView, callback);
  }  


  
  // requestViewFromServer (Method)
  // Request a view from the server, either because is the first time the view
  // is requested or because the cached version has expired
  //
  this.requestViewFromServer = function(viewName, callback) {

     if (mvc.trace) console.log("[mvc.requestViewFromServer] " + this.baseUrl + viewName);
	   var request = this.newHttpRequest(this.baseUrl + viewName)
	   request.callback = callback;
	   request.view = viewName;
	   request.dataType = "text";
	   request.targetId = this.targetId;
     this.loadViewCallback = callback;

	   this.httpRequest(request, function(response) {
	      
        if (mvc.trace) console.log("[mvc.requestViewFromServer] Answer: " + response.success);
	      if (response.success) {

            mvc.loadViewUI(response.request.view, response.data);	
            mvc.cache.add(mvc.view, response.data);	     
            var result = {
               loaded: true,
               error: "",
               cached: true
            }       

            /* 
               NOTA IMPORTANTE
               Si la vista es devuelta por el servidor correctamente, no se invoca
               el callback en este punto, sino que se difiere para el momento en 
               que es cargado el controller asincronamente (ver loadController).
            */
	       
	      } else {
	
    	       mvc.view = response.request.view;
    	       mvc.controller = null;
    	       $(response.request.targetId).html(response.error);
    	
             var result = {
               loaded: false,
               error: response.error,
               cached: false
             }       
    	       if (response.request.callback) response.request.callback(result);
	      }

	      
	   });	  
  }
  
  
  
  // loadViewUI (Method)
  // We update the app UI with the view contents
  //
  this.loadViewUI = function(viewName, viewContent) {

       // Update UI
       var viewUI = $(this.targetId);
       viewUI.html(viewContent);
 
       // Set current view
       mvc.view = viewName;	  
  }


  // loadViewController (Method)
  // Load current view's controller.  This method is called async when 
  // view's controller is loaded from server
  this.loadViewController = function(viewName, callback) {

       // Load view's controller
       if (mvc.trace) console.log("[mvc.loadViewController] View: " + viewName);
       var viewController = viewName + "Controller";
       mvc.controller = new window[viewController]();
       window[viewName] = this.controller;  // Creates a public var with the same name of the controller's class
       
       // Set controller's ui property
       var viewUI = $(mvc.targetId);
       mvc.controller.ui = new mvcUI(viewUI);
      
       // Report back to caller. This allows to add additional functionality
       // to the controller before calling controller's onLoad event
       var result = {
         loaded: true,
         error: null,
         cached: mvc.cached
       }                      
       if (!callback) callback = mvc.loadViewCallback;
       if (callback) callback(result);
   
       // Fire controller's onLoad event
       if (mvc.controller.onLoad) {
          if (mvc.trace) console.log("[mvc.loadViewController] Loaded: " + mvc.controller.loaded);
          mvc.controller.onLoad();
       }
  }
  
  
  
  // disposeCurrentView (Method)
  // Release current view from memory
  //
  this.disposeCurrentView = function() {
  
     if (mvc.trace) console.log("[mvc.disposeCurrentView] Disposing view " + this.view);

     // Clear UI
     $(this.targetId).empty();
  
     // Fire controller's onDispose event
     if (this.controller.onDispose) this.controller.onDispose();
     
     // Unload controller
     window[this.view] = null;
     delete window[this.view];
     this.controller = null

     this.view = null;
  }
 
 
 
 
 
  // newHttpRequest (Method)
  // Returns a request object to be used with
  // httpRequest method
  //
  this.newHttpRequest = function(url, method, data) {
  
    var request = {
      url: url,
      method: ((method) ? method : "GET"),
      data: data,
      callback: null
    }
    
    return request;
  }
  
 
  // httpRequest
  // Send a HTTP request to the server. The request object 
  // should have the following attrs:
  //
  // url: resource to be requested
  // data: data to be sent
  // dataType: data type (defaults to "json")
  // method: request method (defaults to "GET")
  // 
  this.httpRequest = function(request, callback) {
  
    var dataType = ((request.dataType) ? request.dataType : "text");

    $.ajax({
             type: ((request.method) ? request.method : "GET"),
             url: request.url,
             data: "data=" + JSON.stringify(request.data),
             contentType: ((request.contentType) ? request.contentType : "application/x-www-form-urlencoded"),
             crossDomain: true,
             dataType: dataType,
             cache: false,

             
             success: function (result, status, jqXHR) {
                 var response = {
                  success: true,
                  request: request,
                  statusCode: status,
                  data: result
                 }

                 if (callback) callback(response);
             },

             error: function (jqXHR, status) {
                 response = {
                  sucess: false,
                  request: request,
                  status: status,
                  statusCode: jqXHR.status,
                  statusText: jqXHR.statusText,
                  error: jqXHR.responseText
                 };
                 if (mvc.trace) {
                  console.log(request);
                  console.log(jqXHR);
                }
                 if (callback) callback(response);
             }
          });
          
  }
 
 
}



function mvcUI(root) {

  this.content = root;
  

  // getSelector (Method)
  // Returns a jQuery valid selector, following
  // this rules:
  //
  // * If selector starts with ".", returns ".selector"
  // * If selector starts with "!", returns "selector"
  // * If selector starts with "#", returns "#selector"
  // * Otherwise, returns "#selector"
  //
  this.getSelector = function(selector) {
    if (selector[0] == ".") return selector;
    if (selector[0] == "#") return selector;
    if (selector[1] == "!") return selector.substr(selector,1,selector.length-1);
    return "#" + selector;
  }


  // item (Method)
  // Locates an element or group of element inside view's content, using jQuery
  //
  this.item = function(selector) {
     selector = this.getSelector(selector);
     var result = this.content.find(selector);
     if (result.length == 0) result = null;
     return result;
  }
  
  this.setValue = function(id, value) {
     var element = this.item("#" + id);
     var tag = element.prop("tagName");
     switch (tag) {
        case "INPUT":
        case "SELECT":
          element.val(value);
          break;

        default:
          element.html(value);  
     }     
  }

  // show (Method)
  // Makes a DOM element visible
  //
  this.show = function(selector) {
    var target = this.item(selector);
    if (!target) console.log(selector);
    this.item(selector).removeClass("hide").show();
  }


  // hide (Method)
  // Makes a DOM element invisible
  //
  this.hide = function(selector) {
    var target = this.item(selector);
    if (!target) console.log(selector);    
    this.item(selector).removeClass("hide").hide();
  }


}



// mvcCache
// Allows to cache previously loaded content
//
function mvcCache() {
	
	this.active = true;
	this.lifespan = 30;  // Time (in minutes) for a cached content be considered "expired".
	
	var repository = {};
	this.size = 0;      // Number of elements in the cache
	

    // newCacheEntry (Method)
    // Returns a new entry for the cache
    this.newCacheEntry = function(id, content, lifespan) {
      var entry = {
		           id: id,
		           added: new Date(),
		           content: content,
		           lifespan: lifespan,
		           life: function() {
		              var now = new Date();
			          return ((now - this.added) / (60*1000));
		           },
		           expired: function() {
			          return (this.life() > this.lifespan);
		           }
		         };
		            
	  return entry;	         
    }
    
    
    // add (Method)
    // Add content to the cache	
	this.add = function(id, content) {
	    if (!this.active) return;
		repository[id] = this.newCacheEntry(id, content, this.lifespan);
		this.size++;
	}
	
	// exists (Method)
	// Check if a specific content has been cached
	this.exists = function(id, log) {
	    var entry = this.newCacheEntry(null, null, -1);
	    if (id in repository) entry = repository[id];
	    if (log) {
	      console.log(repository);
	      console.log(entry);
	      console.log("life: " + entry.life());
	      console.log("expired: " + entry.expired().toString());	    
	    }
		return (!entry.expired());
	}
	
	// get (Method)
	// Returns a cached content
	this.get = function(id) {
	    var entry = repository[id];
		return entry.content;
	}
	
	// clear (Method)
	// Clear the cache
	this.clear = function() {
		repository = {};
		this.size = 0;
	}
	
}

