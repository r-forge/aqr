#include <stdlib.h>
#include <math.h>

#define DEBUG_PRINTF 0

// plain function to run a convolution. 
void convolve(double *a, int *na, double *b, int *nb, double *ab)
{
   int i, j, nab = *na + *nb - 1;
  
   for(i = 0; i < nab; i++)
     ab[i] = 0.0;
   for(i = 0; i < *na; i++)
     for(j = 0; j < *nb; j++)
       ab[i + j] += a[i] * b[j];
}

	
// 
// all pnl changes are executed at same time as position curves and in and ask prices. 
// if you calculate some indicators based on close prices and you want to execute on these close 
// prices, make sure you pump in close prices plus some spread as bid and ask prices. 
// time is not taken into account in this method. 
// 
void c_generatePnlCurve(double* inBidPrices, double* inAskPrices, double* inRunningPosition, int* inNRows, double* outPnlSeries)
{
	double currentPosition = 0.0;
	double formerPosition = 0.0;
	double currentPnl = 0.0;
	// iterate over all incoming rows. 	
	for(int i=1;i<*inNRows;i++)
	{
		currentPosition = inRunningPosition[i];
		double formerAsk = inAskPrices[i-1];
		double ask = inAskPrices[i];
		double formerBid = inBidPrices[i-1];
		double bid = inBidPrices[i];
		if(currentPosition > 0 && formerPosition>0)
		{
				outPnlSeries[i] = bid - formerBid;
		}
		else if(currentPosition == 0 && formerPosition == 0)
		{
				outPnlSeries[i] = 0.0;
		}
		else if(currentPosition <0 && formerPosition<0)
		{
				double val = formerAsk - ask;
				outPnlSeries[i] = val;
		}
		else if(currentPosition > 0 && formerPosition < 0)
		{
				double change = (formerAsk - ask) + (bid - ask);
				outPnlSeries[i] = change;
		}
		else if(currentPosition < 0 && formerPosition > 0)
		{
				double change = (bid - formerBid) + (bid - ask);
				outPnlSeries[i] = change;
		}
		else if(currentPosition == 0 && formerPosition > 0)
		{
				outPnlSeries[i] = bid - formerBid;
		}
		else if(currentPosition == 0 && formerPosition < 0)
		{
				outPnlSeries[i] = formerAsk - ask;
		}
		else if(currentPosition > 0 && formerPosition == 0)
		{
				outPnlSeries[i] = bid - ask;
		}
		else if(currentPosition <0 && formerPosition == 0)
		{
				outPnlSeries[i] = bid - ask;
		}

		formerPosition = currentPosition;
		
	}

}



void c_stopLossTakeProfit(double* inBidPrices, double* inAskPrices, double* inRunningPosition, int* inNRows, double* inStopLoss, double* inTakeProfit, double* outRunningPosition)
{
	double* pnlSeries = malloc(*inNRows * sizeof(double));
	double currentPosition = 0.0;
	double currentPnl = 0.0;
	c_generatePnlCurve(inBidPrices, inAskPrices, inRunningPosition, inNRows, pnlSeries);
	for(int i=0;i<*inNRows;i++)
	{
		//printf("= = = = \n I: %d\n", i);
		if(inRunningPosition[i] != currentPosition)currentPnl = 0;
		currentPosition = inRunningPosition[i];
		//printf("current position: %f\n", currentPosition);
		currentPnl = currentPnl + pnlSeries[i];
		//printf("current pnl: %f\n", currentPnl);
		outRunningPosition[i] = currentPosition;
		if( (*inStopLoss < 0 && currentPnl < *inStopLoss) || (*inTakeProfit > 0&& currentPnl > *inTakeProfit))
		{
			//printf("Stop Loss triggered. \n");
			// overwrite until end of current direction. 
			for(int j=i;j<*inNRows;j++)
			{
				//printf("J: %d\n", j);
				double tempPosition = inRunningPosition[j];
				if(tempPosition > 0 && currentPosition > 0)
				{
					inRunningPosition[j] = 0;
					outRunningPosition[j] = 0;
				}
				else if(tempPosition < 0 && currentPosition < 0)
				{
					inRunningPosition[j] = 0;
					outRunningPosition[j] = 0;
				}
				else
				{
					c_generatePnlCurve(inBidPrices, inAskPrices, inRunningPosition, inNRows, pnlSeries);
					i=j;
					break;
				}
			}
		}
	}

}

