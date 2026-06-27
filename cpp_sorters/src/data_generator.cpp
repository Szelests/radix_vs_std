#include <iostream>
#include <vector>
#include <fstream>
#include <random>
#include <algorithm>
#include <string>
// Assumindo que você colocou o json.hpp na pasta include
#include "../include/json.hpp" 

using json = nlohmann::json;

// Enum para facilitar a legibilidade dos tipos de distribuição
enum class Distribution {
    RANDOM,
    REVERSE_SORTED,
    NEARLY_SORTED
};

// Converte o enum para string para salvar no JSON
std::string distToString(Distribution d) {
    switch(d) {
        case Distribution::RANDOM: return "random";
        case Distribution::REVERSE_SORTED: return "reverse_sorted";
        case Distribution::NEARLY_SORTED: return "nearly_sorted";
        default: return "unknown";
    }
}

int main() {
    std::cout << "Iniciando gerador de dados...\n";

    // Setup do gerador de números aleatórios de alta qualidade (Mersenne Twister)
    std::random_device rd;
    std::mt19937 gen(rd());
    // Limitando os valores entre 0 e 10 milhões (valores positivos, ideal para Radix LSB)
    std::uniform_int_distribution<int> value_dist(0, 10000000); 

    json output_json;
    output_json["arrays"] = json::array();

    const int TOTAL_ARRAYS = 100;

    for (int i = 0; i < TOTAL_ARRAYS; ++i) {
        // Varia o tamanho do array entre 1.000 e 500.000 elementos
        int size;
        if (i < 30) size = 1000 + (gen() % 9000);          // 30 arrays pequenos: 1k - 10k
        else if (i < 70) size = 10000 + (gen() % 90000);   // 40 arrays médios: 10k - 100k
        else size = 100000 + (gen() % 400000);             // 30 arrays grandes: 100k - 500k

        // Escolhe o tipo de distribuição circularmente para garantir balanceamento
        Distribution dist_type = static_cast<Distribution>(i % 3);

        std::vector<int> current_array(size);

        // 1. Preenche aleatoriamente por padrão
        for (int j = 0; j < size; ++j) {
            current_array[j] = value_dist(gen);
        }

        // 2. Modifica a distribuição conforme o tipo escolhido
        if (dist_type == Distribution::REVERSE_SORTED) {
            std::sort(current_array.begin(), current_array.end(), std::greater<int>());
        } 
        else if (dist_type == Distribution::NEARLY_SORTED) {
            std::sort(current_array.begin(), current_array.end());
            // Embaralha cerca de 5% dos elementos para simular ruído de ordenação
            int swaps = size * 0.05;
            std::uniform_int_distribution<int> index_dist(0, size - 1);
            for (int s = 0; s < swaps; ++s) {
                int idx1 = index_dist(gen);
                int idx2 = index_dist(gen);
                std::swap(current_array[idx1], current_array[idx2]);
            }
        }

        // 3. Constrói o objeto JSON para este array
        json array_obj;
        array_obj["id"] = i + 1;
        array_obj["size"] = size;
        array_obj["distribution"] = distToString(dist_type);
        array_obj["data"] = current_array;

        // É exatamente aqui que o seu arquivo tinha sido cortado!
        output_json["arrays"].push_back(array_obj);

        if ((i + 1) % 10 == 0) {
            std::cout << "Gerados " << (i + 1) << " / " << TOTAL_ARRAYS << " arrays...\n";
        }
    }

    // 4. Salva no disco
    std::cout << "Escrevendo arquivo JSON...\n";
    std::ofstream file("data/inputs/test_arrays.json");
    if (file.is_open()) {
        file << output_json.dump(); 
        file.close();
        std::cout << "Arquivo data/inputs/test_arrays.json criado com sucesso!\n";
    } else {
        std::cerr << "Erro: Não foi possível abrir o arquivo para escrita. Verifique se a pasta data/inputs/ existe.\n";
    }

    return 0;
}