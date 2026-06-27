@echo off
setlocal enabledelayedexpansion

echo ======================================================
echo    Pipeline Estatistico: Radix Sort vs std::sort      
echo ======================================================

echo.
echo [1/4] Gerando massa de dados JSON (C++)...
if exist "cpp_sorters\build\data_generator.exe" (
    cpp_sorters\build\data_generator.exe
) else (
    echo Erro: Executavel data_generator.exe nao encontrado! Compile o projeto primeiro.
    exit /b 1
)

echo.
echo [2/4] Executando ordenacao e medindo latencia (C++)...
if exist "cpp_sorters\build\benchmark.exe" (
    cpp_sorters\build\benchmark.exe
) else (
    echo Erro: Executavel benchmark.exe nao encontrado!
    exit /b 1
)

echo.
echo [3/4] Processando Inferencia e Modelagem (R)...
Rscript r_analysis\analysis.R
if %errorlevel% neq 0 (
    echo Erro: Falha ao executar o script em R. Verifique se o Rscript esta no PATH do Windows.
    exit /b %errorlevel%
)

echo.
echo [4/4] Inicializando o Dashboard...

echo Abrindo o navegador automaticamente...
REM Aguarda 1 segundo antes de abrir o navegador
timeout /t 1 /nobreak > nul
start http://localhost:8000/frontend/index.html

echo Servidor Python online! Pressione CTRL+C no terminal para encerrar o servidor.
python -m http.server 8000