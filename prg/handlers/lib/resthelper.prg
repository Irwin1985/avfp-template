* restHelper.prg
* Helper class that allow an easy implementation of REST-like calls
* within ActiveVFP
*
* Author : Victor Espina
* Version: 1.0
*
* VERSION HISTORY
*
* DATE        BY      VERS    DESCRIPTION
* =========   ===     ====    =======================================================================================
* Jul 2016    VES     1.3     CORS support. new returnStatusCode and jsonResponse methoda. Minor fixes. Cache support
*                             on returnJSON() method. Url parameters support on GET requests over Data property.
* Aug 2015    VES     1.2     Accept header support
* Aug 2012    CKF     1.1     Custom methods for MVC
* Apr 2012    VES     1.0     Initial version

DEFINE CLASS restHelper AS Custom
 *
 Folders = NULL
 Controllers = NULL
 Version = "1.3"


 * Constructor
 *
 PROCEDURE Init
  *
  THIS.Folders = CREATEOBJECT("Dictionary")
  THIS.Folders.Add("ROOT","")
  THIS.Folders.Add("CONTROLLERS","")

  THIS.Controllers = CREATEOBJECT("Dictionary")
  *
 ENDPROC


 * setFolder
 * Sets a folder location
 *
 PROCEDURE setFolder(pcFolderID, pcFolderPath)
  THIS.Folders.Values[pcFolderId] = ADDBS(CHRTRAN(pcFolderPath,"/","\\"))
 ENDPROC


 * loadControllers
 * Look for controllers in the controllers folder
 *
 PROCEDURE loadControllers
  *
  LOCAL ARRAY aControllers[1]
  LOCAL cPath,cFile,cController,nCount,i
  cPath = THIS.Folders.Values["CONTROLLERS"]
  nCount = ADIR(aControllers, cPath + "*.PRG")
  THIS.Controllers.Clear()
  FOR i = 1 TO nCount
   cFile = ADDBS(cPath) + aControllers[i,1]
   cController = LOWER(JUSTSTEM(cFile))
   THIS.Controllers.Add(cController, cFile)
  ENDFOR
  *
 ENDPROC


 * isREST
 * Check if the given request is a RESTful request. A request is considered
 * a REST-compliant request if:
 *
 * a) Does not contains a file extension
 * b) The URL conforms to the form http://server/resource/
 *
 PROCEDURE isREST(poRequest)
  *
  LOCAL cUri
  IF VARTYPE(poRequest)<>"C"
   cUri = poRequest.serverVariables("SCRIPT_NAME")
  ELSE
   cUri = poREquest
  ENDIF

  * Check for extension
  IF !EMPTY(JUSTEXT(cUri))
   RETURN .F.
  ENDIF

  IF RIGHT(cUri,1) <> "/"
   cBaseUri = cUri + "/"
  ELSE
   cBaseUri = cUri
  ENDIF

  * Check if URI contains a reference to an available resource controller
  LOCAL lHasController,i,cResource,cTestUri
  lHasController = .F.
  FOR i = 1 TO THIS.Controllers.Count
   cResource = THIS.Controllers.Keys[i]
   cTestUri = LOWER(oAVFP.cBaseUrl + "/" + cResource + "/")
   IF LOWER(LEFT(cBaseUri, LEN(cTestUri))) == cTestUri
    lHasController = .T.
    EXIT
   ENDIF
  ENDFOR

  IF NOT lHasController
   RETURN .F.
  ENDIF

  * If we get through here, then the uri MAY be a REST api call
  RETURN .T.
  *
 ENDPROC


 * handleRequest
 * Handle a given HTTP request
 *
 PROCEDURE handleRequest(poRequest, poProps)
  *


  * Analyze the requested URL to obtain:
  * a) VERB
  * b) Resource controller
  * c) Resources parameters
  * d) Request base folder
  * e) Url Parameters (QueryString)
  *
  oAVFP.Log("restHelper.handleRequest: 1")
  LOCAL cUri,cRESTUri,cVerb,cResource,cParams,i,j,cController,cBaseURL,cLocalFolder,cTestUri
  IF VARTYPE(poRequest)<>"C"
   cUri = poRequest.serverVariables("SCRIPT_NAME")
   cVerb = poRequest.serverVariables("REQUEST_METHOD")
  ELSE
   cUri = poRequest
   cVerb = "GET"
  ENDIF
  oAVFP.Log("restHelper.handleRequest: Uri: " + cUri + ", Verb: " + cVerb)

  IF RIGHT(cUri,1) <> "/"
   cUri = cUri + "/"
  ENDIF

  j = 0
  cResource = ""
  cController = ""
  cLocalFolder = ""
  FOR i = 1 TO THIS.Controllers.Count
   cResource = THIS.Controllers.Keys[i]
   cController = THIS.Controllers.Values[i]
   cTestUri = LOWER(oAVFP.cBaseUrl + "/" + cResource + "/")
   IF LOWER(LEFT(cUri,LEN(cTestUri))) == cTestUri
    j = ATC(oAVFP.cBaseUrl + "/" + cResource + "/", cUri)
    EXIT
   ENDIF
  ENDFOR
  IF j = 0   && There is no controller for the specified resource
   oAVFP.Log("restHelper.handleRequest: unhandled resource - error 404")
   oResponse.status = "404 Not Found"
   RETURN "restHelper: unhandled resource on REST call (" + cUri + ")"
  ENDIF

  j = ATC("/" + cResource + "/", cUri)
  cBaseURL = LEFT(cUri, j) + cResource + "/"
  cLocalFolder = oAVFP.translateUrl(LEFT(cUri, j))
  cRESTUri = SUBSTR(cUri,j)  && /server/resource/params --> /resource/params
  cParams = SUBSTR(cRESTUri,LEN(cResource) + 3)
  oAVFP.setPath("local", cLocalFolder)

  *RETURN cResource + " | "  + cUri + " | " + STR(j) + " | " + cBaseURL + " | " + cRESTUri

  * Convert the parameter list to a collection
  LOCAL ARRAY aParams[1]
  LOCAL nCount, cPAram
  LOCAL oParams AS Collection
  nCount = ALINES(aParams, STRT(cParams,"/",CHR(13)+CHR(10)))
  oParams = CREATEOBJECT("Collection")
  FOR EACH cParam IN aParams
   IF !EMPTY(cParam)
    oParams.Add(cParam)
   ENDIF
  ENDFOR

  * Create an instance of the resources controller
  LOCAL oController,cHTMLOut
  IF NOT FILE(cController)
   * Added status code.  -RJC 7/14/2016
   oResponse.status = "404 Not Found"
   RETURN "restHelper: controller file <b>" + cController + "</b> could not be found"
  ENDIF
  oController = oAVFP.New(cResource + "Controller", cController)
  
  
  DO CASE
     CASE cVerb == "GET" AND oPArams.Count = 0
          cAction = "listAction"

     CASE cVerb == "GET" AND oParams.Count > 0
          cAction = LOWER(oParams.Item[1])
          DO CASE
             CASE cAction == "pdi"
                  RETURN oAVFP.pathDebugInfo()

             CASE INLIST(cAction,"info","help")
                  cAction = cAction + "Action"

             CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
                  IF oParams.Count = 1
                   cAction = "getAction"
                  ELSE
                   cAction = "listAction"
                  ENDIF

             OTHERWISE
                  cAction = oParams.Item[1]   && Custom action
          ENDCASE

     CASE cVerb == "POST" AND oParams.Count = 0
          cAction = "addAction"

     CASE (cVerb == "POST" OR cVerb == "PUT") AND oParams.Count > 0
          cAction = LOWER(oParams.Item[1])
          DO CASE
             CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
                  cAction = "updAction"

             OTHERWISE
                  cAction = oParams.Item[1]   && Custom action
          ENDCASE

     CASE cVerb == "DELETE" AND oParams.Count = 0
          cAction = "zapAction"

     CASE cVerb == "DELETE" AND oPArams.Count > 0
          cAction = LOWER(oParams.Item[1])
          DO CASE
             CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
                  cAction = "dropAction"

             OTHERWISE
                  cAction = oParams.Item[1]   && Custom action
          ENDCASE

     OTHERWISE
          cAction = oParams.Item[1]    &&"customAction"
  ENDCASE
  

  * Use the verb + parameter count to deduce the actual action
  * to be invoked on the controller
  *
  *** Modified to add Verb prefix to Action for better controller method separation.  -RJC 7/19/2016
  IF NOT PEMSTATUS(oController, cAction, 5)
    DO CASE
    CASE oParams.Count = 0
      cAction = "List"
    CASE oParams.Count = 1
      cAction = PROPER(oParams.Item[1])
      IF !PEMSTATUS(oController, cVerb+cAction, 5)
        * if its not a method, it must be a parameter to the verb+"Item" method
        cAction = "Item"
      ENDIF
    OTHERWISE
      cAction = PROPER(oParams.Item[1])
    ENDCASE
    cAction = LOWER(cVerb) + cAction
  ENDIF
      
  oAVFP.Log("restHelper:handleRequest - " + "Verb: " + cVerb + ", Action: " + cAction + " - " + DTOC(DATE()) + " - " + LTRIM(STR(SECONDS())))
  IF !PEMSTATUS(oController, cAction, 5)
    * Added status code.  -RJC 7/14/2016
    oResponse.status = "501 Not Implemented"
    RETURN "restHelper: unrecognized REST call (" + cRESTUri + ", verb: " + cVerb + ", params: " + ALLTRIM(STR(oParams.Count)) + ")"
  ENDIF

  cHTMLOut = ""
  TRY
   WITH oController   &&oController.Object
    .Request = poRequest
    .Verb = cVerb
    .Props = poProps
    .Params = oParams
    .rootFolder = oAVFP.cRootFolder
    .localFolder = cLocalFolder
    .homeFolder = ADDBS(JUSTPATH(cController))
    .baseURL = cBaseURL
    .restBaseUrl = LEFT(cBaseURL, ATC("/rest/",cBaseURL) + 5)
    .restData = poRequest.Data
    .rawData = poRequest.rawData
    .Data = NULL
     DO CASE
        CASE cVerb <> "GET" AND "json" $ .Request.contentType AND !EMPTY(AVJSONError())
             cHTMLOut = oAVFP.renderEx(oAVFP.Exception(AVJSONError(), .rawData, ""))

        CASE cVerb == "GET"    && GET request doesnt support body-data. Use url parameters instead.
             * Create an object with all parameters included in the QueryString
             LOCAL oQS, cQSVar
             oQS = CREATE("Empty")
             FOR EACH cQSVar IN poRequest.oRequest.QueryString
               ADDPROPERTY(oQS, cQSVar, poRequest.oRequest.QueryString(cQSVar).ITEM())
             NEXT
             .Data = oQS

        CASE .Request.contentType = "application/x-www-form-urlencoded"
             .restData = NVL(poRequest.Form("restdata"),"")
             DO CASE
                CASE EMPTY(.restData)
                CASE (LEFT(.restData,1)="{" AND RIGHT(.restData,1)="}") OR ;
                     (LEFT(.restData,1)="[" AND RIGHT(.restData,1)="]")           && JSON string
                     .Data = AVEvalJSON(.restData)
             IF !EMPTY(AVJSONError())
              cHTMLOut = oAVFP.renderEx(oAVFP.Exception(AVJSONError(), .restData, ""))
             ENDIF

        CASE LEFT(.restData,6) == "<?xml "                                && XML data
             .Data = oAVFP.oJSON.parseXML(.restData)
             IF !EMPTY(AVJSONError())
              cHTMLOut = oAVFP.renderEx(oAVFP.Exception(AVJSONError(), .restData, ""))
             ENDIF
             ENDCASE

        CASE .Request.contentType = "application/json" AND !ISNULL(.rawData)
             .Data = AVEvalJSON(.rawData)
             IF !EMPTY(AVJSONError())
              cHTMLOut = oAVFP.renderEx(oAVFP.Exception(AVJSONError(), .rawData, ""))
             ENDIF

        CASE .Request.contentType = "application/xml" AND !ISNULL(.rawData)
             .Data = oAVFP.oJSON.parseXml(.rawData)
             IF !EMPTY(AVJSONError())
              cHTMLOut = oAVFP.renderEx(oAVFP.Exception(AVJSONError(), .rawData, ""))
             ENDIF
     ENDCASE
   ENDWITH

   oAVFP.Log("restHelper.handleRequest: 2")

   IF EMPTY(cHTMLOut)
    IF PEMSTATUS(oController, cAction, 5)  &&PEMSTATUS(oController.Object, cAction, 5)
     LOCAL uResp,lnSec
     lnSec = SECONDS()
     uResp = oController.beforeHandleAction(cAction)
     oAVFP.Log( "restHelper.beforeHandleAction -> Controller/Method: " + cResource + "/" + cAction + " -> run_time: " + TRANSFORM(SECONDS()-lnSec) )
     IF VARTYPE(uResp) <> "L"
       cHTMLOut = oController.response(uResp)
     ELSE
       lnSec = SECONDS()     
       cHTMLOut = EVALUATE("oController." + cAction + "()")  &&EVALUATE("oController.Object." + cAction + "()")
       oAVFP.Log( "restHelper.handleRequest -> Controller/Method: " + cResource + "/" + cAction + " -> run_time: " + TRANSFORM(SECONDS()-lnSec) )
       IF VARTYPE(cHTMLOut)<>"C"
        cHTMLOut = oController.Response(cHTMLOut)
       ENDIF
       cHTMLOut = oController.afterActionHandled(cAction, cHTMLOut)
     ENDIF
    ELSE
     * Added status code.  -RJC 7/14/2016
     oAVFP.Log("restHelper.handleRequest: 501 - Not Implemented")
     oResponse.status = "501 Not Implemented"
     cHTMLOut = "restHelper: the <b>" + PROPER(cResource) + "</b>'s controller does not implement the requested action (<b>" + cAction + "</b>)"
    ENDIF
   ENDIF

  CATCH TO ex
   ex.Details = AVFormat("<br>url: {0}<br>controller: {1}", cRESTUri, LOWER(JUSTFNAME(cController)))
   cHTMLOut = oAVFP.renderEx(ex)

  FINALLY
   oController.collectGarbage()

  ENDTRY

  RETURN cHTMLOut
  *
 ENDPROC

 *
