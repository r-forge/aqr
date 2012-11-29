/*********
 * 
 * Mostly written on a saturday afternoon while listening to Genesis' Live Album, particulary "The Music Box" is very stimulating. 
 * Currently watching "Escape from New York". 
 * 
 * Enjoying the Dishonored Soundtracks (f.e. http://www.youtube.com/watch?v=Fsak_zSyKjM&feature=related ). 
 * 
 * Spent more time on a Monday morning. And a monday afternoon. 
 * It's getting dark. Listening to Kirlian Camera, Not Of This World, Edges. 
 * Making the package ready while listening to XP8, Forgive(N), Das Licht (Imperative Reaction Remix). 
 * Tuesday evening. Fixing a stdout. 
 * 
 * Code by The Ghost Rider, November 2012. 
 * 
 ********/


// STD INCLUDES. 
#include <errno.h>  

#include <netdb.h>
#include <netinet/in.h>

#include <pthread.h>

#include <signal.h>
#include <stdio.h>
#include <stdlib.h> 

#include <sys/socket.h>
#include <sys/types.h> 

#include <unistd.h> 

// R INCLUDES FOLLOW
#include <R.h>
#include <Rdefines.h>
#include <Rinternals.h>


// maximum amount of channels for this subscriber. Setting it to 100 for now. 
#define MAX_CHANNELS 100

// maximum channel buffer. Total memory consumption = buffer length * max channels. So, take care. 
#define BUFFER_LENGTH 4096 * 5

char* subscribedChannels[MAX_CHANNELS];
char* individualChannelBuffers[MAX_CHANNELS];
int subscriptionCount = 0; 
int initialized = 0; 

// tcp STOMP port
int tcpTargetPort = 61618; 
// tcp STOMP host
char* tcpTargetHost = "localhost";
int socketFileDescriptor = 0x00;  
char connected = 0x00; 
char debugMessagesEnabled = 0x00; 


// lock across all threads 
pthread_mutex_t varLock = PTHREAD_MUTEX_INITIALIZER;

// dataRedy mutex , see Stevens, 1997, Unix Network Programming, p. 627
int dataReady; 
pthread_mutex_t dataReadyMutex = PTHREAD_MUTEX_INITIALIZER; 
pthread_cond_t dataReadyCond = PTHREAD_COND_INITIALIZER; 

void debugPrint(const char *fmt, ...)
{
  if(debugMessagesEnabled==0x00)return; 
  va_list args;
  va_start(args, fmt);
  Rvprintf(fmt, args);
  va_end(args);
}

SEXP aqEnableDebugMessages(){
  SEXP Rresult = R_NilValue; 
  debugMessagesEnabled = 0x01; 
  return Rresult;
}

SEXP aqDisableDebugMessages(){
  SEXP Rresult = R_NilValue; 
  debugMessagesEnabled = 0x00; 
  return Rresult; 
}


// using stomp 1.0
char* buildConnectMsg(){
  char* msg;
  msg = Calloc(200, char);
  // zero it. 
  bzero(msg, 200);
  strcpy(msg, "CONNECT\naccept-version:1.0\n\n");
  return msg; 
}


char* buildSubscribeMsg(const char* topicName, const char* selector, const char* id){
  char msgPart1[] = "SUBSCRIBE\ndestination: ";  
  char msgPart1_1[] = "id: ";
  char msgPart2[] = "selector: ";
  char msgPart3[] = "\n\n";  
  char newLine[] = "\n";
  
  
  // make it one character longer to capture the zero byte. 
  size_t strlength = strlen(msgPart1) + strlen(topicName) + strlen(msgPart1_1) + strlen(id) + strlen(msgPart2) + 2 + 2;
  
  if(selector != 0x00){
    debugPrint("Subscribing with selector \n");
    strlength = strlength + strlen(msgPart2) + strlen(newLine) + strlen(selector);    
  }
    
  //
  char* ret = (char*)Calloc(strlength, char);
  // zero it out. 
  bzero(ret, strlength);
    
  strcpy(ret, msgPart1);
  strcat(ret, topicName);
  strcat(ret, newLine);
  strcat(ret, msgPart1_1);
  strcat(ret, id);
  
  if(selector!=0x00){
    strcat(ret, newLine);
    strcat(ret, msgPart2);
    strcat(ret, selector);
  }
  
  strcat(ret, msgPart3);  
  return ret;
}

