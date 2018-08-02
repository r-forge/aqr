############
## Utility functions for sending and receiving real time messages. 
############
#' @export
aqInitMessaging <- function(host = "localhost", port = 61618){
  .C("aqInit", host, port, PACKAGE="aqr")
}
#' @export
aqEnableDebugMessages <- function(){
  .C("aqEnableDebugMessages", PACKAGE="aqr")
}
#' @export
aqDisableDebugMessages <- function(){
  .C("aqDisableDebugMessages", PACKAGE="aqr")
}
#' @export
aqSubscribeChannel <- function(channel){
  .C("aqSubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}
#' @export
aqUnsubscribeChannel <- function(channel){
  .C("aqUnsubscribe", paste("/topic/", channel, sep=""), PACKAGE="aqr")
}
#' @export
aqPoll <- function(){
  return(.C("aqPollAll", PACKAGE="aqr"))
}

# waits for data and returns a list of channels for which data is available. 
# this is a synchronous call and thus blocks. 
#' @export
aqDataReady <- function(){
  return(.C("aqDataReady", PACKAGE="aqr"))
}
#' @export
aqWaitForData <- function(){
  return(.C("aqWaitForData", PACKAGE="aqr"))
}
#' @export
aqSend <- function(channel, message){
  .C("aqSend", paste("/topic/", channel, sep=""), message, PACKAGE="aqr")
}
#' @export
aqTestCallToDynLib<- function(testMessage){
  return(.C("testCall", testMessage, PACKAGE="aqr"))
}
