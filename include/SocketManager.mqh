//+------------------------------------------------------------------+
//|                    SocketManager.mqh                             |
//|  Class to manage TCP server socket + accept clients              |
//+------------------------------------------------------------------+

#include <socketlib.mqh>

#import "kernel32.dll"
void RtlMoveMemory(char &dest[], int &src, int length);
#import

class CSocketManager {
private:
    SOCKET64 m_socket;

public:
    CSocketManager();
    ~CSocketManager();

    bool CreateServer(int port);
    bool SetNonBlocking();
    SOCKET64 AcceptClient();
    bool IsValid();
    SOCKET64 GetSocket();
    void Close();
};

//+------------------------------------------------------------------+
//|              CSocketManager Implementation                       |
//+------------------------------------------------------------------+

CSocketManager::CSocketManager() {
    m_socket = INVALID_SOCKET64;
}

CSocketManager::~CSocketManager() {
    Close();
}

bool CSocketManager::CreateServer(int port) {
    m_socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (m_socket == INVALID_SOCKET64) {
        Print("Socket creation failed: ", WSAErrorDescript(WSAGetLastError()));
        return false;
    }

    // Enable SO_REUSEADDR
    int optval = 1;
    char optvalArr[4];
    RtlMoveMemory(optvalArr, optval, 4);
    if (setsockopt(m_socket, SOL_SOCKET, SO_REUSEADDR, optvalArr, ArraySize(optvalArr)) == SOCKET_ERROR) {
        Print("setsockopt failed: ", WSAErrorDescript(WSAGetLastError()));
        Close();
        return false;
    }

    sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr = 0x00000000;
    addr.sin_port = htons(port);

    ref_sockaddr ref;
    sockaddrIn2RefSockaddr(addr, ref);

    if (bind(m_socket, ref.ref, sizeof(addr)) == SOCKET_ERROR ||
        listen(m_socket, SOMAXCONN) == SOCKET_ERROR ||
        !SetNonBlocking()) {
        Print("Bind/listen failed: ", WSAErrorDescript(WSAGetLastError()));
        Close();
        return false;
    }

    Print("Listening on port ", port);
    return true;
}

bool CSocketManager::SetNonBlocking() {
    int non_block = 1;
    return ioctlsocket(m_socket, FIONBIO, non_block) == NO_ERROR;
}

SOCKET64 CSocketManager::AcceptClient() {
    sockaddr_in clientAddr;
    int addrLen = sizeof(clientAddr);
    ref_sockaddr clientRef;
    sockaddrIn2RefSockaddr(clientAddr, clientRef);

    SOCKET64 clientSock = accept(m_socket, clientRef.ref, addrLen);
    if (clientSock != INVALID_SOCKET64) {
        int non_block = 1;
        ioctlsocket(clientSock, FIONBIO, non_block);
    }

    return clientSock;
}

bool CSocketManager::IsValid() {
    return m_socket != INVALID_SOCKET64;
}

SOCKET64 CSocketManager::GetSocket() {
    return m_socket;
}

void CSocketManager::Close() {
    if (m_socket != INVALID_SOCKET64) {
        closesocket(m_socket);
        m_socket = INVALID_SOCKET64;
    }
}
