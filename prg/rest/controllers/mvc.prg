* MVC.PRG
* MVC REST Servioce
*
* This service responds only to GET requests (getAction). 
*
 
DEFINE CLASS mvcController AS restController
 *
 Caption = "MVC"
 Description = "MVC REST Controller"
 Version = "1.0"
 Author = "Victor Espina"

 cResponse = ""           && Response to be returned from internal methods

 modelsUrl = ""        && Location of model files       (ex: /mvc/models)
 viewsUrl = ""         && Location of view files        (ex: /mvc/views)
 controllersUrl = ""   && Location of controller files  (ex: /mvc/controllers)
 
 PROCEDURE Init
  DODEFAULT()
 ENDPROC
 
 PROCEDURE collectGarbage
  DODEFAULT()
 ENDPROC
 
  
 PROCEDURE beforeHandleAction(pcAction)
 
  THIS.modelsUrl = oAVFP.oPrefs.get("mvc.urls.models")
  THIS.viewsUrl = oAVFP.oPrefs.get("mvc.urls.views")
  THIS.controllersUrl = oAVFP.oPrefs.get("mvc.urls.controllers")

  IF INLIST(LOWER(pcAction),"infoaction")
   RETURN
  ENDIF
    
  IF ISNULL(THIS.modelsUrl) OR ISNULL(THIS.viewsUrl) OR ISNULL(THIS.controllersUrl)
   AVError("The MVC service is not fully configured ", ,THIS.Description)
  ENDIF

  THIS.checkUrl(THIS.modelsUrl)
  THIS.checkUrl(THIS.viewsUrl)
  THIS.checkUrl(THIS.controllersUrl)
    
 ENDPROC
 
 
 HIDDEN PROCEDURE checkUrl(pcUrl)
  LOCAL cFolder
  cFolder = oAVFP.translateUrl(pcUrl)
  IF !DIRECTORY(cFolder)
   AVError(AVFormat("The folder {0} is missing", cFolder), ,THIS.Description)  
  ENDIF
 ENDPROC
 
  
 ******************************************************
 **
 **      S E R V I C E     I N T E R F A C E
 **
 ******************************************************
 
 * infoAction
 * Return information about the service
 *
 PROCEDURE infoAction
  LOCAL cHTML
  TEXT TO cHTML NOSHOW TEXTMERGE
   <h3><<THIS.Caption>> <<THIS.Version>></h3>
   <<THIS.Description>><br>
   <br>
   <h4>Configuration</h4>
   <ul>
     <li>Local folder: <b><<THIS.localFolder>></b>
     <li>Local delegate: <b><<oAVFP.oDelegate.lHasDelegate>></b>
     <li>Models: <b><<EVL(THIS.modelsUrl,"(not configured)")>></b>
     <li>Views: <b><<EVL(THIS.viewsUrl,"(not configured)")>></b>
     <li>Controllers: <b><<EVL(THIS.controllersUrl,"(not configured)")>></b>
   </ul>
  ENDTEXT
  RETURN cHTML
 ENDPROC
 
  
 * getAction
 * Main entry point of the service. The last parameter passed to the request is considered
 * as the name of the view file to be returned. Any previous parameter will be considered
 * as a folder, ex:
 *
 * GET /views/newcustomer                   --> /views/newcustomer.avfp
 * GET /views/customers/new.avfp            --> /views/customers/new.avfp 
 * GET /views/customers/crud/new.avfp       --> /views/customers/crud/new.avfp
 *
 * If a file with the same name of the view and js extension is found at the controllers folder, the file will be included
 * at the end of the view using a <script> tag.
 *
 PROCEDURE getAction
 
  * Get the full view file name and location
  LOCAL cViewName,cViewFile, cViewPath, cViewController
  cViewPath = ""
  cViewName = THIS.Params[THIS.Params.Count]
  IF THIS.Params.Count > 1
   LOCAL i
   FOR i = 1 TO THIS.Params.Count - 1
    cViewPath = cViewPath + IIF(i > 1,"/","") + THIS.Params[i]
   ENDFOR
   cViewPath = cViewPath + "/"
  ENDIF
  cViewFile = oAVFP.formatPath(ADDBS(oAVFP.translateUrl(THIS.viewsUrl)) + cViewPath + cViewName + ".avfp")

  IF !FILE(cViewFile)
   AVError(AVFormat("The view '{0}' does not exists", cViewName), cViewFile, "infoAction")
   RETURN ""
  ENDIF
 
  * Load & parse view content 
  LOCAL cHTML
  cHTML = THIS.loadPage(cViewFile)
  
  * Check for views controller
  cViewController = FORCEPATH(FORCEEXT(cViewFile, "js"), oAVFP.translateUrl(THIS.controllersUrl))
  IF FILE(cViewController) 
   cViewController = oAVFP.formatPath(THIS.controllersUrl + "/" + cViewPath + cViewName + ".js")
   cHTML = cHTML + CRLF + ;
           AVFormat("<script>"+;
                    "$.getScript( '{0}' )" + ;
                    " .done(function( script, textStatus ) {"+;
                    "     mvc.loadViewController('{1}');"+;
                    "  })"+;
                    " .fail(function( jqxhr, settings, exception ) {"+;
                    "     if (settings == 'parsererror') { "+ ;
                    "       alert('File {0} has some errors: \n\r\n\r' + exception);" + ;
                    "     } else {" + ;
                    "     console.log(jqxhr); " + ;
                    "     console.log(settings); " + ;
                    "     console.log(exception); " + ;                    
                    "       alert('File {0} could not be loaded');" + ;
                    "     }" + ;
                    "  });"+;
                    "</script>", cViewController, cViewName) 
  ELSE
   cHTML = cHTML + CRLF + ;
           AVFormat("<script>console.log('{0}');</script>", "File " + cViewController + " is missing")
                     
  ENDIF
      
  RETURN cHTML
 ENDPROC
 
 
 
 
ENDDEFINE


