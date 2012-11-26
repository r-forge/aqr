############
## Utility functions for sending and receiving real time messages. 
############

aqInitMessaging <- function(){

}

aqEnableDebugMessages <- function(){
  .Call("aqEnableDebugMessages")
}

aqDisableDebugMessages <- function(){
  .Call("aqDisableDebugMessages")
}

aqSubscribeChannel <- function(channel){
  .Call("aqSubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}

aqUnsubscribeChannel <- function(channel){
  .Call("aqUnsubscribe", paste("/topic/", channel, sep=""))
}

aqPoll <- function(){
  return(.Call("aqPollAll"))
}

# waits for data and returns a list of channels for which data is available. 
# this is a synchronous call and thus blocks. 
aqDataReady <- function(){
  return(.Call("aqDataReady"))
}

aqWaitForData <- function(){
  return(.Call("aqWaitForData"))
}

aqSend <- function(channel, message){
  .Call("aqSend", paste("/topic/", channel, sep=""), message)
}

aqTestCallToDynLib<- function(testMessage){
  return(.Call("testCall", testMessage))
}
