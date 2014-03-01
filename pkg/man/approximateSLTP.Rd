\name{approximateSLTP}
\alias{approximateSLTP}
\title{Approximates StopLoss/TakeProfit for a given PNL series and an HLC series.}
\usage{
approximateSLTP (high, low, close, takeProfit, stopLoss, runningPosition, messages=FALSE)
}
\arguments{
  \item{high}{an XTS object containing the highs of a price series}
  \item{low}{an XTS object containing the lows of a price series}
  \item{close}{an XTS object containing the closes of a price series}
  \item{takeProfit}{an absolute value when to trigger a take profit action}  
  \item{stopLoss}{an absolute value when to trigger a stop loss action}
  \item{runningPosition}{the running position}
  \item{messages}{whether to print informational message or not, defaults to FALSE}
  
}
\value{
a two column matrix with position and pnl, where position is a rewritten version of the input
}
\description{
This function uses the generatePnlCurve function to forward generate a PNL curve. 
Best, test it with your own series to understand how it works (or contribute documentation). 
}
