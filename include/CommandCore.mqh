//+------------------------------------------------------------------+
//|                                                  CommandCore.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Data.mqh>
#include <HttpLib.mqh>
#include <HistoryManager.mqh>
#include <Trade/Trade.mqh>

struct JsonResponse {
    string jsonContent;
    int status;
};


struct Order {
    string symbol;
    double volume;
    string order_type;     // "buy", "sell", "buy_limit", etc.
    double sl;
    double tp;
    double price;
    ulong magic;
    string comment;
    string type_filling;   // "IOC", "FOK", etc.
    bool async;
    datetime expiration;   // For pending orders only

    // Constructor with defaults
    void Init() {
        symbol        = "";
        volume        = 0.0;
        order_type    = "";
        sl            = 0.0;
        tp            = 0.0;
        price         = 0.0;
        magic         = 123456;
        comment       = "";
        type_filling  = "";       // Will map this string later to ENUM_ORDER_TYPE_FILLING
        async         = false;
        expiration    = 0;        // 0 means no expiration
    }
};


//+------------------------------------------------------------------+
//| CCommandCore Class Declaration                                   |
//+------------------------------------------------------------------+
class CCommandCore {
private:
    CData *dataSender;
    
    JsonResponse SendError(int status, string details = "");
    JsonResponse SendJson(string jsonContent, int status = 200);
public:
    // Constructor
    CCommandCore(CData *ps = NULL) {
        dataSender = ps;
    }


    JsonResponse SetSymbols(string &symbols[]);
    JsonResponse SetOhlcRequests(OhlcRequest &symbols[]);
    JsonResponse GetQuote(string symbol);
    JsonResponse RetriveHistoricalData(string symbol, string timeFrame, string from_date_str, string to_date_str);
    JsonResponse GetHistoryByMode(string mode, string from_date_str, string to_date_str);
    JsonResponse GetOrderList();
    JsonResponse PlaceOrder(Order &order);
    JsonResponse CloseOrder(ulong ticket, double volume, bool async);
    JsonResponse GetAccountInformation();
    JsonResponse GetSymbolInfo(string symbol);
    JsonResponse GetSymbolList();
    JsonResponse OrderInformation(ulong ticket);
    
    
};



//+------------------------------------------------------------------+
//| Commands logic                                                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Place Order Command                                              |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::PlaceOrder(Order &order) {
    CTrade trade;

    // Set pre-trade configs
    trade.SetExpertMagicNumber(order.magic);
    trade.SetAsyncMode(order.async);

    // Set filling type if provided
    if (order.type_filling != "") {
        ENUM_ORDER_TYPE_FILLING filling = parseFillingType(order.type_filling);
        if(filling == (ENUM_ORDER_TYPE_FILLING)-1){
            return SendError(400, "invalid Order Type Filling");
        }
        trade.SetTypeFilling(filling);
    }

    bool result = false;
    double price = 0;
    bool is_pending = false;

    // Market orders have no price
    if (order.order_type == "buy" || order.order_type == "sell") {
        price = SymbolInfoDouble(order.symbol ,SYMBOL_ASK);
        Print("price:"+ price);
    } else {
        // Pending orders require valid   price
        if (order.price <= 0) {
            return SendError(400, "Price is required for pending orders");
        }
        price = order.price;
        is_pending = true;
    }
    

    // Determine time type (pending order expiration handling)
    ENUM_ORDER_TYPE_TIME time_type_enum = ORDER_TIME_GTC;
    if (order.expiration > 0) {
        time_type_enum = ORDER_TIME_SPECIFIED;
    }

    // Place order based on type
    if (order.order_type == "buy") {
        result = trade.PositionOpen(order.symbol, ORDER_TYPE_BUY, order.volume, price, order.sl, order.tp, order.comment);
    } else if (order.order_type == "sell") {
        result = trade.PositionOpen(order.symbol, ORDER_TYPE_SELL, order.volume, price, order.sl, order.tp, order.comment);
    } else if (order.order_type == "buy_limit") {
        result = trade.BuyLimit(order.volume, price, order.symbol, order.sl, order.tp, time_type_enum, order.expiration, order.comment);
    } else if (order.order_type == "buy_stop") {
        result = trade.BuyStop(order.volume, order.symbol, price, order.sl, order.tp, time_type_enum, order.expiration, order.comment);
    } else if (order.order_type == "sell_limit") {
        result = trade.SellLimit(order.volume, order.symbol, price, order.sl, order.tp, time_type_enum, order.expiration, order.comment);
    } else {
        result = trade.SellStop(order.volume, order.symbol, price, order.sl, order.tp, time_type_enum, order.expiration, order.comment);
    }

    // Handle result
    if (result) {
        ulong ticket = trade.RequestOrder();

        string json = StringFormat(
             "\"message\":\"Order placed successfully\", \"order_ticket\":%d",
             ticket
         );

        return SendJson(json);
    } else {
        Print("Order placement failed: ", trade.ResultRetcodeDescription());
        return SendError(500, trade.ResultRetcodeDescription());
    }
}