const char* buildUnsubscribeMsg(char* id){
  char msgPart1[] = "UNSUBSCRIBE\n";  
  char msgPart2[] = "id: ";
  char msgPart3[] = "\n\n";  
  char newLine[] = "\n";
  
  
  // make it one character longer to capture the zero byte. 
  size_t strlength = strlen(msgPart1) + strlen(id) + strlen(msgPart2) + 1 + 3;
    
  //
  char* ret = (char*)Calloc(strlength, char);
  // zero it out. 
  bzero(ret, strlength);
    
  strcpy(ret, msgPart1);
  strcat(ret, msgPart2);
  strcat(ret, id);
  strcat(ret, newLine);  
  strcat(ret, msgPart3);
  
  return ret;
}



const char* buildSendMsg(char* channel, char* message){
  char msgPart1[] = "SEND\n";  
  char msgPart2[] = "destination: ";
  char msgPart3[] = "\n\n";  
  char newLine[] = "\n";
  
  
  // make it one character longer to capture the zero byte. 
  size_t strlength = strlen(msgPart1) + strlen(msgPart2) + strlen(channel) + 1 + 1 + strlen(message) + 1 + 1 + 1;
    
  // allocate it. has to be Freed later on. 
  char* ret = (char*)Calloc(strlength, char);
  // zero it out. 
  bzero(ret, strlength);
    
  strcpy(ret, msgPart1);
  strcat(ret, msgPart2);
  strcat(ret, channel);
  strcat(ret, msgPart3);  
  strcat(ret, message);
  // strcat(ret, newLine);
  
  return ret;
}



void stopConnection(){
  connected = 0x00; 
}

void flush(){
    int n; 
    n = write(socketFileDescriptor,"\0\n",2);
}

// limited to 4k long messages. 
char* readMessage(){
  
  //
  char* buffer;
  buffer = (char*)Calloc(4096, char);
  bzero(buffer,4096);
  
  // 
  char readByte[1];
  bzero(readByte, 1); 
  int readCounter = 0; 
  int n = 0; 
  // debugPrint("Reading one byte.\n");
  n = read(socketFileDescriptor, readByte, 1);
  if (n < 0)
    error("ERROR reading from socket");    
  buffer[0] = *readByte; 
  
  //
  readCounter ++; 
  unsigned char endSignalled;
  endSignalled = 0; 
  while(readByte!='\0' && readCounter < 4096){  
    // debugPrint("Read byte\n");
    // let's append this lovely tiny byte. 
    n = read(socketFileDescriptor, readByte, 1);
    if (n < 0)
      error("ERROR reading from socket");  
    if(endSignalled==1){
      if(*readByte == 10){
	break;
      }
    }
    if(*readByte == 0){
      endSignalled = 1; 
    }
    else{	
      // no endbyte. 
      buffer[readCounter] = *readByte; 
      // debugPrint("%d %d %s\n", *readByte, n, buffer);    
      readCounter++; 
    }
  }  
  debugPrint("Read %d bytes. %s\n",readCounter, buffer);
  return(buffer);
}

