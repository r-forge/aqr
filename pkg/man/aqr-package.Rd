\name{aqr-package}
\alias{aqr-package}
\alias{aqr}
\docType{package}
\title{Package level introduction}
\description{This package provides an R interface for using an AQ Master Server (AQMS). Preferrably, this package is used in conjunction with an AQMS, although the messaging layer works with any STOMP compliant messaging server, too. While I do not want this text to become an advertorial for AQMS, it is unavoidable to refer to AQ and AQMS. 


Some remarks upfront. An AQMS instance does not include data sources or data fetchers, it is a simple and dumb data store and data relay, built on open source components. Connectors to venues such as Yahoo, Bloomberg, Reuters, etc., are not within this extension's scope. The #1 rule to keep in mind: \emph{what is inside, can go out}. 

AQ-R tries to maintain a consistent variable naming scheme. Throughout this package, you will encounter the terms \emph{seriesId}, \emph{fieldId} and \emph{channel}. All these terms are plain names, which you give meaning to and which you can choose freely within certain sanity boundaries. Note, that ActiveQuant itself generates IDs for instruments automatically. As soon as your R code interacts with other AQ components, these other components might specify the IDs of instruments. As we deal in this tutorial only with R, we are going to skip the technical details of how auto-generated IDs look like in the Java world and work with the fact that you are free to choose them for your own purposes. As said before, the server itself is very dumb and does not enforce a naming pattern or consistency between instrument definitions and timeseries data. What goes in, can go out. 

This introductory section is separated into two parts, a) historical data and b) messaging realtime data.}


\section{Historical data}{

AQ-R provides methods to store and fetch historical timeseries data with an AQMS. Keep rule #1 in mind, you can't fetch what isn't in. So, in order to load 1 minute, 5 minute, 1 hour or tick data, data has to be to put in. There exist some ready-made data feeders within AQ, but you are free to write your own in python, Java or in R Although the AQMS interfaces are cross language compatible, we focus in this text on R. This basic structure of data feeders and data consumers is shown in the next figure. 

  \if{html}{\figure{1.png}{Basic setup}}
  \if{latex}{\figure{1.png}{options: width=4in}}

AQMS is built on HBase and Hadoop, an ultra-scalable NoSQL solution which enables you to build large storage clusters capable of handling Petabytes of data. Try that with plain file-based storage of HDF5 files. But let's move on. Also with HBase, data gets separated into tables, rows and columns. Specific to the AQMS approach is that time series data is stored into one table per timeframe. This means, all \code{timeFrame = RAW} data goes into the RAW table, all \code{timeFrame = EOD} goes into the EOD table, etc. There is no logical enforcement that all data is indeed of the specified granularity, but there is a logical enforcement that table names are of specific values only. It is for the time being within the responsibility of the user to put data where it belongs. A series can contain an arbitrary amount of fields. The \emph{seriesId} specifies the logical name of the series, typically it contains the instrument ID, but it is literally just a string used to identify. Examples of a seriesId are \emph{CNX.
MDI.EURUSD} or \emph{BBG.FUT.GXZ12_INDEX}. Let's move on to fields. FieldIDs, similar to seriesIDs are plain strings used to identify a field within a series. The user is responsible for maintaining a naming scheme, within the data feeders of AQ, we use the same field naming conventions. Part of the convention is to use only upper-case field names. Examples of field names are \emph{OPEN}, \emph{HIGH}, \emph{PX_SETTLE}, \emph{SMA10}, \emph{IMPLVOL}, etc., but these are just examples. In case of doubt, rule #1 applies: what goes in, goes out. 



\strong{Tutorial}

In the context of this tutorial, we assume you have your AQMS server up and running. At first we will create a small script that uses quantmod to fetch end-of-day historical data from Yahoo. We will then store that data in AQMS. Because it is so much fun, we will also calculate the simple-moving-average and store this one in AQMS, too. As the final step, we will write another script and fetch former stored data from AQMS. 

Let's fetch data for Microsoft and SAP from Yahoo. 

\preformatted{
require(aqr)
require(quantmod)
# fetch them via quantmod
getSymbols(c("MSFT", "SAP"))
# visual check 
candleChart(MSFT)
candleChart(SAP)
aqStoreMatrix("myMSFT", "EOD", MSFT)
aqStoreMatrix("mySAP", "EOD", MSFT)
}

Once data has been stored in AQMS, it is much faster to retrieve data in the future from AQMS than it is to fetch it from Yahoo or Google. Keep in mind that some providers' data usage policies prohibit storing data locally. 

Now let's assume we are in a new R session. We'll first load the data from yesterday and will then calculate the SMAs and store these, too. 

\preformatted{
#let's load what we stored. 
aqLoadOHLC("myMSFT", "EOD", 19900101, 20200101)
aqLoadOHLC("mySAP", "EOD", 19900101, 20200101)
# let's calc SMAs
smaMsft = SMA(MSFT[,4])
smaSap = SMA(SAP[,4])
# let's store it. 
aqStoreSeriesField("MSFT", "SMA14", "EOD", smaMsft)
# It should say: Wrote 1478 lines. 
aqStoreSeriesField("SAP", "SMA14", "EOD", smaSap)
...
}


