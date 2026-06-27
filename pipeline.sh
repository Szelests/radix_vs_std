#!/bin/bash

# Interrompe o script imediatamente se algum comando falhar
set -e

# Configuração de cores para deixar o terminal bonito
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   Pipeline Estatístico: Radix Sort vs std::sort      ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Geração de Dados
echo -e "\n${YELLOW}[1/4] Gerando massa de dados JSON (C++)...${NC}"
if [ -f "./cpp_sorters/build/data_generator" ]; then
    ./cpp_sorters/build/data_generator
else
    echo -e "${RED}Erro: Executável data_generator não encontrado! Compile o projeto primeiro.${NC}"
    exit 1
fi

# 2. Execução do Benchmark
echo -e "\n${YELLOW}[2/4] Executando ordenação e medindo latência (C++)...${NC}"
if [ -f "./cpp_sorters/build/benchmark" ]; then
    ./cpp_sorters/build/benchmark
else
    echo -e "${RED}Erro: Executável benchmark não encontrado!${NC}"
    exit 1
fi

# 3. Análise Estatística
echo -e "\n${YELLOW}[3/4] Processando Inferência e Modelagem (R)...${NC}"
Rscript r_analysis/analysis.R

# 4. Inicialização do Front-end
echo -e "\n${YELLOW}[4/4] Inicializando o Dashboard...${NC}"

# Função para abrir o navegador (xdg-open é o padrão no CachyOS/Arch)
echo -e "${GREEN}Abrindo o navegador automaticamente...${NC}"
sleep 1 && xdg-open "http://localhost:8000/frontend/index.html" &

# Inicia o servidor web
echo -e "${BLUE}Servidor Python online! Pressione CTRL+C no terminal para encerrar o servidor.${NC}"
python -m http.server 8000