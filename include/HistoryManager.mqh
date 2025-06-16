//+------------------------------------------------------------------+
//|                                               HistoryManager.mq5 |
//|                          Copyright 2024, Wanateki Solutions Ltd. |
//|                                         https://www.wanateki.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2024, Wanateki Solutions Ltd."
#property link      "https://www.wanateki.com"
#property version   "1.00"

//- Define directives for sorting different history data
//-----------------------------------------------------------------------
#define GET_ORDERS_HISTORY_DATA 1001
#define GET_DEALS_HISTORY_DATA 1002
#define GET_POSITIONS_HISTORY_DATA 1003
#define GET_PENDING_ORDERS_HISTORY_DATA 1004
#define GET_ALL_HISTORY_DATA 1005

//- Global data structures
//-----------------------------------------------------------------------
//- Data structure to store deal properties
struct DealData
  {
   ulong             ticket;
   ulong             magic;
   ENUM_DEAL_ENTRY   entry;
   ENUM_DEAL_TYPE    type;
   ENUM_DEAL_REASON  reason;
   ulong             positionId;
   ulong             order;
   string            symbol;
   string            comment;
   double            volume;
   double            price;
   datetime          time;
   double            tpPrice;
   double            slPrice;
   double            commission;
   double            swap;
   double            profit;
  };

//- Data structure to store order properties
struct OrderData
  {
   datetime                timeSetup;
   datetime                timeDone;
   datetime                expirationTime;
   ulong                   ticket;
   ulong                   magic;
   ENUM_ORDER_REASON       reason;
   ENUM_ORDER_TYPE         type;
   ENUM_ORDER_TYPE_FILLING typeFilling;
   ENUM_ORDER_STATE        state;
   ENUM_ORDER_TYPE_TIME    typeTime;
   ulong                   positionId;
   ulong                   positionById;
   string                  symbol;
   string                  comment;
   double                  volumeInitial;
   double                  priceOpen;
   double                  priceStopLimit;
   double                  tpPrice;
   double                  slPrice;
  };

//- Data structure to store closed position/trade properties
struct PositionData
  {
   ENUM_POSITION_TYPE type;
   ulong              ticket;
   ENUM_ORDER_TYPE    initiatingOrderType;
   ulong              positionId;
   bool               initiatedByPendingOrder;
   ulong              openingOrderTicket;
   ulong              openingDealTicket;
   ulong              closingDealTicket;
   string             symbol;
   double             volume;
   double             openPrice;
   double             closePrice;
   datetime           openTime;
   datetime           closeTime;
   long               duration;
   double             commission;
   double             swap;
   double             profit;
   double             tpPrice;
   double             slPrice;
   int                tpPips;
   int                slPips;
   int                pipProfit;
   double             netProfit;
   ulong              magic;
   string             comment;
  };

//- Data structure to store executed or canceled pending order properties
struct PendingOrderData
  {
   string                  symbol;
   ENUM_ORDER_TYPE         type;
   ENUM_ORDER_STATE        state;
   double                  priceOpen;
   double                  tpPrice;
   double                  slPrice;
   int                     tpPips;
   int                     slPips;
   ulong                   positionId;
   ulong                   ticket;
   datetime                timeSetup;
   datetime                expirationTime;
   datetime                timeDone;
   ENUM_ORDER_TYPE_TIME    typeTime;
   ulong                   magic;
   ENUM_ORDER_REASON       reason;
   ENUM_ORDER_TYPE_FILLING typeFilling;
   string                  comment;
   double                  volumeInitial;
   double                  priceStopLimit;
  };

//- Global data structures dynamic arrays to store the loaded history data
OrderData orderInfo[];
DealData dealInfo[];
PositionData positionInfo[];
PendingOrderData pendingOrderInfo[];

