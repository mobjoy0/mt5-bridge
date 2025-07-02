

#include <JAson.mqh>


struct ValidationResponse {
   int code;
   string message;

   // Default constructor
   void ValidationResponse() {
      code = 0;
      message = "";
   }

};

//+------------------------------------------------------------------+
//| Validation Methods                                               |
//+------------------------------------------------------------------+
ValidationResponse ValidateJson(CJAVal &json, const string &body) {
    ValidationResponse res;
    
    if (body == "") {
      res.code = 400;
      res.message = "Body cannot be empty.";
      return res;
    }
    
    if (!json.Deserialize(body)) {
        res.code = 400;res.message = "Invalid JSON format";
        return res;
    }
    
    return res;
}

ValidationResponse ValidateSymbol(const string &symbol) {
    ValidationResponse res;

    if (symbol == "") {
        res.code = 400;
        res.message = "Symbol cannot be empty";
        return res;
    }

    if (!SymbolSelect(symbol, true)) {
        res.code = 404;
        res.message = "Symbol not found";
        return res;
    }

    return res;
}


// Helper: Checks if a date string matches ISO8601: YYYY-MM-DD [T HH:MM:SS optional]
bool IsValidISO8601Format(const string &str) {
    int len = StringLen(str);

    if (len < 10)  // Must at least contain date
        return false;

    // Check mandatory date format: YYYY-MM-DD
    if (str[4] != '-' || str[7] != '-')
        return false;

    int year  = StringToInteger(StringSubstr(str, 0, 4));
    int month = StringToInteger(StringSubstr(str, 5, 2));
    int day   = StringToInteger(StringSubstr(str, 8, 2));

    if (year < 1970 || month < 1 || month > 12 || day < 1 || day > 31)
        return false;

    if (len == 10) // Only date
        return true;

    if (str[10] != 'T') // If more than date, it must start with 'T'
        return false;

    int hour = -1, minute = -1, second = -1;

    // Parse time components
    if (len >= 13) {
        hour = StringToInteger(StringSubstr(str, 11, 2));
        if (hour < 0 || hour > 23)
            return false;
    }

    if (len >= 16) {
        if (str[13] != ':')
            return false;
        minute = StringToInteger(StringSubstr(str, 14, 2));
        if (minute < 0 || minute > 59)
            return false;
    }

    if (len >= 19) {
        if (str[16] != ':' && str[17] != ':')
            return false;
        second = StringToInteger(StringSubstr(str, 17, 2));
        if (second < 0 || second > 59)
            return false;
    }

    // If the length is something strange like 12, 15, 18 — reject
    if (!(len == 13 || len == 16 || len == 19))
        return false;

    return true;
}


ValidationResponse ValidateDateRange(const string &from_date_str, const string &to_date_str,
                                     datetime &from_date, datetime &to_date) {
    ValidationResponse res;

    if (!IsValidISO8601Format(from_date_str)) {
        res.code = 400;
        res.message = "Invalid from_date format. Expected YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS";
        return res;
    }

    if (!IsValidISO8601Format(to_date_str)) {
        res.code = 400;
        res.message = "Invalid to_date format. Expected YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS";
        return res;
    }

    string from_temp = from_date_str;
    string to_temp = to_date_str;

    StringReplace(from_temp, "T", " ");
    StringReplace(to_temp, "T", " ");

    from_date = StringToTime(from_temp);
    to_date = StringToTime(to_temp);

    if (from_date == 0) {
        res.code = 400;
        res.message = "Invalid from_date value after parsing";
        return res;
    }

    if (to_date == 0) {
        res.code = 400;
        res.message = "Invalid to_date value after parsing";
        return res;
    }

    if (from_date > to_date) {
        res.code = 400;
        res.message = "from_date must be earlier than to_date";
        return res;
    }

    return res;
}



ValidationResponse ValidateTimeFrame(const string &timeFrame, ENUM_TIMEFRAMES &tf) {
    ValidationResponse res;
    tf = getTimeFrameEnum(timeFrame);

    if (tf == (ENUM_TIMEFRAMES)-1) {
        res.code = 400;
        res.message = "Invalid timeframe: '" + timeFrame + "'. Valid values: M1, M5, M15, M30, H1, H4, D1, W1, MN1";
        return res;
    }

    return res;
}



ValidationResponse ValidateOrderType(const string order_type) {
    ValidationResponse res;

    if (order_type != "buy" && order_type != "sell" &&
        order_type != "buy_limit" && order_type != "sell_limit" &&
        order_type != "buy_stop" && order_type != "sell_stop") {
        res.code = 400;
        res.message = "Invalid order_type: '" + order_type + "'. Valid values: buy, sell, buy_limit, sell_limit, buy_stop, sell_stop";
        return res;
    }

    return res;
}



ValidationResponse ValidateHistoryMode(const string &mode) {
    ValidationResponse res;

    if (mode != "deals" && mode != "orders" && mode != "positions") {
        res.code = 400;
        res.message = "Invalid mode: '" + mode + "'. Valid values: deals, orders, positions";
        return res;
    }

    return res;
}
  // utility

  // Helper to format datetime to ISO8601 (e.g., 2025-06-27T03:30:53.000)
string ToIso8601(datetime time) {
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return StringFormat("%04d-%02d-%02dT%02d:%02d:%02d.000", dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
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