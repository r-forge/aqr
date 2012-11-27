# test script for AQ-R

require(aqr)
aqEnableDebugMessages()
aqInitMessaging()
aqSubscribeChannel("TEXT")
aqSend("TEXT", "ABCD")


#for(i in 1:4){
  # block 
  #aqWaitForData()
  # fetch all data. 
  #text = aqPoll()
  # browser()
  #message(text)

#}


#aqUnsubscribeChannel("TEXT")
#Sys.sleep(15)

