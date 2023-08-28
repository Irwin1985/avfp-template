* AVFP Delegate Class
* Use this program to write code for specific events
*

DEFINE CLASS Delegate AS avfpDelegate

 lTracing = .F.
 lLocalMode = .T. 
 cMainFoo = "This is a property on the main delegate"
 cFoo = "This property gets shadowed by the local delegate"
 lTraceRequest = .F.

 PROCEDURE mainFoo
  RETURN "This came from the main delegate"
 ENDPROC
  

 * onInitDataSession
 * Open DBF tables, create data connections, etc
 PROCEDURE onInitDataSession

 
 * onLoadLibraries
 * Load function libraries into memory, ex:
 *
 * THIS.loadLib("mylib.prg")
 *
 PROCEDURE onLoadLibraries

 
 * onBeforeHandleRequest
 * Put code to be run before the request is handle
 PROCEDURE onBeforeHandleRequest
   * MVC REST Service Configuration
  THIS.setPref("mvc.urls.models", AVUrl("/mvc"))
  THIS.setPref("mvc.urls.views", THIS.Prefs("mvc.urls.models"))
  THIS.setPref("mvc.urls.controllers", THIS.Prefs("mvc.urls.models"))
 ENDPROC

 

 * onAfterHandleRequest
 * Use this event to alter the HTML to be returned to the client
 PROCEDURE onAfterHandleRequest(pcHTMLOut)
  RETURN pcHTMLOut
 ENDPROC
 

 * onCloseDataSession
 * Use this event to close open tables or connections
 PROCEDURE onCloseDataSession
 
 
 * onGarbageCollect
 * Release any other resource
 PROCEDURE onGarbageCollect
 
 
 * onRenderError
 * Format the UI used to show an error message
 PROCEDURE onRenderError(pcText)
  RETURN pcText
 ENDPROC


ENDDEFINE







