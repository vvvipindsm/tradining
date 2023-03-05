//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>


input double LotsMultiplier = 2;
input double Lots = 0.1;
input int TimeStartHour = 8;
input int TimeStartMMin = 0;
ulong DistancePoints = 300;
double upperLine, lowerLine,tpupperLine,tplowerLine;

int tradeCount = 1;
int stepSetupUpperLine = 0;
int stepHedgingStart = 0;
int stepHedingFirstTrade = 0;
ulong TpPoint = 1000;
double highestLotSize = 0;
int lastDirection = 0;
int totalProfitPoints = 0;

CTrade trade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//  Comment("Hedging");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //highest price a buyer will pay to "BUY"   FOR SELL
   double ask =  SymbolInfoDouble(_Symbol,SYMBOL_ASK); // lowest price a seller will pay to "SELL"  FOR BUY
    //  for(int i = PositionsTotal()-1;i >= 0;i--){
     if(stepSetupUpperLine == 0 && stepHedgingStart == 1)
     {
       ulong ticket = PositionGetTicket(0);
       if(PositionSelectByTicket(ticket)) {
         double posLots = PositionGetDouble(POSITION_VOLUME);
         double whereFirstOrder =  PositionGetDouble(POSITION_PRICE_OPEN);
         upperLine = whereFirstOrder + DistancePoints * _Point;
         lowerLine = whereFirstOrder - DistancePoints * _Point;
         tpupperLine = upperLine + TpPoint * _Point;
         tplowerLine = lowerLine - TpPoint * _Point;
         ObjectCreate(0,"Upper line",OBJ_HLINE,0,0,upperLine);
         ObjectCreate(0,"Lower Line",OBJ_HLINE,0,0,lowerLine);
         ObjectCreate(0,"Upper tp line",OBJ_HLINE,0,0,tpupperLine);
         ObjectCreate(0,"Upper linerr",OBJ_HLINE,0,0,tplowerLine);
         stepSetupUpperLine = 1;
       }
   
  
     }

   if(stepHedgingStart == 0)
     {
      stepHedgingStart = 1;
      upperLine = 0;
      lowerLine = 0;
     
      trade.Buy(calculateLotsSize(tradeCount));
       tradeCount = tradeCount + 1;

     }

 
//if start to trade
//if start to trade
   if(upperLine > 0 && lowerLine > 0)
     {
      double lots = Lots;
      //checking if any first trade or not

      if(highestLotSize > 0)
         lots = highestLotSize + LotsMultiplier;

      lots = NormalizeDouble(lots,2);

      if(bid > upperLine)
        {
        // Comment("break upper and last direction is :",lastDirection);
         if(lastDirection < 0 || stepHedingFirstTrade == 0)
           {
            
            stepHedingFirstTrade = 1;
            lastDirection = 1;
            //buy poistion
            trade.Buy(calculateLotsSize(tradeCount));
            tradeCount = tradeCount + 1;
           }
        }

      //todo check bid or ask price
      else
         if(bid < lowerLine)
           {
          //  Comment("break lower line and last direction is:",lastDirection);
            if(lastDirection > 0 || stepHedingFirstTrade == 0)
              {
               stepHedingFirstTrade = 1;
               lastDirection = -1;
               //sell position
               trade.Sell(calculateLotsSize(tradeCount));
               tradeCount = tradeCount + 1;
              }
           }
      //squre off
      if(bid < tplowerLine || bid > upperLine)
        {
         for(int i = PositionsTotal()-1; i >= 0; i--)
           {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket))
              {
               trade.PositionClose(ticket);
              }
           }
         //reset all

         ObjectDelete(0,"Upper line");
         ObjectDelete(0,"Upper tp line");
         ObjectDelete(0,"Upper tp linee");
         ObjectDelete(0,"Upper linerr");
        }
     }
   
   //Comment("\n \n \n \n \n trade count ",tradeCount);
  }
//+------------------------------------------------------------------+
double calculateLotsSize(int i)
  {
   double temp = Lots * (i*i);
   return(temp);
  }