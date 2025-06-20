//+------------------------------------------------------------------+
//|                                                      HttpLib.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <socketlib.mqh>

struct HttpRequest {
    string method;          // GET, POST, PUT, DELETE
    string path;           // /v1/account, /v1/orders, etc.
    string body;           // Request body for POST/PUT
    string headers;        // HTTP headers
};
struct HttpResponse {
   SOCKET64 ClientSocket;
    int status_code;       // 200, 404, etc.
    string status_text;    // OK, Not Found, etc.
    string content_type;   // application/json, text/plain, etc.
    string body;           // Response body
    bool keep_alive;       // Whether to keep connection open
};



HttpRequest ParseHttpRequest(string httpRequest) {
    HttpRequest request;
  string lines[];
   StringReplace(httpRequest, "\r\n", "\n");
   int k = StringSplit(httpRequest, '\n', lines);
   Print("line1: " + lines[0]);


   string parts[];
   int partsCount = StringSplit(lines[0], ' ', parts);
   
   Print("---- Split HTTP Request parts ----");
   for(int i = 0; i < partsCount; i++) {
       Print("part" + IntegerToString(i+1) + ": " + parts[i]);
   }
   
   if(partsCount >= 3) {
       request.method = parts[0];
       request.path = parts[1];
       // If you want, you can also assign HTTP version:
       // request.version = parts[2];
   } else {
       Print("Error: HTTP request line has less than 3 parts");
   }


    // Find empty line (separator between headers and body)
    int bodyStart = -1;
    for(int i = 1; i < ArraySize(lines); i++) {
        if(StringLen(lines[i]) == 0) {
            bodyStart = i + 1;
            break;
        }
    }

    // Extract body for POST/PUT requests
    if(bodyStart >= 0 && bodyStart < ArraySize(lines)) {
        request.body = "";
        for(int i = bodyStart; i < ArraySize(lines); i++) {
            if(i > bodyStart) request.body += "\r\n";
            request.body += lines[i];
        }
    }

    return request;
}



void SendHttpResponse(HttpResponse &res) {
    string connectionHeader = res.keep_alive ? "keep-alive" : "close";

    string response =
        "HTTP/1.1 " + IntegerToString(res.status_code) + " " + res.status_text + "\r\n" +
        "Content-Type: " + res.content_type + "\r\n" +
        "Content-Length: " + IntegerToString(StringLen(res.body)) + "\r\n" +
        "Connection: " + connectionHeader + "\r\n\r\n" +
        res.body;

    char out[];
    StringToCharArray(response, out);
    send(res.ClientSocket, out, StringLen(response), 0);
}