//+------------------------------------------------------------------+
//| GetHistoryData(): Get and save history data based on the         |
//| specified time period and data type to query                     |
//+------------------------------------------------------------------+
bool GetHistoryData(datetime fromDateTime, datetime toDateTime, uint dataToGet)
  {
//- Check if the provided period of dates are valid
   if(fromDateTime >= toDateTime)
     {
      //- Invalid time period selected
      Print("Invalid time period provided. Can't load history!");
      return(false);
     }

//- Reset last error and get the history
   ResetLastError();
   if(HistorySelect(fromDateTime, toDateTime)) //- History selected ok
     {
      //- Get the history data
      switch(dataToGet)
        {
         case GET_DEALS_HISTORY_DATA: //- Get and save only the deals history data
            SaveDealsData();
            break;

         case GET_ORDERS_HISTORY_DATA: //- Get and save only the orders history data
            SaveOrdersData();
            break;

         case GET_POSITIONS_HISTORY_DATA: //- Get and save only the positions history data
            SaveDealsData();  //- Needed to generate the positions history data
            SaveOrdersData(); //- Needed to generate the positions history data
            SavePositionsData();
            break;

         case GET_PENDING_ORDERS_HISTORY_DATA: //- Get and save only the pending orders history data
            SaveOrdersData(); //- Needed to generate the pending orders history data
            SavePendingOrdersData();
            break;

         case GET_ALL_HISTORY_DATA: //- Get and save all the history data
            SaveDealsData();
            SaveOrdersData();
            SavePositionsData();
            SavePendingOrdersData();
            break;

         default: //-- Unknown entry
            Print("-----------------------------------------------------------------------------------------");
            Print(__FUNCTION__, ": Can't fetch the historical data you need.");
            Print("*** Please specify the historical data you need in the (dataToGet) parameter.");
            break;
        }
     }
   else
     {
      Print(__FUNCTION__, ": Selecting the history failed. Error code = ", GetLastError());
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------------------+
//| SaveDealsData(): Queries the deals properties and saves them for processing  |
//| in a dynamic data structure array                                            |
//+------------------------------------------------------------------------------+
void SaveDealsData()
  {
//- Get the number of loaded history deals
   int totalDeals = HistoryDealsTotal();
   ulong dealTicket;
//-
//- Check if we have any deals to be worked on
   if(totalDeals > 0)
     {
      //- Resize the dynamic array that stores the deals
      ArrayResize(dealInfo, totalDeals);

      //- Let us loop through the deals and save them one by one
      for(int x = totalDeals - 1; x >= 0; x--)
        {
         ResetLastError();
         dealTicket = HistoryDealGetTicket(x);
         if(dealTicket > 0)
           {
            //- Deal ticket selected ok, we can now save the deals properties
            dealInfo[x].ticket = dealTicket;
            dealInfo[x].entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            dealInfo[x].type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
            dealInfo[x].magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
            dealInfo[x].positionId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            dealInfo[x].order = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
            dealInfo[x].symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
            dealInfo[x].comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
            dealInfo[x].volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
            dealInfo[x].price = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
            dealInfo[x].time = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
            dealInfo[x].tpPrice = HistoryDealGetDouble(dealTicket, DEAL_TP);
            dealInfo[x].slPrice = HistoryDealGetDouble(dealTicket, DEAL_SL);
            dealInfo[x].commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            dealInfo[x].swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
            dealInfo[x].reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON);
            dealInfo[x].profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
           }
         else
           {
            Print(
               __FUNCTION__, " HistoryDealGetTicket(", x, ") failed. (dealTicket = ", dealTicket,
               ") *** Error Code: ", GetLastError()
            );
           }
        }
     }
   else
     {
      Print(__FUNCTION__, ": No deals available to be processed, totalDeals = ", totalDeals);
     }
  }

//+------------------------------------------------------------------------------+
//| PrintDealsHistory(): Prints the deals history data for the specified period  |
//+------------------------------------------------------------------------------+
void PrintDealsHistory(datetime fromDateTime, datetime toDateTime) export
  {
//- Get and save the deals history for the specified period
   GetHistoryData(fromDateTime, toDateTime, GET_DEALS_HISTORY_DATA);
   int totalDeals = ArraySize(dealInfo);
   if(totalDeals <= 0)
     {
      Print("");
      Print(__FUNCTION__, ": No deals history found for the specified period.");
      return; //-- Exit the function
     }

   Print("");
   Print(__FUNCTION__, "-------------------------------------------------------------------------------");
   Print(
      "Found a total of ", totalDeals,
      " deals executed between (", fromDateTime, ") and (", toDateTime, ")."
   );

   for(int r = 0; r < totalDeals; r++)
     {
      Print("---------------------------------------------------------------------------------------------------");
      Print("Deal #", (r + 1));
      Print("Symbol: ", dealInfo[r].symbol);
      Print("Time Executed: ", dealInfo[r].time);
      Print("Ticket: ", dealInfo[r].ticket);
      Print("Position ID: ", dealInfo[r].positionId);
      Print("Order Ticket: ", dealInfo[r].order);
      Print("Type: ", EnumToString(dealInfo[r].type));
      Print("Entry: ", EnumToString(dealInfo[r].entry));
      Print("Reason: ", EnumToString(dealInfo[r].reason));
      Print("Volume: ", dealInfo[r].volume);
      Print("Price: ", dealInfo[r].price);
      Print("SL Price: ", dealInfo[r].slPrice);
      Print("TP Price: ", dealInfo[r].tpPrice);
      Print("Swap: ", dealInfo[r].swap, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Commission: ", dealInfo[r].commission, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Profit: ", dealInfo[r].profit, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Comment: ", dealInfo[r].comment);
      Print("Magic: ", dealInfo[r].magic);
      Print("");
     }
  }

//+----------------------------------------------------------------------------+
//| SaveOrdersData(): Queries the order history properties and saves them for  |
//| processing in a dynamic data structure array                               |
//+----------------------------------------------------------------------------+
void SaveOrdersData()
  {
//- Get the number of loaded history orders
   int totalOrdersHistory = HistoryOrdersTotal();
   ulong orderTicket;
//-
//- Check if we have any orders in the history to be worked on
   if(totalOrdersHistory > 0)
     {
      //- Resize the dynamic array that stores the history orders
      ArrayResize(orderInfo, totalOrdersHistory);

      //- Let us loop through the order history and save them one by one
      for(int x = totalOrdersHistory - 1; x >= 0; x--)
        {
         ResetLastError();
         orderTicket = HistoryOrderGetTicket(x);
         if(orderTicket > 0)
           {
            //- Order ticket selected ok, we can now save the order properties
            orderInfo[x].ticket = orderTicket;
            orderInfo[x].timeSetup = (datetime)HistoryOrderGetInteger(orderTicket, ORDER_TIME_SETUP);
            orderInfo[x].timeDone = (datetime)HistoryOrderGetInteger(orderTicket, ORDER_TIME_DONE);
            orderInfo[x].expirationTime = (datetime)HistoryOrderGetInteger(orderTicket, ORDER_TIME_EXPIRATION);
            orderInfo[x].typeTime = (ENUM_ORDER_TYPE_TIME)HistoryOrderGetInteger(orderTicket, ORDER_TYPE_TIME);
            orderInfo[x].magic = HistoryOrderGetInteger(orderTicket, ORDER_MAGIC);
            orderInfo[x].reason = (ENUM_ORDER_REASON)HistoryOrderGetInteger(orderTicket, ORDER_REASON);
            orderInfo[x].type = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
            orderInfo[x].state = (ENUM_ORDER_STATE)HistoryOrderGetInteger(orderTicket, ORDER_STATE);
            orderInfo[x].typeFilling = (ENUM_ORDER_TYPE_FILLING)HistoryOrderGetInteger(orderTicket, ORDER_TYPE_FILLING);
            orderInfo[x].positionId = HistoryOrderGetInteger(orderTicket, ORDER_POSITION_ID);
            orderInfo[x].positionById = HistoryOrderGetInteger(orderTicket, ORDER_POSITION_BY_ID);
            orderInfo[x].symbol = HistoryOrderGetString(orderTicket, ORDER_SYMBOL);
            orderInfo[x].comment = HistoryOrderGetString(orderTicket, ORDER_COMMENT);
            orderInfo[x].volumeInitial = HistoryOrderGetDouble(orderTicket, ORDER_VOLUME_INITIAL);
            orderInfo[x].priceOpen = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
            orderInfo[x].priceStopLimit = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_STOPLIMIT);
            orderInfo[x].tpPrice = HistoryOrderGetDouble(orderTicket, ORDER_TP);
            orderInfo[x].slPrice = HistoryOrderGetDouble(orderTicket, ORDER_SL);
           }
         else
           {
            Print(
               __FUNCTION__, " HistoryOrderGetTicket(", x, ") failed. (orderTicket = ", orderTicket,
               ") *** Error Code: ", GetLastError()
            );
           }
        }
     }
   else
     {
      Print(__FUNCTION__, ": No order history available to be processed, totalOrdersHistory = ", totalOrdersHistory);
     }
  }

//+--------------------------------------------------------------------------------+
//| PrintOrdersHistory(): Prints the orders history data for the specified period  |
//+--------------------------------------------------------------------------------+
void PrintOrdersHistory(datetime fromDateTime, datetime toDateTime) export
  {
//- Get and save the orders history for the specified period
   GetHistoryData(fromDateTime, toDateTime, GET_ORDERS_HISTORY_DATA);
   int totalOrders = ArraySize(orderInfo);
   if(totalOrders <= 0)
     {
      Print("");
      Print(__FUNCTION__, ": No orders history found for the specified period.");
      return; //-- Exit the function
     }

   Print("");
   Print(__FUNCTION__, "-------------------------------------------------------------------------------");
   Print(
      "Found a total of ", totalOrders,
      " orders filled or cancelled between (", fromDateTime, ") and (", toDateTime, ")."
   );

   for(int r = 0; r < totalOrders; r++)
     {
      Print("---------------------------------------------------------------------------------------------------");
      Print("Order #", (r + 1));
      Print("Symbol: ", orderInfo[r].symbol);
      Print("Time Setup: ", orderInfo[r].timeSetup);
      Print("Type: ", EnumToString(orderInfo[r].type));
      Print("Ticket: ", orderInfo[r].ticket);
      Print("Position ID: ", orderInfo[r].positionId);
      Print("State: ", EnumToString(orderInfo[r].state));
      Print("Type Filling: ", EnumToString(orderInfo[r].typeFilling));
      Print("Type Time: ", EnumToString(orderInfo[r].typeTime));
      Print("Reason: ", EnumToString(orderInfo[r].reason));
      Print("Volume Initial: ", orderInfo[r].volumeInitial);
      Print("Price Open: ", orderInfo[r].priceOpen);
      Print("Price Stop Limit: ", orderInfo[r].priceStopLimit);
      Print("SL Price: ", orderInfo[r].slPrice);
      Print("TP Price: ", orderInfo[r].tpPrice);
      Print("Time Done: ", orderInfo[r].timeDone);
      Print("Expiration Time: ", orderInfo[r].expirationTime);
      Print("Comment: ", orderInfo[r].comment);
      Print("Magic: ", orderInfo[r].magic);
      Print("");
     }
  }

//+------------------------------------------------------------------------------+
//| SavePositionsData(): Queries the data saved in the deals and orders history  |
//| data structures arrays to generate an audit trail to identify and save the   |
//| trades/positions history.                                                    |
//+------------------------------------------------------------------------------+
void SavePositionsData()
  {
//- Since every transaction is recorded as a deal, we will begin by scanning the deals and link them
//- to different orders and generate the positions data using the POSITION_ID as the primary and foreign key
   int totalDealInfo = ArraySize(dealInfo);
   ArrayResize(positionInfo, totalDealInfo); //- Resize the position array to match the deals array
   int totalPositionsFound = 0, posIndex = 0;
   if(totalDealInfo == 0) //- Check if we have any deal history available for processing
     {
      return; //- No deal data to process found, we can't go on. exit the function
     }
//- Let us loop through the deals array
   for(int x = totalDealInfo - 1; x >= 0; x--)
     {
      //- First we check if it is an exit deal to close a position
      if(dealInfo[x].entry == DEAL_ENTRY_OUT)
        {
         //- We begin by saving the position id
         ulong positionId = dealInfo[x].positionId;
         bool exitDealFound = false;

         //- Now we check if we have an exit deal from this position and save it's properties
         for(int k = ArraySize(dealInfo) - 1; k >= 0; k--)
           {
            if(dealInfo[k].positionId == positionId)
              {
               if(dealInfo[k].entry == DEAL_ENTRY_IN)
                 {
                  exitDealFound = true;

                  totalPositionsFound++;
                  posIndex = totalPositionsFound - 1;

                  positionInfo[posIndex].openingDealTicket = dealInfo[k].ticket;
                  positionInfo[posIndex].openTime = dealInfo[k].time;
                  positionInfo[posIndex].openPrice = dealInfo[k].price;
                  positionInfo[posIndex].volume = dealInfo[k].volume;
                  positionInfo[posIndex].magic = dealInfo[k].magic;
                  positionInfo[posIndex].comment = dealInfo[k].comment;
                 }
              }
           }

         if(exitDealFound) //- Continue saving the exit deal data
           {
            //- Save the position type
            if(dealInfo[x].type == DEAL_TYPE_BUY)
              {
               //- If the exit deal is a buy, then the position was a sell trade
               positionInfo[posIndex].type = POSITION_TYPE_SELL;
              }
            else
              {
               //- If the exit deal is a sell, then the position was a buy trade
               positionInfo[posIndex].type = POSITION_TYPE_BUY;
              }

            positionInfo[posIndex].positionId = dealInfo[x].positionId;
            positionInfo[posIndex].symbol = dealInfo[x].symbol;
            positionInfo[posIndex].profit = dealInfo[x].profit;
            positionInfo[posIndex].closingDealTicket = dealInfo[x].ticket;
            positionInfo[posIndex].closePrice = dealInfo[x].price;
            positionInfo[posIndex].closeTime = dealInfo[x].time;
            positionInfo[posIndex].swap = dealInfo[x].swap;
            positionInfo[posIndex].commission = dealInfo[x].commission;
            positionInfo[posIndex].tpPrice = dealInfo[x].tpPrice;
            positionInfo[posIndex].tpPips = 0;
            positionInfo[posIndex].slPrice = dealInfo[x].slPrice;
            positionInfo[posIndex].slPips = 0;

            //- Calculate the trade duration in seconds
            positionInfo[posIndex].duration = MathAbs((long)positionInfo[posIndex].closeTime - (long)positionInfo[posIndex].openTime);

            //- Calculate the net profit after swap and commission
            positionInfo[posIndex].netProfit =
               positionInfo[posIndex].profit + positionInfo[posIndex].swap - positionInfo[posIndex].commission;

            //- Get pip values for the position
            if(positionInfo[posIndex].type == POSITION_TYPE_BUY) //- Buy position
              {
               //- Get sl and tp pip values
               if(positionInfo[posIndex].tpPrice > 0)
                 {
                  double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
                  positionInfo[posIndex].tpPips =
                     int((positionInfo[posIndex].tpPrice - positionInfo[posIndex].openPrice) / symbolPoint);
                 }
               if(positionInfo[posIndex].slPrice > 0)
                 {
                  double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
                  positionInfo[posIndex].slPips =
                     int((positionInfo[posIndex].openPrice - positionInfo[posIndex].slPrice) / symbolPoint);
                 }

               //- Get the buy profit in pip value
               double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
               positionInfo[posIndex].pipProfit =
                  int((positionInfo[posIndex].closePrice - positionInfo[posIndex].openPrice) / symbolPoint);
              }
            else //- Sell position
              {
               //- Get sl and tp pip values
               if(positionInfo[posIndex].tpPrice > 0)
                 {
                  double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
                  positionInfo[posIndex].tpPips =
                     int((positionInfo[posIndex].openPrice - positionInfo[posIndex].tpPrice) / symbolPoint);
                 }
               if(positionInfo[posIndex].slPrice > 0)
                 {
                  double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
                  positionInfo[posIndex].slPips =
                     int((positionInfo[posIndex].slPrice - positionInfo[posIndex].openPrice) / symbolPoint);
                 }

               //- Get the sell profit in pip value
               double symbolPoint = SymbolInfoDouble(positionInfo[posIndex].symbol, SYMBOL_POINT);
               positionInfo[posIndex].pipProfit =
                  int((positionInfo[posIndex].openPrice - positionInfo[posIndex].closePrice) / symbolPoint);
              }

            //- Now we scan and get the opening order ticket in the orderInfo array
            for(int k = 0; k < ArraySize(orderInfo); k++) //- Search from the oldest to newest order
              {
               if(
                  orderInfo[k].positionId == positionInfo[posIndex].positionId &&
                  orderInfo[k].state == ORDER_STATE_FILLED
               )
                 {
                  //- Save the order ticket that intiated the position
                  positionInfo[posIndex].openingOrderTicket = orderInfo[k].ticket;
                  positionInfo[posIndex].ticket = positionInfo[posIndex].openingOrderTicket;

                  //- Determine if the position was initiated by a pending order or direct market entry
                  switch(orderInfo[k].type)
                    {
                     //- Pending order entry
                     case ORDER_TYPE_BUY_LIMIT:
                     case ORDER_TYPE_BUY_STOP:
                     case ORDER_TYPE_SELL_LIMIT:
                     case ORDER_TYPE_SELL_STOP:
                     case ORDER_TYPE_BUY_STOP_LIMIT:
                     case ORDER_TYPE_SELL_STOP_LIMIT:
                        positionInfo[posIndex].initiatedByPendingOrder = true;
                        positionInfo[posIndex].initiatingOrderType = orderInfo[k].type;
                        break;

                     //- Direct market entry
                     default:
                        positionInfo[posIndex].initiatedByPendingOrder = false;
                        positionInfo[posIndex].initiatingOrderType = orderInfo[k].type;
                        break;
                    }

                  break; //--- We have everything we need, exit the orderInfo loop
                 }
              }
           }
        }
      else //--- Position id not found
        {
         continue;//- skip to the next iteration
        }
     }
//- Resize the positionInfo array and delete all the indexes that have zero values
   ArrayResize(positionInfo, totalPositionsFound);
  }

//+-------------------------------------------------------------------------------------+
//| PrintPositionsHistory(): Prints the position history data for the specified period  |
//+-------------------------------------------------------------------------------------+
void PrintPositionsHistory(datetime fromDateTime, datetime toDateTime) export
  {
//- Get and save the deals, orders, positions history for the specified period
   GetHistoryData(fromDateTime, toDateTime, GET_POSITIONS_HISTORY_DATA);
   int totalPositionsClosed = ArraySize(positionInfo);
   if(totalPositionsClosed <= 0)
     {
      Print("");
      Print(__FUNCTION__, ": No position history found for the specified period.");
      return; //- Exit the function
     }

   Print("");
   Print(__FUNCTION__, "-------------------------------------------------------------------------------");
   Print(
      "Found a total of ", totalPositionsClosed,
      " positions closed between (", fromDateTime, ") and (", toDateTime, ")."
   );

   for(int r = 0; r < totalPositionsClosed; r++)
     {
      Print("---------------------------------------------------------------------------------------------------");
      Print("Position #", (r + 1));
      Print("Symbol: ", positionInfo[r].symbol);
      Print("Time Open: ", positionInfo[r].openTime);
      Print("Ticket: ", positionInfo[r].ticket);
      Print("Type: ", EnumToString(positionInfo[r].type));
      Print("Volume: ", positionInfo[r].volume);
      Print("0pen Price: ", positionInfo[r].openPrice);
      Print("SL Price: ", positionInfo[r].slPrice, " (slPips: ", positionInfo[r].slPips, ")");
      Print("TP Price: ", positionInfo[r].tpPrice, " (tpPips: ", positionInfo[r].tpPips, ")");
      Print("Close Price: ", positionInfo[r].closePrice);
      Print("Close Time: ", positionInfo[r].closeTime);
      Print("Trade Duration: ", positionInfo[r].duration);
      Print("Swap: ", positionInfo[r].swap, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Commission: ", positionInfo[r].commission, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Profit: ", positionInfo[r].profit, " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("Net profit: ", DoubleToString(positionInfo[r].netProfit, 2), " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("pipProfit: ", positionInfo[r].pipProfit);
      Print("Initiating Order Type: ", EnumToString(positionInfo[r].initiatingOrderType));
      Print("Initiated By Pending Order: ", positionInfo[r].initiatedByPendingOrder);
      Print("Comment: ", positionInfo[r].comment);
      Print("Magic: ", positionInfo[r].magic);
      Print("");
     }
  }

//+---------------------------------------------------------------------------------+
//| SavePendingOrdersData(): Queries the data saved in the deals and orders history |
//| data structures array to generate and save the pending order history data.      |
//+---------------------------------------------------------------------------------+
void SavePendingOrdersData()
  {
//- Let us begin by scanning the orders and link them to different deals
   int totalOrderInfo = ArraySize(orderInfo);
   ArrayResize(pendingOrderInfo, totalOrderInfo);
   int totalPendingOrdersFound = 0, pendingIndex = 0;
   if(totalOrderInfo == 0)
     {
      return; //- No order data to process found, we can't go on. exit the function
     }

   for(int x = totalOrderInfo - 1; x >= 0; x--)
     {
      //- Check if it is a pending order and save its properties
      if(
         orderInfo[x].type == ORDER_TYPE_BUY_LIMIT || orderInfo[x].type == ORDER_TYPE_BUY_STOP ||
         orderInfo[x].type == ORDER_TYPE_SELL_LIMIT || orderInfo[x].type == ORDER_TYPE_SELL_STOP ||
         orderInfo[x].type == ORDER_TYPE_BUY_STOP_LIMIT || orderInfo[x].type == ORDER_TYPE_SELL_STOP_LIMIT
      )
        {
         totalPendingOrdersFound++;
         pendingIndex = totalPendingOrdersFound - 1;

         pendingOrderInfo[pendingIndex].type = orderInfo[x].type;
         pendingOrderInfo[pendingIndex].state = orderInfo[x].state;
         pendingOrderInfo[pendingIndex].positionId = orderInfo[x].positionId;
         pendingOrderInfo[pendingIndex].ticket = orderInfo[x].ticket;
         pendingOrderInfo[pendingIndex].symbol = orderInfo[x].symbol;
         pendingOrderInfo[pendingIndex].timeSetup = orderInfo[x].timeSetup;
         pendingOrderInfo[pendingIndex].expirationTime = orderInfo[x].expirationTime;
         pendingOrderInfo[pendingIndex].timeDone = orderInfo[x].timeDone;
         pendingOrderInfo[pendingIndex].typeTime = orderInfo[x].typeTime;
         pendingOrderInfo[pendingIndex].priceOpen = orderInfo[x].priceOpen;
         pendingOrderInfo[pendingIndex].tpPrice = orderInfo[x].tpPrice;
         pendingOrderInfo[pendingIndex].slPrice = orderInfo[x].slPrice;

         if(pendingOrderInfo[pendingIndex].tpPrice > 0)
           {
            double symbolPoint = SymbolInfoDouble(pendingOrderInfo[pendingIndex].symbol, SYMBOL_POINT);
            pendingOrderInfo[pendingIndex].tpPips =
               (int)MathAbs((pendingOrderInfo[pendingIndex].tpPrice - pendingOrderInfo[pendingIndex].priceOpen) / symbolPoint);
           }
         if(pendingOrderInfo[pendingIndex].slPrice > 0)
           {
            double symbolPoint = SymbolInfoDouble(pendingOrderInfo[pendingIndex].symbol, SYMBOL_POINT);
            pendingOrderInfo[pendingIndex].slPips =
               (int)MathAbs((pendingOrderInfo[pendingIndex].slPrice - pendingOrderInfo[pendingIndex].priceOpen) / symbolPoint);
           }

         pendingOrderInfo[pendingIndex].magic = orderInfo[x].magic;
         pendingOrderInfo[pendingIndex].reason = orderInfo[x].reason;
         pendingOrderInfo[pendingIndex].typeFilling = orderInfo[x].typeFilling;
         pendingOrderInfo[pendingIndex].comment = orderInfo[x].comment;
         pendingOrderInfo[pendingIndex].volumeInitial = orderInfo[x].volumeInitial;
         pendingOrderInfo[pendingIndex].priceStopLimit = orderInfo[x].priceStopLimit;

        }
     }
//--Resize the pendingOrderInfo array and delete all the indexes that have zero values
   ArrayResize(pendingOrderInfo, totalPendingOrdersFound);
  }

//+-----------------------------------------------------------------------------------------------+
//| PrintPendingOrdersHistory(): Prints the pending orders history data for the specified period  |
//+-----------------------------------------------------------------------------------------------+
void PrintPendingOrdersHistory(datetime fromDateTime, datetime toDateTime) export
  {
//- Get and save the pending orders history for the specified period
   GetHistoryData(fromDateTime, toDateTime, GET_PENDING_ORDERS_HISTORY_DATA);
   int totalPendingOrders = ArraySize(pendingOrderInfo);
   if(totalPendingOrders <= 0)
     {
      Print("");
      Print(__FUNCTION__, ": No pending orders history found for the specified period.");
      return; //- Exit the function
     }

   Print("");
   Print(__FUNCTION__, "-------------------------------------------------------------------------------");
   Print(
      "Found a total of ", totalPendingOrders,
      " pending orders filled or cancelled between (", fromDateTime, ") and (", toDateTime, ")."
   );

   for(int r = 0; r < totalPendingOrders; r++)
     {
      Print("---------------------------------------------------------------------------------------------------");
      Print("Pending Order #", (r + 1));
      Print("Symbol: ", pendingOrderInfo[r].symbol);
      Print("Time Setup: ", pendingOrderInfo[r].timeSetup);
      Print("Type: ", EnumToString(pendingOrderInfo[r].type));
      Print("Ticket: ", pendingOrderInfo[r].ticket);
      Print("State: ", EnumToString(pendingOrderInfo[r].state));
      Print("Time Done: ", pendingOrderInfo[r].timeDone);
      Print("Volume Initial: ", pendingOrderInfo[r].volumeInitial);
      Print("Price Open: ", pendingOrderInfo[r].priceOpen);
      Print("SL Price: ", pendingOrderInfo[r].slPrice, " (slPips: ", pendingOrderInfo[r].slPips, ")");
      Print("TP Price: ", pendingOrderInfo[r].tpPrice, " (slPips: ", pendingOrderInfo[r].slPips, ")");
      Print("Expiration Time: ", pendingOrderInfo[r].expirationTime);
      Print("Position ID: ", pendingOrderInfo[r].positionId);
      Print("Price Stop Limit: ", pendingOrderInfo[r].priceStopLimit);
      Print("Type Filling: ", EnumToString(pendingOrderInfo[r].typeFilling));
      Print("Type Time: ", EnumToString(pendingOrderInfo[r].typeTime));
      Print("Reason: ", EnumToString(pendingOrderInfo[r].reason));
      Print("Comment: ", pendingOrderInfo[r].comment);
      Print("Magic: ", pendingOrderInfo[r].magic);
      Print("");
     }
  }


/******************************************
END OF ARTICLE ONE
******************************************/

/*****************************************
START OF ARTICLE TWO
********************
*/
//+-------------------------------------------------------------------------------------+
//| GetTotalDataInfoSize(): Gets and saves the specified history data structure dynamic |
//| array size, works together with the FetchHistoryByCriteria() function.              |
//+-------------------------------------------------------------------------------------+
int GetTotalDataInfoSize(uint dataToGet)
  {
   int totalDataInfo = 0; //- Saves the total elements of the specified history found
   switch(dataToGet)
     {
      case GET_DEALS_HISTORY_DATA: //- Check if we have any available deals history data
         totalDataInfo = ArraySize(dealInfo); //- Save the total deals found
         break;

      case GET_ORDERS_HISTORY_DATA: //- Check if we have any available orders history data
         totalDataInfo = ArraySize(orderInfo); //- Save the total orders found
         break;

      case GET_POSITIONS_HISTORY_DATA: //- Check if we have any available positions history data
         totalDataInfo = ArraySize(positionInfo); //- Save the total positions found
         break;

      case GET_PENDING_ORDERS_HISTORY_DATA: //- Check if we have any available pending orders history data
         totalDataInfo = ArraySize(pendingOrderInfo); //- Save the total pending orders found
         break;

      default: //-- Unknown entry
         totalDataInfo = 0;
         break;
     }
   return(totalDataInfo);
  }
//+--------------------------------------------------------------------------------------+
//| FetchHistoryByCriteria(): Fetches the available history data systematically starting |
//| from one day, one week and continues untill it finds the specified history data.     |
//+--------------------------------------------------------------------------------------+
bool FetchHistoryByCriteria(uint dataToGet)
  {
   int interval = 1; //- Modulates the history period

//- Save the history period for the last 24 hours
   datetime fromDateTime = TimeCurrent() - 1 * (PeriodSeconds(PERIOD_D1) * interval);
   datetime toDateTime = TimeCurrent();

//- Get the specified history
   GetHistoryData(fromDateTime, toDateTime, dataToGet);

//- If we have no history in the last 24 hours we need to keep increasing the retrieval
//- period by one week untill we scan a full year (53 weeks)
   while(GetTotalDataInfoSize(dataToGet) <= 0)
     {
      interval++;
      fromDateTime = TimeCurrent() - 1 * (PeriodSeconds(PERIOD_W1) * interval);
      toDateTime = TimeCurrent();
      GetHistoryData(fromDateTime, toDateTime, dataToGet);

      //- If no history is found after a one year scanning period, we exit the while loop
      if(interval > 53)
        {
         break;
        }
     }

//- If we have not found any trade history in the last year, we scan and cache the intire account history
   fromDateTime = 0; //-- 1970 (Epoch)
   toDateTime = TimeCurrent(); //-- Time now
   GetHistoryData(fromDateTime, toDateTime, dataToGet);

//- If we still havent retrieved any history in the account, we log this info by
//- printing it and exit the function by returning false
   if(GetTotalDataInfoSize(dataToGet) <= 0)
     {
      return(false); //- Specified history not found, exit and return false
     }
   else
     {
      return(true); //- Specified history found, exit and return true
     }
  }

//***********************************************************************************
//-- CLOSED POSITIONS HISTORY PROCESSING

//+-------------------------------------------------------------------------+
//| GetLastClosedPositionData(): Gets the last closed positions properties  |
//| and saves it in the referenced lastClosedPositions data structure.      |
//+-------------------------------------------------------------------------+
bool GetLastClosedPositionData(PositionData &lastClosedPositionInfo) export
  {
   if(!FetchHistoryByCriteria(GET_POSITIONS_HISTORY_DATA))
     {
      Print(__FUNCTION__, ": No trading history available. Last closed position can't be retrieved.");
      return(false);
     }

//-- Save the last closed position data in the referenced lastClosedPositionInfo variable
   lastClosedPositionInfo = positionInfo[0];
   return(true);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionType(): Gets the last closed position's type and saves |
//| it in the referenced lastClosedPositionType variable.                    |
//+--------------------------------------------------------------------------+
bool LastClosedPositionType(ENUM_POSITION_TYPE &lastClosedPositionType) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionType = lastClosedPositionInfo.type;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionVolume(): Gets the last closed position's volume and   |
//| saves it in the referenced lastClosedPositionVolume variable.            |
//+--------------------------------------------------------------------------+
bool LastClosedPositionVolume(double &lastClosedPositionVolume) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionVolume = lastClosedPositionInfo.volume;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionSymbol(): Gets the last closed position's symbol and   |
//| saves it in the referenced lastClosedPositionSymbol variable.            |
//+--------------------------------------------------------------------------+
bool LastClosedPositionSymbol(string &lastClosedPositionSymbol) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionSymbol = lastClosedPositionInfo.symbol;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionTicket(): Gets the last closed position's ticket and   |
//| saves it in the referenced lastClosedPositionTicket variable.            |
//+--------------------------------------------------------------------------+
bool LastClosedPositionTicket(ulong &lastClosedPositionTicket) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionTicket = lastClosedPositionInfo.ticket;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionProfit(): Gets the last closed position's profit and   |
//| saves it in the referenced lastClosedPositionProfit variable.            |
//+--------------------------------------------------------------------------+
bool LastClosedPositionProfit(double &lastClosedPositionProfit) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionProfit = lastClosedPositionInfo.profit;
      return(true);
     }
   return(false);
  }

//+---------------------------------------------------------------------------------+
//| LastClosedPositionNetProfit(): Gets the last closed position's net profit and   |
//| saves it in the referenced lastClosedPositionNetProfit variable.                |
//+---------------------------------------------------------------------------------+
bool LastClosedPositionNetProfit(double &lastClosedPositionNetProfit) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionNetProfit = lastClosedPositionInfo.netProfit;
      return(true);
     }
   return(false);
  }