//+------------------------------------------------------------------+
//| Close Order Command                                              |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::CloseOrder(ulong ticket, double volume, bool async) {
    if (!PositionSelectByTicket(ticket)) {
        return SendError(404, "Position not found for ticket: " + (string)ticket);
    }

    string symbol = PositionGetString(POSITION_SYMBOL);
    double positionVolume = PositionGetDouble(POSITION_VOLUME);

    if (positionVolume <= 0.0) {
        return SendError(400, "Position has no remaining volume to close");
    }

    if (volume <= 0.0 || volume > positionVolume) {
        volume = positionVolume;
    }

    CTrade trade;
    trade.SetAsyncMode(async);

    bool result = trade.PositionClosePartial(ticket, volume);

    if (!result) {
        return SendError(500, "Failed to close position: " + trade.ResultRetcodeDescription());
    }

    if (async) {
        return SendJson("\"message\":\"close order submitted\"");
    }

    int retcode = trade.ResultRetcode();
    if (retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_DONE_PARTIAL) {
        // Extract result data
        ulong order_ticket = trade.ResultOrder();
        ulong deal         = trade.ResultDeal();
        double price       = trade.ResultPrice();
        double bid         = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask         = SymbolInfoDouble(symbol, SYMBOL_ASK);

        string type = (volume == positionVolume) ? "fully_closed" : "partial_closed";

        string json = StringFormat(
            "\"message\":\"order closed successfully\"," \
            "\"ticket\":%d," \
            "\"type\":\"%s\"," \
            "\"deal\":%d," \
            "\"order\":%d," \
            "\"volume\":%.2f," \
            "\"price\":%.5f," \
            "\"bid\":%.5f," \
            "\"ask\":%.5f" \,
            ticket,
            type,
            deal,
            order_ticket,
            volume,
            price,
            bid,
            ask
        );

        return SendJson(json);
    } else {
        return SendError(500, "Close failed: " + trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Get order info                                                   |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::OrderInformation(ulong ticket) {
    if (!PositionSelectByTicket(ticket)) {
        return SendError(404, "Position not found: " + (string)ticket);
    }

    string symbol = PositionGetString(POSITION_SYMBOL);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double price_open = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl = PositionGetDouble(POSITION_SL);
    double tp = PositionGetDouble(POSITION_TP);
    double price_current = SymbolInfoDouble(symbol, SYMBOL_BID);
    double swap = PositionGetDouble(POSITION_SWAP);
    double profit = PositionGetDouble(POSITION_PROFIT);
    datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
    datetime time_update = (datetime)PositionGetInteger(POSITION_TIME_UPDATE);
    long magic = PositionGetInteger(POSITION_MAGIC);
    string comment = PositionGetString(POSITION_COMMENT);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    long reason = PositionGetInteger(POSITION_REASON);

    double change = price_current - price_open;

    string json = StringFormat(
        "\"ticket\":%I64d,"
        "\"open_time\":\"%s\","
        "\"time_update\":\"%s\","
        "\"type\":\"%s\","
        "\"magic\":%d,"
        "\"identifier\":%I64d,"
        "\"reason\":%d,"
        "\"volume\":%.2f,"
        "\"price_open\":%.5f,"
        "\"sl\":%.5f,"
        "\"tp\":%.5f,"
        "\"price_current\":%.5f,"
        "\"swap\":%.2f,"
        "\"profit\":%.2f,"
        "\"symbol\":\"%s\","
        "\"external_id\":null,"
        "\"comment\":%s,"
        "\"change\":%.2f",
        ticket,
        ToIso8601(open_time),
        ToIso8601(time_update),
        EnumToString(type),
        magic,
        ticket,
        reason,
        volume,
        price_open,
        sl,
        tp,
        price_current,
        swap,
        profit,
        symbol,
        comment == "" ? "null" : "\"" + comment + "\"",
        change
    );

    return SendJson(json);
}

//+------------------------------------------------------------------+
//| Get order list                                                   |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::GetOrderList() {
    string openedJson = "";
    string pendingJson = "";

    // ----------- Opened Positions -----------
    int totalPositions = PositionsTotal();

    for (int i = 0; i < totalPositions; i++) {
        if (!PositionGetTicket(i)) continue;

        ulong ticket = PositionGetInteger(POSITION_TICKET);
        string symbol = PositionGetString(POSITION_SYMBOL);
        datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
        datetime time_update = (datetime)PositionGetInteger(POSITION_TIME_UPDATE);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        long magic = PositionGetInteger(POSITION_MAGIC);
        double volume = PositionGetDouble(POSITION_VOLUME);
        double price_open = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double price_current = SymbolInfoDouble(symbol, SYMBOL_BID);
        double profit = PositionGetDouble(POSITION_PROFIT);
        double swap = PositionGetDouble(POSITION_SWAP);
        string comment = PositionGetString(POSITION_COMMENT);
        long reason = PositionGetInteger(POSITION_REASON);
        double change = price_current - price_open;

        string entry = StringFormat(
            "{"
            "\"ticket\":%I64d,"
            "\"open_time\":\"%s\","
            "\"time_update\":\"%s\","
            "\"type\":\"%s\","
            "\"magic\":%d,"
            "\"identifier\":%I64d,"
            "\"reason\":%d,"
            "\"volume\":%.2f,"
            "\"price_open\":%.5f,"
            "\"sl\":%.5f,"
            "\"tp\":%.5f,"
            "\"price_current\":%.5f,"
            "\"swap\":%.2f,"
            "\"profit\":%.2f,"
            "\"symbol\":\"%s\","
            "\"comment\":%s,"
            "\"external_id\":null,"
            "\"change\":%.2f"
            "}",
            ticket,
            TimeToString(open_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            TimeToString(time_update, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            EnumToString(type),
            magic,
            ticket,
            reason,
            volume,
            price_open,
            sl,
            tp,
            price_current,
            swap,
            profit,
            symbol,
            comment == "" ? "null" : "\"" + comment + "\"",
            change
        );

        openedJson += (openedJson == "" ? "" : ",") + entry;
    }

    // ----------- Pending Orders -----------
    int totalOrders = OrdersTotal();

    for (int i = 0; i < totalOrders; i++) {
        ulong ticket = OrderGetTicket(i);
        if (!OrderSelect(ticket)) {
            Print("Failed to select order #", ticket);
            continue;
        }

        ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
        bool isPending =
            orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT ||
            orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP ||
            orderType == ORDER_TYPE_BUY_STOP_LIMIT || orderType == ORDER_TYPE_SELL_STOP_LIMIT;

        if (!isPending) continue;

        string symbol = OrderGetString(ORDER_SYMBOL);
        datetime open_time = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
        datetime time_update = (datetime)OrderGetInteger(ORDER_TIME_SETUP); //TODO: for now using this fix later
        long magic = OrderGetInteger(ORDER_MAGIC);
        double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
        double price_open = OrderGetDouble(ORDER_PRICE_OPEN);
        double sl = OrderGetDouble(ORDER_SL);
        double tp = OrderGetDouble(ORDER_TP);
        double price_current = SymbolInfoDouble(symbol, SYMBOL_BID);
        //double profit ; pending orders dont have profit ig
        string comment = OrderGetString(ORDER_COMMENT);
        long reason = OrderGetInteger(ORDER_REASON);
        double change = price_current - price_open;
        datetime time_done = (datetime)OrderGetInteger(ORDER_TIME_DONE);
        double price_stoplimit = OrderGetDouble(ORDER_PRICE_STOPLIMIT);
        long pos_id = OrderGetInteger(ORDER_POSITION_ID);
        long pos_byid = OrderGetInteger(ORDER_POSITION_BY_ID);
        double vol_initial = OrderGetDouble(ORDER_VOLUME_INITIAL);
        double vol_current = OrderGetDouble(ORDER_VOLUME_CURRENT);

        string entry = StringFormat(
            "{"
            "\"ticket\":%I64d,"
            "\"open_time\":\"%s\","
            "\"time_update\":\"%s\","
            "\"type\":\"%s\","
            "\"magic\":%d,"
            "\"identifier\":%I64d,"
            "\"reason\":%d,"
            "\"volume\":%.2f,"
            "\"price_open\":%.5f,"
            "\"sl\":%.5f,"
            "\"tp\":%.5f,"
            "\"price_current\":%.5f,"
            "\"symbol\":\"%s\","
            "\"comment\":%s,"
            "\"external_id\":null,"
            "\"change\":%.2f,"
            "\"time_done\":\"%s\","
            "\"time_setup\":\"%s\","
            "\"order_reason\":%d,"
            "\"position_id\":%I64d,"
            "\"position_byid\":%I64d,"
            "\"volume_initial\":%.2f,"
            "\"volume_current\":%.2f,"
            "\"price_stoplimit\":%.5f"
            "}",
            ticket,
            TimeToString(open_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            TimeToString(time_update, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            EnumToString(orderType),
            magic,
            ticket,
            reason,
            volume,
            price_open,
            sl,
            tp,
            price_current,
            symbol,
            comment == "" ? "null" : "\"" + comment + "\"",
            change,
            TimeToString(time_done, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            TimeToString(open_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
            reason,
            pos_id,
            pos_byid,
            vol_initial,
            vol_current,
            price_stoplimit
        );

        pendingJson += (pendingJson == "" ? "" : ",") + entry;
    }


    string finalJson = StringFormat(
        "\"msg\":\"order_list\","
        "\"count\":%d,"
        "\"opened\":[%s],"
        "\"pending\":[%s],",
        totalPositions + OrdersTotal(),
        openedJson,
        pendingJson
    );

    return SendJson(finalJson);
}



//+------------------------------------------------------------------+
//| Retrieve historical data Command                                 |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::RetriveHistoricalData(string symbol, string timeFrame, string from_date_str, string to_date_str)
{
    if(!SymbolSelect(symbol, true)) {
        return SendError(400, "Symbol not found: '" + symbol +"'");
    }

    // Convert ISO8601 strings to datetime
    StringReplace(from_date_str, "T", " ");
    StringReplace(to_date_str, "T", " ");

    datetime from_date = StringToTime(from_date_str);
    datetime to_date   = StringToTime(to_date_str);

    ENUM_TIMEFRAMES tf = getTimeFrameEnum(timeFrame);
    MqlRates rates[];
    int bars = CopyRates(symbol, tf, from_date, to_date, rates);
    if(bars <= 0) {
        return SendError(500, "Failed to retrieve data for " + symbol);
    }

    string norm_from = TimeToString(from_date, TIME_DATE | TIME_SECONDS);
    string norm_to   = TimeToString(to_date, TIME_DATE | TIME_SECONDS);
    StringReplace(norm_from, ".", "-");
    StringReplace(norm_from, " ", "T");
    StringReplace(norm_to, ".", "-");
    StringReplace(norm_to, " ", "T");

 
    string jsonData = "[";
    for(int i = 0; i < bars; i++) {
        string t = TimeToString(rates[i].time, TIME_DATE | TIME_SECONDS);
        StringReplace(t, ".", "-");
        StringReplace(t, " ", "T");

        jsonData += "{";
        jsonData += "\"time\":\"" + t + "\",";
        jsonData += "\"open\":" + DoubleToString(rates[i].open, 5) + ",";
        jsonData += "\"high\":" + DoubleToString(rates[i].high, 5) + ",";
        jsonData += "\"low\":"  + DoubleToString(rates[i].low, 5) + ",";
        jsonData += "\"close\":" + DoubleToString(rates[i].close, 5) + ",";
        jsonData += "\"volume\":" + IntegerToString(rates[i].tick_volume);
        jsonData += "}";
        if(i < bars - 1)
            jsonData += ",";
    }
    jsonData += "]";

 
    string jsonStr = "\"from_date\":\"" + norm_from + "\",";
    jsonStr += "\"to_date\":\"" + norm_to + "\",";
    jsonStr += "\"data\":" + jsonData;

    return SendJson(jsonStr);
}

//+------------------------------------------------------------------+
//| Get Account Command                                              |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::GetAccountInformation() {
    string json = StringFormat(
        "\"company\":\"%s\","
        "\"currency\":\"%s\","
        "\"name\":\"%s\","
        "\"server\":\"%s\","
        "\"login\":%I64d,"
        "\"trade_mode\":%d,"
        "\"leverage\":%d,"
        "\"limit_orders\":%d,"
        "\"margin_so_mode\":%d,"
        "\"trade_allowed\":%d,"
        "\"trade_expert\":%d,"
        "\"margin_mode\":%d,"
        "\"currency_digits\":%d,"
        "\"fifo_close\":%d,"
        "\"hedge_allowed\":%d,"
        "\"balance\":%.2f,"
        "\"credit\":%.2f,"
        "\"profit\":%.2f,"
        "\"equity\":%.2f,"
        "\"margin\":%.2f,"
        "\"margin_free\":%.2f,"
        "\"margin_level\":%.2f,"
        "\"margin_so_cal\":%.2f,"
        "\"margin_so_so\":%.2f"
        ,
        AccountInfoString(ACCOUNT_COMPANY),
        AccountInfoString(ACCOUNT_CURRENCY),
        AccountInfoString(ACCOUNT_NAME),
        AccountInfoString(ACCOUNT_SERVER),
        AccountInfoInteger(ACCOUNT_LOGIN),
        (int)AccountInfoInteger(ACCOUNT_TRADE_MODE),
        (int)AccountInfoInteger(ACCOUNT_LEVERAGE),
        (int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS),
        (int)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE),
        (int)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED),
        (int)AccountInfoInteger(ACCOUNT_TRADE_EXPERT),
        (int)AccountInfoInteger(ACCOUNT_MARGIN_MODE),
        (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS),
        (int)AccountInfoInteger(ACCOUNT_FIFO_CLOSE),
        (int)AccountInfoInteger(ACCOUNT_HEDGE_ALLOWED),
        AccountInfoDouble(ACCOUNT_BALANCE),
        AccountInfoDouble(ACCOUNT_CREDIT),
        AccountInfoDouble(ACCOUNT_PROFIT),
        AccountInfoDouble(ACCOUNT_EQUITY),
        AccountInfoDouble(ACCOUNT_MARGIN),
        AccountInfoDouble(ACCOUNT_MARGIN_FREE),
        AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),
        AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL),
        AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)
    );

    return SendJson(json);
}


//+------------------------------------------------------------------+
//| get History positions / orders / deal                            |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::GetHistoryByMode(string mode, string from_date_str, string to_date_str)
{
    // Convert ISO8601 to datetime
    StringReplace(from_date_str, "T", " ");
    StringReplace(to_date_str, "T", " ");
    
    datetime from_date = StringToTime(from_date_str);
    datetime to_date   = StringToTime(to_date_str);

    // Clear/reset arrays
    ArrayResize(dealInfo, 0);
    ArrayResize(orderInfo, 0);
    ArrayResize(positionInfo, 0);

    uint dataFlag = 0;
    if (mode == "deals")
        dataFlag = GET_DEALS_HISTORY_DATA;
    else if (mode == "orders")
        dataFlag = GET_ORDERS_HISTORY_DATA;
    else if (mode == "positions")
        dataFlag = GET_POSITIONS_HISTORY_DATA;
    else {
        return SendError(400, "Invalid mode: '" + mode + "'");
    }

    if (!GetHistoryData(from_date, to_date, dataFlag)) {
        return SendError(500, "Failed to retrieve history data");
    }

    string jsonData = "\"data\":[";
    string rows = "";

    if (mode == "deals") {
        for (int i = 0; i < ArraySize(dealInfo); i++) {
            string row = StringFormat(
                "{"
                "\"symbol\":\"%s\","
                "\"time\":%d,"
                "\"ticket\":%d,"
                "\"position_id\":%d,"
                "\"order_ticket\":%d,"
                "\"type\":\"%s\","
                "\"entry\":\"%s\","
                "\"reason\":\"%s\","
                "\"volume\":%.2f,"
                "\"price\":%.5f,"
                "\"sl_price\":%.5f,"
                "\"tp_price\":%.5f,"
                "\"swap\":%.2f,"
                "\"commission\":%.2f,"
                "\"profit\":%.2f,"
                "\"comment\":\"%s\","
                "\"magic\":%d"
                "}",
                dealInfo[i].symbol,
                dealInfo[i].time,
                dealInfo[i].ticket,
                dealInfo[i].positionId,
                dealInfo[i].order,
                EnumToString(dealInfo[i].type),
                EnumToString(dealInfo[i].entry),
                EnumToString(dealInfo[i].reason),
                dealInfo[i].volume,
                dealInfo[i].price,
                dealInfo[i].slPrice,
                dealInfo[i].tpPrice,
                dealInfo[i].swap,
                dealInfo[i].commission,
                dealInfo[i].profit,
                dealInfo[i].comment,
                dealInfo[i].magic
            );
            rows += row + (i < ArraySize(dealInfo) - 1 ? "," : "");
        }
    }
    else if (mode == "orders") {
        for (int i = 0; i < ArraySize(orderInfo); i++) {
            string row = StringFormat(
                "{"
                "\"ticket\":%d,"
                "\"symbol\":\"%s\","
                "\"time_setup\":%d,"
                "\"type\":\"%s\","
                "\"position_id\":%d,"
                "\"state\":\"%s\","
                "\"type_filling\":\"%s\","
                "\"type_time\":\"%s\","
                "\"reason\":\"%s\","
                "\"volume_initial\":%.2f,"
                "\"price_open\":%.5f,"
                "\"price_stop_limit\":%.5f,"
                "\"sl_price\":%.5f,"
                "\"tp_price\":%.5f,"
                "\"time_done\":%d,"
                "\"expiration_time\":%d,"
                "\"comment\":\"%s\","
                "\"magic\":%d"
                "}",
                orderInfo[i].ticket,
                orderInfo[i].symbol,
                orderInfo[i].timeSetup,
                EnumToString(orderInfo[i].type),
                orderInfo[i].positionId,
                EnumToString(orderInfo[i].state),
                EnumToString(orderInfo[i].typeFilling),
                EnumToString(orderInfo[i].typeTime),
                EnumToString(orderInfo[i].reason),
                orderInfo[i].volumeInitial,
                orderInfo[i].priceOpen,
                orderInfo[i].priceStopLimit,
                orderInfo[i].slPrice,
                orderInfo[i].tpPrice,
                orderInfo[i].timeDone,
                orderInfo[i].expirationTime,
                orderInfo[i].comment,
                orderInfo[i].magic
            );
            rows += row + (i < ArraySize(orderInfo) - 1 ? "," : "");
        }
    }
    else if (mode == "positions") {
        for (int i = 0; i < ArraySize(positionInfo); i++) {
            string row = StringFormat(
                "{"
                "\"symbol\":\"%s\","
                "\"open_time\":%d,"
                "\"ticket\":%d,"
                "\"type\":\"%s\","
                "\"volume\":%.2f,"
                "\"open_price\":%.5f,"
                "\"sl_price\":%.5f,"
                "\"sl_pips\":%.1f,"
                "\"tp_price\":%.5f,"
                "\"tp_pips\":%.1f,"
                "\"close_price\":%.5f,"
                "\"close_time\":%d,"
                "\"duration\":%d,"
                "\"swap\":%.2f,"
                "\"commission\":%.2f,"
                "\"profit\":%.2f,"
                "\"net_profit\":%.2f,"
                "\"pip_profit\":%.1f,"
                "\"initiating_order_type\":\"%s\","
                "\"initiated_by_pending_order\":%s,"
                "\"comment\":\"%s\","
                "\"magic\":%d"
                "}",
                positionInfo[i].symbol,
                positionInfo[i].openTime,
                positionInfo[i].ticket,
                EnumToString(positionInfo[i].type),
                positionInfo[i].volume,
                positionInfo[i].openPrice,
                positionInfo[i].slPrice,
                positionInfo[i].slPips,
                positionInfo[i].tpPrice,
                positionInfo[i].tpPips,
                positionInfo[i].closePrice,
                positionInfo[i].closeTime,
                positionInfo[i].duration,
                positionInfo[i].swap,
                positionInfo[i].commission,
                positionInfo[i].profit,
                positionInfo[i].netProfit,
                positionInfo[i].pipProfit,
                EnumToString(positionInfo[i].initiatingOrderType),
                positionInfo[i].initiatedByPendingOrder ? "true" : "false",
                positionInfo[i].comment,
                positionInfo[i].magic
            );
            rows += row + (i < ArraySize(positionInfo) - 1 ? "," : "");
        }
    }

    jsonData += rows + "]";
    return SendJson(jsonData);
}


//+------------------------------------------------------------------+
//| Get symbol quote                                                 |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::GetQuote(string symbol){
   if(!SymbolSelect(symbol, true)) {
      return SendError(404, "Symbol not found : '" + symbol + "'");
   }
   
   MqlTick tick;
   if(!SymbolInfoTick(symbol, tick)) {
      return SendError(500, "Failed to get tick for: '" + symbol + "'");
   }
   
   datetime time = tick.time_msc / 1000;
   int ms        = (int)(tick.time_msc % 1000);

   // Format ISO 8601 datetime string: "YYYY-MM-DDTHH:MM:SS.mmmZ"
   string isoTime = StringFormat(
      "%sT%s.%03dZ",
      TimeToString(time, TIME_DATE),       // "2025-06-20"
      TimeToString(time, TIME_MINUTES | TIME_SECONDS), // "23:58:55"
      ms
   );
   
   string json = "";
   json += "\"symbol\": \"" + symbol + "\",";
   json += "\"ask\": " + DoubleToString(tick.ask, _Digits) + ",";
   json += "\"bid\": " + DoubleToString(tick.bid, _Digits) + ",";
   json += "\"flags\": " + IntegerToString((int)tick.flags) + ",";
   json += "\"time\": \"" + isoTime + "\",";
   json += "\"volume\": " + IntegerToString((long)tick.volume);
   
   return SendJson(json);
}

