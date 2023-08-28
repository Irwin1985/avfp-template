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
oProp.RunningPrg=[main.prg]
oProp.Action=JustStem(oRequest.ServerVariables("SCRIPT_NAME"))  &&action is the script name
oProp.Ext=[.]+JUSTEXT(oRequest.ServerVariables("SCRIPT_NAME"))  && .avfp or whatever

IF oProp.Ext == "."
 oProp.Ext = ".avfp"
ENDIF

*!*	oAA=newOBJECT('schedbizobj','c:\avfp5.61Demo\prg\utiltest2.prg')
*oEmp=newOBJECT('schedbizobj','c:\avfp5.61Demo\prg\utiltest2.prg')  &&TEST Class Library
*SET PROC to 'c:\avfp6\prg\utiltest' ADDITIVE   &&TEST procedure library
 
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
    lcHTMLout=[]
    oResponse.Write([<input type="button" value="Go Back" onClick="history.go(-1);"];
    +[<BR><BR><pre><CENTER><textarea cols="115" rows="30">] + lcFileText + [</textarea></pre></CENTER>])
*!*    COMMENT OUT FOR PRODUCTION
 
CASE oProp.Action=='LogOut'
	oSession.VALUE("authenticated",.F.)
	oSession.VALUE("logout",.T.)
	oResponse.Redirect(JUSTPATH(oProp.ScriptPath)+[/default]+oProp.Ext)   

*CASE oProp.Action=='test'
	        *lcHTMLout=test3('new')
*	        lcHTMLout=oAA.test3('new')
*!*	            SET PROC to 'c:\avfp6\prg\compileifnew' additive
*!*	            RETURN compileifnew('avfputilities')
       
CASE oProp.Action=='DeletemKey'
	oCookie.DELETE("mkey")
	oSession.VALUE("authenticated",.F.)
	oResponse.Redirect(JUSTPATH(oProp.ScriptPath)+[/default]+oProp.Ext)


OTHERWISE   && get .avfp script

    IF !ISNULL(oProp.Action) .AND. FILE(oProp.HtmlPath+oProp.Action+oProp.Ext)
        * This section must stay here for pure scripting mode      
    	lcHTMLout= FILETOSTR(oProp.HtmlPath+oProp.Action+oProp.Ext)
    	oProp.RunningPrg=oProp.Action+oProp.Ext
	    lcHTMLout= oHTML.mergescript(lcHTMLout)
    ELSE    && goto default page
*		USE mydbf  && test error
		CookieLogin()  && checks for cookie to authenticate
		lcHTMLfile = 'default'+oProp.Ext
    DO CASE 
         CASE FILE(oProp.HtmlPath + lcHTMLFile)
              lcHTMLout= FILETOSTR(oProp.HtmlPath+lcHTMLfile)
              oProp.RunningPrg=[default]+oProp.Ext
              lcHTMLout= oHTML.mergescript(lcHTMLout)

         CASE FILE(oProp.HtmlPath + "index.html")
              oProp.RunningPrg=[index.html]         
              lcHTMLout= FILETOSTR(oProp.HtmlPath + "index.html")

         CASE FILE(oProp.HtmlPath+".htm")
              oProp.RunningPrg=[index.htm]
              lcHTMLout= FILETOSTR(oProp.HtmlPath+"index.htm")

      ENDCASE

    ENDIF

ENDCASE
*  end mainline
oProp.RunningPrg=[main.prg]

*!*	*!*    COMMENT OUT FOR PRODUCTION
lcHTMLout = DebugDump(lcHTMLout) && DEBUG Dump Routine			  *!*	*!*    COMMENT OUT FOR PRODUCTION
*!*	*!*    COMMENT OUT FOR PRODUCTION

*!*	oAA=null       && Clear class and program from memory
*!*	CLEAR CLASS ('schedbizobj')  && Clear class and program from memory
*!*	CLEAR PROGRAM ('prg\utiltest2.prg')    && Clear class and program from memory
*RELEASE PROCEDURE 'c:\avfp5.61Demo\prg\utiltest'   && Clear class and program from memory
* CLOSE DATA   && optionally close tables after each hit
* now we'll return the HTML output to the browser
RETURN STRCONV(lcHTMLout,11)

************************************************************************
*
***FUNCTIONS******************
*
************************************************************************

* include

*********************************

*** Function: Include an HTML file as part of the output

************************************************************************
FUNCTION include
LPARAMETERS lcHTMLfile
lcHTMLout= FILETOSTR(oProp.HTMLpath+lcHTMLfile)
RETURN oHTML.mergescript(lcHTMLout)

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

************************************************************************

* DebugDump

*********************************

*** Function: Output Debugging Variables at the bottom

************************************************************************
FUNCTION DebugDump
LPARAMETERS lcHTMLout
*DEBUG Dump Routine
   DO CASE
   CASE oRequest.querystring("debug")=="on"
	llDebug= .T.
   CASE oRequest.querystring("debug")=="off"
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
	lcHTMLout = lcHTMLout + oHTML.mergescript(FILETOSTR(oProp.HTMLpath+'aspvars'+oProp.Ext))
ENDIF
*!*	DISPLAY MEMORY LIKE * TO FILE 'c:\temp\test.txt'
*!*	lcHTMLout= lcHTMLout+'<pre>'+FILETOSTR('c:\temp\test.txt')+'</pre>'
RETURN lcHTMLout 
ENDFUNC && DEBUG Dump Routine

************************************************************************

* cookielogin

*********************************

*** Function: authenticate against a dbf using cookie

************************************************************************
FUNCTION CookieLogin
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
FUNCTION TableAuth
LPARAMETERS lcName,lcPassWord,lcAutoLogin
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

	IF UPPER(ALLTRIM(m.lcPassWord)) == UPPER(ALLTRIM(cnusers.PASSWORD))
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
			INSERT INTO mcookies (KEY, USER, PASS) VALUES (lcNewKey, lcName, lcPassWord)
			oCookie.WRITE("mkey",lcNewKey,"January 1, 2035")
		ENDIF

   ENDIF

ENDIF

************************************************************************

* AVFPinit

*********************************

*** Function: Set up data and html paths

************************************************************************
FUNCTION AVFPinit
* Set up data and html paths
************************************************************************

* Set Data and HTML paths (adjust per your needs as necessary)

	*SET PATH TO oProp.AppStartPath+'data\AVFPdemo41\' && SET DEFA TO 'c:\mydata\' 
	*oProp.DataPath =  oProp.AppStartPath+'data\AVFPdemo41\' 
	oProp.HtmlPath=oProp.AppStartPath && oProp.cHTMLpath='c:\myHTML\'

*Check if authenticated 
oSession.Value("authenticated",IIF(EMPTY(oSession.Value("authenticated"));
 .OR. ISNULL(oSession.Value("authenticated")),.F.,oSession.Value("authenticated")))

RETURN

ENDFUNC 