//+---------------------------------------------------------------------------------+
//| LastClosedPositionPipProfit(): Gets the last closed position's pip profit and   |
//| saves it in the referenced lastClosedPositionPipProfit variable.                |
//+---------------------------------------------------------------------------------+
bool LastClosedPositionPipProfit(int &lastClosedPositionPipProfit) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionPipProfit = lastClosedPositionInfo.pipProfit;
      return(true);
     }
   return(false);
  }

//+-----------------------------------------------------------------------------------+
//| LastClosedPositionClosePrice(): Gets the last closed position's closing price and |
//| saves it in the referenced lastClosedPositionClosePrice variable.                 |
//+-----------------------------------------------------------------------------------+
bool LastClosedPositionClosePrice(double &lastClosedPositionClosePrice) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionClosePrice = lastClosedPositionInfo.closePrice;
      return(true);
     }
   return(false);
  }

//+----------------------------------------------------------------------------------+
//| LastClosedPositionOpenPrice(): Gets the last closed position's opening price and |
//| saves it in the referenced lastClosedPositionOpenPrice variable.                 |
//+----------------------------------------------------------------------------------+
bool LastClosedPositionOpenPrice(double &lastClosedPositionOpenPrice) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionOpenPrice = lastClosedPositionInfo.openPrice;
      return(true);
     }
   return(false);
  }

