//+------------------------------------------------------------------+
//|                                                 Risk_Manager.mqh |
//|                                                       Joy D Moyo |
//|                                               joydmoyo@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Joy D Moyo"
#property link      "joydmoyo@gmail.com"

#include <Trade\DealInfo.mqh>
CDealInfo DealInfo;

enum ENUM_RISK_TYPE
  {
   UseFixedLot,
   UsePercentageBalance,
   UsePercentageEquity,
   UseFixedBalance,
   UseFreeMargin,
   UseFixedRiskMoney,
   UseDynamicLotStep,
   UseFixedLotStep
  };

enum ENUM_MARTINGALE
  {
   FixedLot,
   Martingale,
   ReverseMartingale,
   SemiMartingale
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotSize(double FunSL,double FunFixedLot, ENUM_RISK_TYPE FunUsedRiskType, double FunFixedBalance,int FunPercentRisk, double FunFixedRiskMoney,double FunFundsPerLot, double FunLotPerFunds)
  {
   double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE),AccountEquity=AccountInfoDouble(ACCOUNT_EQUITY),RiskMoney = 0,cal_lot = 0,
          FreeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double TickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),TickValue;

   switch(FunUsedRiskType)
     {
      case UseFixedLot :
         return FunFixedLot;
         break;
      case UsePercentageBalance :
         RiskMoney = AccountBalance*FunPercentRisk/100;
         break;
      case UseFixedBalance :
         RiskMoney = FunFixedBalance*FunPercentRisk/100;
         break;
      case UseFreeMargin :
         RiskMoney = FreeMargin*FunPercentRisk/100;
         break;
      case UseFixedRiskMoney :
         RiskMoney = FunFixedRiskMoney;
         break;
      default:
         RiskMoney = AccountEquity*FunPercentRisk/100;
         break;
     }

   if(Symbol()=="XAUUSD")
      TickValue = 1;
   else
      TickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

   if(FunSL!=0&&TickValue!=0&&TickSize!=0)
     {
      if(FunUsedRiskType==UseDynamicLotStep)
         cal_lot = NormalizeDouble(AccountBalance/FunFundsPerLot*FunLotPerFunds,2);
      else
         if(FunUsedRiskType==UseFixedLotStep)
            cal_lot = NormalizeDouble(MathFloor(AccountBalance/FunFundsPerLot)*FunLotPerFunds,2);
         else
            cal_lot = NormalizeDouble(RiskMoney/(FunSL*TickValue/TickSize),2);
     }

   if(cal_lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
      cal_lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(cal_lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
      cal_lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);

   return cal_lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MartingaleLot(string FunSymbol,double FunLot,double FunEAMagic,ENUM_MARTINGALE FunUsedLot,double FunMultiplier,int FunLimit,double FunLotChange)
  {
   int WinCount = 0, LossCount = 0;
   double Cal_Lot = FunLot;

   if(HistorySelect(0,TimeCurrent()))
     {
      int DealsTotal = HistoryDealsTotal();
      for(int i = DealsTotal-1; i>=0; i--)
        {
         if(!DealInfo.SelectByIndex(i))
            continue;
         if(DealInfo.Magic()!=FunEAMagic)
            continue;
         if(DealInfo.Symbol()!=FunSymbol)
            continue;
         if(DealInfo.Entry()!=DEAL_ENTRY_OUT)
            continue;

         if(WinCount==0 && DealInfo.Profit()<0)
           {
            Cal_Lot = DealInfo.Volume();
            LossCount++;
           }

         else
            if(LossCount==0 && DealInfo.Profit()>0)
              {
               Cal_Lot = DealInfo.Volume();
               WinCount++;
              }

            else
               break;
        }
     }

   switch(FunUsedLot)
     {
      case  FixedLot:
         return FunLot;
         break;
      case  SemiMartingale:
         if(WinCount>0)
            Cal_Lot = NormalizeDouble(Cal_Lot + (FunLotChange*WinCount),2);
         if(LossCount>0)
            Cal_Lot = NormalizeDouble(Cal_Lot - (FunLotChange*LossCount),2);
         break;
      case ReverseMartingale:
         if(WinCount>FunLimit)
            WinCount = FunLimit;
         Cal_Lot = NormalizeDouble(FunLot*MathPow(FunMultiplier,WinCount),2);
         break;
      default:
         if(LossCount>FunLimit)
            LossCount = FunLimit;
         Cal_Lot = NormalizeDouble(FunLot*MathPow(FunMultiplier,LossCount),2);
         break;
     }

   if(Cal_Lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
      Cal_Lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(Cal_Lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
      Cal_Lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   return Cal_Lot;
  }
//+------------------------------------------------------------------+