char* getMessageBody(char* incomingMessage){ 
  // get the first line. 
  char* lineBuffer;lineBuffer = Calloc(4096, char);
  bzero(lineBuffer,4096);
  int pos;pos = 0; 
  int linePos; linePos = 0; 
  char inBody; inBody = 0x00; 
  char* body; body = Calloc(4096, char); 
  
  char currentByte;currentByte = 0x00; 
  
  while(pos < 4096){	
    currentByte = incomingMessage[pos];
    if(currentByte!='\n' && currentByte != 0x00){
      lineBuffer[linePos] = currentByte;     
      // debugPrint("Current line: %d %d\n", pos, currentByte);
      linePos ++; 
    }
    else {
      linePos = 0; 
      // debugPrint("new line\n");
      // debugPrint("%d  %s\n", strlen(lineBuffer), lineBuffer);
      if(strlen(lineBuffer)==0){
	// debugPrint("body start detected\n");
	// new line received. body starting. 
	inBody = 0x01; 
      }
      else{
	// debugPrint("f1\n");
	if(inBody == 0x00){
	  // debugPrint("f2\n");
	    // not in body, thus zero out line.
	    bzero(lineBuffer, 4096); 	    
	}
	else{
	  // debugPrint("f3\n");
	    // in body. new line is treated as part of body.  
	    if(strlen(body)==0){
	      // debugPrint("f4\n");
	      strcpy(body, lineBuffer);
	    }
	    else{
	      // debugPrint("f5\n");
	      strcat(body, "\n"); 
	      strcat(body, lineBuffer);
	    }
	}
      }      
    }
    pos++; 
    // final termination. 
    if(currentByte == 0x00)
      break; 
  }
  // cleanup, 
  Free(lineBuffer); 
  
  // 
  return body;
}


char* getDestination(char* incomingMessage){
  debugPrint("Getting destination\n");
  // get the first line. 
  char* lineBuffer;lineBuffer = Calloc(4096, char);
  bzero(lineBuffer,4096);
  int pos;pos = 0; 
  int linePos; linePos = 0; 
  char inBody; inBody = 0x00; 
  char* destination; destination = Calloc(4096, char); 
  bzero(destination, 4096);
  char currentByte;currentByte = 0x00; 
  
  while(pos < 4096){	
    currentByte = incomingMessage[pos];
    if(currentByte!='\n' && currentByte != 0x00){
      lineBuffer[linePos] = currentByte;     
      // debugPrint("Current line: %d %d\n", pos, currentByte);
      linePos ++; 
    }
    else {
      linePos = 0; 
      // debugPrint("new line\n");
      // debugPrint("%d  %s\n", strlen(lineBuffer), lineBuffer);
      if(strlen(lineBuffer)>12){
	// check if the line starts with a DESTINATION command. 
	if(strncmp("destination:", lineBuffer, 5)==0){
	    // 
	    memcpy(destination, &lineBuffer[12], strlen(lineBuffer));
	    debugPrint("Destination extracted: %s\n", destination);
	}
      }      
      // line processing done, zero out the line buffer. 
      bzero(lineBuffer, 4096); 	    

    }
    pos++; 
    // final termination. 
    if(currentByte == 0x00)
      break; 
  }
  // cleanup, 
  Free(lineBuffer); 
  
  // 
  return destination;
}


char* getMessageCommand(char* incomingMessage){
  
    // get the first line. 
      char* lineBuffer;lineBuffer = Calloc(4096, char);
      bzero(lineBuffer,4096);
      int pos;pos = 0; 
      unsigned char currentByte;currentByte = 0; 
      while(pos < 4096){	
	currentByte = incomingMessage[pos];
	if(currentByte!='\n')
	  lineBuffer[pos] = currentByte; 
	else 
	  break;
	pos++; 
	// final termination. 
	if(currentByte == 0x00)
	  break; 
      }
      debugPrint("command: >%s<\n", lineBuffer);
      return lineBuffer;
}