//+----------------------------------------------------------------------------------+
//| LastClosedPositionSlPrice(): Gets the last closed position's stop loss price and |
//| saves it in the referenced lastClosedPositionSlPrice variable.                   |
//+----------------------------------------------------------------------------------+
bool LastClosedPositionSlPrice(double &lastClosedPositionSlPrice) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionSlPrice = lastClosedPositionInfo.slPrice;
      return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------------------------+
//| LastClosedPositionTpPrice(): Gets the last closed position's take profit price and |
//| saves it in the referenced lastClosedPositionTpPrice variable.                     |
//+------------------------------------------------------------------------------------+
bool LastClosedPositionTpPrice(double &lastClosedPositionTpPrice) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionTpPrice = lastClosedPositionInfo.tpPrice;
      return(true);
     }
   return(false);
  }

//+----------------------------------------------------------------------------------------+
//| LastClosedPositionSlPips(): Gets the last closed position's stop loss in points (pips) |
//| and saves it in the referenced lastClosedPositionSlPips variable.                      |
//+----------------------------------------------------------------------------------------+
bool LastClosedPositionSlPips(int &lastClosedPositionSlPips) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionSlPips = lastClosedPositionInfo.slPips;
      return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------------------------------+
//| LastClosedPositionTpPips(): Gets the last closed position's take profit in points (pips) |
//| and saves it in the referenced LastClosedPositionTpPips variable.                        |
//+------------------------------------------------------------------------------------------+
bool LastClosedPositionTpPips(int &lastClosedPositionTpPips) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionTpPips = lastClosedPositionInfo.tpPips;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionOpenTime(): Gets the last closed position's open time  |
//| and saves it in the referenced lastClosedPositionOpenTime variable.      |
//+--------------------------------------------------------------------------+
bool LastClosedPositionOpenTime(datetime &lastClosedPositionOpenTime) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionOpenTime = lastClosedPositionInfo.openTime;
      return(true);
     }
   return(false);
  }

