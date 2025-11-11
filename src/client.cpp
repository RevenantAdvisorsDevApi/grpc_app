#include <grpcpp/grpcpp.h>
#include "generated/market.grpc.pb.h"
#include <chrono>
#include <iostream>

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using grpc::ClientReader;
using market::Price;
using market::SubscribeRequest;
using market::MarketData;

class MarketDataClient {
public:
    MarketDataClient(std::shared_ptr<Channel> channel)
        : stub_(MarketData::NewStub(channel)) {}

    void Subscribe(const std::string& ticker) {
        SubscribeRequest req;
        req.set_ticker(ticker);
        ClientContext context;

        std::unique_ptr<ClientReader<Price>> reader(stub_->Subscribe(&context, req));
        Price p;
        while (reader->Read(&p)) {

            using namespace std::chrono;

            // Current time
            auto now = system_clock::now();

            // Timestamp from protobuf
            auto ts_point = system_clock::from_time_t(p.ts().seconds()) + nanoseconds(p.ts().nanos());

            // Compute latency
            auto latency = now - ts_point;

            // Convert to milliseconds for display
            auto ms = duration_cast<milliseconds>(latency).count();

            std::cout << "[" << p.ticker() << "] Price: " << p.price()
                << ", Latency: " << ms << " ms\n";
        }
        Status status = reader->Finish();
        if (!status.ok()) {
            std::cerr << "Subscribe RPC failed: " << status.error_message() << "\n";
        }
    }

private:
    std::unique_ptr<MarketData::Stub> stub_;
};