//+------------------------------------------------------------------+
//| Get symbol info and List                                         |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::GetSymbolList() {
   int total = SymbolsTotal(false);
   string json = "\"symbols\": [";
   bool first = true;
   Print("total symobls : " + IntegerToString(total));

   for(int i = 0; i < total; i++) {
      string symbol = SymbolName(i, false);

      int trade_mode = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
      string description = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
      string path = SymbolInfoString(symbol, SYMBOL_PATH);

      if(!first) json += ",";
      first = false;

      json += "{";
      json += "\"name\": \"" + symbol + "\",";
      json += "\"trade_mode\": " + IntegerToString(trade_mode) + ",";
      json += "\"description\": \"" + description + "\",";
      json += "\"path\": \"" + path + "\"";
      json += "}";
   }

   json += "]";

   return SendJson(json);
}

//symbol INFO
JsonResponse CCommandCore::GetSymbolInfo(string symbol) {
   if(!SymbolSelect(symbol, true)) {
      return SendError(404, "symbol not found: '" + symbol + "'");
   }

   datetime now = TimeCurrent();
   string timeStr = TimeToString(now, TIME_DATE | TIME_SECONDS);

   // Basic symbol info
   int digits                = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   double spread_float = (ask - bid) / point;  // spread in points (ticks)

   int spread                = (int)MathRound(spread_float * MathPow(10, digits));
   int trade_calc_mode       = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE);
   int trade_mode            = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   ulong start_time          = (ulong)SymbolInfoInteger(symbol, SYMBOL_START_TIME);
   ulong expiration_time     = (ulong)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
   int trade_stops_level     = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int trade_freeze_level    = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   int trade_exemode         = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE);
   int swap_mode             = (int)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE);
   int swap_rollover_3days   = (int)SymbolInfoInteger(symbol, SYMBOL_SWAP_ROLLOVER3DAYS);
   double trade_tick_value   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double trade_tick_value_profit = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
   double trade_tick_value_loss   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   double trade_tick_size    = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double trade_contract_size= SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double volume_min         = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double volume_max         = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double volume_step        = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double volume_limit       = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
   double swap_long          = SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
   double swap_short         = SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);
   double margin_initial     = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);
   double margin_maintenance = SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE);

   string currency_base      = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   string currency_profit    = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   string currency_margin    = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);
   string description        = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
   string path               = SymbolInfoString(symbol, SYMBOL_PATH);

   // For sessions, MQL5 does not expose detailed sessions easily, so mock all days 00:00-24:00:
   string sessions = "[{\"(?)monday\":\"00:00-24:00\"},{\"(?)tuesday\":\"00:00-24:00\"},{\"(?)wednesday\":\"00:00-24:00\"},{\"(?)thursday\":\"00:00-24:00\"},{\"(?)friday\":\"00:00-24:00\"}]";

   // Manually build JSON string:
   string json = "";
   json += "\"name\": \"" + symbol + "\",";
   json += "\"time\": \"" + timeStr + "\",";
   json += "\"digits\": " + IntegerToString(digits) + ",";
   json += "\"spread_float\": " + DoubleToString(spread_float, digits) + ",";
   json += "\"spread\": " + IntegerToString(spread) + ",";
   json += "\"trade_calc_mode\": " + IntegerToString(trade_calc_mode) + ",";
   json += "\"trade_mode\": " + IntegerToString(trade_mode) + ",";
   json += "\"start_time\": " + (string)start_time + ",";
   json += "\"expiration_time\": " + (string)expiration_time + ",";
   json += "\"trade_stops_level\": " + IntegerToString(trade_stops_level) + ",";
   json += "\"trade_freeze_level\": " + IntegerToString(trade_freeze_level) + ",";
   json += "\"trade_exemode\": " + IntegerToString(trade_exemode) + ",";
   json += "\"swap_mode\": " + IntegerToString(swap_mode) + ",";
   json += "\"swap_rollover3days\": " + IntegerToString(swap_rollover_3days) + ",";
   json += "\"point\": " + DoubleToString(point, digits) + ",";
   json += "\"trade_tick_value\": " + DoubleToString(trade_tick_value, 8) + ",";
   json += "\"trade_tick_value_profit\": " + DoubleToString(trade_tick_value_profit, 8) + ",";
   json += "\"trade_tick_value_loss\": " + DoubleToString(trade_tick_value_loss, 8) + ",";
   json += "\"trade_tick_size\": " + DoubleToString(trade_tick_size, digits) + ",";
   json += "\"trade_contract_size\": " + DoubleToString(trade_contract_size, 8) + ",";
   json += "\"volume_min\": " + DoubleToString(volume_min, 8) + ",";
   json += "\"volume_max\": " + DoubleToString(volume_max, 8) + ",";
   json += "\"volume_step\": " + DoubleToString(volume_step, 8) + ",";
   json += "\"volume_limit\": " + DoubleToString(volume_limit, 8) + ",";
   json += "\"swap_long\": " + DoubleToString(swap_long, 8) + ",";
   json += "\"swap_short\": " + DoubleToString(swap_short, 8) + ",";
   json += "\"margin_initial\": " + DoubleToString(margin_initial, 8) + ",";
   json += "\"margin_maintenance\": " + DoubleToString(margin_maintenance, 8) + ",";
   json += "\"currency_base\": \"" + currency_base + "\",";
   json += "\"currency_profit\": \"" + currency_profit + "\",";
   json += "\"currency_margin\": \"" + currency_margin + "\",";
   json += "\"description\": \"" + description + "\",";
   json += "\"path\": \"" + path + "\",";
   json += "\"session_quote\": " + sessions + ",";
   json += "\"session_trade\": " + sessions;

   return SendJson(json);
}

