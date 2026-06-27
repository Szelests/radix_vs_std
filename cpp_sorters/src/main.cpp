#include <iostream>
#include <vector>
#include <fstream>
#include <algorithm>
#include <string>

// Inclusão dos nossos módulos e da biblioteca JSON
#include "../include/radix_sort.hpp"
#include "../include/timer_utils.hpp"
#include "../include/json.hpp"

using json = nlohmann::json;

void runBenchmark() {
    std::cout << "Iniciando o orquestrador de benchmark...\n";

    // 1. Abrir e ler o arquivo JSON gerado
    std::ifstream input_file("data/inputs/test_arrays.json");
    if (!input_file.is_open()) {
        std::cerr << "Erro: Nao foi possivel abrir data/inputs/test_arrays.json. Rode o data_generator primeiro!\n";
        return;
    }

    std::cout << "Fazendo parse do JSON (isso pode levar alguns instantes)...\n";
    json input_data;
    input_file >> input_data;
    input_file.close();

    // 2. Preparar o arquivo CSV de saída
    std::ofstream csv_file("data/outputs/benchmark_results.csv");
    if (!csv_file.is_open()) {
        std::cerr << "Erro: Nao foi possivel criar data/outputs/benchmark_results.csv!\n";
        return;
    }
    
    // Cabeçalho do CSV agora inclui a Distribuição para podermos analisar no R
    csv_file << "ArrayID,Algorithm,ArraySize,Distribution,Time_us\n";

    utils::Timer timer; // Instancia o nosso cronômetro de alta precisão

    const auto& arrays = input_data["arrays"];
    size_t total = arrays.size();
    
    std::cout << "Iniciando processamento de " << total << " arrays...\n";

    // 3. Iterar sobre todos os arrays do JSON
    for (size_t i = 0; i < total; ++i) {
        const auto& item = arrays[i];
        
        int id = item["id"];
        int size = item["size"];
        std::string distribution = item["distribution"];
        
        // Pega os dados brutos
        std::vector<int> original_data = item["data"].get<std::vector<int>>();

        // Cria duas cópias exatas para que a ordenação de um não interfira no outro
        std::vector<int> data_for_radix = original_data;
        std::vector<int> data_for_std = original_data;

        // --- Benchmark Radix Sort ---
        timer.reset();
        radixSort(data_for_radix);
        long long duration_radix = timer.getElapsedMicroseconds();
        
        csv_file << id << ",RadixSort," << size << "," << distribution << "," << duration_radix << "\n";

        // --- Benchmark std::sort ---
        timer.reset();
        std::sort(data_for_std.begin(), data_for_std.end());
        long long duration_std = timer.getElapsedMicroseconds();
        
        csv_file << id << ",StdSort," << size << "," << distribution << "," << duration_std << "\n";

        // Feedback no terminal
        if ((i + 1) % 10 == 0) {
            std::cout << "Processados " << (i + 1) << " / " << total << " arrays...\n";
        }
    }

    csv_file.close();
    std::cout << "\nBenchmark concluido com sucesso!\n";
    std::cout << "Resultados salvos em: data/outputs/benchmark_results.csv\n";
}

int main() {
    runBenchmark();
    return 0;
}