\strong{More complex scenario}
The following figure shows you a more developed setup for historical data, where instead of R, other applications, like Excel play the role of data consumers. The builtin cross-language support of AQMS enables R applications to share data through AQMS with other environments, for exampe Excel - imagine some R processes calculating some risk parameters and some other non-scientific person viewing this data without installing ODBC drivers, etc. The AQMS contains an CSV-over-HTTP interface, which returns data in CSV format, so that any application, able to view a webpage can access data. Isn't that neat? And way easier than SQL, ODBC or other fancy technology, but that's all for now. 

  \if{html}{\figure{2.png}{More complex historical data scenario}}
  \if{latex}{\figure{2.png}{options: width=5in}}

}



\section{Messaging realtime data}{
  
Messaging happens in channels. All messages sent to a channel are broadcasted to all subscribers. Several data consumers can subscribe to the same channel and several data producers can publish into the same channel. Subscribers subscribe to a channel by specifying the \emph{channel name} to which they would like to subscribe. 

The channel name is not governed by conventions, although some data feeders use similar naming conventions. These channel names are plain string representations, for example "TEXT", "PNL", "CNX.MDI.EURUSD". The messages transmitted in a channel are not standardized either, although some data feeders (particularly the AQ data feeders) send messages in a consistent, google protocol buffers based format. 


Using the messaging solution involves always the same flow. Some data consumer has subscribed to a channel. Some data publisher sends a message to a channel. All subscribed data consumers will receive this message. The following diagram summarizes this. 

  \if{html}{\figure{3.png}{Basic messaging setup}}
  \if{latex}{\figure{3.png}{options: width=5in}}


While sending data is a trivial call to \code{aqSend()}, receiving messages involves not only subscribing to a channel, but also either waiting for data or looking for data at regular intervals. The call to \code{aqWaitForData()} is a blocking call and will return a list of channels for which data is available. A subsequent call to \code{aqPoll()} will return all data received since its last call. An event driven R script would always call \code{aqWaitForData()}, followed immediately by \code{aqPoll()}. A message independent system can call \code{aqPoll()} at regular intervals, for example as soon as some other computations conclude. 


\strong{Technicalities}

Feel free to skip the next paragraphs and go straight to the tutorials, if you are not so technical. To my knowledge - without checking ALL existing packages of R - there is no easy and generic way to do realtime messaging in R. This partly owing to the fact that R is single threaded. This means of course that at some point within the messaging infrastructure, some sort of buffering has to occur. AQ-R solves this by spawning a background thread in its C part, this messaging interface buffers a limited amount of incoming data until it has been processed by R. On the communication protocol side, AQ-R uses the STOMP protocol to implement a two-way messaging solution. Technically, you do not need to use AQMS, as any STOMP compliant messaging server may be used. 

On the technical side, the default way to messaging is through a \emph{topic}, rather than a \emph{queue} - but queues are also implementable should there be a serious need. The distinction between a topic and a queue is, a topic is a broadcast to all subscribers in a channel, whereas a queue means the message gets sent to the next available subscriber. 

\strong{Tutorial}

In this tutorial we build a simple message producer and a simple message consumer. Assuming the latest AQMS is up and running on \emph{localhost}, we need two R instances, one for sending and one for receiving data. At first we write the data sender. Our data sender should send out a random number every second. The trivial code is shown next. 

\preformatted{
require(aqr)
while(1){
  # generate a message containing a number between 1 and 1000. 
  msg = toString(sample(1000,1))
  # send the message to channel RAND_DAT_CHAN
  aqSend("RAND_DAT_CHAN", msg)
  # sleep for a second. 
  Sys.sleep(1);
}
}


Now, let's build the receiver side. The two key function are \code{aqPoll()}, which will return at the time of this writing all received messages separated by a newline character and \code{aqWaitForData}, which is a blocking call and which will wait until data has been received. \code{aqPoll} will fetch all messages for all channels as a two dimensional matrix, one row corresponding to one channel. It is the responsibility of the R code to further process these messages. 

In a new R instance, the following code will print the received message as soon as the event hits the R instance. 

\preformatted{
require(aqr)
aqSubscribeChannel("RAND_DAT_CHAN")
while(1){
  aqWaitForData()
  # fetch all data. 
  text = aqPoll()
  # browser()
  message("Message received: ", text[,2])
}
}

Now that messages have been received, you could for example convert it to a double. The open nature of this messaging solution enables creating arbitrarily complex messaging scenarios. The only real restriction is a maximum message size of 4096 bytes within the R extension. 	






\strong{More complex scenario}
The following diagram presents a more complex messaging scenario with various data producers and consumers. Again, this messaging solution is not R specific. 
  \if{html}{\figure{4.png}{More complex}}
  \if{latex}{\figure{4.png}{options: width=5in}}

Thanks for your attention, now on to the function documentation. 
}


