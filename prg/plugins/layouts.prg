* LAYOUTS.PRG
* Layouts implementation for ActiveVFP 6.04+
*
* Author: Victor Espina
*
DEFINE CLASS Layouts AS avfpParser

 cAuthor = "Victor Espina"
 cDescription = "Layouts parser"
 cVersion = "1.0"
 
 
 PROCEDURE Parse(pcHTML, plRecursive)
  *
  * Get page tag
  LOCAL oLayout
  oLayout = oHTML.getTags(pcHTML,"lp:layout")
  IF oLayout.Count = 0  && If page doesnt content lp:layout, there is nothing left to do 
   RETURN pcHTML
  ENDIF
  IF oLayout.Count > 1  && Check we have only on lp:layout tag
   RETURN "More than one instance of lp:page tag found."
  ENDIF
  oLayout = oLayout.Item[1]
  IF !PEMSTATUS(oLayout.Props,"Source",5)  && Check for tag's required properties
   RETURN "Property 'Source' is missing on lp:layout tag."
  ENDIF
  
  * Check if master page actually exists
  LOCAL cMaster, cHTML
  cMaster = oLayout.Props.Source
  *IF EMPTY(JUSTPATH(cMaster))
  * cMaster = "{root}/" + cMaster
  *ENDIF
  *cMaster = STRT(cMaster,"{root}",oAVFP.cRootFolder)  
  *cMaster = STRT(cMaster,"{home}",oProp.HtmlPath)
  *cMaster = AVLocate(cMaster)
  cMaster = AVLocate(cMaster)
  
  IF !FILE(cMaster)
   AVError(AVFormat("File not found: ({0})", LOWER(cMaster)))
  ENDIF
  cHTML = FILETOSTR(cMaster)
  
  
  * Parse the master page to check if it actually implements other masterpage
  cHTML = THIS.Parse(cHTML, .T.)

  
  * Expand page custom properties
  cHTML = THIS.expandProps(oLayout.Props, cHTML)


  * Get master page's placeholders
  LOCAL oPHList
  oPHList = oHTML.getTags(cHTML, "lp:placeholder")
  IF oPHList.Count = 0  && No placeholders? nothing left to do
   RETURN cHTML
  ENDIF
  
  
  * Get lp:content tags
  LOCAL oContents
  oContents = oHTML.getTags(pcHTML, "lp:content")
  
  
  * Inject content in the corresponding placeholders
  LOCAL i, oPH,cPH,j,oItem,oContent,nStart,nEnd,cBuff,cExternalContent
  FOR i = 1 TO oPHList.Count
   oPH = oPHList.Item[i]
   IF !PEMSTATUS(oPH.Props, "Name", 5)
    LOOP
   ENDIF
   cPH = LOWER(oPH.Props.Name)

   
   * Find the corresponding content
   oContent = NULL
   FOR j = 1 TO oContents.Count
    oItem = oContents.Item[j]
    IF !PEMSTATUS(oItem.Props, "Name", 5)
     LOOP
    ENDIF
    IF LOWER(oItem.Props.Name) == cPH
     oContent = oItem
     EXIT
    ENDIF
   ENDFOR

   IF ISNULL(oContent) && No content found for the placeholder?  generates a "empty" content
    oContent = AVObject("content", "")
   ELSE  
    * If content is empty but it has a "Source" property, load content
    * from the external file    
    IF PEMSTATUS(oContent.Props,"Source",5) AND EMPTY(oContent.content)
     cExternalContent = AVLocate(oContent.Props.Source)
     IF FILE(cExternalContent)
      oContent.content = oHTML.mergeScript(FILETOSTR(cExternalContent))
     ELSE
      oContent.content = "(file not found)" 
     ENDIF
    ENDIF
   ENDIF
     
     
   * Insert content in the placeholder
   nStart = ATC([<lp:placeholder Name="] + cPH + ["], cHTML)
   cBuff = SUBSTR(cHTML,nStart)
   nEnd = nStart + ATC([</lp:placeholder>], cBuff) + 16
   cHTML = LEFT(cHTML, nStart - 1) + oContent.Content + SUBSTR(cHTML, nEnd + 1)
  ENDFOR
    
  RETURN cHTML
  *
 ENDPROC
 
 
 HIDDEN PROCEDURE expandProps(poProps, pcHTML)
  LOCAL ARRAY aProps[1]
  LOCAL i,nCount,cProp,cValue,nPos
  nCount = AMEMBERS(aPRops, poProps, 0)
  FOR i = 1 TO nCount
   cProp = aProps[i]
   cValue = EVALUATE("poProps." + cProp)
   DO WHILE .T.
    nPos = ATC("%" + cProp + "%", pcHTML)
    IF nPos = 0 
     EXIT
    ENDIF
    pcHTML = LEFT(pcHTML, nPos - 1) + cValue + SUBSTR(pcHTML, nPos + LEN(cProp) + 2)
   ENDDO
  ENDFOR
  RETURN pcHTML
 ENDPROC

ENDDEFINE