//+------------------------------------------------------------------+
//| Set Tracking for symbols                                         |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::SetSymbols(string &symbols[])
{
    string validSymbols[];
    string invalidSymbols[];
    int count = ArraySize(symbols);

    for(int i = 0; i < count; i++)
    {
        string sym = symbols[i];
        bool selected = SymbolSelect(sym, true);
        if(selected)
        {
            int newSize = ArraySize(validSymbols);
            ArrayResize(validSymbols, newSize + 1);
            validSymbols[newSize] = sym;
        }
        else
        {
            int newSize = ArraySize(invalidSymbols);
            ArrayResize(invalidSymbols, newSize + 1);
            invalidSymbols[newSize] = sym;
        }
    }

    // Set valid symbols
    if(dataSender != NULL && ArraySize(validSymbols) >= 0)
    {
        dataSender.setSymbols(validSymbols);
    }

    // Build success/fail JSON
    string validStr = "[";
    for(int i = 0; i < ArraySize(validSymbols); i++) {
        if(i > 0) validStr += ",";
        validStr += "\"" + validSymbols[i] + "\"";
    }
    validStr += "]";

    string invalidStr = "[";
    for(int i = 0; i < ArraySize(invalidSymbols); i++) {
        if(i > 0) invalidStr += ",";
        invalidStr += "\"" + invalidSymbols[i] + "\"";
    }
    invalidStr += "]";

    string jsonStr = "\"response\":\"track_prices\",\"status\":\"success\",\"accepted\":" + validStr + ",\"rejected\":" + invalidStr;

    return SendJson(jsonStr);
}

