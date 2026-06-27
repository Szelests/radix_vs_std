# ==============================================================================
# TRABALHO INTEGRADO DE ESTATÍSTICA APLICADA
# Script de Processamento e Modelagem
# ==============================================================================

# Carregar bibliotecas
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(moments)
  library(fitdistrplus)
  library(jsonlite)
})

cat("A iniciar análise estatística conforme especificações do PDF...\n")

# 1. Carregamento dos Dados
dados <- read.csv("data/outputs/benchmark_results.csv")
dir.create("r_analysis/exports", showWarnings = FALSE)
dir.create("data/outputs", showWarnings = FALSE)

# ==============================================================================
# SEÇÃO 5: ORGANIZAÇÃO E ANÁLISE DESCRITIVA
# ==============================================================================
cat("A calcular estatísticas descritivas...\n")

# Função para moda
get_mode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

descritiva <- dados %>%
  group_by(Algorithm) %>%
  summarise(
    Media = mean(Time_us),
    Mediana = median(Time_us),
    Moda = get_mode(Time_us),
    Desvio_Padrao = sd(Time_us),
    Variancia = var(Time_us),
    Coef_Variacao = (sd(Time_us) / mean(Time_us)) * 100,
    Q1 = quantile(Time_us, 0.25),
    Q3 = quantile(Time_us, 0.75),
    .groups = 'drop'
  )

# Gráfico 1: Boxplot (Identificação de Outliers e Variabilidade)
g_box <- ggplot(dados, aes(x = Algorithm, y = Time_us, fill = Algorithm)) +
  geom_boxplot(alpha = 0.7, outlier.colour = "red", outlier.shape = 16, outlier.size = 2) +
  scale_y_log10() + # Escala log devido à grande variação de tempos
  labs(title = "Boxplot: Dispersão dos Tempos de Execução (Escala Log)", x = "Algoritmo", y = "Tempo (us) - Log10") +
  theme_minimal()
ggsave("r_analysis/exports/boxplot_descritiva.png", plot = g_box, width = 8, height = 5)

# Gráfico 2: Densidade (Comportamento Central)
g_dens <- ggplot(dados, aes(x = Time_us, fill = Algorithm)) +
  geom_density(alpha = 0.5) +
  scale_x_log10() +
  labs(title = "Gráfico de Densidade: Distribuição dos Tempos", x = "Tempo (us) - Log10", y = "Densidade") +
  theme_minimal()
ggsave("r_analysis/exports/densidade_descritiva.png", plot = g_dens, width = 8, height = 5)


# ==============================================================================
# SEÇÃO 6: INFERÊNCIA ESTATÍSTICAA
# ==============================================================================
cat("A realizar Inferências (Testes e IC)...\n")

# 6.1 Intervalo de Confiança (IC 95%) para o Radix Sort
radix_data <- dados %>% filter(Algorithm == "RadixSort")
std_data <- dados %>% filter(Algorithm == "StdSort")

ic_radix <- t.test(radix_data$Time_us)$conf.int

# 6.3 Testes de Hipótese
# Teste 1 (Uma amostra): Testar se a média do Radix é diferente de 200us
t_one_sample <- t.test(radix_data$Time_us, mu = 200)

# Teste 2 (Duas amostras): Comparar Radix vs StdSort (Pareado, pois são os mesmos arrays)
t_two_sample <- wilcox.test(radix_data$Time_us, std_data$Time_us, paired = TRUE)

# Teste 3 (ANOVA): Comparar os tempos do RadixSort entre as 3 distribuições
anova_radix <- aov(Time_us ~ Distribution, data = radix_data)
anova_summary <- summary(anova_radix)
p_value_anova <- anova_summary[[1]][["Pr(>F)"]][1]


# ==============================================================================
# SEÇÃO 7: MODELAGEM DE DISTRIBUIÇÕES DE PROBABILIDADE
# ==============================================================================
cat("A ajustar distribuições (MLE)...\n")

# Variável escolhida: Tempos do RadixSort na distribuição 'random'
dados_modelagem <- radix_data %>% filter(Distribution == "random") %>% pull(Time_us)

# 7.2 Características Preliminares
assimetria <- skewness(dados_modelagem)
curtose <- kurtosis(dados_modelagem)

# 7.4 Ajuste por Máxima Verossimilhança (MLE)
fit_lnorm <- fitdist(dados_modelagem, "lnorm")

# --- CORREÇÃO DO ERRO MLE ---
# Cálculo dos parâmetros iniciais via Método dos Momentos (MOM) 
m_est <- mean(dados_modelagem)
v_est <- var(dados_modelagem)
shape_est <- (m_est^2) / v_est
rate_est <- m_est / v_est

# O limite 'lower' força o uso do algoritmo de otimização L-BFGS-B (com restrições).
# Isso impede que o R teste parâmetros negativos que geram derivadas infinitas (Error 100).
fit_gamma <- fitdist(dados_modelagem, "gamma", 
                     start = list(shape = shape_est, rate = rate_est),
                     lower = c(1e-10, 1e-10))
# ----------------------------

# Escolher a melhor baseado no AIC (Critério de Informação de Akaike)
melhor_aic <- min(fit_lnorm$aic, fit_gamma$aic)
melhor_dist <- ifelse(fit_lnorm$aic == melhor_aic, "Log-Normal", "Gamma")

# Plot do ajuste (Comparação)
png("r_analysis/exports/ajuste_distribuicoes.png", width = 800, height = 600, res=100)
par(mfrow=c(2,2))
plot.legend <- c("Log-Normal", "Gamma")
denscomp(list(fit_lnorm, fit_gamma), legendtext = plot.legend)
qqcomp(list(fit_lnorm, fit_gamma), legendtext = plot.legend)
cdfcomp(list(fit_lnorm, fit_gamma), legendtext = plot.legend)
ppcomp(list(fit_lnorm, fit_gamma), legendtext = plot.legend)
dev.off()


# ==============================================================================
# EXPORTAÇÃO DOS RESULTADOS (JSON) PARA O FRONT-END
# ==============================================================================
cat("A exportar resultados para o Front-end...\n")

resultados_json <- list(
  descritiva = list(
    radix = as.list(descritiva[descritiva$Algorithm == "RadixSort", ]),
    std = as.list(descritiva[descritiva$Algorithm == "StdSort", ])
  ),
  inferencia = list(
    ic_radix = list(lower = ic_radix[1], upper = ic_radix[2]),
    one_sample_p = t_one_sample$p.value,
    two_sample_p = t_two_sample$p.value,
    anova_p = p_value_anova
  ),
  modelagem = list(
    assimetria = assimetria,
    curtose = curtose,
    aic_lnorm = fit_lnorm$aic,
    aic_gamma = fit_gamma$aic,
    vencedora = melhor_dist,
    params_lnorm = as.list(fit_lnorm$estimate),
    params_gamma = as.list(fit_gamma$estimate)
  )
)

write_json(resultados_json, "data/outputs/stats_results.json", auto_unbox = TRUE)
cat("Concluído! Verifique a pasta r_analysis/exports e data/outputs/\n")