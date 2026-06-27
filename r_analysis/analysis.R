# ==============================================================================
# TRABALHO INTEGRADO DE ESTATÍSTICA APLICADA
# Radix Sort (LSB) vs std::sort — Análise Completa
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(moments)
  library(fitdistrplus)
  library(jsonlite)
})

cat("Iniciando análise estatística completa...\n")

# Diretórios de saída
dir.create("r_analysis/exports", showWarnings = FALSE, recursive = TRUE)
dir.create("data/outputs",       showWarnings = FALSE, recursive = TRUE)

# Carregamento
dados <- read.csv("data/outputs/benchmark_results.csv")

# ==============================================================================
# SEÇÃO 5 — ESTATÍSTICA DESCRITIVA
# ==============================================================================
cat("Calculando estatísticas descritivas...\n")

get_mode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

descritiva <- dados %>%
  group_by(Algorithm) %>%
  summarise(
    Media         = mean(Time_us),
    Mediana       = median(Time_us),
    Moda          = get_mode(Time_us),
    Desvio_Padrao = sd(Time_us),
    Variancia     = var(Time_us),
    Coef_Variacao = (sd(Time_us) / mean(Time_us)) * 100,
    Q1            = quantile(Time_us, 0.25),
    Q3            = quantile(Time_us, 0.75),
    IQR           = IQR(Time_us),
    Min           = min(Time_us),
    Max           = max(Time_us),
    .groups       = "drop"
  )

print(descritiva)