//+------------------------------------------------------------------+
//| Set Tracking for ohlc                                            |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::SetOhlcRequests(OhlcRequest &requests[]) {
    // Set valid OHLCs
    if (dataSender != NULL && ArraySize(requests) > 0) {
        dataSender.setOhlcs(requests);
    }

    string validStr = "[";
    for (int i = 0; i < ArraySize(requests); i++) {
        if (i > 0)
            validStr += ",";
        Print("timeframe:" + timeframeToString(requests[i].timeframe));
        string tfStr = timeframeToString(requests[i].timeframe);

        validStr += "{";
        validStr += "\"symbol\":\"" + requests[i].symbol + "\",";
        validStr += "\"time_frame\":\"" + tfStr + "\"";
        validStr += "}";
    }
    validStr += "]";

    string response = "\"response\":\"ohlc_update\",";
    response += "\"accepted\":" + validStr;

    return SendJson(response);
}




//+------------------------------------------------------------------+
//| Send Acknowledgment Response                                     |
//+------------------------------------------------------------------+
JsonResponse CCommandCore::SendError(int status, string details = "") {
    Print("Sending ACK -Status: ", status, ", details: ", details);
    
  
    string jsonStr = "";
    if(details != "")
        jsonStr += "\"details\":\"" + details + "\"";
        
    return SendJson(jsonStr, status);
}