void processMessage(char* incomingMessage){
  // first, process the message type 
  char* msgType = getMessageCommand(incomingMessage); 
  if(strcmp(msgType, "MESSAGE")==0){
      // message received. get the body 
    //char* channel = getChannel(incomingMessage);
    char* msgBody = getMessageBody(incomingMessage);
    int msgLength = strlen(msgBody); 
    debugPrint("Received message >%s<\n", msgBody); 
    // 
    // append the message body to the channel's buffer so that R can poll it later on.     
    char* channel = getDestination(incomingMessage);

    // find the right channel. 
    for(int i=0;i<MAX_CHANNELS;i++){    
      if(subscribedChannels[i] != 0x00){	
	if(strcmp(subscribedChannels[i], channel)==0){
	  debugPrint("channel with subscription found: %s\n", subscribedChannels[i]);
	  
	  // lock the mutex. 
	  pthread_mutex_lock (&varLock);

	  
	  
	  debugPrint("Channel buffer found.\n");
	  //ok, channel found. append do channel buffer. 	  
	  int currentBufferLength = strlen(individualChannelBuffers[i]); 
	  debugPrint("Current buffer length: %d vs msg length %d\n", currentBufferLength, msgLength);
	  if(currentBufferLength==0 && msgLength < BUFFER_LENGTH ){
	    strcpy(individualChannelBuffers[i], msgBody);
	    strcat(individualChannelBuffers[i], "\n");
	  }
	  else{
	    
	    if(currentBufferLength + msgLength < (BUFFER_LENGTH)){
	      strcat(individualChannelBuffers[i], msgBody);
	      strcat(individualChannelBuffers[i], "\n");
	    }
	    else{	      
	      error("ALERT: SLOW CONSUMER. Dropping message due to full buffer [%s]. \n", channel);
	    }
	  }
  	  // unlock the mutex. 
	  pthread_mutex_unlock (&varLock);

	  // signal data ready. 
	  pthread_mutex_lock(&dataReadyMutex);
	  dataReady=1; 
	  pthread_cond_signal(&dataReadyCond);
	  pthread_mutex_unlock(&dataReadyMutex);
	  
	  // 
	  
	  
	  
	  // mark channel as very dirty. 
	}
      }
    }    
    // cleanup. 
    Free(msgBody);
    Free(channel);

  }
  Free(msgType);   
}




/**
 * main receiver loop. 
 **/
void* receiverThreadCode(){
 	// child process code. 
	while(connected == 0x01){
	  char* readMsg = readMessage();		  
	  processMessage(readMsg);
	  Free(readMsg);	  
	}
	pthread_exit(0);   
}

void startConnection(){
  if(connected==0x01)
    error("Already connected. Not reconnecting. \n");
  // 
  int n; 
  // 
  char* msg;msg = buildConnectMsg();
  debugPrint("Sending out: %s\n", msg);
  // send the welcome message. 
  n = write(socketFileDescriptor,msg,strlen(msg));  
  flush();    
  // read the response. 
  char* readMsg;readMsg = readMessage();  
  // ... 
  char* cmd; cmd = getMessageCommand(readMsg);
  
  if(strcmp(cmd, "CONNECTED")==0){
     debugPrint("Connected\n");
     connected = 0x01;      
  }
  else{
     error("Error connecting. The library received: %s", cmd);     
  }
  
  // 
  debugPrint("Processed. \n");
    
  // cleanup. 
  Free(cmd);
  Free(msg);
  Free(readMsg);
  
  // 
  if(connected == 0x01){
      // ok connected. 
      debugPrint("Connected. Forking off a message receiver. \n");
            
      // fork/pthread it from here. Cupid. 
      pthread_t thread; 
      int rc; 
      rc = pthread_create(&thread, NULL, receiverThreadCode, NULL);
      if (rc){
  
	error("Error %d while spawning message receiver. \n", errno);      
      }
   }
}




