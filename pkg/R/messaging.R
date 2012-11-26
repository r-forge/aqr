############
## Utility functions for sending and receiving real time messages. 
############

aqInitMessaging <- function(){
  # dyn.load(paste("am", .Platform$dynlib.ext, sep=""))
  #library.dynam("am",package=c("aqr")) 
  
}

aqSubscribeChannel <- function(channel){
  .Call("aqSubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}

aqUnsubscribeChannel <- function(channel){
  .Call("aqUnsubscribe", paste("/topic/", channel, sep=""))
}

aqPollAll <- function(){
  .Call("aqPollAll")
}

# waits for data and returns a list of channels for which data is available. 
# this is a synchronous call and thus blocks. 
aqWaitForData <- function(){
  .Call("aqWaitForData")
}

aqPollChannel <- function(channel){
  .Call("aqPollChannel", channel)
}

aqSendMessage <- function(channel, message){
  .Call("aqSend", paste("/topic/", channel, sep=""), message)
}

aqTestCallToDynLib<- function(testMessage){
  return(.Call("testCall", testMessage))
}



# .Call("aqSubscribe", 20)