// note, this function does not support position scaling, it can only handly position side changes as long as the position size stays the same. 
// can't handle increasing positions right now ...
// trades at close 
void c_approximateStopLossTakeProfit(double* inHigh, double* inLow, double* inClose, double* inRunningPosition, int* inNRows, double* inStopLoss, double* inTakeProfit, double* outReturn, double* outPosition)
{
	double formerPosition = 0.0; 
	double currentPnl = 0.0;
	double refPrice = 0.0; 
	int stopFlag = 0; 
#if DEBUG_PRINTF > 0
	printf("Doing something ... %d, %f, %f\n", *inNRows, *inStopLoss, *inTakeProfit);
#endif	
	for(int i=0;i<*inNRows;i++)
	{
#if DEBUG_PRINTF > 0	  
	    printf("***\nNext row, %f, %f, %f, %f\n", inHigh[i], inLow[i], inClose[i], inRunningPosition[i]);
#endif	    
		double pnlChange = 0.0; 
		// reset our current PNL. 
#if DEBUG_PRINTF > 0		
		printf("current pos %f, current pnl %f, refPrice %f\n",  formerPosition, currentPnl, refPrice);
#endif		
		 
		// let's calculate the PNL change for our current position ... 
		if(stopFlag == 1){
#if DEBUG_PRINTF > 0
		  printf("2\n");
#endif		  
		}		
		else if(formerPosition!=0.0){
		  // same side, so we can calculate a running PNL and also check for high/low/violations. 
		  // 
#if DEBUG_PRINTF > 0		  
		  printf("5\n");
#endif		  
		  
		  double signum = 1.0; 
		  if(formerPosition < 0.0)signum = -1.0; 
#if DEBUG_PRINTF > 0		  
		  printf("5. signum: %d\n", signum);
#endif		  
		  
		  double formerCloseToLow = (inLow[i] - refPrice) * signum; 
		  double formerCloseToHigh = (inHigh[i] - refPrice) * signum; 
		  
		  pnlChange = (inClose[i] - refPrice) * signum; 
#if DEBUG_PRINTF > 0		  
		  printf("pnlChange: %f\n", pnlChange);
#endif		  
		  
		  
		  // let's now check if this violates the take profit and stop loss thresholds. 		  
		  double tempPnl = fmin(currentPnl + formerCloseToLow, currentPnl + formerCloseToHigh);
#if DEBUG_PRINTF > 0		  
		  printf("5.1. %f\n", tempPnl);
#endif		  

		  if(tempPnl < *inStopLoss){
		    // liquidate ... 
		    outPosition[i] = 0.0; 
		    stopFlag = 1; // set the stop flag .. 
		    double leeway = *inStopLoss - currentPnl; 
		    pnlChange = leeway; 
#if DEBUG_PRINTF > 0		    
		    printf("5.1.1.\n");
#endif		  

		    
		  }
		  
		  tempPnl = fmax(currentPnl + formerCloseToLow, currentPnl + formerCloseToHigh);
#if DEBUG_PRINTF > 0		  
		  printf("5.2. %f\n", tempPnl);
#endif		  
		  // checking if we weren't stopped yet ... 
		  if((stopFlag==0) && (tempPnl > *inTakeProfit)){
		    // liquidate ... 
		    outPosition[i] = 0.0; 
		    stopFlag = 1;
		    double leeway = *inTakeProfit - currentPnl; 
		    pnlChange = leeway; 
#if DEBUG_PRINTF > 0		    
		    printf("5.2.2.\n");
#endif		  

		    
		  }
		}
		
		// compute current pnl in current position ... 
		currentPnl = currentPnl + pnlChange; 
#if DEBUG_PRINTF > 0		
		printf("pnlChange: %f\n", pnlChange);
#endif		  

		if(stopFlag == 0) // not stopped out, so let's copy it over 
		  outPosition[i] = inRunningPosition[i]; 
		else if(stopFlag == 1 && inRunningPosition[i] != formerPosition) // stopped out, but different position ... 
		  outPosition[i] = inRunningPosition[i]; 
		else
		  outPosition[i] = 0.0; 

		outReturn[i] = pnlChange; 
		// store the current period's position for the next cycle. 
		if(inRunningPosition[i] != formerPosition){
		  // ok, starting next period, we have a new position .. 
		  currentPnl = 0.0;				
		  stopFlag = 0; 
#if DEBUG_PRINTF > 0		  
		  printf("Resetting pnl\n");		  
#endif		  
		  
		}

		// carry over of data to next iteration ... 
		formerPosition = inRunningPosition[i]; 
		refPrice = inClose[i];		  


#if DEBUG_PRINTF > 0		
		printf("end of period PNL: %f\n----\n", currentPnl);
#endif		  

	}



}



void c_excessiveSpreadStop(double* inBid, double* inAsk, double* inRunningPosition, int* inNRows, double* inExcessiveSpreadVar, double* outRunningPosition)
{	
	double currentPosition = 0.0;
	double currentSpread = 0.0;
	int clearPosFlag = 0; 
	for(int i=0;i<*inNRows;i++)
	{
		//printf("= = = = \n I: %d\n", i);
		if(inRunningPosition[i] != currentPosition){
		   currentPosition = inRunningPosition[i];
		   clearPosFlag = 0;
		}
		
		currentSpread = inAsk[i] - inBid[i];
		
		// check if the current spread increase is a widening towards the current position ...
		// for example: long position and ask "runs away"/bid stays where it is : no exit necessary. 
		
		if(currentSpread >= *inExcessiveSpreadVar)
		{
		  // check the direction of the gap.
		  //if(currentPosition>0 && inBid[i] < currentBid)
		  //{
		    clearPosFlag = 1; 		  
		  //}
		  //else if(currentPosition < 0 && inAsk[i] > currentAsk){
		   //clearPosFlag = 1; 		    
		  //}
		}
		if(clearPosFlag == 1)
		{
		  outRunningPosition[i]	= 0;	  
		}
		else{
		  outRunningPosition[i] = currentPosition;
		}		
		
	}


}



