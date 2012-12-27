

	  AQ-R 0.2


	  Hi there. This video has sound. 










require(aqr)
aqInitMessaging(host="192.168.0.177")
aqSubscribeChannel("PROCESS1")

while(aqWaitForData()>0){
  data = aqPoll()
  val = as.double(data[1,2])
  message("******\nReceived: ", val)
  message("Pretending some calculations in addition to doubling the value. ")
  Sys.sleep(3)
  val = val * 2
  if(val>100)break
  message("Let's send data to process 2 ...")
  aqSend("PROCESS2", as.character(val))
}
message("Ok, all done.")










require(aqr)
aqInitMessaging(host="192.168.0.177")
aqSubscribeChannel("PROCESS2")

while(aqWaitForData()>0){
  data = aqPoll()  
  val = as.double(data[1,2])
  message("******\nReceived: ", val)
  message("Pretending some calculations in addition to doubling the value. ")
  Sys.sleep(3)
  val = val * 2
  if(val>100)break
  message("Let's send data back ...")
  aqSend("PROCESS1", as.character(val))
}








aqInitMessaging(host="192.168.0.177")
aqSend("PROCESS1", "0.1")



