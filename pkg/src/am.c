/*********
 * 
 * Mostly written on a saturday afternoon while listening to Genesis' Live Album, particulary "The Music Box" is very stimulating. 
 * Currently watching "Escape from New York". 
 * 
 * Enjoying the Dishonored Soundtracks (f.e. http://www.youtube.com/watch?v=Fsak_zSyKjM&feature=related ). 
 * 
 * Spent more time on a Monday morning. And a monday afternoon. 
 * 
 * Code by The Ghost Rider. 
 * 
 ********/

#include <stdio.h>   /* printf, stderr, fprintf */
#include <sys/types.h> /* pid_t */
#include <unistd.h>  /* _exit, fork */
#include <stdlib.h>  /* exit */
#include <errno.h>   /* errno */
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <signal.h>

#include <pthread.h>


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>


#define MAX_CHANNELS 100
#define BUFFER_LENGTH 4096 * 5

char* subscribedChannels[MAX_CHANNELS];
char* individualChannelBuffers[MAX_CHANNELS];
int subscriptionCount = 0; 
int initialized = 0; 

int tcpTargetPort = 61618; 
char* tcpTargetHost = "localhost";
int socketFileDescriptor = 0x00;  
char connected = 0x00; 


// lock across all threads 
pthread_mutex_t varLock = PTHREAD_MUTEX_INITIALIZER;

// dataRedy mutex , see Stevens, 1997, Unix Network Programming, p. 627
int dataReady; 
pthread_mutex_t dataReadyMutex = PTHREAD_MUTEX_INITIALIZER; 
pthread_cond_t dataReadyCond = PTHREAD_COND_INITIALIZER; 




// using stomp 1.1 
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
    printf("Subscribing with selector \n");
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
  // printf("Reading one byte.\n");
  n = read(socketFileDescriptor, readByte, 1);
  if (n < 0)
    error("ERROR reading from socket");    
  buffer[0] = *readByte; 
  
  //
  readCounter ++; 
  unsigned char endSignalled;
  endSignalled = 0; 
  while(readByte!='\0' && readCounter < 4096){  
    // printf("Read byte\n");
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
      // printf("%d %d %s\n", *readByte, n, buffer);    
      readCounter++; 
    }
  }  
  printf("Read %d bytes. %s\n",readCounter, buffer);
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
      // printf("Current line: %d %d\n", pos, currentByte);
      linePos ++; 
    }
    else {
      linePos = 0; 
      // printf("new line\n");
      // printf("%d  %s\n", strlen(lineBuffer), lineBuffer);
      if(strlen(lineBuffer)==0){
	// printf("body start detected\n");
	// new line received. body starting. 
	inBody = 0x01; 
      }
      else{
	// printf("f1\n");
	if(inBody == 0x00){
	  // printf("f2\n");
	    // not in body, thus zero out line.
	    bzero(lineBuffer, 4096); 	    
	}
	else{
	  // printf("f3\n");
	    // in body. new line is treated as part of body.  
	    if(strlen(body)==0){
	      // printf("f4\n");
	      strcpy(body, lineBuffer);
	    }
	    else{
	      // printf("f5\n");
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
      printf("command: >%s<\n", lineBuffer);
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
    printf("Received message >%s<\n", msgBody); 
    // 
    
    // append the message body to the channel's buffer so that R can poll it later on.     
    char* channel = "/topic/TEXT"; 
    // find the right channel. 
    for(int i=0;i<MAX_CHANNELS;i++){    
      if(subscribedChannels[i] != 0x00){
	printf("channel with subscription found: %s\n", subscribedChannels[i]);
	if(strcmp(subscribedChannels[i], channel)==0){
	  // lock the mutex. 
	  pthread_mutex_lock (&varLock);

	  printf("Channel buffer found.\n");
	  //ok, channel found. append do channel buffer. 	  
	  int currentBufferLength = strlen(individualChannelBuffers[i]); 
	  printf("Current buffer length: %d vs msg length %d\n", currentBufferLength, msgLength);
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
	      printf("ALERT: Dropping message due to full buffer. \n");
	    }
	  }
  	  // unlock the mutex. 
	  pthread_mutex_unlock (&varLock);

	  // mark channel as very dirty. 
	}
      }
    }    
    // cleanup. 
    Free(msgBody);
  }
  Free(msgType);   
}




