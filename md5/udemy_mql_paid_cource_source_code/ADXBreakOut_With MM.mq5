//+------------------------------------------------------------------+
//|                                                  ADXBreakOut.mq5 |
//|                                                       Joy D Moyo |
//|                                               joydmoyo@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Joy D Moyo"
#property link      "joydmoyo@gmail.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include "Risk_Manager.mqh"

CTrade *Trade;
CSymbolInfo SymbolInfo;
CAccountInfo AccountInfo;
CPositionInfo PositionInfo;

sinput string ADXINPUTS = ""; //=== ADX INPUTS ===
input int ADXPeriod = 14;
input int ADXLevel = 25;

sinput string GENERALINPUTS = ""; //=== GENERAL INPUTS ===
input int Displacement = 3;
input int EAMagic = 32456;
input int Slippage = 3;
input double FixedLot = 0.01;
input int MaxRange = 20;

sinput string TARGETSINPUTS = ""; //=== TARGETS INPUTS ===
input int StopLoss = 10;
input double ProfitFactor = 2;

sinput string MONEYMANAGEMENT = ""; //=== MONEY MANAGEMENT ===
input ENUM_RISK_TYPE UsedRiskType = UseFixedLotStep;
input double FixedBalance = 1000;
input int PercentageRisk = 2;
input double FixedRiskMoney = 32.50;
input double BalanceIncrease = 1000;
input double LotIncrease = 0.1;

int ADXHandle;
double ADXBuffer[],Lots;
double highs[],lows[],RangeBars[];
datetime RangeStart,RangeEnd;
int RangeHighBar,RangeLowBar,NumBarsRange;
double RangeSize, displacement;

double STP,SellSLPrice,BuySLPrice,BuyEntryPrice,SellEntryPrice;
bool sold, bought, GoodRange = false;
ulong slippage;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Trade = new CTrade;
   Trade.SetExpertMagicNumber(EAMagic);

   slippage = Slippage*10;
   Trade.SetDeviationInPoints(slippage);

   ADXHandle = iADX(_Symbol,PERIOD_CURRENT,ADXPeriod);
   ArraySetAsSeries(ADXBuffer,true);
   ArraySetAsSeries(highs,true);
   ArraySetAsSeries(lows,true);
   ArraySetAsSeries(RangeBars,true);

   STP = StopLoss*_Point*10;
   displacement = Displacement*_Point*10;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete Trade;
   PendingOrderDelete();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CopyBuffer(ADXHandle,0,0,3,ADXBuffer);
   ArrayResize(highs,NumBarsRange());
   ArrayResize(lows,NumBarsRange());

   if(RangeBegining())
     {
      sold = false;
      bought = false;
     }

   if(RangeEnding())
     {
      RangeSize = ((rangeHigh()-rangeLow())/_Point)/10;
      if(RangeSize<=MaxRange)
        {
         GoodRange = true;
        }
     }

   Lots = LotSize(STP,FixedLot,UsedRiskType,FixedBalance,PercentageRisk,FixedRiskMoney,BalanceIncrease,LotIncrease);
   
   string rectangleName = "Range"+(string)TimeCurrent();
   string start = "Start"+(string)TimeCurrent();
   string end = "end"+(string)TimeCurrent();

   if(RangeEnding() && GoodRange)
     {
      ObjectCreate(0,rectangleName,OBJ_RECTANGLE,0,RangeStart,rangeHigh(),RangeEnd,rangeLow());
     }
   if(!sold && GoodRange)
     {
      SellEntryPrice = rangeLow()-displacement;
      SellSLPrice = rangeLow()-displacement+STP;
      Sell();
      Print("RangeSize = ",RangeSize," Good Range? =",GoodRange);
     }
   if(!bought && GoodRange)
     {
      BuyEntryPrice = rangeHigh()+displacement;
      BuySLPrice = rangeHigh()+displacement-STP;
      Buy();
      Print("RangeSize = ",RangeSize," Good Range? =",GoodRange);
     }

   if(RangeBegining()||PositionsTotal()>0)
     {
      PendingOrderDelete();
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|RANGE BEGIN FUNCTION                                              |
//+------------------------------------------------------------------+
bool RangeBegining()
  {
   if(ADXBuffer[1]<ADXLevel&&ADXBuffer[2]>ADXLevel)
      return true;
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|RANGE ENDING FUNCTION                                             |
//+------------------------------------------------------------------+
bool RangeEnding()
  {
   if(ADXBuffer[1]>ADXLevel&&ADXBuffer[2]<ADXLevel)
      return true;
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NumBarsRange()
  {
   if(RangeBegining())
      RangeStart = iTime(_Symbol,PERIOD_CURRENT,1);
   if(RangeEnding())
      RangeEnd = iTime(_Symbol,PERIOD_CURRENT,1);
   if(RangeEnding())
      NumBarsRange = Bars(_Symbol,PERIOD_CURRENT,RangeStart,RangeEnd);

   return NumBarsRange;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double rangeHigh()
  {
   double RangeHighPrice = 0;
   if(RangeEnding())
     {
      CopyHigh(_Symbol,PERIOD_CURRENT,RangeStart,RangeEnd,highs);
      RangeHighBar = fabs(ArrayMaximum(highs,0,WHOLE_ARRAY));
      RangeHighPrice = highs[RangeHighBar];
     }
   return RangeHighPrice;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double rangeLow()
  {
   double RangeLowPrice = 0;
   if(RangeEnding())
     {
      CopyLow(_Symbol,PERIOD_CURRENT,RangeStart,RangeEnd,lows);
      RangeLowBar = fabs(ArrayMinimum(lows,0,WHOLE_ARRAY));
      RangeLowPrice = lows[RangeLowBar];
     }
   return RangeLowPrice;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuyTP()
  {
   return (BuyEntryPrice + STP*ProfitFactor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellTP()
  {
   return (SellEntryPrice - STP*ProfitFactor);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Buy()
  {
   if(RangeEnding())
     {
      Trade.BuyStop(Lots,BuyEntryPrice,_Symbol,BuySLPrice,BuyTP(),ORDER_TIME_GTC,0,"Buy Stop");
      bought = true;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sell()
  {
   if(RangeEnding())
     {
      Trade.SellStop(Lots,SellEntryPrice,_Symbol,SellSLPrice,SellTP(),ORDER_TIME_GTC,0,"Sell Stop");
      sold = true;
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PendingOrderDelete()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      ulong orderTicket = OrderGetTicket(i);
      if(orderTicket != 0)
        {
         Trade.OrderDelete(orderTicket);
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
