#pragma once
#include <chrono>

namespace utils {

    class Timer {
    private:
        // Ponto no tempo exato em que o timer foi iniciado
        std::chrono::time_point<std::chrono::high_resolution_clock> start_timepoint;

    public:
        // O construtor já inicia a contagem automaticamente
        Timer();

        // Reinicia o cronômetro
        void reset();

        // Retorna o tempo decorrido em microssegundos (10^-6 segundos)
        long long getElapsedMicroseconds() const;

        // Retorna o tempo decorrido em nanossegundos (10^-9 segundos)
        long long getElapsedNanoseconds() const;
    };

} // namespace utils