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
* =========   ===     ====    ================================
* Aug 2015    VES     1.2     Accept header support
* Aug 2012 	  CKF	  1.1     Custom methods for MVC
* Apr 2012    VES     1.0     Initial version

DEFINE CLASS restHelper AS CUSTOM
	*
	Folders = NULL
	Controllers = NULL

	* Constructor
	*
	PROCEDURE INIT
		*
		THIS.Folders = CREATEOBJECT("Dictionary")
		THIS.Folders.ADD("ROOT","")
		THIS.Folders.ADD("CONTROLLERS","")

		THIS.Controllers = CREATEOBJECT("Dictionary")
		*
	ENDPROC


	* setFolder
	* Sets a folder location
	*
	PROCEDURE setFolder(pcFolderID, pcFolderPath)
		THIS.Folders.VALUES[pcFolderId] = ADDBS(CHRTRAN(pcFolderPath,"/","\"))
	ENDPROC


	* loadControllers
	* Look for controllers in the controller's folder
	*
	PROCEDURE loadControllers
		*
		LOCAL ARRAY aControllers[1]
		LOCAL cPath,cFile,cController,nCount,i
		cPath = THIS.Folders.VALUES["CONTROLLERS"]
		nCount = ADIR(aControllers, cPath + "*.PRG")
		THIS.Controllers.CLEAR()
		FOR i = 1 TO nCount
			cFile = ADDBS(cPath) + aControllers[i,1]
			cController = LOWER(JUSTSTEM(cFile))
			THIS.Controllers.ADD(cController, cFile)
		ENDFOR
		*
	ENDPROC


	* isREST
	* Check if the given request is a RESTful request. A request is considered
	* a REST-compliant request if:
	*
	* a) Does not contains a file extension
	* b) Does not contains a ? sign
	* c) The URL conforms to the form http://server/resource/
	*
	PROCEDURE isREST(poRequest)
		*
		LOCAL cUri
		IF VARTYPE(poRequest)<>"C"
			cUri = poRequest.serverVariables("SCRIPT_NAME")
		ELSE
			cUri = poRequest
		ENDIF


		* Basic syntax check
		IF !EMPTY(JUSTEXT(cUri)) OR AT("?",cUri)<>0
			RETURN .F.
		ENDIF


		* Check if URI contains a reference to an available resource controller
		LOCAL lHasController,i
		lHasController = .F.
		IF RIGHT(cUri,1) <> "/"
			cUri = cUri + "/"
		ENDIF
		FOR i = 1 TO THIS.Controllers.COUNT
			IF ATC("/" + THIS.Controllers.KEYS[i] + "/", cUri) > 0
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
		* c) Resource's parameters
		* d) Request base folder
		*
		LOCAL cUri,cRESTUri,cVerb,cResource,cParams,i,j,cController,cBaseURL,cLocalFolder
		IF VARTYPE(poRequest)<>"C"
			cUri = poRequest.serverVariables("SCRIPT_NAME")
			cVerb = poRequest.serverVariables("REQUEST_METHOD")
		ELSE
			cUri = poRequest
			cVerb = "GET"
		ENDIF

		IF RIGHT(cUri,1) <> "/"
			cUri = cUri + "/"
		ENDIF

		j = 0
		cResource = ""
		cController = ""
		cLocalFolder = ""
		FOR i = 1 TO THIS.Controllers.COUNT
			cResource = THIS.Controllers.KEYS[i]
			cController = THIS.Controllers.VALUES[i]
			IF ATC(cResource, cUri) > 0
				j = ATC("/" + cResource + "/", cUri)
				IF j > 0
					EXIT
				ENDIF
			ENDIF
		ENDFOR
		IF j = 0   && There is no controller for the specified resource
			RETURN "restHelper: unhandled resource on REST call (" + cUri + ")"
		ENDIF

		cBaseURL = LEFT(cUri, j) + cResource + "/"
		cLocalFolder = oAVFP.translateUrl(LEFT(cUri, j))
		cRESTUri = SUBSTR(cUri,j)  && /server/resource/params --> /resource/params
		cParams = SUBSTR(cRESTUri,LEN(cResource) + 3)
		oAVFP.setPath("local", cLocalFolder)

		* Convert the parameter list to a collection
		LOCAL ARRAY aParams[1]
		LOCAL nCount, cPAram
		LOCAL oParams AS COLLECTION
		nCount = ALINES(aParams, STRT(cParams,"/",CHR(13)+CHR(10)))
		oParams = CREATEOBJECT("Collection")
		FOR EACH cPAram IN aParams
			IF !EMPTY(cPAram)
				oParams.ADD(cPAram)
			ENDIF
		ENDFOR


		*!*          * IF there is a local PRG in the base folder with a DELEGATE, load it
		*!*          LOCAL oLocalDelegate
		*!*          oLocalDelegate = NULL
		*!*          IF FILE(cLocalFolder + "/prg/delegate.prg")
		*!*           oAVFP.oDelegate.loadDelegateFrom(cLocalFolder + "/prg/")
		*!*           IF oAVFP.oDelegate.lHasDelegate
		*!*            oLocalDelegate = oAVFP.oDelegate.oDelegate
		*!*           ENDIF
		*!*          ENDIF
		*!*
		*!*
		*!*          * IF there is a local delegate, call its events at this point. The rest of the delegate's events
		*!*          * will be called automatically from the main Delegate object at proxystub
		*!*          IF !ISNULL(oLocalDelegate) AND ;
		*!*            (!oLocalDelegate.initDataSession() OR ;
		*!*             !oLocalDelegate.loadLibraries() OR ;
		*!*             !oLocalDelegate.beforeHandleRequest())
		*!*           RETURN oLocalDelegate.getErrorText()
		*!*          ENDIF

		* Create a instance of the resource's controller
		LOCAL oController,cHTMLOut
		IF NOT FILE(cController)
			RETURN "restHelper: controller file <b>" + cController + "</b> could not be found"
		ENDIF
		oController = oAVFP.New(cResource + "Controller", cController)


		* Use the verb + parameter count to deduce the actual action
		* to be invoked on the controller
		*
		LOCAL cAction
		cAction = ""

		DO CASE
		CASE cVerb == "GET" AND oParams.COUNT = 0
			cAction = "listAction"

		CASE cVerb == "GET" AND oParams.COUNT > 0
			cAction = LOWER(oParams.ITEM[1])
			DO CASE
			CASE cAction == "pdi"
				RETURN oAVFP.pathDebugInfo()

			CASE INLIST(cAction,"info","help")
				cAction = cAction + "Action"

			CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
				IF oParams.COUNT = 1
					cAction = "getAction"
				ELSE
					cAction = "listAction"
				ENDIF

			OTHERWISE
				cAction = oParams.ITEM[1]   && Custom action
			ENDCASE

		CASE cVerb == "POST" AND oParams.COUNT = 0
			cAction = "addAction"

		CASE cVerb == "POST" AND oParams.COUNT > 0
			cAction = LOWER(oParams.ITEM[1])
			DO CASE
			CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
				cAction = "updAction"

			OTHERWISE
				cAction = oParams.ITEM[1]   && Custom action
			ENDCASE

		CASE cVerb == "DELETE" AND oParams.COUNT = 0
			cAction = "zapAction"

		CASE cVerb == "DELETE" AND oParams.COUNT > 0
			cAction = LOWER(oParams.ITEM[1])
			DO CASE
			CASE !PEMSTATUS(oController, cAction, 5) OR !oController.allowCustomActions
				cAction = "dropAction"

			OTHERWISE
				cAction = oParams.ITEM[1]   && Custom action
			ENDCASE

		OTHERWISE
			cAction = oParams.ITEM[1]    &&"customAction"
		ENDCASE
		IF EMPTY(cAction)
			RETURN "restHelper: unrecognized REST call (" + cRESTUri + ", verb: " + cVerb + ", params: " + ALLTRIM(STR(oParams.COUNT)) + ")"
		ENDIF

		cHTMLOut = ""
		TRY
			WITH oController   &&oController.Object
				.REQUEST = poRequest
				.VERB = cVerb
				.Props = poProps
				.Params = oParams
				.rootFolder = oAVFP.cRootFolder
				.localFolder = cLocalFolder
				.homeFolder = ADDBS(JUSTPATH(cController))
				.baseURL = cBaseURL
				.restBaseUrl = LEFT(cBaseURL, ATC("/rest/",cBaseURL) + 5)
				.restData = NULL
				.rawData = NULL
				.DATA = NULL
				DO CASE
				CASE .REQUEST.contentType = "application/x-www-form-urlencoded"
					.restData = NVL(poRequest.FORM("restdata"),"")
					DO CASE
					CASE EMPTY(.restData)

					CASE (LEFT(.restData,1)="{" AND RIGHT(.restData,1)="}") OR ;
							(LEFT(.restData,1)="[" AND RIGHT(.restData,1)="]")           && JSON string
						.DATA = AVEvalJSON(.restData)
						IF !EMPTY(AVJSONError())
							cHTMLOut = oAVFP.renderEx(oAVFP.EXCEPTION(AVJSONError(), .restData, ""))
						ENDIF

					CASE LEFT(.restData,6) == "<?xml "                                && XML data
						.DATA = oAVFP.oJSON.parseXML(.restData)
						IF !EMPTY(AVJSONError())
							cHTMLOut = oAVFP.renderEx(oAVFP.EXCEPTION(AVJSONError(), .restData, ""))
						ENDIF
					ENDCASE

				CASE .REQUEST.contentType = "application/json" AND !ISNULL(.rawData)
					.DATA = AVEvalJSON(.rawData)
					IF !EMPTY(AVJSONError())
						cHTMLOut = oAVFP.renderEx(oAVFP.EXCEPTION(AVJSONError(), .rawData, ""))
					ENDIF

				CASE .REQUEST.contentType = "application/xml" AND !ISNULL(.rawData)
					.DATA = oAVFP.oJSON.parseXML(.rawData)
					IF !EMPTY(AVJSONError())
						cHTMLOut = oAVFP.renderEx(oAVFP.EXCEPTION(AVJSONError(), .rawData, ""))
					ENDIF
				ENDCASE
			ENDWITH

			IF EMPTY(cHTMLOut)
				IF PEMSTATUS(oController, cAction, 5)  &&PEMSTATUS(oController.Object, cAction, 5)
					oController.beforeHandleAction(cAction)
					cHTMLOut = EVALUATE("oController." + cAction + "()")  &&EVALUATE("oController.Object." + cAction + "()")
					cHTMLOut = oController.afterActionHandled(cAction, cHTMLOut)
				ELSE
					cHTMLOut = "restHelper: the <b>" + PROPER(cResource) + "</b>'s controller does not implement the requested action (<b>" + cAction + "</b>)"
				ENDIF
			ENDIF

		CATCH TO ex
			ex.DETAILS = AVFormat("<br>url: {0}<br>controller: {1}", cRESTUri, LOWER(JUSTFNAME(cController)))
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
* Abstract class for REST resource's controllers
*
DEFINE CLASS avfpRestController AS avfpObject
	CAPTION = ""
	DESCRIPTION = ""
	VERSION = ""
	Author = ""

	REQUEST = NULL
	VERB = "GET"
	Props = NULL
	Params = NULL
	rootFolder = ""    && Site's root folder
	localFolder = ""   && Request's local folder
	homeFolder = ""    && REST Controllers folder
	baseURL = ""       && Site's base URL
	restBaseUrl = ""   && REST call base url (before resource/params)
	restData = NULL    && Value of restdata form value (if present)
	rawData = NULL     && Raw data received
	DATA = NULL        && Processed data
	allowCustomActions = .T.


	PROCEDURE beforeHandleAction(pcAction)                && Invoked before processing any action
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
	PROCEDURE helpAction
		RETURN "helpAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE getAction
		RETURN "getAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE listAction
		RETURN "listAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE addAction
		RETURN "addAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE updAction
		RETURN "updAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE dropAction
		RETURN "dropAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE zapAction
		RETURN "zapAction: <b>not implemented</b>"
	ENDPROC
	PROCEDURE listParameters
		LOCAL cHTML,i
		cHTML = THIS.CLASS + " - Received Parameters:<ul>"
		FOR i = 1 TO THIS.Params.COUNT
			cHTML = cHTML + "<li>" + THIS.Params.ITEM[i] + "</li>"
		ENDFOR
		RETURN cHTML
	ENDPROC

	PROCEDURE loadPage(pcFileName)
		pcFileName = STRT(pcFileName,"{root}",THIS.rootFolder)
		pcFileName = STRT(pcFileName,"{home}",THIS.homeFolder)
		LOCAL cSCript
		IF EMPTY(JUSTPATH(pcFileName))
			pcFileName = oAVFP.LOCATE(pcFileName)
		ENDIF
		IF NOT FILE(pcFileName)
			AVError("File not found: " + LOWER(pcFileName),"rest."+LOWER(THIS.NAME),"loadPage")
			RETURN ""
		ENDIF
		cSCript = FILETOSTR(pcFileName)
		cSCript = STRT(cSCript,"{resource}",THIS.baseURL)
		cSCript = STRT(cSCript,"{rest}", THIS.restBaseUrl)
		RETURN THIS.mergeScript(cSCript, JUSTPATH(pcFileName))
	ENDPROC

	PROCEDURE mergeScript(pcScript, pcHOMEPath)
		RETURN oAVFP.mergeScript(pcScript, pcHOMEPath)
	ENDPROC


	PROCEDURE Response(puResponse, pcXmlParentNode, poXmlOptions)
		IF PCOUNT() = 0
			RETURN AVObject("result,data,error",False,NULL,"")
		ENDIF
		DO CASE
		CASE THIS.REQUEST.ACCEPT == "application/json"
			RETURN THIS.returnJSON(puResponse)

		CASE THIS.REQUEST.ACCEPT == "application/xml"
			pcXmlParentNode = EVL(pcXmlParentNode, "response")
			RETURN THIS.returnXml(puResponse, pcXmlParentNode, poXmlOptions)

		CASE VARTYPE(puResponse) = "O"
			RETURN THIS.returnJSON(puResponse)

		OTHERWISE
			oResponse.contentType = EVL(THIS.REQUEST.ACCEPT, "text/plain")
			oResponse.WRITE(CHRT(puResponse,CHR(13)+CHR(10),""))
			oResponse.FLUSH()
			RETURN ""
		ENDCASE
	ENDPROC


	PROCEDURE returnJSON(pcJSONData)
		IF VARTYPE(pcJSONData) <> "C"
			pcJSONData = AVToJSON(pcJSONData)
		ENDIF
		oResponse.contentType = "application/json"  &&;charset=utf-8"
		oResponse.WRITE( CHRT(pcJSONData,CHR(13)+CHR(10),"") )
		oResponse.FLUSH()
		RETURN ""
	ENDPROC


	PROCEDURE returnXml(puXmlData, pcParentNode, poOptions)
		IF VARTYPE(puXmlData) <> "C"
			puXmlData = AVToXml(puXmlData, pcParentNode, poOptions)
		ENDIF
		oResponse.contentType = "application/xml"  &&;charset=utf-8"
		oResponse.WRITE( CHRT(puXmlData,CHR(13)+CHR(10),"") )
		oResponse.FLUSH()
		RETURN ""
	ENDPROC


	PROCEDURE returnStream(pcFileName, pcContentType, pcDisposition)
		oAVFP.setStreamResponse(pcFileName, pcContentType, pcDisposition)
		RETURN ""
	ENDPROC

	PROCEDURE returnPDF(pcFileName)
		RETURN THIS.returnStream(pcFileName, "application/pdf", "inline")
	ENDPROC

	PROCEDURE jsonResponse(poData)
		RETURN AVObject("result,error,data",.F.,"",EVL(poData,NULL))
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
DEFINE CLASS Dictionary AS CUSTOM

	DIMEN VALUES[1]
	DIMEN KEYS[1]
	COUNT = 0

	PROCEDURE INIT(pnCapacity)
		IF PCOUNT() = 0
			pnCapacity = 0
		ENDIF
		DIMEN THIS.VALUES[MAX(1,pnCapacity)]
		DIMEN THIS.KEYS[MAX(1,pnCapacity)]
		THIS.COUNT = pnCapacity
	ENDPROC

	PROCEDURE Values_Access(nIndex1,nIndex2)
		IF VARTYPE(nIndex1) = "N"
			RETURN THIS.VALUES[nIndex1]
		ENDIF
		LOCAL i
		FOR i = 1 TO THIS.COUNT
			IF THIS.KEYS[i] == nIndex1
				RETURN THIS.VALUES[i]
			ENDIF
		ENDFOR
	ENDPROC

	PROCEDURE Values_Assign(cNewVal,nIndex1,nIndex2)
		IF VARTYPE(nIndex1) = "N"
			THIS.VALUES[nIndex1] = m.cNewVal
		ELSE
			LOCAL i
			FOR i = 1 TO THIS.COUNT
				IF THIS.KEYS[i] == nIndex1
					THIS.VALUES[i] = m.cNewVal
					EXIT
				ENDIF
			ENDFOR
		ENDIF
	ENDPROC


	* Clear
	* Elimina el contenido de la clase
	*
	PROCEDURE CLEAR
		DIMEN THIS.VALUES[1]
		DIMEN THIS.KEYS[1]
		THIS.COUNT = 0
	ENDPROC

	* Add
	* Incluye un nuevo item en el diccionario
	*
	PROCEDURE ADD(pcKey, puValue)
		IF THIS.ContainsKey(pcKey)
			RETURN .F.
		ENDIF
		THIS.COUNT = THIS.COUNT + 1
		DIMEN THIS.VALUES[THIS.Count]
		DIMEN THIS.KEYS[THIS.Count]
		THIS.VALUES[THIS.Count] = puValue
		THIS.KEYS[THIS.Count] = pcKey
	ENDPROC

	* containsKey
	* Permite determinar si existe un item registrado
	* con la clase indicada
	*
	PROCEDURE ContainsKey(pcKey)
		LOCAL i,lResult
		lResult = .F.
		FOR i = 1 TO THIS.COUNT
			IF THIS.KEYS[i] == pcKey
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
		IF THIS.COUNT = 0
			RETURN .F.
		ENDIF
		DIMEN paTarget[THIS.Count]
		ACOPY(THIS.KEYS, paTarget)
		RETURN THIS.COUNT
	ENDPROC

	* Clone
	* Devuelve una copia del diccionario con todo su contenido
	*
	PROCEDURE CLONE()
		LOCAL oClone,i
		oClone = CREATE(THIS.CLASS)
		FOR i = 1 TO THIS.COUNT
			oClone.ADD(THIS.KEYS[i], THIS.VALUES[i])
		ENDFOR
		RETURN oClone
	ENDPROC

ENDDEFINE



