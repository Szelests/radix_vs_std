#include "../include/radix_sort.hpp"
#include <vector>

void radixSort(std::vector<int>& arr) {
    if (arr.empty()) return;

    size_t n = arr.size();
    std::vector<int> output(n);

    // Como operamos na Base 256 (8 bits), o vetor de contagem precisa de 256 posições
    const int BUCKETS = 256;

    // Um inteiro de 32 bits tem 4 bytes. Faremos exatamente 4 passagens.
    // shift = 0  (bits 0-7), shift = 8  (bits 8-15)
    // shift = 16 (bits 16-23), shift = 24 (bits 24-31)
    for (int shift = 0; shift < 32; shift += 8) {
        int count[BUCKETS] = {0};

        // 1. Contagem das ocorrências do byte atual (usando máscara binária 0xFF)
        for (size_t i = 0; i < n; ++i) {
            int byte_value = (arr[i] >> shift) & 0xFF;
            count[byte_value]++;
        }

        // 2. Atualização do vetor count para conter as posições reais no vetor de saída
        for (int i = 1; i < BUCKETS; ++i) {
            count[i] += count[i - 1];
        }

        // 3. Construção do vetor de saída (iteração reversa para garantir a estabilidade)
        for (size_t i = n; i > 0; --i) {
            size_t idx = i - 1;
            int byte_value = (arr[idx] >> shift) & 0xFF;
            output[count[byte_value] - 1] = arr[idx];
            count[byte_value]--;
        }

        // 4. Cópia dos dados ordenados deste passo de volta para o vetor original
        for (size_t i = 0; i < n; ++i) {
            arr[i] = output[i];
        }
    }
}