ENDDEFINE


* restController (Class)
* Abstract class for REST resources controllers
*
DEFINE CLASS avfpRestController AS avfpObject
 Caption = ""
 Description = ""
 Version = "1.2"
 Author = ""

 Request = NULL
 Verb = "GET"
 Props = NULL
 Params = NULL
 rootFolder = ""    && Sites root folder
 localFolder = ""   && Requests local folder
 homeFolder = ""    && REST Controllers folder
 baseUrl = ""       && Sites base URL
 restBaseUrl = ""   && REST call base url (before resource/params)
 restData = NULL    && Value of restdata form value (if present)
 rawData = NULL     && Raw data received
 Data = NULL        && Processed data
 allowCustomActions = .T.
 useCORS = .F.

 PROCEDURE beforeHandleAction(pcAction)                && Invoked before processing any action
 ENDPROC


 PROCEDURE afterActionHandled(pcAction, pcHTMLOut)     && Invoked after processing any action
  RETURN pcHTMLOut
 ENDPROC


 PROCEDURE infoAction
  LOCAL cHTML
  TEXT TO cHTML NOSHOW TEXTMERGE
   <h2><<THIS.Caption>> (REST Controller)</h2>
   <<THIS.Description>>
   <hr>
   <br>
   Version: <b><<THIS.Version>></b></br>
   Author : <b><<THIS.Author>></b></br>
  ENDTEXT
  RETURN cHTML
 ENDPROC



 PROCEDURE listParameters
  LOCAL cHTML,i
  cHTML = THIS.Class + " - Received Parameters:<ul>"
  FOR i = 1 TO THIS.PArams.Count
   cHTML = cHTML + "<li>" + THIS.Params.Item[i] + "</li>"
  ENDFOR
  RETURN cHTML
 ENDPROC


 PROCEDURE loadPage(pcFileName)
  *pcFileName = STRT(pcFileName,"{root}",THIS.rootFolder)
  *pcFileName = STRT(pcFileName,"{home}",THIS.homeFolder)
  pcFileName = AVLocate(pcFileName)
  IF NOT FILE(pcFileName)
   AVError("File not found: " + LOWER(pcFileName),"rest."+LOWER(THIS.Name),"loadPage")
   RETURN ""
  ENDIF
  cScript = FILETOSTR(pcFileName)
  cScript = STRT(cScript,"{resource}",THIS.baseUrl)
  cScript = STRT(cScript,"{rest}", THIS.restBaseUrl)
  RETURN THIS.mergeScript(cScript, JUSTPATH(pcFileName))
 ENDPROC


 PROCEDURE mergeScript(pcScript, pcHOMEPath)
  RETURN oAVFP.mergeSCript(pcScript, pcHOMEPath)
 ENDPROC


 PROCEDURE Response(puResponse, pcXmlParentNode, poXmlOptions)
  DO CASE
     CASE PCOUNT() = 0
          RETURN AVObject("result,data,error",False,NULL,"")
          
     CASE VARTYPE(puResponse) = "N"
          RETURN THIS.returnStatusCode(puResponse)

     CASE THIS.Request.Accept == "application/json"
          DO CASE
             CASE VARTYPE(puResponse) = "C"
                  LOCAL oResp
                  oResp = THIS.Response()
                  oResp.result = False
                  oResp.error = puResponse
                  puResponse = oResp

             CASE VARTYPE(puResponse) = "O" AND (!PEMSTATUS(puResponse, "Result", 5) OR !PEMSTATUS(puResponse, "Data", 5) OR !PEMSTATUS(puResponse, "Error", 5))
                  LOCAL oResp
                  oResp = THIS.Response()
                  oResp.Result = True
                  oResp.Data = puResponse
                  puResponse = oResp
          ENDCASE
          RETURN THIS.returnJSON(puResponse)

     CASE THIS.Request.Accept == "application/xml"
          pcXmlParentNode = EVL(pcXmlParentNode, "response")
          RETURN THIS.returnXml(puResponse, pcXmlParentNode, poXmlOptions)

     CASE VARTYPE(puResponse) = "O"
          RETURN THIS.returnJSON(puResponse)

     OTHERWISE
          oResponse.contentType = EVL(THIS.Request.Accept, "text/plain")
          oResponse.Write(CHRT(puResponse,CHR(13)+CHR(10),""))
          oResponse.Flush()
          RETURN ""
  ENDCASE
 ENDPROC


 PROCEDURE returnStatusCode(puStatusCode)
  LOCAL cStatus
  DO CASE
    CASE VARTYPE(puStatusCode) = "C"
         cStatus = puStatusCode

    CASE puStatusCode = 200
         cStatus = "200 OK"

    CASE puStatusCode = 201
         cStatus = "201 Created"

    CASE puStatusCode = 202
         cStatus = "202 Accepted"

    CASE puStatusCode = 203
         cStatus = "203 Non-Authoritative Information"

    CASE puStatusCode = 204
         cStatus = "204 No Content"

    CASE puStatusCode = 304
         cStatus = "304 Not Modified"

    CASE puStatusCode = 400
         cStatus = "400 Bad Request"

    CASE puStatusCode = 401
         cStatus = "401 Unauthorized"

    CASE puStatusCode = 402
         cStatus = "402 Payment Required"

    CASE puStatusCode = 403
         cStatus = "403 Forbidden"

    CASE puStatusCode = 404
         cStatus = "404 Not Found"

    CASE puStatusCode = 405
         cStatus = "405 Method Not Allowed"

    CASE puStatusCode = 406
         cStatus = "406 Not Acceptable"

    CASE puStatusCode = 408
         cStatus = "408 Request Timeout"

    CASE puStatusCode = 500
         cStatus = "500 Internal Server Error"

    CASE puStatusCode = 501
         cStatus = "501 Not Implemented"

    OTHERWISE
         cStatus = "200 OK"
  ENDCASE
  oResponse.status = cStatus
  RETURN ""
 ENDPROC


 PROCEDURE returnJSON(pcJSONData, pnMaxAge)
  IF VARTYPE(pcJSONData) <> "C"
   pcJSONData = AVToJSON(pcJSONData)
  ENDIF
  IF THIS.useCORS
    oResponse.addheader("Access-Control-Allow-Origin","*")
  ENDIF
  IF PCOUNT() = 2
   IF pnMAxAge > 0
     oResponse.addHeader("Cache-control","public, max-age=" + LTRIM(STR(pnMAxAge)))
     oResponse.addHeader("Vary","Accept-Encoding")
   ELSE
     oResponse.addHeader("Cache-control","no-cache, no-store, must-revalidate")
     oResponse.addHeader("Pragma","no-cache")
     oResponse.addHeader("Expires",0)
   ENDIF
  ENDIF
  oResponse.ContentType = "application/json"  &&;charset=utf-8"
  oResponse.Write( CHRT(pcJSONData,CHR(13)+CHR(10),"") )
  oResponse.Flush()
  RETURN ""
 ENDPROC


 PROCEDURE returnXml(puXmlData, pcParentNode, poOptions)
  IF VARTYPE(puXmlData) <> "C"
   puXmlData = AVToXml(puXmlData, pcParentNode, poOptions)
  ENDIF
  oResponse.ContentType = "application/xml"  &&;charset=utf-8"
  oResponse.Write( CHRT(puXmlData,CHR(13)+CHR(10),"") )
  oResponse.Flush()
  RETURN ""
 ENDPROC


 PROCEDURE returnStream(pcFileName, pcContentType, pcDisposition, plDeleteFile)
  oAVFP.setStreamResponse(pcFileName, pcContentType, pcDisposition, plDeleteFile)
  RETURN ""
 ENDPROC

 PROCEDURE returnPDF(pcFileName)
  RETURN THIS.returnStream(pcFileName, "application/pdf", "inline")
 ENDPROC


 PROCEDURE jsonResponse(plResult, puData)
  RETURN IIF(plResult, AVObject("result,error,data",True,"",puData),;
                       AVObject("result,error,data",False,EVL(puData,""),NULL))
 ENDPROC

