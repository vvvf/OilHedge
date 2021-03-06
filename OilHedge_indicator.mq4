//+------------------------------------------------------------------+
//|                                                     差价对冲.mq4 |
//|                                                              LDX |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "LDX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window  //指标放在副图
#property indicator_color1 Black    //第一条指标线为黑色

#property indicator_level1 0      //在副图中零值位置上画一条水平横线,

extern string High_Symbol = "UKOIL";//高价品种
extern string Low_Symbol = "USOIL";//低价品种
extern int bars = 2000;//计算的蜡烛数
//只能用于长时间的那个图表

double buf[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,buf);//设置数组buf为第一条指标线
   SetIndexStyle(0,DRAW_LINE);//设置第一条指标线线型为连续曲线

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
  
   datetime high_time;
   datetime low_time;
   int limit = 0;
   
   limit=rates_total-prev_calculated;
   if(rates_total==limit)
      limit--;
   for(int i=0,j=0; i<=limit; i++)
   {
      high_time = iTime(High_Symbol,0,j);
      low_time = iTime(Low_Symbol,0,i);
   //   Print(high_time,low_time);
      if(high_time==low_time)
      {
         
         buf[i] = iOpen(High_Symbol, 0, j) - iOpen(Low_Symbol, 0, i);
         j++;
      }
      
      
   }


   return(rates_total);
  }
//+------------------------------------------------------------------+
