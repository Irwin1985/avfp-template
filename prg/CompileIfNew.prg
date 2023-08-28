LPARAMETERS lcPrgName 
 *must be compiled object and compile is source date newer         
  IF !FILE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp") OR ;
   FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".prg",1) > FDATE(oProp.AppStartPath+"prg\"+lcPrgName+".fxp",1) 
  		COMPILE oProp.AppStartPath+"prg\"+lcPrgName+".prg"
   RETURN .T.
  ELSE
   RETURN .F.
  ENDIF