JsonResponse CCommandCore::SendJson(string jsonContent = "", int status = 200)
{
    JsonResponse jsonRes;
    
    jsonRes.jsonContent = "{" + jsonContent + "}";
    jsonRes.status = status;

    return jsonRes;
}



ENUM_TIMEFRAMES getTimeFrameEnum(string tfStr)
{
    if(tfStr == "M1") return PERIOD_M1;
    if(tfStr == "M5") return PERIOD_M5;
    if(tfStr == "M15") return PERIOD_M15;
    if(tfStr == "M30") return PERIOD_M30;
    if(tfStr == "H1") return PERIOD_H1;
    if(tfStr == "H4") return PERIOD_H4;
    if(tfStr == "D1") return PERIOD_D1;
    if(tfStr == "W1") return PERIOD_W1;
    if(tfStr == "MN1") return PERIOD_MN1;
    return (ENUM_TIMEFRAMES)-1; // invalid
}
string timeframeToString(ENUM_TIMEFRAMES tf) {
    switch(tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "UNKNOWN";
    }
}

ENUM_ORDER_TYPE_FILLING parseFillingType(string fill) {
    if (fill == "fok") {
        return ORDER_FILLING_FOK;      // Fill or Kill
    } else if (fill == "ioc") {
        return ORDER_FILLING_IOC;      // Immediate or Cancel
    } else if (fill == "return") {
        return ORDER_FILLING_RETURN;   
    } else if (fill == "boc"){
        return ORDER_FILLING_BOC;
    } 
    return (ENUM_ORDER_TYPE_FILLING)-1;
}



// Helper to format datetime to ISO8601 (e.g., 2025-06-27T03:30:53.000)
string ToIso8601(datetime time) {
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return StringFormat("%04d-%02d-%02dT%02d:%02d:%02d.000", dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
}