//+------------------------------------------------------------------+
//|                                               Black Fairy EA.mq5 |
//|                                                       Joy D Moyo |
//|                                               www.latvianfts.com |
//+------------------------------------------------------------------+
#property copyright "Joy D Moyo"
#property link      "www.latvianfts.com"
#property version   "1.00"
#include <Trade\Trade.mqh>

CTrade *Trade;
CPositionInfo PositionInfo;

enum CloseType {UseProfitTarget,UseTrailingSL};
enum LossRecoveryType {UseTrailingTP,UseHedging};

input group "GENERAL INPUTS"
input string SymbolTraded = "EURUSD";
input ENUM_TIMEFRAMES PeriodTraded = PERIOD_M5;
input int EAMagic = 767767676;
input int Slippage = 5;

input group "KCC INPUTS"
input int KCCPeriod = 100; //todo make as enum 100,50,20,200
input int KCCDeviation = 5; // todo make as 5,3,6,7,3,2 
input ENUM_MA_METHOD KCCMode = MODE_SMA; //todo make as enum MODE_SMA
input ENUM_APPLIED_PRICE KCCAppliedPrice = PRICE_TYPICAL; //todo make enum PRICE_WEIGHTED,PRICE_TYPICALPRICE_MEDIAN

input group "TRADE MANAGEMENT"
input double ProfitTarget = 3; //todo enum 3,4,5,6,2
input double HedgeProfitTarget = 1; //todo eneum .5,1,1.5
input int GridDistance = 7;
input double LotMultiplier = 3;
input double HedgeLotMultiplier = 1.5;
input int MaxNumTrades = 7;
input CloseType ClosingOption = UseTrailingSL;
input LossRecoveryType LossRecoveryMethod = UseHedging;

input group "RISK MANAGEMENT"
input double BalanceIncrease = 1000;
input double VolumeIncrease = 0.01;
input double MinLot = 0.01;
input double MaxLot = 0.05;

int MAHandle,ATRHandle,OldNumBars=0,BarsAfterBuy=0,BarsAfterSell=0;
int MyDigits;
double  MABuffer[],ATRBuffer[],CHigh[],CLow[],PriceClose[],ASK,BID,NextBuyPrice=0,NextSellPrice=0
      ,GridDistancePoints,NextBuyLot,NextSellLot,MyPoint, LastBuyPrice, LastSellPrice;
