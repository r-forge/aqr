############
## Utility functions for sending and receiving real time messages. 
############

aqInitMessaging <- function(host = "localhost", port = 61618){
  .Call("aqInit", host, port, PACKAGE="aqr")
}

aqEnableDebugMessages <- function(){
  .Call("aqEnableDebugMessages", PACKAGE="aqr")
}

aqDisableDebugMessages <- function(){
  .Call("aqDisableDebugMessages", PACKAGE="aqr")
}

aqSubscribeChannel <- function(channel){
  .Call("aqSubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}

aqUnsubscribeChannel <- function(channel){
  .Call("aqUnsubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}

aqPoll <- function(){
  return(.Call("aqPollAll", PACKAGE="aqr"))
}

# waits for data and returns a list of channels for which data is available. 
# this is a synchronous call and thus blocks. 
aqDataReady <- function(){
  return(.Call("aqDataReady", PACKAGE="aqr"))
}

aqWaitForData <- function(){
  return(.Call("aqWaitForData", PACKAGE="aqr"))
}

aqSend <- function(channel, message){
  .Call("aqSend", paste("/topic/", channel, sep=""), message, PACKAGE="aqr")
}

aqTestCallToDynLib<- function(testMessage){
  return(.Call("testCall", testMessage, PACKAGE="aqr"))
}