//+---------------------------------------------------------------------------+
//| LastClosedPositionCloseTime(): Gets the last closed position's close time |
//| and saves it in the referenced lastClosedPositionCloseTime variable.      |
//+---------------------------------------------------------------------------+
bool LastClosedPositionCloseTime(datetime &lastClosedPositionCloseTime) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionCloseTime = lastClosedPositionInfo.closeTime;
      return(true);
     }
   return(false);
  }

//+-----------------------------------------------------------------+
//| LastClosedPositionSwap(): Gets the last closed position's swap  |
//| and saves it in the referenced lastClosedPositionSwap variable. |
//+-----------------------------------------------------------------+
bool LastClosedPositionSwap(double &lastClosedPositionSwap) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionSwap = lastClosedPositionInfo.swap;
      return(true);
     }
   return(false);
  }

//+-----------------------------------------------------------------------------+
//| LastClosedPositionCommission(): Gets the last closed position's commission  |
//| and saves it in the referenced lastClosedPositionCommission variable.       |
//+-----------------------------------------------------------------------------+
bool LastClosedPositionCommission(double &lastClosedPositionCommission) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionCommission = lastClosedPositionInfo.commission;
      return(true);
     }
   return(false);
  }

//+-------------------------------------------------------------------------------------------+
//| LastClosedPositionInitiatingOrderType(): Gets the last closed position's initiating       |
//| order type and saves it in the referenced lastClosedPositionInitiatingOrderType variable. |
//+-------------------------------------------------------------------------------------------+
bool LastClosedPositionInitiatingOrderType(ENUM_ORDER_TYPE &lastClosedPositionInitiatingOrderType) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionInitiatingOrderType = lastClosedPositionInfo.initiatingOrderType;
      return(true);
     }
   return(false);
  }

