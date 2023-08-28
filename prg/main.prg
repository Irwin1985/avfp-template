#DEFINE crlf CHR(13)+CHR(10)
************************************************
* ActiveVFP 6.03
* MAIN.prg  -Mainline entry point of the app   *
************************************************
* *NOTE:  this (main.prg) ALWAYS runs before your .AVFP script code and after
* *use this to setup your datapath in a centralized place (in the AVFPinit function at the bottom)
* *use this for pre or post-processing of each web hit
* *optionally use this for centralized code (in the Functions section)
***********************************
LOCAL lchtmlfile,lchtmlout
AVFPinit() && set data and HTML paths
oProp.RunningPrg	= [main.prg]
oProp.Action		= JUSTSTEM(oRequest.ServerVariables("SCRIPT_NAME"))  &&action is the script name
oProp.Ext			= '.avfp'&&[.]+Justext(oRequest.ServerVariables("SCRIPT_NAME"))  && .avfp or whatever

DO CASE   && process the request from the URL
	*!*    COMMENT OUT FOR PRODUCTION
CASE oProp.Action == 'showhtmlsource'   &&*!*	                        *!*    COMMENT OUT FOR PRODUCTION
	lcFileName = oRequest.QueryString("file")
	DO CASE
	CASE FILE(oProp.HtmlPath+[\prg\rest\controllers\]+lcFileName+'.prg')
		lcFileText= FILETOSTR(oProp.HtmlPath+[\prg\rest\controllers\]+lcFileName+'.prg')
	CASE FILE(oProp.HtmlPath+[\prg\]+lcFileName+'.prg')
		lcFileText= FILETOSTR(oProp.HtmlPath+[\prg\]+lcFileName+'.prg')
	OTHERWISE
		lcFileText= FILETOSTR(oProp.HtmlPath+lcFileName+oProp.Ext)
	ENDCASE
	lchtmlout=[]
	oResponse.WRITE([<input type="button" value="Go Back" onClick="history.go(-1);"];
		+[<BR><BR><pre><CENTER><textarea cols="115" rows="30">] + lcFileText + [</textarea></pre></CENTER>])
	*!*    COMMENT OUT FOR PRODUCTION

CASE oProp.Action=='LogOut'
	oSession.VALUE("authenticated",.F.)
	oSession.VALUE("logout",.T.)
	oResponse.Redirect(JUSTPATH(oProp.ScriptPath)+[/default]+oProp.Ext)

CASE oProp.Action=='DeletemKey'
	oCookie.DELETE("mkey")
	oSession.VALUE("authenticated",.F.)
	oResponse.Redirect(JUSTPATH(oProp.ScriptPath)+[/default]+oProp.Ext)
OTHERWISE   && get .avfp script
	IF !ISNULL(oProp.Action) .AND. FILE(oProp.HtmlPath+oProp.Action+oProp.Ext)
		* This section must stay here for pure scripting mode

		lchtmlout= FILETOSTR(oProp.HtmlPath+oProp.Action+oProp.Ext)
		oProp.RunningPrg=oProp.Action+oProp.Ext
		lchtmlout= oHTML.mergescript(lchtmlout)
	ELSE    && goto default page
		CookieLogin()  && checks for cookie to authenticate
		oProp.Ext = ".avfp"   && FIX FOR DEFAULT PAGE AUTO LOADING
		lchtmlfile	= 'default.avfp'
		lchtmlout	= FILETOSTR('default.avfp')
		lchtmlout	='dafa'
		*lchtmlout	= Filetostr(oProp.HtmlPath+lchtmlfile)
		*lchtmlout= oHTML.mergescript(lchtmlout)
	ENDIF
ENDCASE
*  end mainline
oProp.RunningPrg=[main.prg]
*!*	*!*    COMMENT OUT FOR PRODUCTION
lchtmlout = DebugDump(lchtmlout) && DEBUG Dump Routine			  *!*	*!*    COMMENT OUT FOR PRODUCTION
* now we'll return the HTML output to the browser
RETURN lchtmlout

************************************************************************
*
***FUNCTIONS******************
*
************************************************************************

* include

*********************************

*** Function: Include an HTML file as part of the output

************************************************************************
FUNCTION INCLUDE
	LPARAMETERS lchtmlfile
	LOCAL lchtmlout
	lchtmlout = FILETOSTR(oProp.HtmlPath+lchtmlfile)
	RETURN oHTML.mergescript(lchtmlout)
ENDFUNC
************************************************************************

* CompileIfNew

*********************************

*** Function: Compile source if source date is newer than object or no object

************************************************************************
FUNCTION CompileIfNew
	LPARAMETERS lcPrgName
	*must be compiled object and compile is source date newer
	IF !FILE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp") OR ;
			FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".prg",1) > FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp",1)
		COMPILE oProp.AppStartPath+"prg\"+lcPrgName+".prg"
		RETURN .T.
	ELSE
		RETURN .F.
	ENDIF
ENDFUNC
************************************************************************

* DebugDump

*********************************

*** Function: Output Debugging Variables at the bottom