static void killReceiver(int signum){
  printf("Cleaning up child process due to signal %d\n", signum);
//   printf("Cleaning up child process %d. \n", receiverForkPid);
  if(connected==0x01){
  //   kill( receiverForkPid, SIGKILL );
  }
}

void* receiverThreadCode(){
 	// child process code. 
	while(connected == 0x01){
	  
	  // check if the parent process died. 
	  if(getppid()==1)
	    exit(0);
	  
	  printf("Receiver still running. \n");
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
  printf("Sending out: %s\n", msg);
  // send the welcome message. 
  n = write(socketFileDescriptor,msg,strlen(msg));  
  flush();    
  // read the response. 
  char* readMsg;readMsg = readMessage();  
  // ... 
  char* cmd; cmd = getMessageCommand(readMsg);
  
  if(strcmp(cmd, "CONNECTED")==0){
     printf("Connected\n");
     connected = 0x01;      
  }
  else{
     error("Error connecting. The library received: %s", cmd);     
  }
  
  // 
  printf("Processed. \n");
    
  // cleanup. 
  Free(cmd);
  Free(msg);
  Free(readMsg);
  
  // 
  if(connected == 0x01){
      // ok connected. 
      printf("Connected. Forking off a message receiver. \n");
      
      
      // register the sigint listeners. 
      if (signal(SIGTERM, killReceiver) == SIG_ERR) {
        printf("2 An error occurred while setting a signal handler.\n");
      }
      if (signal(SIGHUP, killReceiver) == SIG_ERR) {
        printf("3 An error occurred while setting a signal handler.\n");
      }
      if (signal(SIGINT, killReceiver) == SIG_ERR) {
        printf("4 An error occurred while setting a signal handler.\n");
      }
      
      
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
  printf("Subscribing to channel >%s<\n", channel);
  // now that we are here ... let's add this channel. 
  for(int i=0;i<MAX_CHANNELS;i++){    
    if(subscribedChannels[i] == 0x00){
      // free slot found. 
      printf("Using slot %d\n", i); 
      // 
      subscribedChannels[i] = Calloc(strlen(channel), char);
      strcpy(subscribedChannels[i], channel);
      //
      char id [ 5 ];
      sprintf(id, "%d", i);
      char* msg = buildSubscribeMsg(channel, 0x00, id);
      printf("Subscription message:\n>%s<\n", msg);      
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
  printf("Unsubscribe from channel >%s<\n", channel);
  for(int i=0;i<MAX_CHANNELS;i++){    
    if(subscribedChannels[i] != 0x00){
      int result = strncmp(subscribedChannels[i], channel, 100);
      if(result==0){
	// ok, channel found. let's unsubscribe. 
	char id [ 5 ];
	sprintf(id, "%d", i);
	const char* msg = buildUnsubscribeMsg(id);
	printf("Unsubscribe message:\n>%s<\n", msg);      
	int n = write(socketFileDescriptor,msg,strlen(msg));  
	flush();          
	Free(msg);     
      }     
    }
  }
}

// open the socket connection. 
void openSocketConnection(){
  struct sockaddr_in serv_addr;
  struct hostent *server;
  //   
  socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
  if (socketFileDescriptor < 0) 
    error("ERROR opening socket");
  server = gethostbyname(tcpTargetHost);
  // 
  if (server == NULL) {
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
      error("AQ-R could not connect to STOMP connector at %s:%d", tcpTargetHost, tcpTargetPort);      
  }  
  // 
  printf("AQ-R connected successfully to %s:%d\n", tcpTargetHost, tcpTargetPort);  
}

void closeSocketConnection(){
  if(socketFileDescriptor!=0x00)
    close(socketFileDescriptor); 
  
}



// utility function to initialize the AQ-R part. 
void initialize(){
  printf("Initializing AQ-R C part. \n");
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
  openSocketConnection();
  startConnection();
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
  SEXP Rresult;  
  // get the mutex on our channel list. 
  
  
  
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
  
  
  
  // 
  return Rresult;  
  
}

/**
 * sexpression contains channel list with ready data. 
 */
SEXP aqDataReady(){
  // 
  SEXP Rresult = R_NilValue;    
  // 
  // count all channels for which there is data. 
  // lock the mutex. 
  pthread_mutex_lock (&varLock);
   
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
  return Rresult;    
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
  printf("%s\n", name);
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
