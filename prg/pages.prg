*Settings
*!*	   lnTotPerPage  =10        && total records displayed per page
*!*	   lnpagenumbers =5         && how many page numbers to show
*!*	   lnStart=VAL(oRequest.querystring("page"))  && what page number are we on
*!*	   lcButton=oRequest.querystring("nav")       && which way are we going: next, previous, first, last
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