void subscribe(const char* channel){
  debugPrint("Subscribing to channel >%s<\n", channel);
  // now that we are here ... let's add this channel. 
  for(int i=0;i<MAX_CHANNELS;i++){    
    if(subscribedChannels[i] == 0x00){
      // free slot found. 
      debugPrint("Using slot %d\n", i); 
      // 
      subscribedChannels[i] = Calloc(strlen(channel), char);
      strcpy(subscribedChannels[i], channel);
      //
      char id [ 5 ];
      sprintf(id, "%d", i);
      char* msg = buildSubscribeMsg(channel, 0x00, id);
      debugPrint("Subscription message:\n>%s<\n", msg);      
      int n = write(socketFileDescriptor,msg,strlen(msg));  
      flush();          
      Free(msg);
      
     
      // 
      break;       
    }
  }  
}

//
void unsubscribe(const char* channel){
  debugPrint("Unsubscribe from channel >%s<\n", channel);
  for(int i=0;i<MAX_CHANNELS;i++){    
    if(subscribedChannels[i] != 0x00){
      int result = strncmp(subscribedChannels[i], channel, 100);
      if(result==0){
	// ok, channel found. let's unsubscribe. 
	char id [ 5 ];
	sprintf(id, "%d", i);
	const char* msg = buildUnsubscribeMsg(id);
	debugPrint("Unsubscribe message:\n>%s<\n", msg);      
	int n = write(socketFileDescriptor,msg,strlen(msg));  
	flush();          
	Free(msg);     
      }     
    }
  }
}