************************************************************************
FUNCTION DebugDump
	LPARAMETERS lchtmlout
	*DEBUG Dump Routine
	DO CASE
	CASE oRequest.QueryString("debug")=="on"
		llDebug= .T.
	CASE oRequest.QueryString("debug")=="off"
		llDebug= .F.
	OTHERWISE
		llDebug=oSession.VALUE("debug")
		IF (ISNULL(llDebug) .OR. EMPTY(llDebug))
			llDebug= .F.
		ENDIF
	ENDCASE
	* save llDebug to session
	oSession.VALUE("debug",llDebug)
	IF llDebug
		lchtmlout = lchtmlout + oHTML.mergescript(FILETOSTR(oProp.HtmlPath+'aspvars'+oProp.Ext))
	ENDIF
	*!*	DISPLAY MEMORY LIKE * TO FILE 'c:\temp\test.txt'
	*!*	lcHTMLout= lcHTMLout+'<pre>'+FILETOSTR('c:\temp\test.txt')+'</pre>'
	RETURN lchtmlout
ENDFUNC && DEBUG Dump Routine

************************************************************************

* cookielogin

*********************************

*** Function: authenticate against a dbf using cookie

************************************************************************
FUNCTION CookieLogin
	lcUsuario=BlowFish1(ALLTRIM(oRequest.cookies('_u')),2)
	lcPassword=BlowFish1(ALLTRIM(oRequest.cookies('_p')),2)
	IF !EMPTY(lcUsuario) AND !EMPTY(lcPassword) AND oSession.VALUE("authenticated")= .F. .AND. ISNULL(oSession.VALUE("logout"))
		RETURN TableAuth(lcUsuario,lcPassword,"")
	ENDIF
	RETURN .F.
ENDFUNC

************************************************************************

FUNCTION CookieLoginAnt
	LOCAL lcKey
	lcKey=ALLTRIM(oRequest.cookies('mkey'))
	IF ! EMPTY(lcKey) .AND. oSession.VALUE("authenticated")= .F. .AND. ISNULL(oSession.VALUE("logout"))
		IF .NOT. USED('mcookies')
			USE ('mcookies') IN 0 SHARED
		ENDIF
		SELECT mcookies
		SET ORDER TO KEY
		SET EXACT ON
		SEEK lcKey
		SET EXACT OFF
		IF ! EOF()
			TableAuth(mcookies.USER,mcookies.PASS,"")
		ENDIF
	ENDIF
	RETURN
ENDFUNC
************************************************************************

* TableAuth

*********************************

*** Function: authenticate against a dbf

************************************************************************
*--------------------------------------------
* TableAuth (ActiveVFP)
FUNCTION TableAuthAnt
	LPARAMETERS lcName,lcPassword,lcAutoLogin
	LOCAL lcNewKey,lcPrev,lcFirst
	IF .NOT. USED('cnusers')
		USE ('cnusers') IN 0 SHARED
	ENDIF
	SELECT cnusers
	SET ORDER TO NAME
	SET EXACT ON
	SEEK UPPER(PADR(ALLTRIM(lcName),LEN(cnusers.NAME),' '))
	SET EXACT OFF
	IF FOUND()
		IF UPPER(ALLTRIM(m.lcPassword)) == UPPER(ALLTRIM(cnusers.PASSWORD))
			oSession.VALUE("authenticated",.T.)   && this is why we're here - authenticated or not
			lcPrev = oSession.VALUE("previous")
			lcFirst= cnusers.Firstname
			oSession.VALUE("name",lcFirst+[ ]+ cnusers.Lastname)
			oSession.VALUE("account",cnusers.USERID)
			oSession.VALUE("company",cnusers.company)
			oSession.VALUE("address",cnusers.address1)
			oSession.VALUE("city",cnusers.city)
			oSession.VALUE("state",cnusers.state)
			oSession.VALUE("zip",cnusers.zip)
			oSession.VALUE("country",cnusers.country)
			oSession.VALUE("email",cnusers.email)
			IF ! ISNULL(lcAutoLogin)
				lcNewKey = SUBSTR(SYS(2015), 3, 10)
				IF .NOT. USED('mcookies')
					USE ('mcookies') IN 0 SHARED
				ENDIF
				SELECT mcookies
				INSERT INTO mcookies (KEY, USER, PASS) VALUES (lcNewKey, lcName, lcPassword)
				oCookie.WRITE("mkey",lcNewKey,"January 1, 2035")
			ENDIF

		ENDIF

	ENDIF
ENDFUNC
************************************************************************

* AVFPinit

*********************************

*** Function: Set up data and html paths

************************************************************************
FUNCTION AVFPinit
	* Set up data and html paths
	************************************************************************
	* Set Data and HTML paths (adjust per your needs as necessary)
	LOCAL lcPath
	SET EXCLUSIVE OFF
	SET DELETED ON
	SET POINT TO ','
	SET SEPARATOR TO '.'
	lcPath = ADDBS(SYS(5) + SYS(2003))
	STRTOFILE(lcPath, lcPath + "info.log")
	SET DEFAULT TO (lcPath)
	oProp.HtmlPath	= lcPath + 'html\'
ENDFUNC
