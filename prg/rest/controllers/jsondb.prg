* JSONDB.PRG
* JSON save/retrieve service
*
* This service responds only to POSTs requests (addAction). It
* expects a JSON object like this:
*
* {
*   "action" : "action to perform",
*   "repository" : "name of the JSON repository where the action should be performed",
*   "data" : {a JSON object with the data required by the action}
* }
*
* The service respond with a JSON string like the following:
*
* {
*  "action" : "action performed",
*  "repository": "JSON repository where the action was performed",
*  "result" : true | false,
*  "data" : {a JSON object with the requested data},
*  "error" : "description of the error ocurred (in case result = false)"
* }
*
* The service respond to the following requestss:
*
* SERVICE HANDLING
* {"action" : "configure", "data" : {"connectionType" : "vfp,odbc", "odbcConnString" : "connection-string", "vfpFolder" : "vfp-dbf-folder"}}
* {"action" : "configuration" } -- Return service configuration
* 
* REPOSITORY HANDLING
* {"action" : "create", "repository" : "name of the repository to be created", "data" : {repository-schema}}
* {"action" : "drop", "repository" : "name of the repository to be dropped" }
* {"action" : "info", "repository" : "name of the repository whom info is requested" }
* {"action" : "list" } -- List of available repositories
*
* DATA HANDLING
* {"action" : "save", "repository" : "name of the repository to update", "data" : {data to be added to the repository}}
* {"action" : "retrieve", "repository" : "name of the repository to query", "data" : {"parameters" : {search values}, "order" : "order"}}
* {"action" : "delete", "repository" : "name of the repository to update", "data" : {"parameters" : {search values}}
*
* ACTIONS RESPONSE DATA
* configuration: {"connectionType" : "vfp,odbc", "odbcConnString" : "connection-string", "odbcDatabase" : "databasename", "vfpFolder" : "vfp-dbf-folder"}
* list:          {"rowcount" : number-of-rows, "rows" : [{"name" : "repository name", "rows" : rows-in-the-repository},...]}
* info:          {"rowcount" : number-of-rows}
* save:          {saved row data (including any identity column)}
* retrieve:      {"rows" : [rows that matched the search values], "rowcount": returned-rows-count}
* delete:        {"rowcount" : number-of-deleted-rows}
*
* REPOSITORY SCHEMA
* { 
*   "columns" : [{"name" : "column-name", "type" : "vfp-data-type", "lon" : lon, "dec" : dec}, ...],
*   "primaryKey" : "columnName",
*   "indexes" : [{"name" : "index-name", "key" : "index-expr"}, ...]
* }
*
* EXAMPLES
* 1. Configure service for DBF storage:
*    {"action" : "configure", "data" : {"connectionType" : "DBF", "vfpFolder" : "c:\data\"}}
*
* 2. Configure service for ODBC storage:
*    {"action" : "configure", "data" : {"connectionType" : "ODBC", "odbcConnString" : "dsn=local;uid=sa;pwd=easy;dbname=jsondbd;"}}
*
* 3. Create a repository:
*    {
*     "Action" : "create", 
*     "repository" : "users", 
*     "data" : { 
*                "columns" : [ 
*                             {"name" : "loginname", "type" : "C", "lon" : 15 },
*                             {"name" : "fullname", "type" : "C", "lon" : 50 },
*                             {"name" : "password", "type" : "C", "lon" : 15 },
*                             {"name" : "groupname", "type" : "C", "lon" : 15},
*                             {"name" : "active", "type" : "L"},
*                             {"name" : "lastlogin", "type" : "T"}
*                            ],
*               "primaryKey" : "loginname",
*               "indexes" : [
*                            {"name" : "users1", "key" : "groupname"},
*                            {"name" : "users2", "key" : "active"}
*                           ]
*              }
*    }
*
* 4. Add a record to a repository:
*    {
*     "Action" : "save", 
*     "repository" : "users", 
*     "data" : { 
*               "loginname" : "vespina",
*               "fullname" : "victor espina",
*               "password" : "4FA674C67F8A9BAD",
*               "groupname" : "sysop",
*               "active" : true,
*               "lastlogin" : null
*             }
*    }
*
*
* 5. Retrieve an specific record from a repository:
*    {
*     "Action" : "retrieve", 
*     "repository" : "users", 
*     "data" : {"parameters" : {
*                                "loginname" : "vespina"
*                              }
*    }                
*
*    RESPONSE:
*    {
*     "Action" : "retrieve", 
*     "repository" : "users", 
*     "result" : true,
*     "data" : { 
*               "rowcount" : 1,
*               "rows" : [
*                         {
*                          "loginname" : "vespina",
*                          "fullname" : "victor espina",
*                          "password" : "4FA674C67F8A9BAD",
*                          "groupname" : "sysop",
*                          "active" : true,
*                          "lastlogin" : null
*                         }
*                        ]
*             }
*    }
*
* 6. Retrieve a list of records from a repository:
*    {
*     "Action" : "retrieve", 
*     "repository" : "users", 
*     "data" : {
*                "parameters": {
*                               "groupname" : "sysop",
*                               "active" : true
*                              },
*                "order" : "groupname"
*             }
*    }
*
*    RESPONSE:
*    {
*     "Action" : "retrieve", 
*     "repository" : "users", 
*     "result" : true,
*     "data" : { 
*               "rowcount" : 2,
*               "rows" : [
*                         {
*                          "loginname" : "vespina",
*                          "fullname" : "victor espina",
*                          "password" : "4FA674C67F8A9BAD",
*                          "groupname" : "sysop",
*                          "active" : true,
*                          "lastlogin" : null
*                         },
*                         {
*                          "loginname" : "jsnow",
*                          "fullname" : "john snow",
*                          "password" : "4FA674C67F8A9BAD",
*                          "groupname" : "sysop",
*                          "active" : true,
*                          "lastlogin" : "2014-06-10T14:23:00"
*                         }
*                        ]
*             }
*    }
*
* 7. Update a record to a repository:
*    {
*     "Action" : "save", 
*     "repository" : "users", 
*     "data" : { 
*               "parameters" : {
*                               "loginname" : "vespina",
*                               "lastlogin" : "2014-06-20T10:00:00"
*                              }
*             }
*    }
*
* 8. Drop a record from a repository (with failed response):
*    {
*     "Action" : "delete", 
*     "repository" : "users", 
*     "data" : { "parameters" : {"loginname" : "vespina"}}
*    }
*
*    RESPONSE:
*    {
*     "Action" : "delete", 
*     "repository" : "users", 
*     "result" : false,
*     "error" : "User can not be deleted"
*    }
*
*
* 9. Delete a list of records from a repository:
*    {
*     "Action" : "delete", 
*     "repository" : "users", 
*     "data" : {
*               "groupname" : "sysop"},
*               "active" : false
*              }
*    }
*
*    RESPONSE:
*    {
*     "Action" : "delete", 
*     "repository" : "users", 
*     "result" : true,
*     "data" : { "rowcount" : 2 }
*    }
*
 
DEFINE CLASS jsondbController AS restController
 *
 Caption = "JsonDB"
 Description = "JsonDB REST Controller"
 Version = "1.0"
 Author = "Victor Espina"
 
 action = ""        && Last action handled
 repository = ""    && Last repository affected
 Response = NULL    && Response data 
 Config = NULL       && Service configuration
 configFolder = ""  && Location of the configuration files
 dbStore = NULL     && Access to the current JSON store      
 
 
 PROCEDURE Init
  DODEFAULT()
  SET DELETED OFF
  SET MULTILOCKS ON
 ENDPROC
 
 PROCEDURE collectGarbage
  THIS.Response = NULL
  THIS.Config = NULL
  IF !ISNULL(THIS.dbStore)
   THIS.dbStore.collectGarbage()
   THIS.dbStore = NULL
  ENDIF
  DODEFAULT()
 ENDPROC
 
 PROCEDURE configFolder_Access
 RETURN ADDBS(THIS.homeFolder) + "jsondb"
 PROCEDURE configFolder_Assign(vNewVal)
 
 
 ******************************************************
 **
 **      S E R V I C E     I N T E R F A C E
 **
 ******************************************************
 
 * infoAction
 * Return information about the service
 *
 PROCEDURE infoAction
  LOCAL cJSON
  TEXT TO cJSON TEXTMERGE NOSHOW
  {
   "name" : "<<THIS.Caption>>",
   "description: "<<THIS.Description>>",
   "version" : "<<THIS.Version>>",
   "author" : "<<THIS.Author>>",
   "configFolder": "<<THIS.configFolder>>"
  }
  ENDTEXT
  RETURN THIS.returnJSON(cJSON)
 ENDPROC
 
 
 * addAction
 * Main entry point of the service. Here we parse
 * the request and invoque the appropiate action
 * handler
 *
 PROCEDURE addAction
  THIS.action = ""
  THIS.repository = ""
  THIS.Response = THIS.newResponse()
  

  * Check if the request contains data
  IF ISNULL(THIS.Data)
   THIS.setErrorResponse("Invalid call. Form value 'restData' is missing")
   RETURN THIS.returnJSON(THIS.Response)
  ENDIF 


  * Load current configuration
  IF NOT THIS.loadConfiguration()
   RETURN THIS.returnJSON(THIS.Response)
  ENDIF

  
  * If configured, load the store delegate
  IF THIS.Config.Configured
   DO CASE
      CASE THIS.Config.connectionType == "dbf"
           THIS.dbStore = oAVFP.New("jsondbDbfStore", THIS.classLibrary)
           
      CASE THIS.Config.connectionType == "odbc"
           THIS.dbStore = oAVFP.New("jsondbOdbcStore", THIS.classLibrary)           
   ENDCASE

   IF ISNULL(THIS.dbStore)
    THIS.setErrorResponse("Invalid connection type - " + THIS.Config.connectionType)
    RETURN THIS.ReturnJSON( AVToJSON(THIS.REsponse) )
   ENDIF

   THIS.dbStore.Config = THIS.Config
   THIS.dbStore.Response = THIS.Response
  ENDIF
    
    
  * Parse the request data
  LOCAL oCall
  oCall = THIS.parseRequestData(THIS.Data)
  IF !THIS.Response.Result
   RETURN THIS.returnJSON( AVToJSON(THIS.Response) )
  ENDIF


  * If action is not related to configuration and the service
  * is not configured, ends here
  IF !INLIST(oCall.ACtion,"configure","configuration") AND !THIS.Config.Configured
   THIS.setErrorResponse("The service is not configured. Please use the 'configure' action")
   RETURN THIS.returnJSON( AVToJSON(THIS.Response) )
  ENDIF
 
 
  * Invoke the appropiate handler
  THIS.Response.Action = oCall.Action
  THIS.Response.Repository = oCall.Repository
  TRY
  DO CASE
          * Service actions
     CASE oCall.action == "configure"
          THIS.configureService(oCall.Data)
          
     CASE oCall.action == "configuration"
          THIS.getServiceConfiguration()
     
     
     
          * Repository actions
     CASE oCall.action == "create"
          THIS.createRepository(oCall.Repository, oCall.Data)
          
     CASE oCall.action == "drop"
          THIS.dropRepository(oCall.Repository)
         
     CASE oCall.action == "info"
          THIS.getRepositoryInfo(oCall.Repository)
          
     CASE oCall.action == "list"
          THIS.listRepositories()
     
     
          
          * Data actions
     CASE oCall.action == "save"
          THIS.saveDataToRepository(oCall.Repository, oCall.Data)
          
     CASE oCall.action == "retrieve"
          THIS.queryRepository(oCall.Repository, oCall.Data)
          
     CASE oCall.action == "delete"
          THIS.deleteFromRepository(oCall.Repository, oCall.Data)
          
          
          * Invalid action
     OTHERWISE
         THIS.serErrorResponse("Invalid call. Action '" + oCall.Action + "' is not implemented")
  ENDCASE
  
  CATCH TO ex
    THIS.setErrorResponse("An error has ocurred when processing the action '" + oCall.Action + "' at " + ex.Procedure + "(" + ALLTRIM(STR(ex.LineNo)) + "): " + ex.Message)
    
  ENDTRY  
    
  RETURN THIS.returnJSON( AVToJSON(THIS.Response) )
 ENDPROC
 
 
 
 * listAction
 * JsonDB presentation page
 *
 PROCEDURE listAction
  RETURN THIS.loadPage("{home}/jsondb/jsondb.avfp")
 ENDPROC
 
 
 
 * Examples
 * Show some code examples of JsonDB
 *
 PROCEDURE Examples
  *RETURN "Under construction"
  RETURN THIS.loadPage("{home}/jsondb/examples.avfp")
 ENDPROC
 
 * Reference
 * Show JsonDB user's manual
 *
 PROCEDURE Reference
  RETURN "Under construction"
  *RETURN THIS.loadPage("{home}/jsondb/reference.avfp")
 ENDPROC
 
 
 
 ******************************************************
 **
 **     S E R V I C E    C O N F I G U R A T I O N
 **
 ******************************************************
 
 * configureService
 * Change service configuration
 *
 HIDDEN PROCEDURE configureService(poData)
  poData.connectionType = LOWER(ALLTRIM(poData.connectionType))
  DO CASE
     CASE poData.connectionType == "dbf"
          IF EMPTY(NVL(poData.dbfFolder,""))
           poData.dbfFolder = "{home}"
          ENDIF
          poData.dbfFolder = STRT(poData.dbfFolder, "{home}", CHRTRAN(THIS.homeFolder,"\","/")) 
          IF DIRECTORY(poData.dbfFolder)
           WITH THIS.Config
            .connectionType = "dbf"
            .dbfFolder = poData.dbfFolder
           ENDWITH
          ELSE
           THIS.setErrorResponse("Folder not found: " + poData.dbfFolder)
          ENDIF
           
     CASE poData.connectionType == "odbc"
          LOCAL nConn
          nConn = SQLSTRINGCONNECT(poData.odbcConnString)
          IF nConn >= 0
           SQLDISCONNECT(nConn)
           WITH THIS.Config
            .connectionType = "odbc"
            .odbcConnString = poData.odbcConnString
           ENDWITH
          ELSE
           THIS.setErrorResponse("Connection error: " + THIS.getLastOdbcError())
          ENDIF
          
     
     OTHERWISE
         THIS.setErrorResponse("Invalid connectionType (" + poData.connectionType + ")")
  ENDCASE
  
  IF THIS.Response.Result
   THIS.Response.Data = THIS.Config   
   THIS.Config.Configured = .T.
   THIS.saveConfiguration()
  ENDIF
 ENDPROC
 
 
 * getServiceConfiguration
 * Returns current service configuration
 *
 HIDDEN PROCEDURE getServiceConfiguration()
  LOCAL oData
  THIS.Response.Data = THIS.Config
  IF THIS.Response.Data.Configured AND ;
     THIS.Response.Data.connectionType == "dbf"
   THIS.Response.Data.dbfFolder = STRT(THIS.Response.Data.dbfFolder, CHRTRAN(THIS.homeFolder, "\", "/"), "{home}")
  ENDIF
 ENDPROC
 
 
 * saveConfiguration
 * Save service configuration
 *
 HIDDEN PROCEDURE saveConfiguration()
  IF NOT DIRECTORY(THIS.configFolder)
   THIS.setErrorResponse("Please, create this folder (read/write) and try again: " + THIS.configFolder)
   RETURN
  ENDIF
  STRTOFILE(AVToJSON(THIS.Config, true), ADDBS(THIS.configFolder) + "configuration.json")
 ENDPROC
 
 
 * loadConfiguration
 * Load last saved configuration
 *
 HIDDEN PROCEDURE loadConfiguration()
  THIS.Config = NULL
  TRY
    LOCAL cFile
    cFile = ADDBS(THIS.configFolder) + "configuration.json"
    IF FILE(cFile)
     THIS.Config = AVEvalJSON(FILETOSTR(cFile))
     IF !EMPTY(AVJSONError())
      THIS.Config = NULL
      THIS.setErrorResponse("Error parsing configuration.json: " + AVJSONError())
     ENDIF
    ENDIF
    
  CATCH TO ex
    THIS.setErrorResponse(ex.Message)
    THIS.Config = NULL
  ENDTRY
  
  RETURN !ISNULL(THIS.Config)
 ENDPROC

 
 ******************************************************
 **
 **    R E P O S I T O R I E S    H A N D L I N G
 **
 ****************************************************** 
 
 * createRepository
 * Creates a new json repository
 *
 HIDDEN PROCEDURE createRepository(pcName, poData)
  * Check if the given data is an schema object
  IF !PEMSTATUS(poData, "columns", 5) OR ;
     !PEMSTATUS(poData, "indexes", 5) OR ;
     !PEMSTATUS(poData, "primaryKey", 5)
   THIS.setErrorResponse("Invalid json data. One or more required properties are missing")
   RETURN 
  ENDIF   
  
  * Check if the repository already exists
  IF THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse("The repository '"+ pcName + "' already exists")
   RETURN
  ENDIF
  
  * Create the repository
  THIS.dbStore.createRepository(pcName, poData)
 ENDPROC
 
 
 * dropRepository
 * Drops an existing repository
 *
 HIDDEN PROCEDURE dropRepository(pcName)
  IF NOT THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not exist", pcName))
   RETURN
  ENDIF
  THIS.dbStore.dropRepository(pcName)
 ENDPROC
 
 
 * getRepositoryInfo
 * Returns some info for a given repository
 *
 HIDDEN PROCEDURE getRepositoryInfo(pcName)
  IF NOT THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not exist", pcName))
   RETURN
  ENDIF
  THIS.Response.Data = THIS.dbStore.getRepositoryInfo(pcName)
 ENDPROC
 
 
 * listRepositories
 * Return a list of available repositories
 *
 HIDDEN PROCEDURE listRepositories()
  THIS.Response.Data = AVObject("rowcount,rows",0,null)
  WITH THIS.Response.Data
   .Rows = THIS.dbStore.listRepositories()
   .rowCount = .Rows.Count   
  ENDWITH
 ENDPROC
 
 
 
 ******************************************************
 **
 **    R E P O S I T O R Y    A C C E S S
 **
 ****************************************************** 
 
 * saveDatatoRepository
 * Add or update a record in a repository
 *
 HIDDEN PROCEDURE saveDataToRepository(pcName, poData)
  IF NOT THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not exist", pcName))
   RETURN
  ENDIF
  THIS.dbStore.updateRepository(pcName, poData)
 ENDPROC
 
 
 * queryRepository
 * Retrieve data from a repository
 *
 HIDDEN PROCEDURE queryRepository(pcName, poData)
  IF NOT THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not exist", pcName))
   RETURN
  ENDIF

  * Build search expr
  LOCAL ARRAY aColumns[1]
  LOCAL nCount, i, cWhere, cOrder, oParams
  cWhere = NULL
  cOrder = NULL
  oParams = NULL
  IF PEMSTATUS(poData, "parameters", 5) AND !ISNULL(poData.Parameters)
   oParams = poData.Parameters
   nCount = AMEMBERS(aColumns, oParams)
   cWhere = ""
   FOR i = 1 TO nCount
    cColumn = LOWER(aColumns[i])
    cWhere = cWhere + IIF(i>1," AND ","") + cColumn + " = poRow." + cColumn
   ENDFOR
  ENDIF
  IF PEMSTATUS(poData, "order", 5)
   cOrder = poData.order
  ENDIF
  THIS.dbStore.queryRepository(pcName, cWhere, cOrder, oParams)
 ENDPROC
 
 
 * deleteFRomRepository
 * Delete one or more rows from a repository
 *
 HIDDEN PROCEDURE deleteFromRepository(pcName, poData)
  IF NOT THIS.dbStore.isRepository(pcName)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not exist", pcName))
   RETURN
  ENDIF
  
  IF NOT PEMSTATUS(poData, "parameters", 5) OR ISNULL(poData.PArameters)
   THIS.setErrorResponse(AVFormat("A required value is missing: 'parameters'"))
   RETURN
  ENDIF


  * Build search expr
  LOCAL ARRAY aColumns[1]
  LOCAL nCount, i, cWhere
  cWhere = NULL
  nCount = AMEMBERS(aColumns, poData.Parameters)
  cWhere = ""
  FOR i = 1 TO nCount
   cColumn = LOWER(aColumns[i])
   cWhere = cWhere + IIF(i>1," AND ","") + cColumn + " = poRow." + cColumn
  ENDFOR
  THIS.dbStore.dropFromRepository(pcName, cWhere, poData.Parameters)
 ENDPROC


 


 
 ******************************************************
 **
 **                S U P P O R T 
 **
 ******************************************************
 
 * parseCall
 * Parse the JSON data included in the request
 *
 HIDDEN PROCEDURE parseRequestData(puData)
  LOCAL oRequest
  oRequest = puData
  IF VARTYPE(oRequest) = "C"
   TRY
    oRequest = AVEvalJSON(pcData)
   CATCH TO ex
    THIS.setErrorResponse("Invalid call. Data is not well formatted: " + ex.Message)
   ENDTRY
   IF !THIS.Response.Result
    RETURN NULL
   ENDIF
  ENDIF
  
  IF !PEMSTATUS(oRequest, "action", 5)
   oRequest = NULL
   THIS.setErrorResponse("Invalid call. Data is not well formatted (action property is missing)")
  ENDIF
  
  IF THIS.Response.Result
   oRequest.action = LOWER(ALLTRIM(oRequest.action))
  ENDIF
  
  RETURN oRequest
 ENDPROC
 


 * newResponse
 * Prepares a reponse object
 *
 HIDDEN PROCEDURE newResponse
  RETURN AVObject("action,repository,result,error,data",null,null,.T.,null,null)
 ENDPROC
 

 * newConfig
 * Prepares a configuration object
 *
 HIDDEN PROCEDURE newConfig
  RETURN AVObject("configured,connectionType,dbfFolder,odbcConnString",.F.,null,null,null)
 ENDPROC

 
 * setErrorResponse
 * Set an error response
 *
 HIDDEN PROCEDURE setErrorResponse(pcErrorText, poData)
  THIS.Response.Result = .F.
  THIS.Response.Error = pcErrorText
  THIS.Response.Data = IIF(PCOUNT() = 2, poData, NULL)
 ENDPROC
 
 
 * getLastOdbcError
 * Return the last ODBC error
 *
 HIDDEN PROCEDURE getLastOdbcError
  LOCAL ARRAY aErrInfo[1]
  AERROR(aErrInfo)
  RETURN aErrInfo[2]
 ENDPROC
 
 
ENDDEFINE


******************************************************
**
** jsondbStore (Class)
** Abstract class for json store managment
**
****************************************************** 
DEFINE CLASS jsondbStore AS avfpObject

 Config = NULL
 Response = NULL
 
 PROCEDURE createRepository(pcName)
 PROCEDURE dropRepository(pcName)
 PROCEDURE listRepositories()
 PROCEDURE isRepository(pcName)
 PROCEDURE getRepositoryInfo(pcName)
 
 PROCEDURE queryRepository(pcName, pcWhere, pcOrder, poRow)
 PROCEDURE updateRepository(pcName, poRow)
 PROCEDURE dropFromRepository(pcName, pcWhere, poRow)

 * setErrorResponse
 * Set an error response
 *
 PROCEDURE setErrorResponse(pcErrorText, poData)
  THIS.Response.Result = .F.
  THIS.Response.Error = pcErrorText
  THIS.Response.Data = IIF(PCOUNT() = 2, poData, NULL)
 ENDPROC 

 PROCEDURE collectGarbage
  THIS.Config = NULL
  THIS.Response = NULL
 ENDPROC 
ENDDEFINE



******************************************************
**
** jsondbDbfStore (Class)
** Delegate class for json dbf store managment
**
****************************************************** 
DEFINE CLASS jsondbDbfStore AS jsondbStore

 
 PROCEDURE createRepository(pcName, poSchema)
  LOCAL cFile,cScript,i,oItem,nWkARea
  cFile = THIS.getRepositoryFile(pcName)
  cScript = AVFormat("CREATE TABLE '{0}' (", cFile)
  nWkArea = SELECT()
  
  * Table
  FOR i = 1 TO poSchema.Columns.Count
   oItem = poSchema.Columns.Item[i]
   cScript = cScript + IIF(i > 1,",","") + oItem.Name + " " + oItem.Type
   IF PEMSTATUS(oItem, "lon", 5) AND !ISNULL(oItem.lon)
    cScript = cScript + "(" + ALLTRIM(STR(oItem.Lon))
    IF PEMSTATUS(oItem, "dec", 5) AND !ISNULL(oItem.Dec)
     cScript = cScript + "," + ALLTRIM(STR(oItem.Dec))    
    ENDIF
    cSCript = cScript + ")"
   ENDIF
  ENDFOR
  cScript = cScript + ")"
  
  TRY
   EXECSCRIPT(cScript)
  
  CATCH TO ex
   THIS.setErrorResponse(AVFormat("An error has ocurred when trying to create the repository '{0}': {1}", pcName, ex.Message))
   THIS.Response.Data = NSStruct("sql", cScript)
  ENDTRY
  IF NOT THIS.REsponse.Result
   SELECT (nWkArea)  
   RETURN
  ENDIF
  
  * Primary key
  IF PEMSTATUS(poSchema, "primaryKey", 5)
   TRY
    cScript = AVFormat("INDEX ON {0} TAG PK CANDIDATE", poSchema.primaryKey)
    EXECSCRIPT(cScript)
    
   CATCH TO ex
    THIS.setErrorResponse(AVFormat("An error has ocurred when trying to create the repository '{0}': {1}", pcName, ex.Message))
    THIS.Response.Data = NSStruct("sql", cScript)
    USE
    ERASE (cFile)
   ENDTRY
   IF NOT THIS.REsponse.Result
    SELECT (nWkArea)  
    RETURN
   ENDIF
  ENDIF
  
  * Other indexes
  FOR i = 1 TO poSchema.Indexes.Count
   oItem = poSchema.Indexes.Item[i]
   cScript = AVFormat("INDEX ON {0} TAG {1}", oItem.Key, oItem.Name)
   TRY
    EXECSCRIPT(cScript)
  
   CATCH TO ex
    THIS.setErrorResponse(AVFormat("An error has ocurred when trying to create the repository '{0}': {1}", pcName, ex.Message))
    THIS.Response.Data = NSStruct("sql", cScript)
    USE
    ERASE (cFile)
   ENDTRY
   IF NOT THIS.Response.Result
    EXIT
   ENDIF
  ENDFOR
  
  IF THIS.Response.Result
   USE
  ENDIF
  
  SELECT (nWkArea)
 ENDPROC
 



 PROCEDURE dropRepository(pcName)
  LOCAL cFile
  cFile = ADDBS(THIS.Config.dbfFolder) + pcName + ".*"
  TRY
   ERASE (cile)
  CATCH TO ex
   THIS.setErrorResponse(AVFormat("An error ocurred while trying to drop the repository '{0}': {1}", pcName, ex.Message))
  ENDTRY
 ENDPROC



 PROCEDURE listRepositories()
  LOCAL cFolder,nCount,oRepositories,i,cName
  LOCAL ARRAY aRepositories[1]
  cFolder = ADDBS(THIS.Config.dbfFolder) + "*.DBF"
  nCount = ADIR(aRepositories, cFolder)
  oRepositories = CREATEOBJECT("Collection")
  FOR i = 1 TO nCount
   cName = JUSTSTEM(aRepositories[i,1])
   oRepositories.Add( THIS.getRepositoryInfo(cName) )
  ENDFOR
  RETURN oRepositories
 ENDPROC
 
 
 PROCEDURE isRepository(pcName) 
  LOCAL cFile
  cFile = THIS.getRepositoryFile(pcNAme)
  RETURN FILE(cFile)
 ENDPROC
 
 
 PROCEDURE getRepositoryInfo(pcName)
  LOCAL cFile,nWkArea,cAlias,oInfo
  cFile = THIS.getRepositoryFile(pcNAme)
  oInfo = AVObject("name,rows")
  oInfo.Name = LOWER(pcName)
  nWkArea = SELECT(0)
  cAlias = pcNAme + "_JSONDB"
  SELECT 0
  USE (cFile) ALIAS (cAlias) AGAIN
  COUNT TO oInfo.Rows
  USE
  SELECT (nWkArea)
  RETURN oInfo
 ENDPROC
 
 
 
 PROCEDURE queryRepository(pcName, pcWhere, pcOrder, poRow)
  LOCAL cFile,nWkARea,oRow,oPK,uPKValue
  cFile = THIS.getRepositoryFile(pcNAme)
  oRow = NULL
  nWkArea = SELECT()
 
  * Open repository
  SELECT 0
  USE (cFile) ALIAS (pcName)
  SET DELETED ON 
    
  * Run query
  LOCAL lResult,cCmd,cAlias
  calias = pcName + "_RESULT"
  lResult = .T.
  TRY
   cCmd = AVFormat("SELECT * FROM {0}", pcName)
   IF !ISNULL(pcWhere)
    cCmd = AVFormat(cCmd + " WHERE {0}", pcWhere)
   ENDIF
   IF !ISNULL(pcOrder)
    cCmd = AVFormat(cCmd + " ORDER BY {0}", pcOrder)
   ENDIF
   cCmd = AVFormat(cCmd + " INTO CURSOR {0}", cAlias)
   cCmd = "PARAMETERS poRow" + CHR(13) + CHR(10) + cCmd
   EXECSCRIPT(cCmd, poRow)
   
   IF NOT USED(cAlias)
    THIS.setErrorResponse(AVFormat("An unknown error ocurred when trying to query repository '{0}'", pcName))
    THIS.Response.Data = AVObject("searchExpr,searchData", pcWhere, poRow)
    lResult = .F.
   ENDIF
   
   
  CATCH TO ex
   THIS.setErrorResponse(AVFormat("An error ocurred when trying to query repository '{0}': {1}", pcName, ex.Message))
   THIS.Response.Data = AVObject("searchExpr,searchData", pcWhere, poRow)
   lResult = .F.
   
  ENDTRY
  
  
  * Return updated data
  IF lResult
   LOCAL oResult
   oResult = AVObject("rowcount,rows,where,order,sql")
   oResult.rowCount = RECCOUNT(cAlias)
   oResult.Rows = AVToObject(cAlias)
   oResult.Where = pcWhere
   oResult.Order = pcOrder
   oResult.sql = cCmd
   THIS.Response.Data = oResult
  ENDIF
  
  
  * Cloose repository and exit
  IF USED(cAlias)
   USE IN (cAlias)
  ENDIF
  
  USE IN (pcName)
  SELECT (nWkArea)
  
  RETURN oRow
 ENDPROC
 

 
 PROCEDURE updateRepository(pcName, poRow)
  LOCAL cFile,nWkARea,oRow,oPK,uPKValue
  cFile = THIS.getRepositoryFile(pcNAme)
  oRow = NULL
  nWkArea = SELECT()
 
  * Open repository
  SELECT 0
  USE (cFile) ALIAS (pcName)
  CURSORSETPROP("Buffering",3)
  SET DELETED OFF
  
  * Get pk info
  oPK = THIS.getPKInfo(ALIAS())
  IF ISNULL(oPK.Name)
   THIS.setErrorResponse(AVFormat("The repository '{0}' does not has a primary key",. pcName))
   RETURN
  ENDIF
  
  * Get PK value
  IF PEMSTATUS(poRow, oPK.Key, 5)
   uPKValue = GETPEM(poRow, oPK.Key)
   SET ORDER TO PK
  ELSE
   THIS.setErrorResponse(AVFormat("Supplied data does not contains value '{0}'", LOWER(oPK.Key)))
  ENDIF
  
  * Check if row exist
  SET ORDER TO (oPK.Name)
  SEEK uPKValue
  IF FOUND() AND DELETED()
   RECALL
  ENDIF
  
  * Get row columns
  LOCAL ARRAY aColumns[1]
  LOCAL nCount, i, cCmd
  nCount = AMEMBERS(aColumns, poRow)
  
  * Prepare command
  cCmd = "REPLACE "
  FOR i = 1 TO nCount
   cColumn = LOWER(aColumns[i])
   IF cColumn == oPK.Key AND FOUND() && Skip PK column on UPDATE operations
    LOOP
   ENDIF
   cCmd = cCmd + cColumn + " WITH poRow." + cColumn + ","
  ENDFOR
  cCmd = LEFT(cCmd, LEN(cCmd) - 1)   


  * Save data
  SELECT (pcName)
  IF !FOUND()
   APPEND BLANK
  ENDIF
  
  LOCAL lResult
  lResult = .T.
  TRY
   cCmd = "PARAMETERS poRow" + CHR(13)+CHR(10) + cCmd
   EXECSCRIPT(cCmd, poRow)
   TABLEUPDATE(.T.)
   
  CATCH TO ex
   TABLEREVERT(.T.)
   THIS.setErrorResponse(AVFormat("An error ocurrend when trying to update repository '{0}': {1}", pcName, ex.Message))
   THIS.Response.Data = poRow
   lResult = .F.
   
  ENDTRY
  
  
  * Return updated data
  IF lResult
   SCATTER NAME oRow MEMO
   THIS.Response.Data = oRow
  ENDIF
  
  * Cloose repository and exit
  USE IN (pcName)
  SELECT (nWkArea)
  RETURN oRow
 ENDPROC
 
 


 PROCEDURE dropFromRepository(pcName, pcWhere, poRow)
  LOCAL cFile,nWkARea,oRow,oPK,uPKValue
  cFile = THIS.getRepositoryFile(pcNAme)
  oRow = NULL
  nWkArea = SELECT()
 
  * Open repository
  SELECT 0
  USE (cFile) ALIAS (pcName)
  SET DELETED ON
    
  * Delete rows
  LOCAL lResult,cCmd
  lResult = .T.
  TRY
   cCmd = AVFormat("DELETE FROM {0} WHERE {1}", pcName, pcWhere)
   EXECSCRIPT("PARAMETERS poRow" + CHR(13) + CHR(10) + cCmd, poRow)
   THIS.Response.Data = AVObject("rowcount,where,sql", _TALLY, pcWhere, cCmd)  
   
  CATCH TO ex
   THIS.setErrorResponse(AVFormat("An error ocurred when trying to delete one or more rows from the repository '{0}': {1}", pcName, ex.Message))
   THIS.Response.Data = AVObject("searchExpr,searchData", pcWhere, poRow)
   lResult = .F.
   
  ENDTRY
    
  
  * Cloose repository and exit
  USE IN (pcName)
  SELECT (nWkArea)
  RETURN oRow
 ENDPROC



 HIDDEN PROCEDURE getRepositoryFile(pcName)
  RETURN ADDBS(THIS.Config.dbfFolder) + pcName + ".DBF"
 ENDPROC
 

 HIDDEN PROCEDURE getPKInfo(pcAlias)
  LOCAL oPK,i
  oPK = AVObject("name,key")
  SELECT (pcAlias)
  FOR i = 1 TO TAGCOUNT()
   IF CANDIDATE(i)
    oPK.name = TAG(i)
    oPK.key = LOWER(KEY(i))
    EXIT
   ENDIF
  ENDFOR
  RETURN oPK
 ENDPROC

ENDDEFINE




******************************************************
**
** jsondbOdbcStore (Class)
** Delegate class for json odbc store managment
**
****************************************************** 
DEFINE CLASS jsondbOdbcStore AS jsondbStore

 PROCEDURE createRepository(pcName)
 PROCEDURE dropRepository(pcName)
 PROCEDURE listRepositories()
 PROCEDURE isRepository(pcName)
 PROCEDURE getRepositoryInfo(pcName)
 
 PROCEDURE queryRepository(pcName, pcWhere, poRow)
 PROCEDURE updateRepository(pcName, poRow)
 PROCEDURE dropFromRepository(pcName, pcWhere, poRow)
 
 PROCEDURE getLastOdbcError
  LOCAL ARRAY aErrInfo[1]
  AERROR(aErrInfo)
  RETURN aErrInfo[2]
 ENDPROC
 
ENDDEFINE
