//+------------------------------------------------------------------+
//|                                              Keltner_Channel.mq5 |
//|                                                       Joy D Moyo |
//|                                               joydmoyo@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Joy D Moyo"
#property link      "joydmoyo@gmail.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 3
#property indicator_width1 2
#property indicator_color1 clrLimeGreen
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_label1 "KChannel-Up"
#property indicator_width2 1
#property indicator_color2 clrDodgerBlue
#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_DOT
#property indicator_label2 "KChannel-Mid"
#property indicator_width3 2
#property indicator_color3 clrLimeGreen
#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_SOLID
#property indicator_label3 "KChannel-Low"

//---- input parameters
input int MA_Period = 10;
input int Deviation = 5;
input ENUM_MA_METHOD Mode_MA = MODE_SMA;
input ENUM_APPLIED_PRICE Price_Type = PRICE_TYPICAL;

//----
double upper[], middle[], lower[], MA_Buffer;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   SetIndexBuffer(0, upper, INDICATOR_DATA);
   SetIndexBuffer(1, middle, INDICATOR_DATA);
   SetIndexBuffer(2, lower, INDICATOR_DATA);

   IndicatorSetString(INDICATOR_SHORTNAME, "KC(" + IntegerToString(MA_Period) + ")");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit;
   double avg;   
   
   int counted_bars = prev_calculated;

   if (counted_bars < 0) return(-1);
   if (counted_bars > 0) counted_bars--;
   
   limit = counted_bars;

   if (limit < MA_Period) limit = MA_Period;

   int myMA = iMA(NULL, 0, MA_Period, 0, Mode_MA, Price_Type);
   if  (CopyBuffer(myMA, 0, 0, rates_total, middle) != rates_total) return(0);

   for (int i = rates_total - 1; i >= limit; i--) 
   {
      avg = findAvg(MA_Period, i, High, Low);
      upper[i] = middle[i] + avg*Deviation;
      lower[i] = middle[i] - avg*Deviation;
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Finds the moving average of the price ranges                     |
//+------------------------------------------------------------------+  
double findAvg(int period, int shift, const double &High[], const double &Low[]) 
{
   double sum = 0;

   for (int i = shift; i > (shift - period); i--) 
       sum += High[i] - Low[i];

   sum = sum / period;
   
   return(sum);
}  
//+------------------------------------------------------------------+



