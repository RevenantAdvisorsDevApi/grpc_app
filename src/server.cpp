#include <grpcpp/grpcpp.h>
#include "generated/market.grpc.pb.h"
#include <fstream>
#include <sstream>
#include <random>
#include <thread>
#include <chrono>
#include <map>
#include <vector>
#include <string>
#include <iostream>

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using grpc::ServerWriter;
using market::Price;
using market::SubscribeRequest;
using market::MarketData;

// Map to store historical data per ticker
std::map<std::string, std::vector<std::pair<std::string, double>>> history;

class MarketDataServiceImpl final : public MarketData::Service {
public:
    Status Subscribe(ServerContext* context, const SubscribeRequest* req,
        ServerWriter<Price>* writer) override {

        auto it = history.find(req->ticker());
        if (it == history.end()) {
            return Status(grpc::StatusCode::NOT_FOUND, "Ticker not found");
        }

        auto& vec = it->second;
        std::uniform_int_distribution<int> dist_ms(10, 200);
        std::uniform_int_distribution<int> dist_nano(0, 999999999);
        std::random_device rd;
        std::mt19937 rng(rd());

        for (auto& row : vec) {
            if (context->IsCancelled()) break;

            Price p;
            p.set_ticker(req->ticker());
            p.set_price(row.second);

            // Parse date YYYY-MM-DD
            std::tm tm{};
            std::istringstream ss(row.first);
            ss >> std::get_time(&tm, "%Y-%m-%d");
            if (ss.fail()) continue;

            // Convert to time_t UTC
            std::time_t tt = std::mktime(&tm);

            google::protobuf::Timestamp* ts = p.mutable_ts();
            ts->set_seconds(static_cast<int64_t>(tt));
            ts->set_nanos(dist_nano(rng));

            writer->Write(p);

            std::this_thread::sleep_for(std::chrono::milliseconds(dist_ms(rng)));
        }
        return Status::OK;
    }
};

// Helper to load CSV
void load_csv(const std::string& ticker) {
    std::ifstream file("rsrc/" + ticker + ".csv");
    if (!file.is_open()) {
        std::cerr << "Could not open CSV for " << ticker << "\n";
        return;
    }

    std::string line;
    bool header = true;
    while (std::getline(file, line)) {
        if (header) { header = false; continue; } // skip header
        std::stringstream ss(line);
        std::string date_str;
        double price;
        std::getline(ss, date_str, ',');
        ss >> price;
        history[ticker].emplace_back(date_str, price);
    }

    std::cout << "Loaded " << history[ticker].size() << " rows for " << ticker << "\n";
}

int main(int argc, char** argv) {
    // List of 10 tickers
    std::vector<std::string> tickers = { "AAPL","MSFT","AMZN","GOOG","META","TSLA","NVDA","JPM","UNH","HD" };

    // Load all CSVs
    for (auto& t : tickers) {
        load_csv(t);
    }

    // Start gRPC server
    std::string server_address("0.0.0.0:50051");
    MarketDataServiceImpl service;

    ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_address << "\n";

    server->Wait();
    return 0;
}