bool HaveBuyHedge = false, HaveSellHedge = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ChartSetInteger(0,CHART_SHOW_GRID,false);
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrWhite);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrWhite);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,clrWhite);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrRed);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrRed);

   MyPoint = SymbolInfoDouble(SymbolTraded,SYMBOL_POINT);
   MyDigits = (int)SymbolInfoInteger(SymbolTraded,SYMBOL_DIGITS);
   ulong SlippagePoints = Slippage*10;
   GridDistancePoints = GridDistance*10*MyPoint;
   Trade = new CTrade;

   Trade.SetExpertMagicNumber(EAMagic);
   Trade.SetDeviationInPoints(SlippagePoints);

   ArraySetAsSeries(MABuffer,true);
   ArraySetAsSeries(ATRBuffer,true);
   ArraySetAsSeries(CHigh,true);
   ArraySetAsSeries(CLow,true);
   ArraySetAsSeries(PriceClose,true);

   ArrayResize(CHigh,4);
   ArrayResize(CLow,4);

   MAHandle = iMA(SymbolTraded,PeriodTraded,KCCPeriod,0,KCCMode,KCCAppliedPrice);
   ATRHandle = iATR(SymbolTraded,PeriodTraded,KCCPeriod);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {


  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(NewBarPresent())
     {
      CopyBuffer(MAHandle,0,0,4,MABuffer);
      CopyBuffer(ATRHandle,0,0,4,ATRBuffer);
      CopyClose(SymbolTraded,PeriodTraded,0,4,PriceClose);
      CalculateKCC();

      FirstBuy();
      FirstSell();
      GridBuy();
      GridSell();

      switch(LossRecoveryMethod)
        {
         case UseHedging:
            HedgeAllBuy();
            HedgeAllSell();
            break;
         default:
            if(NumOfBuy()>=MaxNumTrades || NumOfSell()>= MaxNumTrades)
               TrailingTP();
            break;
        }
     }
   TakeProfit(POSITION_TYPE_BUY,"HedgeBuy");
   TakeProfit(POSITION_TYPE_SELL,"HedgeSell");
   TakeHedgeProfit();
//Comment("Total Buy Size = ",BuyPositionSize(), " Total Sell Size = ",SellPositionSize());
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBarPresent()
  {
   int LatestNumBars = Bars(SymbolTraded,PeriodTraded);
   if(OldNumBars!=LatestNumBars)
     {
      OldNumBars = LatestNumBars;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateKCC()
  {
   for(int i=0; i<4; i++)
     {
      CHigh[i] = MABuffer[i] + (ATRBuffer[i]*KCCDeviation);
      CLow[i] = MABuffer[i] - (ATRBuffer[i]*KCCDeviation);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool FirstBuySignal()
  {
   if(NumOfBuy()==0&&PriceClose[1]>CLow[1]&&PriceClose[2]<CLow[2])
      return true;
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool FirstSellSignal()
  {
   if(NumOfSell()==0&&PriceClose[1]<CHigh[1]&&PriceClose[2]>CHigh[2])
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GridBuySignal()
  {
   if(NumOfBuy()!=0&&NumOfBuy()<MaxNumTrades&&PriceClose[1]>CLow[1]&&PriceClose[2]<CLow[2])
      return true;
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GridSellSignal()
  {
   if(NumOfSell()!=0&&NumOfSell()<MaxNumTrades&&PriceClose[1]<CHigh[1]&&PriceClose[2]>CHigh[2])
      return true;
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NumOfBuy()
  {
   int Num = 0;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
         continue;
      if(PositionInfo.Magic() != EAMagic)
         continue;
      if(PositionInfo.Symbol() != SymbolTraded)
         continue;
      if(PositionInfo.PositionType() != POSITION_TYPE_BUY)
         continue;
      Num++;
     }
   return Num;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NumOfSell()
  {
   int Num = 0;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
         continue;
      if(PositionInfo.Magic() != EAMagic)
         continue;
      if(PositionInfo.Symbol() != SymbolTraded)
         continue;
      if(PositionInfo.PositionType() != POSITION_TYPE_SELL)
         continue;
      Num++;
     }
   return Num;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotSize()
  {
   double lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE)/BalanceIncrease)*VolumeIncrease,2);
   if(lot<SymbolInfoDouble(SymbolTraded,SYMBOL_VOLUME_MIN))
      lot = MinLot;
   if(lot>SymbolInfoDouble(SymbolTraded,SYMBOL_VOLUME_MAX))
      lot = MaxLot;
   return lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FirstBuy()
  {
   if(FirstBuySignal()&&BarsAfterBuy!=Bars(SymbolTraded,PeriodTraded))
     {
      ASK = SymbolInfoDouble(SymbolTraded,SYMBOL_ASK);
      LastBuyPrice = ASK;
      if(!Trade.Buy(LotSize(),SymbolTraded,LastBuyPrice,0,0,"FirstBuy"))
         return;
      else
        {
         BarsAfterBuy = Bars(SymbolTraded,PeriodTraded);
         NextBuyPrice = NormalizeDouble(LastBuyPrice-GridDistancePoints,MyDigits);
         NextBuyLot = NormalizeDouble(LotSize()*LotMultiplier,2);
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FirstSell()
  {
   if(FirstSellSignal()&&BarsAfterSell!=Bars(SymbolTraded,PeriodTraded))
     {
      BID = SymbolInfoDouble(SymbolTraded,SYMBOL_BID);
      LastSellPrice = BID;
      double lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE)/BalanceIncrease)*VolumeIncrease,2);
      if(!Trade.Sell(LotSize(),SymbolTraded,LastSellPrice,0,0,"First Sell"))
         return;
      else
        {
         BarsAfterSell = Bars(SymbolTraded,PeriodTraded);
         NextSellPrice = NormalizeDouble(LastSellPrice+GridDistancePoints,MyDigits);
         NextSellLot = NormalizeDouble(LotSize()*LotMultiplier,2);
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TakeProfit(ENUM_POSITION_TYPE PositionType,string MyComment)
  {
   double TotalProfit = 0;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC)!=EAMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=PositionType)
         continue;
      TotalProfit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
   double AimedProfit = NormalizeDouble(ProfitTarget*AccountInfoDouble(ACCOUNT_BALANCE)/BalanceIncrease,2);
   if(TotalProfit>=AimedProfit)
     {
      switch(ClosingOption)
        {
         case UseTrailingSL :
            TrailingSL(PositionType,MyComment);
            break;
         default:
            CloseTrades(PositionType);
            break;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTrades(ENUM_POSITION_TYPE PositionType)
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC)!=EAMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=PositionType)
         continue;
      if(!Trade.PositionClose(PositionGetInteger(POSITION_TICKET)))
         Print("Failed to close ==",(string)PositionType);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseHedge(string MyComment)
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC)!=EAMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
         continue;
      if(PositionGetString(POSITION_COMMENT)!=MyComment)
         continue;
      if(!Trade.PositionClose(PositionGetInteger(POSITION_TICKET)))
         Print("Failed to close == Hedge");
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridBuy()
  {
   if(GridBuySignal()&&BarsAfterBuy != Bars(SymbolTraded,PERIOD_CURRENT))
     {
      ASK = SymbolInfoDouble(SymbolTraded,SYMBOL_ASK);
      if(ASK<=NextBuyPrice)
        {
         LastBuyPrice = ASK;
         if(!Trade.Buy(NextBuyLot,SymbolTraded,LastBuyPrice,0,0,"Grid Buy"))
            return;
         else
           {
            BarsAfterBuy = Bars(SymbolTraded,PERIOD_CURRENT);
            NextBuyPrice = NormalizeDouble(LastBuyPrice-GridDistancePoints,MyDigits);
            NextBuyLot= NormalizeDouble(NextBuyLot*LotMultiplier,2);
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridSell()
  {
   if(GridSellSignal()&&BarsAfterSell != Bars(SymbolTraded,PERIOD_CURRENT))
     {
      BID = SymbolInfoDouble(SymbolTraded,SYMBOL_BID);
      if(BID>=NextSellPrice)
        {
         LastSellPrice = BID;
         if(!Trade.Sell(NextSellLot,SymbolTraded,LastSellPrice,0,0,"Grid Sell"))
            return;
         else
           {
            BarsAfterSell = Bars(SymbolTraded,PERIOD_CURRENT);
            NextSellPrice = NormalizeDouble(LastSellPrice+GridDistancePoints,MyDigits);
            NextSellLot = NormalizeDouble(NextSellLot*LotMultiplier,2);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingSL(ENUM_POSITION_TYPE MyPositionType, string MyComment)
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
         continue;
      if(PositionInfo.Symbol() != SymbolTraded)
         continue;
      if(PositionInfo.PositionType()!=MyPositionType)
         continue;
      if(PositionInfo.Comment() == MyComment)
         continue;

      double CurrentSL = PositionInfo.StopLoss(),OpenPrice = PositionInfo.PriceOpen(),PositionTP = PositionInfo.TakeProfit(),CurrentPrice = PositionInfo.PriceCurrent();
      double PriceHigh = iHigh(SymbolTraded,PeriodTraded,1),PriceLow = iLow(SymbolTraded,PeriodTraded,1);

      double NewSl = MyPositionType == POSITION_TYPE_BUY?PriceLow:PriceHigh;

      if(CurrentSL!=0)
        {
         if(MyPositionType == POSITION_TYPE_BUY && (NewSl<= CurrentSL||NewSl>=CurrentPrice))
            continue;
         if(MyPositionType == POSITION_TYPE_SELL && (NewSl >= CurrentSL||NewSl<=CurrentPrice))
            continue;
        }
      if(!Trade.PositionModify(PositionInfo.Ticket(),NewSl,PositionTP))
         Print("Position Modifying Failed due to error code: ",GetLastError());
      else
        {
         if(HaveBuyHedge&&MyPositionType==POSITION_TYPE_BUY)
            CloseHedge("HedgeSell");
         if(HaveSellHedge&&MyPositionType==POSITION_TYPE_SELL)
            CloseHedge("HedgeBuy");
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingTP()
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
         continue;
      if(PositionInfo.Magic() != EAMagic)
         continue;
      if(PositionInfo.Symbol() != SymbolTraded)
         continue;

      double CurrentSL = PositionInfo.StopLoss(),NewTP = MABuffer[1];

      ulong MyTicket = PositionInfo.Ticket();

      if(!Trade.PositionModify(MyTicket,CurrentSL,NewTP))
         Print("Error Modifying Position [%d]",GetLastError());
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuyPositionSize()
  {
   double Lots = 0;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != EAMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!= POSITION_TYPE_BUY)
         continue;
      Lots += PositionGetDouble(POSITION_VOLUME);
     }
   return NormalizeDouble(Lots,2);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellPositionSize()
  {
   double Lots = 0;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != EAMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!= POSITION_TYPE_SELL)
         continue;
      Lots += PositionGetDouble(POSITION_VOLUME);
     }
   return NormalizeDouble(Lots,2);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HedgeAllSell()
  {
   if(PriceClose[1]>CHigh[1]&&PriceClose[2]<CHigh[2]&&BarsAfterSell!=Bars(SymbolTraded,PeriodTraded)&& !HaveSellHedge)
     {
      if(NumOfSell()>=MaxNumTrades)
        {
         ASK = SymbolInfoDouble(SymbolTraded,SYMBOL_ASK);
         double lot = NormalizeDouble(SellPositionSize()*HedgeLotMultiplier,2);
         if(!Trade.Buy(lot,SymbolTraded,ASK,0,0,"HedgeBuy"))
            Print("Failed To Hedge ", GetLastError());
         else
            HaveSellHedge = true;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HedgeAllBuy()
  {
   if(PriceClose[1]<CLow[1]&&PriceClose[2]>CLow[2]&& BarsAfterBuy != Bars(SymbolTraded,PeriodTraded)&& !HaveBuyHedge)
     {
      if(NumOfBuy()>=MaxNumTrades)
        {
         BID = SymbolInfoDouble(SymbolTraded,SYMBOL_BID);
         double lot = NormalizeDouble(BuyPositionSize()*HedgeLotMultiplier,2);
         if(!Trade.Sell(lot,SymbolTraded,BID,0,0,"HedgeSell"))
            Print("Failed to Hedge",GetLastError());
         else
            HaveBuyHedge = true;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TakeHedgeProfit()
  {
   double TotalProfit = 0;
   if(HaveBuyHedge||HaveSellHedge)
     {
      for(int i = PositionsTotal()-1; i>=0; i--)
        {
         if(!PositionSelectByTicket(PositionGetTicket(i)))
            continue;
         if(PositionGetInteger(POSITION_MAGIC) != EAMagic)
            continue;
         if(PositionGetString(POSITION_SYMBOL)!= SymbolTraded)
            continue;
         TotalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
      if(TotalProfit >= HedgeProfitTarget)
        {
         CloseTrades(POSITION_TYPE_BUY);
         CloseTrades(POSITION_TYPE_SELL);
         HaveBuyHedge = false;
         HaveSellHedge = false;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
