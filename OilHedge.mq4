//+------------------------------------------------------------------+
//|                                                    Oil Hedge.mq4 |
//|                                                              LDX |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "LDX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define DIRECTION_EXPAND 1
#define DIRECTION_NARROW 0
#define DIRECTION_NO_ORDER 2

input string High_Symbol = "UKOIL";//高价品种
input string Low_Symbol = "USOIL";//低价品种
input int magics = 500;//魔数
input double lots = 0.1;//手数
input double MaxOrder = 2;//最大订单数
input double Open_Price_Expand = 3.75;//差价扩大到该值时开单
input double Open_Price_Narrow = 3.25;//差价缩小到该值时开单        
//由于点差的存在，差价缩小时的实际成交价会大于这个值双倍点差，推荐在预期低值的基础上降低相应的点差

input bool isAddPosition = false;//是否开启加仓
input double Add_Positions_Val  = 0.1;//加仓的差价间隔
input double lots_multi = 1.5;//加仓倍数
double Open_Price_Next_Diff = 0;//开首单后，进一步达到该值时加仓
double next_lots = lots;//记录加仓的手数


extern double Close_Price_Expand = 3.5;//差价达到该值关闭扩大方向订单
extern double Close_Price_Narrow = 3.5;//差价达到该值关闭缩小方向订单

int direction = DIRECTION_NO_ORDER;//用于记录当前做单方向。

double Diff = 0;    //当前实时价差
double Day_High = 0;
double Day_Low = 0;
double Day_Aver = 0;
double Week_High = 0;
double Week_Low = 0;
double Month_Low = 0;
double Month_High = 0;
datetime today;   //用于记录今天


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //先判断是否已存在本EA订单
   if(hasMyOrder() == true)
   {    for(int i=0; i<OrdersTotal(); i++)
        {
           OrderSelect(i, SELECT_BY_POS);
           if(OrderMagicNumber()==magics && OrderSymbol()==High_Symbol) 
           {
              if(OrderType()==OP_SELL){direction = DIRECTION_EXPAND;}
              else if(OrderType()==OP_BUY){direction = DIRECTION_NARROW;}
           }
        }
   }
   else
   {
      direction = DIRECTION_NO_ORDER;
   }

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double highSymbolPrice = 0;
   double lowSymbolPrice = 0;
   string text = "";
   
   
   //获取实时差价
   highSymbolPrice = MarketInfo(High_Symbol, MODE_ASK);
   lowSymbolPrice = MarketInfo(Low_Symbol, MODE_ASK);
   Diff = NormalizeDouble(highSymbolPrice - lowSymbolPrice, Digits);
   
   //生成输出文本
   text = text + StringConcatenate("实时价差 = " , Diff) + "\n"; 
   
   //第一次开仓
   if(hasMyOrder()==false)
   {
      if(Diff >= Open_Price_Expand)
      {
         //如果价差过大
         if(OrderSend(High_Symbol, OP_SELL, lots, MarketInfo(High_Symbol, MODE_BID), 3, 0, 0,"By ldx", magics) &&
            OrderSend(Low_Symbol, OP_BUY, lots, MarketInfo(Low_Symbol, MODE_ASK), 3, 0, 0,"By ldx", magics)         
            )
         {
            direction = DIRECTION_EXPAND;
            Open_Price_Next_Diff = Open_Price_Expand + Add_Positions_Val;//下次加仓的差价值
            next_lots = lots * lots_multi;//下次开仓的手数
         }
         else
         {
            Print("开仓失败");
         }
      }
      else if(Diff <= Open_Price_Narrow)
      {
         //如果价差过小
         if(OrderSend(Low_Symbol, OP_SELL, lots, MarketInfo(Low_Symbol, MODE_BID), 3, 0, 0,"By ldx", magics)  &&
            OrderSend(High_Symbol, OP_BUY, lots, MarketInfo(High_Symbol, MODE_ASK), 3, 0, 0,"By ldx", magics)
         )
         {
            direction = DIRECTION_NARROW;
            Open_Price_Next_Diff = Open_Price_Narrow - Add_Positions_Val;
            next_lots = lots * lots_multi;
         }
         else
         {
            Print("开仓失败");
         }
      }
   }
   
   //加仓
   if(hasMyOrder()==true && isAddPosition==true && MaxOrder>OrdersTotal())
   {
      if(direction==DIRECTION_EXPAND && Diff>=Open_Price_Next_Diff)
      {
         OrderSend(High_Symbol, OP_SELL, next_lots, MarketInfo(High_Symbol, MODE_BID), 3, 0, 0,"By ldx", magics);
         OrderSend(Low_Symbol, OP_BUY, next_lots, MarketInfo(Low_Symbol, MODE_ASK), 3, 0, 0,"By ldx", magics);
         Open_Price_Next_Diff = Open_Price_Next_Diff + Add_Positions_Val;
         next_lots = lots * lots_multi;
      }
      else if(direction==DIRECTION_NARROW && Diff<=Open_Price_Next_Diff)
      {
         OrderSend(Low_Symbol, OP_SELL, next_lots, MarketInfo(Low_Symbol, MODE_BID), 3, 0, 0,"By ldx", magics);
         OrderSend(High_Symbol, OP_BUY, next_lots, MarketInfo(High_Symbol, MODE_ASK), 3, 0, 0,"By ldx", magics);
         Open_Price_Next_Diff = Open_Price_Next_Diff - Add_Positions_Val;
         next_lots = lots * lots_multi;
      }
   }
   
   
   //生成输出文本
   text = text + StringConcatenate("做单方向 = " , getDirection(direction)) + "\n";
   
   
   //记录点差的波动范围
   if(TimeDay(TimeCurrent()) != today)
   {
      //新的一天开始
      Day_High = Diff;
      Day_Low = Diff; 
      today = TimeDay(TimeCurrent());
   }
   if(Diff > Day_High)
   {
      Day_High = Diff;
   }
   else if(Diff < Day_Low)
   {
      Day_Low = Diff;
   }
   
   
   //生成输出文本
   text = text + StringConcatenate("Highest=" , Day_High , "   Lowest=" , Day_Low) + "\n";
   
   
   
   //寻找平仓
   if(hasMyOrder()==true)
   {
      if(Diff >= Close_Price_Narrow && direction==DIRECTION_NARROW)
      {
         //如果做单是价差缩小的方向，达到平仓条件
         while(hasMyOrder()==True)
         {
            ClosePosition();
         }
         direction = DIRECTION_NO_ORDER;
      }
      else if(Diff <= Close_Price_Expand && direction==DIRECTION_EXPAND)
      {
         //如果做单是价差扩大的方向，达到平仓条件
         while(hasMyOrder()==True)
         {
            ClosePosition();
         }
         direction = DIRECTION_NO_ORDER;
      }
   }
   
   
   Comment(text);
   
  }
  


