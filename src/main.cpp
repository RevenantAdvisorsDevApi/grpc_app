#include "client.cpp"
#include <thread>
#include <vector>

int main(int argc, char** argv) {
    std::vector<std::string> tickers = { "AAPL","MSFT","AMZN","GOOG","META","TSLA","NVDA","JPM","UNH","HD" };
    std::vector<std::thread> threads;

    for (auto& t : tickers) {
        threads.emplace_back([t]() {
            MarketDataClient client(grpc::CreateChannel("localhost:50051", grpc::InsecureChannelCredentials()));
            client.Subscribe(t);
            });
    }

    for (auto& th : threads) th.join();
    return 0;
}
