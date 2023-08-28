********************************************************************************************************
*Sample FoxPro prg to run as a background thread on the web
********************************************************************************************************
LPARAMETERS str   && str is comma delim string 
LOCAL lcID,P2,P3,P4,P5      
*get parameters
ALINES(larr,str,.F.,",")  && parse comma delim string to get all params passed
lcID=larr[1] &&1st param is ID, the rest are your parameters you optionally passed in comma delim string
P2=larr[2]  &&parameter 2
P3=larr[3]  &&parameter 3
P4=larr[4]  &&parameter 4
P5=larr[5]  &&parameter 5
*etc..
RELEASE larr

*setup to record events
oAsync=newobject("ThreadManager","webthreads2.prg")
oAsync.StartWebEvent(lcID,[Starting... background thread initiated])  && record start event
TRY   && use exception handling

****************************************************************
* Background thread code.  !!!!!!!!Put your code here!!!!!!!!
****************************************************************

*Main code - in this case, just simulate a long-running task   
			DECLARE Sleep ; 
			  IN WIN32API ;  
			  INTEGER nMillisecs 
*USE mydbf   &&test error
		FOR j=1 TO 100

                IF oAsync.Canceled(lcID)
                   exit
                ENDIF
                   
                 
    
               *************  Update thread status with result at intervals
    		DO CASE                
               CASE j=25
               	oAsync.StatusWebEvent(lcID,[25% Done ]+P2,.T.)  && send an update message
               CASE j=50
               	oAsync.StatusWebEvent(lcID,[50% Done ]+P3,.T.)  && along with the parms I sent from HTML file
               CASE j=75
               	oAsync.StatusWebEvent(lcID,[75% Done ]+P4,.T.)  && 3rd parm to StatusWebEvent is ladditive - add to text already there or not
               CASE j=100
               	oAsync.StatusWebEvent(lcID,[100% Done ]+P5,.T.)  && this is the form variable we passed 
               
		    ENDCASE
		    Sleep(1000)
               
		ENDFOR

**************************************
*end of main thread code!
**************************************

*error handling
CATCH TO oexp   && record any errors in the thread code
oAsync.RecordError(lcID,oexp.message+[  LineNo: ] + STR(oexp.LineNo)) 
ENDTRY 

*record that we finished the background thread (3rd parm is an optional file to redirect to)
IF !oAsync.Canceled(lcID) AND !oAsync.GetError(lcID)
  oAsync.CompleteWebEvent(lcID,[<BR><BR><b>Finished! The vfp code completed successfully on the background thread</b>],[])   &&<BR><BR><b>Finished! The vfp code completed successfully on the background thread</b>
ENDIF



RETURN