// open the socket connection. 
void openSocketConnection(){
  debugPrint("Opening socket connection. \n");
  struct sockaddr_in serv_addr;
  struct hostent *server;
  //   
  socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
  if (socketFileDescriptor < 0) {
    debugPrint("Couldn't open socket.\n");
    error("ERROR opening socket");
  }
  server = gethostbyname(tcpTargetHost);
  // 
  if (server == NULL) {
    debugPrint("No such host.\n");
    error("No such host.");
  }
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  // 
  bcopy((char *)server->h_addr, 
         (char *)&serv_addr.sin_addr.s_addr,
         server->h_length);
  serv_addr.sin_port = htons(tcpTargetPort);
  if (connect(socketFileDescriptor,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
      debugPrint("AQ-R could not connect to STOMP endpoint.\n");
      error("AQ-R could not connect to STOMP connector at %s:%d\n", tcpTargetHost, tcpTargetPort);      
  }  
  // 
  debugPrint("AQ-R connected successfully to %s:%d\n", tcpTargetHost, tcpTargetPort);  
}

void closeSocketConnection(){
  if(socketFileDescriptor!=0x00)
    close(socketFileDescriptor);  
}	



// utility function to initialize the AQ-R part. 
void initialize(){
  debugPrint("Initializing AQ-R C part. \n");
  initialized = 1; 
  // initialize the channel array. 
  for(int i=0;i<MAX_CHANNELS;i++){
    subscribedChannels[i] = Calloc(strlen("\0"), char);    
    subscribedChannels[i] = 0x00;
    // initialize also the channel buffer. 
    individualChannelBuffers[i] = (char*)Calloc(BUFFER_LENGTH, char);  
    //zero it. 
    bzero(individualChannelBuffers[i], BUFFER_LENGTH); 
  }
  debugPrint("Channels initialized\n");
  openSocketConnection();
  debugPrint("Socket connection done, starting connection.\n");
  startConnection();
  debugPrint("Connection started.\n");

}

// utility function to check if we are subscribed already. 
int alreadySubscribed(const char* channel){
  for(int i=0;i<MAX_CHANNELS;i++){
    if(subscribedChannels[i]!=0x00){
      // 
      int result = strncmp(subscribedChannels[i], channel, 100);
      if(result==0){
	return 1; 
      }     
    }
  } 
  return 0; 
}



SEXP aqPollAll(){
  SEXP Rresult = R_NilValue; 

  
   // 
  // count all channels for which there is data. 
  // lock the mutex. 
  pthread_mutex_lock (&varLock);
  // 
  int channelsWithDataCount = 0; 
  // go over all channels and check if there is data. 
  for(int i=0;i<MAX_CHANNELS;i++){
    if(subscribedChannels[i]!=0x00){
      // 
      int currentBufferLength = strlen(individualChannelBuffers[i]); 
      if(currentBufferLength>0)
      {
	      // printf("channel dirty.\n");

	channelsWithDataCount++; 
      }
    }
  } 
  // printf("Copying data. \n");

  // result contains in the first column the channel name and in the second column the actual data set. 
  PROTECT(Rresult = allocMatrix(STRSXP, channelsWithDataCount, 2));
  int channelCounter = 0; 
  for(int i=0;i<MAX_CHANNELS;i++){
    if(subscribedChannels[i]!=0x00){
      // 
      // printf("Found a subscribed channel.\n");
      // 
      int currentBufferLength = strlen(individualChannelBuffers[i]); 
      if(currentBufferLength>0){
	// printf("buffer length high.\n");
	SET_STRING_ELT(Rresult, channelCounter * 2, mkChar(subscribedChannels[i]));
	SET_STRING_ELT(Rresult, channelCounter * 2 + 1, mkChar(individualChannelBuffers[i]));
	// wipe the individualChannelBuffers so that they can carry data again. 
	bzero(individualChannelBuffers[i], BUFFER_LENGTH); 
	
	// 
	channelCounter++;
      }
    }
  } 
  
  // 
  UNPROTECT(1);  
  
  // 
  // clear the data ready flag. 
  pthread_mutex_lock(&dataReadyMutex);
  dataReady = 0; 
  pthread_mutex_unlock(&dataReadyMutex);  
  
  // unlock the mutex. 
  pthread_mutex_unlock (&varLock);  
  
  
  // 
  return Rresult; 
}


SEXP aqPollChannel(SEXP channel){
  SEXP Rresult;  
  // get the mutex on our channel list. 

  
  // 
  return Rresult; 
}

// waits for data and returns a list of channels for which data is available. 
// this is a synchronous call and thus blocks. 
SEXP aqWaitForData(){
  SEXP Rresult;  
  // get the mutex on our channel list. 
  PROTECT(Rresult = NEW_CHARACTER(1));
  pthread_mutex_lock(&dataReadyMutex);
  while(dataReady==0)  
	  pthread_cond_wait(&dataReadyCond, &dataReadyMutex);
  pthread_mutex_unlock(&dataReadyMutex);  
  SET_STRING_ELT(Rresult, 0, mkChar("data ready."));
  UNPROTECT(1);
  return Rresult;  
  
}

/**
 * s-expression contains channel list with ready data. 
 */
SEXP aqDataReady(){
  // 
  SEXP Rresult = R_NilValue;    
  // 
  // count all channels for which there is data. 
  // lock the mutex. 
  pthread_mutex_lock (&varLock);
  // 
  int channelsWithDataCount = 0; 
  // go over all channels and check if there is data. 
  for(int i=0;i<MAX_CHANNELS;i++){
    if(subscribedChannels[i]!=0x00){
      // 
      int currentBufferLength = strlen(individualChannelBuffers[i]); 
      if(currentBufferLength>0)
	channelsWithDataCount++; 
    }
  } 
  
  // 
  PROTECT(Rresult = allocMatrix(STRSXP, channelsWithDataCount, 1));
  int channelCounter = 0; 
  for(int i=0;i<MAX_CHANNELS;i++){
    if(subscribedChannels[i]!=0x00){
      // 
      SET_STRING_ELT(Rresult, channelCounter, mkChar(subscribedChannels[i]));
      channelCounter++; 
      
    }
  } 
  
  // 
  UNPROTECT(1);  
  // unlock the mutex. 
  pthread_mutex_unlock (&varLock);  
  return(Rresult);
}

// 
SEXP aqInit(SEXP stompHost, SEXP stompPort)
{    
  //   
  PROTECT(stompHost = AS_CHARACTER(stompHost));  
  // clear out the tcp target host before ...   
  // we allocate it again. 
  tcpTargetHost = R_alloc(strlen(CHAR(STRING_ELT(stompHost, 0))), sizeof(char));  
  strcpy(tcpTargetHost, CHAR(STRING_ELT(stompHost, 0)));

  // 
  int port;     
  PROTECT(stompPort= AS_INTEGER(stompPort));
  // unclear. Will this persist or might R's GC clear this all up at one point? 
  port = INTEGER_POINTER(stompPort)[0];
  tcpTargetPort = port; 
  debugPrint("Initializing AQ-R messaging with %s:%d\n", tcpTargetHost, tcpTargetPort);
  
  // clear the stack. 
  UNPROTECT(2); 
  return(R_NilValue); 
}

//aqSubscribe is a synchronous call which will open a connection upon start. 
//arguments in R come in over S-Expressions
SEXP aqSubscribe(SEXP channel){
  SEXP Rresult;
  
  // 
  if(!isString(channel)){
    error("channel must be a string.");
  }
  
  // 
  if(initialized==0){
      initialize();
  }
  
  //   
  const char* name; 
  PROTECT(channel = AS_CHARACTER(channel));
  name = CHAR(STRING_ELT(channel, 0));
  debugPrint("%s\n", name);
  // 
  PROTECT(Rresult = NEW_CHARACTER(1));
  if(alreadySubscribed(name)==0)
  {
    if(subscriptionCount<MAX_CHANNELS){
      subscribe(name);
      SET_STRING_ELT(Rresult, 0, mkChar("Subscribed."));
    }
    else{
      SET_STRING_ELT(Rresult, 0, mkChar("Maximum number of subscriptions reached."));
    }
  }
  else{
    SET_STRING_ELT(Rresult, 0, mkChar("Already subscribed to channel."));
  }
  
  // 
  UNPROTECT(2);
  return Rresult;
}


SEXP aqSend(SEXP channel, SEXP message){
  // 
  SEXP Rresult = R_NilValue;   
  // 
  // buildSendMsg(channel
    // 
  if(initialized==0){
      initialize();
  }
  
  if(!isString(channel)){
    error("aqSend: channel must be a string.");
  }
  if(!isString(message)){
    error("aqSend: message must be a string.");
  }
  
  // converted. 
  char* chan; 
  chan = R_alloc(strlen(CHAR(STRING_ELT(channel, 0))), sizeof(char));
  strcpy(chan, CHAR(STRING_ELT(channel, 0)));
  
  char* msg; 
  msg = R_alloc(strlen(CHAR(STRING_ELT(message, 0))), sizeof(char));
  strcpy(msg, CHAR(STRING_ELT(message, 0)));
  
  
    // ...   
  const char* sendBuffer = buildSendMsg(chan, msg);  
  debugPrint("Message: >%s<", sendBuffer);
  int n = write(socketFileDescriptor,sendBuffer,strlen(sendBuffer));  
  flush();            
  Free(sendBuffer);   

  
  //
  // 
  return Rresult;
}

// arguments in R come in over S-Expressions
SEXP aqUnsubscribe(SEXP channel){
  SEXP Rresult;

  if(!isString(channel)){
    error("channel must be a string.");
  }
  
  if(initialized==0){
      initialize();      
  }    

  
  
  
  PROTECT(Rresult = NEW_CHARACTER(1));
  PROTECT(channel = AS_CHARACTER(channel));

  char* name; 
  name = R_alloc(strlen(CHAR(STRING_ELT(channel, 0))), sizeof(char));
  strcpy(name, CHAR(STRING_ELT(channel, 0)));
  unsubscribe(name);

  
  SET_STRING_ELT(Rresult, 0, mkChar("Unsubscribed."));

  //
  UNPROTECT(2);
  // UNPROTECT(1);
  return Rresult;
}



SEXP testCall(SEXP args)
{
	return args; 
}
