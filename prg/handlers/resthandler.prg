**************************************************************
* REST-like APIs implementation
*
* Author: Victor Espina
* Date: April 2012
*
**************************************************************
DEFINE CLASS restHandler AS avfpHttpHandler

	cVerion = "1.1"
	cAuthor = "V. Espina"
	cComments = "REST calls handlers"



	FUNCTION handleRequest(poArgs, poServer)
		* Create an instancia of RESTHelper class
		LOCAL oRESTHelper, cRESTFolder, lIsREST
		oRESTHelper = oAVFP.New("restHelper", AVLocate("{mainprg}\handlers\lib\restHelper.prg"))
		oRESTHelper.setFolder("ROOT", oAVFP.cRootFolder)
		lIsREST = false

		oAVFP.LOG("Starting REST request handling")


		* If there is a local PRG folder with a REST subfolder, check if the
		* request can be handle there
		*
		IF oAVFP.lHasLocalPRG
			cRESTFolder = oAVFP.LOCATE("{localprg}/rest/controllers")
			IF DIRECTORY(cRESTFolder)
				WITH oRESTHelper
					.setFolder("CONTROLLERS", cRESTFolder)
					.loadControllers()
				ENDWITH
				lIsREST = oRESTHelper.isREST(oRequest)
			ENDIF

			oAVFP.LOG(AVFormat("({0}) controllers found at {1}:", oRESTHelper.Controllers.COUNT, cRESTFolder))
			FOR i = 1 TO oRESTHelper.Controllers.COUNT
				oAVFP.LOG("- " + oRESTHelper.Controllers.KEYS[i])
			ENDFOR
			oAVFP.LOG(AVFormat("Controller found: {0}", lIsREST))
		ENDIF




		* If there wasn't a local REST folder or the request couldn't be handled
		* there, try with the main REST folder
		*
		IF !lIsREST
			cRESTFolder = oAVFP.LOCATE("{mainprg}/rest/controllers")
			IF DIRECTORY(cRESTFolder)
				WITH oRESTHelper
					.setFolder("CONTROLLERS", cRESTFolder)
					.loadControllers()
				ENDWITH
				lIsREST = oRESTHelper.isREST(oRequest)

				oAVFP.LOG(AVFormat("({0}) controllers found at {1}:", oRESTHelper.Controllers.COUNT, cRESTFolder))
				FOR i = 1 TO oRESTHelper.Controllers.COUNT
					oAVFP.LOG("- " + oRESTHelper.Controllers.KEYS[i])
				ENDFOR
				oAVFP.LOG(AVFormat("Controller found: {0}", lIsREST))
			ENDIF
		ENDIF


		* Use RESTHelper object to check if the request conforms a REST-like API call. If so, pass
		* the request object to RESTHelper in order to let the right resource controller handle it.
		LOCAL lResult
		lResult = .T.
		IF lIsREST
			TRY
				oProp.appStartPath = oRequest.serverVariables("APPL_PHYSICAL_PATH")
				oProp.ScriptPath = LEFT(oProp.ScriptPath, ATC("/rest/", oProp.ScriptPath) + 5)
				poArgs.cHTMLResponse = oRESTHelper.handleRequest(oRequest, oProp)

			CATCH TO ex
				poArgs.cErrorText = oAVFP.renderEx(ex)
				lResult = .F.

			ENDTRY
			poArgs.lHandled = .T.  && Avoid further processing
		ENDIF

		RETURN lResult
	ENDFUNC

ENDDEFINE