ENDDEFINE



DEFINE CLASS restController AS avfpRestController   && Backward compatibility
ENDDEFINE



* Dictionary (Class)
* Implementacion de un array asociativo
*
* Autor: Victor Espina
* Fecha: Abril 2012
*
* Uso:
* LOCAL oDict
* oDict = CREATE("Dictionary")
* oDict.Add("nombre","VICTOR")
* oDict.Add("apellido","ESPINA")
* ?oDict.Values["nombre"] --> "VICTOR"
*
* IF oDict.containsKey("apellido")
*  oDict.Values["apellido"] = "SARCOS"
* ENDIF
*
* FOR i = 1 TO oDict.Count
*  ?oDict.Keys[i], oDict.Values[i]
* ENDFOR
*
* oCopy = oDict.Clone()
* ?oCopy.Values["apellido"] --> "SARCOS"
*
DEFINE CLASS Dictionary AS Custom

 DIMEN Values[1]
 DIMEN Keys[1]
 Count = 0


 PROCEDURE Init(pnCapacity)
  IF PCOUNT() = 0
   pnCapacity = 0
  ENDIF
  DIMEN THIS.Values[MAX(1,pnCapacity)]
  DIMEN THIS.Keys[MAX(1,pnCapacity)]
  THIS.Count = pnCapacity
 ENDPROC


 PROCEDURE Values_Access(nIndex1,nIndex2)
  IF VARTYPE(nIndex1) = "N"
   RETURN THIS.Values[nIndex1]
  ENDIF
  LOCAL i
  FOR i = 1 TO THIS.Count
   IF THIS.Keys[i] == nIndex1
    RETURN THIS.Values[i]
   ENDIF
  ENDFOR
 ENDPROC


 PROCEDURE Values_Assign(cNewVal,nIndex1,nIndex2)
  IF VARTYPE(nIndex1) = "N"
   THIS.Values[nIndex1] = m.cNewVal
  ELSE
   LOCAL i
   FOR i = 1 TO THIS.Count
    IF THIS.Keys[i] == nIndex1
     THIS.Values[i] = m.cNewVal
     EXIT
    ENDIF
   ENDFOR
  ENDIF
 ENDPROC


 * Clear
 * Elimina el contenido de la clase
 *
 PROCEDURE Clear
  DIMEN THIS.Values[1]
  DIMEN THIS.Keys[1]
  THIS.Count = 0
 ENDPROC


 * Add
 * Incluye un nuevo item en el diccionario
 *
 PROCEDURE Add(pcKey, puValue)
  IF THIS.ContainsKey(pcKey)
   RETURN .F.
  ENDIF
  THIS.Count = THIS.Count + 1
  DIMEN THIS.Values[THIS.Count]
  DIMEN THIS.Keys[THIS.Count]
  THIS.Values[THIS.Count] = puValue
  THIS.Keys[THIS.Count] = pcKey
 ENDPROC


 * containsKey
 * Permite determinar si existe un item registrado
 * con la clase indicada
 *
 PROCEDURE ContainsKey(pcKey)
  LOCAL i,lResult
  lResult = .F.
  FOR i = 1 TO THIS.Count
   IF THIS.Keys[i] == pcKey
    lResult = .T.
    EXIT
   ENDIF
  ENDFOR
  RETURN lResult
 ENDPROC


 * getKeys
 * Copia en un array la lista de claves registradas
 *
 PROCEDURE getKeys(paTarget)
  IF THIS.Count = 0
   RETURN .F.
  ENDIF
  DIMEN paTarget[THIS.Count]
  ACOPY(THIS.Keys, paTarget)
  RETURN THIS.Count
 ENDPROC


 * Clone
 * Devuelve una copia del diccionario con todo su contenido
 *
 PROCEDURE Clone()
  LOCAL oClone,i
  oClone = CREATE(THIS.Class)
  FOR i = 1 TO THIS.Count
   oClone.Add(THIS.Keys[i], THIS.Values[i])
  ENDFOR
  RETURN oClone
 ENDPROC

ENDDEFINE
