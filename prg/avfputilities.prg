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
lcHTMLout= FILETOSTR(substr(oProp.AppStartPath,1,AT([\],oProp.AppStartPath,2))+lcHTMLfile)
RETURN oHTML.mergescript(lcHTMLout)

************************************************************************

* pages

*********************************

*** Function: Calculate pages and build a string to return with the page numbers and links

************************************************************************
*Settings from caller
*!*	   lnTotPerPage  =10        && total records displayed per page
*!*	   lnpagenumbers =5         && how many page numbers to show
*!*	   lnStart=VAL(oRequest.querystring("page"))  && what page number are we on
*!*	   lcButton=oRequest.querystring("nav")       && which way are we going: next, previous, first, last
FUNCTION pages
LPARAMETERS lnTotPerPage,lnpagenumbers,lnStart,lcButton,lnRowCount

* start page navigation stuff   
lnTotPages = 0    
START = NVL(lnStart,1)
IF START = 0 
	START= 1
ENDIF
lnPageMax = START * lnTotPerPage
lnPageBegin = (lnPageMax - lnTotPerPage)+1
IF lnRowCount < lnTotPerPage
		lnTotPages = 1
ELSE
     IF MOD(lnRowCount, lnTotPerPage) > 0
 		lnTotPages = INT(lnRowCount / lnTotPerPage) + 1
     ELSE
		lnTotPages = INT(lnRowCount / lnTotPerPage)
     ENDIF
ENDIF	
oSession.VALUE("totpages",lnTotPages)
DO CASE
CASE lcButton="First"
	START=1
	lnPageBegin=1
	lnPageMax=lnTotPerPage
CASE lcButton="Prev"
	IF lnPageBegin < 1 .OR. START -1 = 0
		START=1
		lnPageBegin=1
		lnPageMax=lnTotPerPage
	ELSE
		START=START-1
		lnPageBegin=lnPageBegin-lnTotPerPage
		lnPageMax=lnPageMax-lnTotPerPage
	ENDIF
CASE lcButton="Next"
	START=START+1
	IF START>lnTotPages
		START = lnTotPages
		lnPageMax =  START * lnTotPerPage
		lnPageBegin = (lnPageMax - lnTotPerPage)+1
		lnPageMax = lnRowCount
	ELSE
		lnPageBegin=lnPageBegin+lnTotPerPage
		lnPageMax=lnPageMax+lnTotPerPage
	ENDIF
CASE lcButton="Last"
	START=lnTotPages
	lnPageMax =  START * lnTotPerPage
	lnPageBegin = (lnPageMax - lnTotPerPage)+1
	lnPageMax = lnRowCount
OTHERWISE
	IF EMPTY(START)
		START=1
		lnPageBegin=1
		lnPageMax=lnTotPerPage
	ENDIF
ENDCASE	

