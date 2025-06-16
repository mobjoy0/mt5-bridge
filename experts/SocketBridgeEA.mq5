//+------------------------------------------------------------------+
//| SocketBridgeEA.mq5                                               |
//| Socket Bridge Expert Advisor for MT5                            |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property version   "1.00"
#property strict

#include <socketlib.mqh>
#include <JAson.mqh>
#include <Trade\Trade.mqh>
#include <CommandHandler.mqh>
#include <PriceSender.mqh>

#define COMMAND_PORT 8888
#define PRICE_PORT 8889
#define SERVER_IP_ADDRESS "127.0.0.1"

SOCKET64 commandSocket = INVALID_SOCKET64;
SOCKET64 priceSocket = INVALID_SOCKET64;
CCommandHandler* commandHandler = NULL;
CPriceSender* priceSender = NULL;
string symbols[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   EnsureSocketConnection();

   EventSetTimer(5);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(commandHandler != NULL) {
      delete commandHandler;
      commandHandler = NULL;
   }
   if(priceSender != NULL) {
      delete priceSender;
      priceSender = NULL;
   }
   CloseClean();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // Not used - we rely on timer events
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   if(commandSocket == INVALID_SOCKET64 || priceSocket == INVALID_SOCKET64) {
      EnsureSocketConnection();
      return;
   }

   // Send price updates if price sender is available
   if(priceSender != NULL && priceSender.ShouldSendUpdate(1)) {
      priceSender.SendCurrentPrices();
   }

   //Try to receive data
   char buf[1024];
   int received = recv(commandSocket, buf, ArraySize(buf), 0);
   if(received > 0) {
      Print("Received message");
      string msg = CharArrayToString(buf, 0, received);
      
      //Use command handler to process the message
      if(commandHandler != NULL) {
         commandHandler.HandleCommand(msg);
      }
   }
}

//+------------------------------------------------------------------+
//| Ensure socket connections                                        |
//+------------------------------------------------------------------+
void EnsureSocketConnection() {
   char wsaData[]; ArrayResize(wsaData, sizeof(WSAData));
   int res = WSAStartup(MAKEWORD(2, 2), wsaData);
   if (res != 0) {
      Print(__FUNCTION__, " > WSAStartup failed error: ", string(res));
      return;
   }

   // Connect command socket
   commandSocket = CreateSocket(COMMAND_PORT);
   if (commandSocket == INVALID_SOCKET64) return;

   // Connect price socket
   priceSocket = CreateSocket(PRICE_PORT);
   if (priceSocket == INVALID_SOCKET64) return;

   // Initialize price sender
   if(priceSender != NULL) delete priceSender;
   priceSender = new CPriceSender(priceSocket);
   
   // Initialize command handler
   if(commandHandler != NULL) delete commandHandler;
   commandHandler = new CCommandHandler(commandSocket, priceSender);
   

   priceSender.setSymbols(symbols);

   Print(__FUNCTION__, " > sockets created...");
}






//+------------------------------------------------------------------+
//| Helper to create and connect socket                              |
//+------------------------------------------------------------------+
SOCKET64 CreateSocket(int port) {
   SOCKET64 sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
   if (sock == INVALID_SOCKET64) {
      Print(__FUNCTION__, " > socket failed error: ", WSAErrorDescript(WSAGetLastError()));
      return INVALID_SOCKET64;
   }

   char ip[]; StringToCharArray(SERVER_IP_ADDRESS, ip);
   sockaddr_in addrin;
   addrin.sin_family = AF_INET;
   addrin.sin_addr = inet_addr(ip);
   addrin.sin_port = htons(port);

   ref_sockaddr ref;
   sockaddrIn2RefSockaddr(addrin, ref);

   int res = connect(sock, ref.ref, sizeof(addrin));
   if (res == SOCKET_ERROR && WSAGetLastError() != WSAEISCONN) {
      Print(__FUNCTION__, " > connect failed error: ", WSAErrorDescript(WSAGetLastError()));
      closesocket(sock);
      return INVALID_SOCKET64;
   }

   int non_block = 1;
   res = ioctlsocket(sock, (int)FIONBIO, non_block);
   if (res != NO_ERROR) {
      Print(__FUNCTION__, " > ioctlsocket failed error: ", string(res));
      closesocket(sock);
      return INVALID_SOCKET64;
   }

   return sock;
}

//+------------------------------------------------------------------+
//| Close all sockets cleanly                                        |
//+------------------------------------------------------------------+
void CloseClean() {
   if (commandSocket != INVALID_SOCKET64) {
      closesocket(commandSocket);
      commandSocket = INVALID_SOCKET64;
   }
   if (priceSocket != INVALID_SOCKET64) {
      closesocket(priceSocket);
      priceSocket = INVALID_SOCKET64;
   }
   WSACleanup();
   Print(__FUNCTION__, " > sockets closed...");
}
