#include <Trade/Trade.mqh>


input double LotsMultiplier = 2;
input double Lots = 0.01;
input int TimeStartHour = 8;
input int TimeStartMMin = 0;
input int DistancePoints = 50;
double upperLine, lowerLine;
int stepSetupUpperLine = 0;
int stepHedgingStart = 0;
input int TpPoint = 100;

CTrade trade;

int OnInit()
  {
 //  Comment("Hedging");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
   
  }
void OnTick()
  {
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //highest price a buyer will pay to "BUY"   FOR SELL
      double ask =  SymbolInfoDouble(_Symbol,SYMBOL_ASK); // lowest price a seller will pay to "SELL"  FOR BUY
      
      
      double highestLotSize = 0;
      int lastDirection = 0;
      int totalProfitPoints = 0;

      for(int i = PositionsTotal()-1;i >= 0;i--){
         Comment("entering positions",i);
        //get order position number or id
         ulong ticket = PositionGetTicket(i);
          //taking particular order details
          if(PositionSelectByTicket(ticket)) {
            //get particular trade lot size
            double posLots = PositionGetDouble(POSITION_VOLUME);

            //loop current trade lot size is less than highestLot Size will update highestLotSize
            if(posLots > highestLotSize ) {
               highestLotSize = posLots;

               //todo we have to take last trade without loop and set last diretion
               //if last trade is buy when we will last direction would be 1= BUY
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  lastDirection = 1;
               }
                 //if last trade is buy when we will last direction would be -1 = SELL
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                  lastDirection = -1;
               }
               //todo end
               
               //calculate total profit
               //31.38 youtube
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  totalProfitPoints += (int)((bid - PositionGetDouble(POSITION_PRICE_OPEN)) / _Point * posLots / Lots);
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    //todo check calculation and what is posLots
                   totalProfitPoints +=  (int)((PositionGetDouble(POSITION_PRICE_OPEN) - ask) / _Point * posLots / Lots);
                }
            }
         }
       
     
      }
     
      if(totalProfitPoints > TpPoint) {
        
        for(int i = PositionsTotal()-1;i >= 0;i--){
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket)) {
               trade.PositionClose(ticket);
            }
        }
        //reset all 
        highestLotSize = 0;
        lastDirection = 0;
        upperLine = 0;
        lowerLine = 0;
      }
     
      MqlDateTime structTime;
      //return last server return time
      TimeCurrent(structTime);
      structTime.hour = TimeStartHour;
      structTime.min = TimeStartMMin;
      structTime.sec = 0;
      datetime timeStart = StructToTime(structTime);
     //for backtesting
      if(stepHedgingStart == 0) {
        stepHedgingStart = 1;
        upperLine = 0;
        lowerLine = 0;
        //do initial trade
        trade.Buy(Lots);
      }

      if(stepSetupUpperLine == 0 && stepHedgingStart == 1) {
        Comment("entering upperline",upperLine);
        upperLine = bid + DistancePoints * _Point;
        lowerLine = bid - DistancePoints * _Point;
        ObjectCreate(0,"Upper line",OBJ_HLINE,0,0,upperLine);
        ObjectCreate(0,"Lower Line",OBJ_HLINE,0,0,lowerLine);
        stepSetupUpperLine = 1;
      }
      //if start to trade
      if(upperLine > 0 && lowerLine > 0) {
         double lots = Lots;
         //checking if any first trade or not
         if(highestLotSize > 0) lots = highestLotSize + LotsMultiplier;
         lots = NormalizeDouble(lots,2);
         if(bid > upperLine) {
            if(highestLotSize == 0 || lastDirection < 0){
             //buy poistion
             trade.Buy(lots);
            }
         }

         //todo check bid or ask price
         else if(bid < lowerLine) {
          if(highestLotSize == 0 || lastDirection > 0){
              //sell position
             trade.Sell(lots);
           }
         }
      }      
      Comment(
       "\n Dppoint",totalProfitPoints,
      "\nUpper Line",upperLine,
      "\nLower Line",bid);
   
  }