# --- Gráfico 1: Boxplot com escala log ---
g_box <- ggplot(dados, aes(x = Algorithm, y = Time_us, fill = Algorithm)) +
  geom_boxplot(alpha = 0.75, outlier.colour = "#ef4444",
               outlier.shape = 16, outlier.size = 2.5) +
  scale_y_log10(labels = scales::comma) +
  scale_fill_manual(values = c("RadixSort" = "#8b5cf6", "StdSort" = "#0ea5e9")) +
  labs(
    title    = "Dispersão dos Tempos de Execução",
    subtitle = "Escala log₁₀ — pontos vermelhos são outliers",
    x = "Algoritmo", y = "Tempo (µs) — escala log"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")
ggsave("r_analysis/exports/boxplot_descritiva.png", plot = g_box,
       width = 8, height = 5, dpi = 150)

# --- Gráfico 2: Densidade ---
g_dens <- ggplot(dados, aes(x = Time_us, fill = Algorithm)) +
  geom_density(alpha = 0.55) +
  scale_x_log10(labels = scales::comma) +
  scale_fill_manual(values = c("RadixSort" = "#8b5cf6", "StdSort" = "#0ea5e9")) +
  labs(
    title    = "Densidade dos Tempos de Execução",
    subtitle = "Escala log₁₀ — assimetria positiva visível",
    x = "Tempo (µs) — escala log", y = "Densidade"
  ) +
  theme_minimal(base_size = 13)
ggsave("r_analysis/exports/densidade_descritiva.png", plot = g_dens,
       width = 8, height = 5, dpi = 150)

# --- Gráfico 3: Histograma (NOVO — obrigatório pelo PDF) ---
g_hist <- ggplot(dados, aes(x = Time_us, fill = Algorithm)) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity", color = "white") +
  scale_x_log10(labels = scales::comma) +
  scale_fill_manual(values = c("RadixSort" = "#8b5cf6", "StdSort" = "#0ea5e9")) +
  facet_wrap(~Algorithm, ncol = 1, scales = "free_y") +
  labs(
    title    = "Histograma dos Tempos de Execução",
    subtitle = "Escala log₁₀ — cada algoritmo em painel separado",
    x = "Tempo (µs) — escala log", y = "Frequência"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")
ggsave("r_analysis/exports/histograma_descritiva.png", plot = g_hist,
       width = 8, height = 7, dpi = 150)

# --- Gráfico 4: Tempo vs Tamanho por distribuição ---
g_scatter <- ggplot(dados, aes(x = ArraySize, y = Time_us,
                                color = Algorithm, shape = Distribution)) +
  geom_point(alpha = 0.7, size = 2.5) +
  geom_smooth(aes(group = Algorithm), method = "loess",
              se = FALSE, linewidth = 1.2) +
  scale_color_manual(values = c("RadixSort" = "#8b5cf6", "StdSort" = "#0ea5e9")) +
  scale_x_continuous(labels = scales::comma) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title    = "Crescimento do Tempo vs Tamanho do Array",
    subtitle = "Divergência cresce rapidamente — confirma complexidades distintas",
    x = "Tamanho do Array (N)", y = "Tempo (µs)"
  ) +
  theme_minimal(base_size = 13)
ggsave("r_analysis/exports/scatter_tamanho.png", plot = g_scatter,
       width = 9, height = 5, dpi = 150)

# ==============================================================================
# SEÇÃO 6 — INFERÊNCIA ESTATÍSTICA
# ==============================================================================
cat("Realizando inferências...\n")

radix_data <- dados %>% filter(Algorithm == "RadixSort")
std_data   <- dados %>% filter(Algorithm == "StdSort")

# 6.1 Intervalo de Confiança 95% para a média do Radix Sort
ic_obj   <- t.test(radix_data$Time_us)
ic_radix <- ic_obj$conf.int

# 6.3a Teste t de uma amostra (H0: média = 200 µs)
t_one_sample <- t.test(radix_data$Time_us, mu = 200)

# 6.3b Wilcoxon pareado — Radix vs StdSort
t_two_sample <- wilcox.test(radix_data$Time_us, std_data$Time_us,
                             paired = TRUE, alternative = "less")

# 6.3c ANOVA — efeito da distribuição inicial no Radix Sort
anova_radix   <- aov(Time_us ~ Distribution, data = radix_data)
anova_summary <- summary(anova_radix)
p_value_anova <- anova_summary[[1]][["Pr(>F)"]][1]
f_value_anova <- anova_summary[[1]][["F value"]][1]

cat(sprintf("IC 95%% Radix: [%.2f, %.2f]\n", ic_radix[1], ic_radix[2]))
cat(sprintf("T-test p-value: %.6f\n", t_one_sample$p.value))
cat(sprintf("Wilcoxon p-value: %e\n",  t_two_sample$p.value))
cat(sprintf("ANOVA p-value: %.6f | F: %.3f\n", p_value_anova, f_value_anova))

# ==============================================================================
# SEÇÃO 7 — MODELAGEM DE DISTRIBUIÇÕES DE PROBABILIDADE
# ==============================================================================
cat("Ajustando distribuições por MLE...\n")

dados_modelagem <- radix_data %>%
  filter(Distribution == "random") %>%
  pull(Time_us)

# 7.2 Características preliminares
assimetria <- skewness(dados_modelagem)
curtose    <- kurtosis(dados_modelagem)

# 7.4 Ajuste MLE
fit_lnorm <- fitdist(dados_modelagem, "lnorm")

m_est     <- mean(dados_modelagem)
v_est     <- var(dados_modelagem)
shape_est <- (m_est^2) / v_est
rate_est  <- m_est  / v_est
fit_gamma <- fitdist(dados_modelagem, "gamma",
                     start = list(shape = shape_est, rate = rate_est),
                     lower = c(1e-10, 1e-10))

# 7.5 Comparação AIC
melhor_aic  <- min(fit_lnorm$aic, fit_gamma$aic)
melhor_dist <- ifelse(fit_lnorm$aic == melhor_aic, "Log-Normal", "Gamma")

cat(sprintf("AIC Log-Normal: %.2f | AIC Gamma: %.2f | Vencedora: %s\n",
            fit_lnorm$aic, fit_gamma$aic, melhor_dist))

# 7.8 Probabilidades relevantes usando a distribuição vencedora
if (melhor_dist == "Log-Normal") {
  mu_ln  <- fit_lnorm$estimate["meanlog"]
  sd_ln  <- fit_lnorm$estimate["sdlog"]
  # P(X > 500 µs) — pior cenário para array aleatório grande
  prob_gt_500  <- 1 - plnorm(500,  mu_ln, sd_ln)
  # P(X < 100 µs) — execução rápida
  prob_lt_100  <- plnorm(100,  mu_ln, sd_ln)
  # P(100 < X < 500) — faixa típica
  prob_range   <- plnorm(500, mu_ln, sd_ln) - plnorm(100, mu_ln, sd_ln)
  # Percentil 90 (tempo máximo em 90% dos casos)
  perc90       <- qlnorm(0.90, mu_ln, sd_ln)
} else {
  sh <- fit_gamma$estimate["shape"]
  rt <- fit_gamma$estimate["rate"]
  prob_gt_500  <- 1 - pgamma(500,  sh, rt)
  prob_lt_100  <- pgamma(100,  sh, rt)
  prob_range   <- pgamma(500, sh, rt) - pgamma(100, sh, rt)
  perc90       <- qgamma(0.90, sh, rt)
}

cat(sprintf("P(X > 500µs) = %.4f | P(X < 100µs) = %.4f | P90 = %.1fµs\n",
            prob_gt_500, prob_lt_100, perc90))

# --- Gráfico ajuste de distribuições ---
png("r_analysis/exports/ajuste_distribuicoes.png",
    width = 900, height = 700, res = 110)
par(mfrow = c(2, 2))
denscomp(list(fit_lnorm, fit_gamma), legendtext = c("Log-Normal", "Gamma"),
         main = "Comparação de Densidade")
qqcomp(list(fit_lnorm, fit_gamma),   legendtext = c("Log-Normal", "Gamma"),
         main = "Q-Q Plot")
cdfcomp(list(fit_lnorm, fit_gamma),  legendtext = c("Log-Normal", "Gamma"),
         main = "Função Dist. Acumulada")
ppcomp(list(fit_lnorm, fit_gamma),   legendtext = c("Log-Normal", "Gamma"),
         main = "P-P Plot")
dev.off()

# ==============================================================================
# EXPORTAÇÃO JSON
# ==============================================================================
cat("Exportando resultados para JSON...\n")

resultados_json <- list(
  descritiva = list(
    radix = as.list(descritiva[descritiva$Algorithm == "RadixSort", ]),
    std   = as.list(descritiva[descritiva$Algorithm == "StdSort",   ])
  ),
  inferencia = list(
    ic_radix      = list(lower = ic_radix[1], upper = ic_radix[2]),
    one_sample_p  = t_one_sample$p.value,
    one_sample_t  = t_one_sample$statistic,
    one_sample_df = t_one_sample$parameter,
    two_sample_p  = t_two_sample$p.value,
    anova_p       = p_value_anova,
    anova_f       = f_value_anova
  ),
  modelagem = list(
    assimetria   = assimetria,
    curtose      = curtose,
    aic_lnorm    = fit_lnorm$aic,
    aic_gamma    = fit_gamma$aic,
    vencedora    = melhor_dist,
    params_lnorm = as.list(fit_lnorm$estimate),
    params_gamma = as.list(fit_gamma$estimate),
    probabilidades = list(
      prob_gt_500 = prob_gt_500,
      prob_lt_100 = prob_lt_100,
      prob_range  = prob_range,
      perc90      = perc90
    )
  )
)

write_json(resultados_json, "data/outputs/stats_results.json", auto_unbox = TRUE)
cat("Concluído! Verifique r_analysis/exports/ e data/outputs/\n")