//获取当前做单方向的文字描述
string getDirection(int directionInt)
{
   string directionStr = "错误";
   switch(directionInt)
   {
   case 0:
      directionStr = "差价缩小";
      break;
   case 1:
      directionStr = "差价扩大";
      break;
   case 2:
      directionStr = "未开单";
      break;
   }
   return directionStr;
}   
  



//检测是否有本EA生成的订单
bool hasMyOrder()
{
   bool res = false;
   if(OrdersTotal()!=0)
   {
     for(int i=0; i<OrdersTotal(); i++)
    {
        OrderSelect(i, SELECT_BY_POS);
        if(OrderMagicNumber()==magics)
        {
           res = true;
        }
     }
   }
   return res;
}




//关闭所有订单
void ClosePosition()
{
 for(int i=0; i<OrdersTotal(); i++)
         {
            OrderSelect(i, SELECT_BY_POS);
            if(OrderType()==OP_BUY && OrderMagicNumber()==magics)
            {
               Print("OP_BUY",+OrderTicket());
            
               if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_BID),3))
              {
                 Print("关闭订单成功");
              }
              else
              {
                 Print("关闭订单失败",GetLastError());
              }
              
            }
            else if(OrderType()==OP_SELL && OrderMagicNumber()==magics)
            {
               Print("OP_SELL",+OrderTicket());
            
               if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_ASK),3))
              {
                 Print("关闭订单成功");
              }
              else
              {
                 Print("关闭订单失败",GetLastError());
              }
              
              
            }
            
         }
}
//+------------------------------------------------------------------+
