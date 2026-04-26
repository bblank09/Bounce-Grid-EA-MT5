//+------------------------------------------------------------------+
//|                                       Bounce_Grid_EA_MT5.mq5     |
//|                        Copyright 2024, MetaQuotes Ltd.           |
//|                            https://www.mql5.com                  |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2024, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property version     "1.00"
#property description "Trailing Buy EA with grid re-entry and trailing exit"
#property strict

#include <Trade\Trade.mqh>

CTrade trade;

//--- ─────────────────────────────────────────────────────────────────
input string step_0          = "=== General Settings ===";
input int    Inp_Magic     = 696969;   // Magic Number
input double Inp_LotSize   = 0.01;     // Lot Size

//--- ─────────────────────────────────────────────────────────────────
input string step_1            = "=== Entry Settings ===";
input int    Inp_BuyPoint    = 2500;  // Re-entry Distance (points)
input int    Inp_TrsPoint    = 250;   // Trailing Entry Trigger (points)

//--- ─────────────────────────────────────────────────────────────────
input string step_2            = "=== Exit Settings ===";
input int    Inp_TPPoint     = 2500;  // TP Trigger Distance (points)
input int    Inp_TrsPointTP  = 250;   // Trailing Stop Distance (points)

//--- Computed price distances (initialised in OnInit)
double trsPointTP;
double TPPoint;
double buypoint;
double trsPoint;

//--- Position counters
double AllPoint_BUY  = 0;
double Allprofit_Buy = 0;
int    buy_order     = 0;

//--- Price trackers
double openprice1;
double leastprice;

double new_buy;
double new_buy1;
double new_buy_TP;
double new_buy1_TP = 0;

ulong  ticket_ticket = 0;

//--- State flags
bool status_buy    = false;
bool status_buy_TP = false;

//--- Bar tracking
datetime current_bar;
datetime last_trade_bar = 0;
datetime lastBarTime    = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Convert point inputs to price distances after _Point is ready
   trsPointTP = Inp_TrsPointTP * _Point;
   TPPoint    = Inp_TPPoint    * _Point;
   buypoint   = Inp_BuyPoint   * _Point;
   trsPoint   = Inp_TrsPoint   * _Point;

   //--- Attach magic number to all trade operations
   trade.SetExpertMagicNumber(Inp_Magic);

   //--- Initialise price sentinels
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   new_buy      = ask + trsPoint;
   new_buy1     = DBL_MAX;                 // sentinel: "no trigger yet"
   new_buy_TP   = SymbolInfoDouble(_Symbol, SYMBOL_BID) - trsPointTP;

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Reset state on removal (no indicator handles to release)
   status_buy    = false;
   status_buy_TP = false;
}

//+------------------------------------------------------------------+
//| Count Orders and Points                                          |
//+------------------------------------------------------------------+
void Count_Order_Point()
{
   AllPoint_BUY  = 0;
   buy_order     = 0;
   Allprofit_Buy = 0;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket))
      {
         if(PositionGetString(POSITION_SYMBOL)  == _Symbol &&
            PositionGetInteger(POSITION_MAGIC)  == Inp_Magic &&
            PositionGetInteger(POSITION_TYPE)   == POSITION_TYPE_BUY)
         {
            buy_order++;
            AllPoint_BUY  += (bid - PositionGetDouble(POSITION_PRICE_OPEN));
            Allprofit_Buy += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Find lowest open price across all symbol positions              |
//+------------------------------------------------------------------+
void findlowestprice()
{
   openprice1 = DBL_MAX;   // sentinel: "no position found yet"

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == Inp_Magic)
         {
            leastprice = PositionGetDouble(POSITION_PRICE_OPEN);
            openprice1 = MathMin(leastprice, openprice1);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Buy function                                                     |
//+------------------------------------------------------------------+
void buy_func()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   current_bar = iTime(_Symbol, PERIOD_M1, 0);
   if(current_bar == last_trade_bar)
      return;

   if(buy_order == 0)
   {
      if(!trade.Buy(Inp_LotSize, _Symbol, ask, 0, 0))
      {
         Print(__FUNCTION__, " | trade.Buy failed | Error: ", GetLastError(),
               " | Retcode: ", trade.ResultRetcode(),
               " | Comment: ", trade.ResultComment());
      }
      else
      {
         last_trade_bar = current_bar;
      }
   }
   else if(buy_order > 0)
   {
      findlowestprice();

      if(openprice1 - ask >= buypoint)
         status_buy = true;

      if(status_buy)
      {
         new_buy  = ask + trsPoint;
         new_buy1 = MathMin(new_buy1, new_buy);
      }

      if(ask > new_buy1 && status_buy)
      {
         if(!trade.Buy(Inp_LotSize, _Symbol, ask, 0, 0))
         {
            Print(__FUNCTION__, " | trade.Buy (re-entry) failed | Error: ", GetLastError(),
                  " | Retcode: ", trade.ResultRetcode(),
                  " | Comment: ", trade.ResultComment());
         }
         else
         {
            last_trade_bar = current_bar;
            status_buy     = false;
            new_buy1       = DBL_MAX;   // reset sentinel
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void trslFunction()
{
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int    total = PositionsTotal();

   if(!status_buy_TP)
   {
      for(int i = total - 1; i >= 0; i--)
      {
         ulong posTicket = PositionGetTicket(i);
         if(PositionSelectByTicket(posTicket))
         {
            if(PositionGetString(POSITION_SYMBOL)  == _Symbol &&
               PositionGetInteger(POSITION_MAGIC)  == Inp_Magic &&
               PositionGetInteger(POSITION_TYPE)   == POSITION_TYPE_BUY)
            {
               double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

               if(bid - openPrice >= TPPoint)
               {
                  status_buy_TP = true;
                  ticket_ticket = posTicket;
                  break;
               }
            }
         }
      }
   }

   if(status_buy_TP)
   {
      new_buy_TP   = bid - trsPointTP;
      new_buy1_TP  = MathMax(new_buy1_TP, new_buy_TP);
   }

   if(bid < new_buy1_TP && status_buy_TP)
   {
      if(!trade.PositionClose(ticket_ticket))
      {
         Print(__FUNCTION__, " | PositionClose failed | Ticket: ", ticket_ticket,
               " | Error: ", GetLastError(),
               " | Retcode: ", trade.ResultRetcode(),
               " | Comment: ", trade.ResultComment());
      }
      else
      {
         status_buy_TP = false;
         new_buy1_TP   = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   Count_Order_Point();
   buy_func();
   trslFunction();
}
