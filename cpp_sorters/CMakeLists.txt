cmake_minimum_required(VERSION 3.10)

# Nome do projeto
project(RadixVsStdSort CXX)

# Exigir C++17 (necessário para algumas features modernas)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Otimizações de Compilador (CRUCIAL para benchmarks confiáveis)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # -O3: Otimização agressiva de loops e inlining
    # -march=native: Otimiza o binário especificamente para a CPU da sua máquina
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native -Wall")
elseif(MSVC)
    # Equivalente para o compilador da Microsoft (Visual Studio)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /O2 /favor:AMD64 /W3")
endif()

# Diz ao CMake onde procurar os arquivos .hpp (como o json.hpp e seus cabeçalhos)
include_directories(include)

# Executável 1: O Gerador de Dados
# Compila apenas o data_generator.cpp
add_executable(data_generator src/data_generator.cpp)

# Executável 2: O Orquestrador/Benchmark
# Compila a main junto com as implementações do radix sort e do timer
add_executable(benchmark src/main.cpp src/radix_sort.cpp src/timer_utils.cpp)