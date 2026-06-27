# 📊 Radix Sort vs std::sort: Análise Estatística de Desempenho na Arquitetura de CPU

Este projeto integra conceitos de estrutura de dados, arquitetura de computadores e estatística aplicada. O objetivo principal é avaliar a latência (tempo de execução) de algoritmos de ordenação baseados em comparação (`std::sort`) contra abordagens baseadas em manipulação de bits (`Radix Sort LSB`) e provar estatisticamente o impacto do uso de memória cache e *branch prediction* no hardware moderno.

Este repositório contém todo o *pipeline* de dados: desde a geração dos arrays em **C++**, passando pelo processamento estatístico rigoroso em **R**, até à apresentação dos dados num **Dashboard Web Interativo**.

Projeto desenvolvido no âmbito académico do curso de Engenharia Eletrónica da UTFPR (Universidade Tecnológica Federal do Paraná).

---

## 📁 Arquitetura do Projeto

O repositório está organizado nas seguintes diretrizes:

* **`cpp_sorters/`**: Contém o código nativo em C++. Responsável por gerar os arrays de diferentes tamanhos (1k a 500k) e distribuições (*Random, Nearly Sorted, Reverse Sorted*), e por medir a latência em microssegundos (via `<chrono>`).
* **`data/outputs/`**: Diretório onde os resultados do *benchmark* (`.csv`) e as extrações estatísticas (`.json`) são guardados.
* **`r_analysis/`**: Contém o script R (`analysis.R`) que lê os dados de execução e realiza as análises descritivas, testes de inferência (Wilcoxon, T-Test, ANOVA) e o ajuste de distribuições probabilísticas (Máxima Verossimilhança / MLE).
* **`frontend/`**: O Dashboard Interativo em HTML, CSS e Vanilla JavaScript. Ele carrega os dados processados pelo R de forma dinâmica, renderiza equações matemáticas (MathJax) e inclui um simulador mecânico dos algoritmos.
* **`run_pipeline.sh` / `.bat`**: Scripts de orquestração para executar todo o fluxo com um único comando.

---

## ⚙️ Pré-requisitos

Para executar este projeto localmente, irá necessitar das seguintes ferramentas instaladas no seu sistema:

1.  **Compilador C++**: `g++` ou `clang` para compilar a fase de *benchmark*.
2.  **Linguagem R**: Versão 4.0+ com os seguintes pacotes estatísticos instalados:
    * `ggplot2`, `dplyr`, `tidyr`, `moments`, `fitdistrplus`, `jsonlite`.
    * *(Para instalar no R, utilize: `install.packages(c("ggplot2", "dplyr", "tidyr", "moments", "fitdistrplus", "jsonlite"))`)*
3.  **Python 3**: Utilizado nativamente pelo sistema para criar um servidor web local e contornar os bloqueios de segurança do navegador (CORS) ao carregar o ficheiro JSON.

---

## 🚀 Como Executar o Projeto

Foi criado um *Shell Script* (para Linux) e um *Batch Script* (para Windows) que automatizam toda a cadeia de execução. O script compila, avalia, gera os gráficos, inicia o servidor e abre o ecrã final.

### Em Linux (Arch / CachyOS / Ubuntu)
Abra o terminal na pasta raiz do projeto, dê permissão de execução e inicie o script:
```bash
chmod +x run_pipeline.sh
./run_pipeline.sh