//+---------------------------------------------------------------+
//| LastClosedPositionId(): Gets the last closed position's ID    |
//| and saves it in the referenced lastClosedPositionId variable. |
//+---------------------------------------------------------------+
bool LastClosedPositionId(ulong &lastClosedPositionId) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionId = lastClosedPositionInfo.positionId;
      return(true);
     }
   return(false);
  }

//+-----------------------------------------------------------------------------------------------------+
//| LastClosedPositionInitiatedByPendingOrder(): Checks if the last closed positions was initiated from |
//| a pending order and saves it in the referenced lastClosedPositionInitiatedByPendingOrder variable.  |
//+-----------------------------------------------------------------------------------------------------+
bool LastClosedPositionInitiatedByPendingOrder(bool &lastClosedPositionInitiatedByPendingOrder) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionInitiatedByPendingOrder = lastClosedPositionInfo.initiatedByPendingOrder;
      return(true);
     }
   return(false);
  }

//+---------------------------------------------------------------------------------------------+
//| LastClosedPositionOpeningOrderTicket(): Gets the last closed position's opening order       |
//| ticket number and saves it in the referenced lastClosedPositionOpeningOrderTicket variable. |
//+---------------------------------------------------------------------------------------------+
bool LastClosedPositionOpeningOrderTicket(ulong &lastClosedPositionOpeningOrderTicket) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionOpeningOrderTicket = lastClosedPositionInfo.openingOrderTicket;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------------------------+
//| LastClosedPositionOpeningDealTicket(): Gets the last closed position's opening deal        |
//| ticket number and saves it in the referenced lastClosedPositionOpeningDealTicket variable. |
//+--------------------------------------------------------------------------------------------+
bool LastClosedPositionOpeningDealTicket(ulong &lastClosedPositionOpeningDealTicket) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionOpeningDealTicket = lastClosedPositionInfo.openingDealTicket;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------------------------+
//| LastClosedPositionClosingDealTicket(): Gets the last closed position's closing deal        |
//| ticket number and saves it in the referenced lastClosedPositionClosingDealTicket variable. |
//+--------------------------------------------------------------------------------------------+
bool LastClosedPositionClosingDealTicket(ulong &lastClosedPositionClosingDealTicket) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionClosingDealTicket = lastClosedPositionInfo.closingDealTicket;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------+
//| LastClosedPositionMagic(): Gets the last closed position's magic number  |
//| and saves it in the referenced lastClosedPositionMagic variable.         |
//+--------------------------------------------------------------------------+
bool LastClosedPositionMagic(ulong &lastClosedPositionMagic) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionMagic = lastClosedPositionInfo.magic;
      return(true);
     }
   return(false);
  }

//+-----------------------------------------------------------------------+
//| LastClosedPositionComment(): Gets the last closed position's comment  |
//| and saves it in the referenced lastClosedPositionComment variable.    |
//+-----------------------------------------------------------------------+
bool LastClosedPositionComment(string &lastClosedPositionComment) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionComment = lastClosedPositionInfo.comment;
      return(true);
     }
   return(false);
  }

//+--------------------------------------------------------------------------------+
//| LastClosedPositionDuration(): Gets the last closed position's trade duration   |
//| in seconds and saves it in the referenced lastClosedPositionDuration variable. |
//+--------------------------------------------------------------------------------+
bool LastClosedPositionDuration(long &lastClosedPositionDuration) export
  {
   PositionData lastClosedPositionInfo;
   if(GetLastClosedPositionData(lastClosedPositionInfo))
     {
      lastClosedPositionDuration = lastClosedPositionInfo.duration;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