* page numbers
lcPages=''
IF lnTotPages > 1
   lngroupnumber = ceiling(START/lnpagenumbers) &&Returns the next highest number
   FOR lnZ = lngroupnumber*lnpagenumbers-(lnpagenumbers-1) TO IIF(lnTotpages<lngroupnumber*lnpagenumbers,lnTotPages,lngroupnumber*lnpagenumbers) &&lnTotPages
	IF lnZ=START
	   lcPages=lcPages+[ <B>]+ALLTRIM(STR(lnZ))+[</B> ]
	ELSE
	   lcPages=lcPages+[ <a href="]+JustPath(oProp.ScriptPath)+[/];
		+oProp.Action+oProp.Ext+[?sid=]+oProp.SessID+[&page=]+ALLTRIM(STR(lnZ))+[&nav=]+[">];
		 +ALLTRIM(STR(lnZ))+[</a> ]
	ENDIF
   ENDFOR
ENDIF
lcPgBef=IIF(start=1,[],[<a href="]+JustPath(oProp.ScriptPath)+[/]+oProp.Action+oProp.Ext+[?nav=First"> << </a><a href="]+JustPath(oProp.ScriptPath)+[/]+oProp.Action+oProp.Ext+[?nav=Prev&page=]+ALLTRIM(STR(start))+[">Prev</a>])
lcPgAft=IIF(start=oSession.value("totpages"),[],[<a href="]+JustPath(oProp.ScriptPath)+[/]+oProp.Action+oProp.Ext+[?nav=Next&page=]+ALLTRIM(STR(start))+[">Next</a><a href="]+JustPath(oProp.ScriptPath)+[/]+oProp.Action+oProp.Ext+[?nav=Last"> >> </a>])
RETURN lcPgBef+lcPages+lcPgAft

************************************************************************

* newpkq

*********************************
FUNCTION newpkq
********************************************
*create new primary key
********************************************
LPARAMETERS tcTable
LOCAL lnCurrSelect, ;
   lcTableName, ;
   llUsed, ;
   lnCurrReprocess, ;
   luKey, ;
   lcKey, ;
   lcField, ;
   lcOldTalk, ;
   liOldidKey, ;
   lnDay, ;
   lnHour

lcOldTalk=SYS(103)
SET TALK OFF

lcAsserts=SET("ASSERTS")

SET ASSERTS ON

ASSERT TYPE("tcTable") = "C" ;
   AND ! EMPTY(tcTable) MESSAGE PROGRAM()+": Parameter must be character type and not empty..."

* Save the current work area, open the NEXTID table
* (if necessary), and find the desired table. If it
* doesn't exist, create a record for it.

lnCurrSelect = SELECT()
llUsed       = USED('QNewPKS')
lcTableName  = UPPER(ALLTRIM(tcTable))
IF llUsed
   SELECT "QNewPKS"
   SET ORDER TO "cTableName"
ELSE
   SELECT 0
   USE QNewPKS ORDER cTableName AGAIN SHARED
ENDIF llUsed
SEEK lcTableName
IF NOT FOUND()
   LOCATE
   CALCULATE MAX(QNewPKS.iidkey) TO liOldidKey
   INSERT INTO QNewPKS (iidkey, iNextKey, cTableName, iIncrement) ;
      VALUES (liOldidKey+1, 0,lcTableName, 1)

ENDIF NOT FOUND()

* Increment the next available ID.

lnCurrReprocess = SET('REPROCESS')
* SET REPROCESS TO AUTOMATIC
* Changed to NOT allow ESC to interrupt lock attempt
SET REPROCESS TO -1


IF RLOCK()
   lnMinute=INT(MINUTE(DATETIME())/10)
   IF lnMinute=0
   	  lnMinute=MINUTE(DATETIME())
	   IF lnMinute<2
	   	  lnMinute=1
	   	 ELSE
	   	  lnMinute = INT(lnMinute/2)
	   	  IF lnMinute = 4
	   	  	lnMinute = 2
	   	  ENDIF
       ENDIF  
   ELSE
   	   IF lnMinute>3
 	  	 lnMinute = 2  
   	   ENDIF
   ENDIF 
   IF lnMinute = 0
   	lnMinute = 1
   ENDIF		   
   IF lcTableName = "CASES"
	   REPLACE iNextKey WITH iNextKey + lnMinute
   ELSE
	   REPLACE iNextKey WITH iNextKey + iIncrement
   ENDIF 		   
   luKey = iNextKey
   UNLOCK
ENDIF RLOCK()

*!*	* Set the data type of the return value to match
*!*	* the data type of the primary key for the table.

*!*	lcKey = dbgetprop(tcTable, 'Table', 'PrimaryKey')
*!*	if not empty(lcKey)
*!*		lcField = key(tagno(lcKey, tcTable, tcTable), ;
*!*			tcTable)
*!*		if type(tcTable + '.' + lcField) = 'C'
*!*			luKey = str(luKey, fsize(lcField, tcTable))
*!*		endif type(tcTable + '.' + lcField) = 'C'
*!*	endif not empty(lcKey)

* Cleanup and return.

SET REPROCESS TO lnCurrReprocess
IF NOT llUsed
   USE
ENDIF NOT llUsed

SELECT (lnCurrSelect)
*SET TALK &lcOldTalk
SET ASSERTS &lcAsserts

RETURN luKey

ENDFUNC

************************************************************************

* hex2val

*********************************
* Turn a hexadecimal value into a decimal value
* Taken from the AATest project that comes with VFP7
FUNCTION hex2val
Lparameters tcString

Local lcChars, lnValue
lcChars = "0123456789abcdef"
lnValue = (Atc(Left(tcString, 1), lcChars) - 1) * 16
lnValue = lnValue + Atc(Right(tcString, 1), lcChars) - 1

Return lnValue
ENDFUNC

************************************************************************

* iis2arr

*********************************
Procedure IIS2Arr(taArray, tcRoot)
************************************
Lparameters taArray, tcRoot
*:Local array taArray[1]
Local lnCount, loIIS, loADSI
lnCount = 1
loADSI  = Null

If Empty(tcRoot)
	loIIS   = GetObject('IIS://LocalHost')
Else
	loIIS   = GetObject(tcRoot)
EndIf

Dimension taArray[1]
taArray[1] = loIIS

For each loADSI in loIIS
	lnCount = lnCount + _IIS2Arr(@taArray, loADSI)
EndFor

Return lnCount


***********************************
Procedure _IIS2Arr(taArray, toADSI)
***********************************
*:Local array taArray[1]
Local lnCount, lnSize, loADSI

lnCount = 1
lnSize = Alen(taArray) + 1
Dimension taArray[lnSize]
taArray[lnSize] = toADSI

For each loADSI in toADSI
	lnCount = lnCount + _IIS2Arr(@taArray, loADSI)
EndFor

Return lnCount

***********************************
Procedure CompileIfNew
***********************************
LPARAMETERS lcPrgName 
 *must be compiled object and compile is source date newer         
  IF !FILE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp") OR ;
   FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".prg",1) > FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp",1) 
  		COMPILE oProp.AppStartPath+"prg\"+lcPrgName+".prg"
   RETURN .T.
  ELSE
   RETURN .F.
  ENDIF