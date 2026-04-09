# 📘 Aula 08 — Projeto Integrador: Infra Monitor

## Módulo: Administração Linux | Flexxo - Polo Caxias do Sul
**Data:** 08 de Abril de 2026
**Instrutor:** Wiliam
**Formato:** Mentoria 1:1

---

## 🎯 Objetivo da Aula

Construir do zero um sistema de monitoramento de infraestrutura Linux utilizando
Shell Script + MariaDB + Cron, integrando todos os conhecimentos adquiridos nas
aulas anteriores em um projeto funcional e automatizado.

---

## 📐 Visão Geral do Projeto

O **Infra Monitor** é um coletor de métricas do servidor que:

1. Coleta dados de CPU, RAM, Disco, Load Average, Uptime e Processos
2. Classifica o nível de alerta (OK / AVISO / CRITICO)
3. Grava tudo no banco de dados MariaDB
4. Roda automaticamente a cada 5 minutos via Cron

### Arquitetura

```
~/infra-monitor/
├── scripts/
│   ├── funcoes.sh        # Biblioteca de funções de coleta
│   └── coletor.sh        # Script principal (orquestra tudo)
├── logs/
│   └── cron.log          # Log de execução do agendamento
└── sql/
    └── schema.sql        # Estrutura do banco de dados
```

---

## 📦 Parte 1 — Estrutura de Pastas

```bash
mkdir -p ~/infra-monitor/{scripts,logs,sql}
cd ~/infra-monitor
```

---

## 🗄️ Parte 2 — Banco de Dados (MariaDB)

### 2.1 Criação do banco e tabelas

```sql
CREATE DATABASE IF NOT EXISTS infra_monitor
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE infra_monitor;

-- Tabela principal de coletas
CREATE TABLE IF NOT EXISTS coletas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  hostname       VARCHAR(100)   NOT NULL,
  cpu_uso        DECIMAL(5,2)   NOT NULL COMMENT 'Percentual de uso de CPU',
  ram_total_mb   INT            NOT NULL,
  ram_usada_mb   INT            NOT NULL,
  ram_uso_pct    DECIMAL(5,2)   NOT NULL COMMENT 'Percentual de uso de RAM',
  disco_total_gb DECIMAL(10,2)  NOT NULL,
  disco_usado_gb DECIMAL(10,2)  NOT NULL,
  disco_uso_pct  DECIMAL(5,2)   NOT NULL COMMENT 'Percentual de uso de Disco',
  load_1min      DECIMAL(5,2)   NOT NULL,
  load_5min      DECIMAL(5,2)   NOT NULL,
  load_15min     DECIMAL(5,2)   NOT NULL,
  uptime_horas   INT            NOT NULL,
  total_processos INT           NOT NULL,
  nivel_alerta   ENUM('OK','AVISO','CRITICO') DEFAULT 'OK',
  data_coleta    DATETIME       DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabela de monitoramento de serviços
CREATE TABLE IF NOT EXISTS servicos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  coleta_id   INT          NOT NULL,
  nome        VARCHAR(100) NOT NULL,
  status      ENUM('ativo','inativo','erro') NOT NULL,
  data_check  DATETIME     DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (coleta_id) REFERENCES coletas(id)
) ENGINE=InnoDB;

-- Tabela de eventos e alertas
CREATE TABLE IF NOT EXISTS eventos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  coleta_id   INT          NOT NULL,
  tipo        ENUM('info','aviso','critico') NOT NULL,
  mensagem    TEXT         NOT NULL,
  data_evento DATETIME     DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (coleta_id) REFERENCES coletas(id)
) ENGINE=InnoDB;
```

### 2.2 Salvar o schema

```bash
# Copie o SQL acima para o arquivo:
nano ~/infra-monitor/sql/schema.sql

# Para executar:
mysql -u root -p < ~/infra-monitor/sql/schema.sql
```

### 2.3 Criar usuário dedicado para o coletor

```sql
CREATE USER IF NOT EXISTS 'sysadmin'@'localhost' IDENTIFIED BY 'SenhaForte2026!';
GRANT INSERT, SELECT ON infra_monitor.* TO 'sysadmin'@'localhost';
FLUSH PRIVILEGES;
```

> 💡 **Boa prática**: Nunca usar root para aplicações. Criar um usuário com
> permissões mínimas (princípio do menor privilégio).

---

## 🔧 Parte 3 — Biblioteca de Funções (funcoes.sh)

```bash
#!/bin/bash
# ============================================
# INFRA MONITOR - Biblioteca de Funções
# Arquivo: funcoes.sh
# Descrição: Funções reutilizáveis para coleta
#            de métricas do servidor
# ============================================

# --- CPU ---
coletar_cpu() {
    top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'
}

# --- RAM ---
coletar_ram_total() {
    free -m | awk '/Mem:/ {print $2}'
}

coletar_ram_usada() {
    free -m | awk '/Mem:/ {print $3}'
}

coletar_ram_percentual() {
    free -m | awk '/Mem:/ {printf "%.2f", $3/$2 * 100}'
}

# --- DISCO ---
coletar_disco_total() {
    df -BG / | awk 'NR==2 {gsub("G",""); print $2}'
}

coletar_disco_usado() {
    df -BG / | awk 'NR==2 {gsub("G",""); print $3}'
}

coletar_disco_percentual() {
    df / | awk 'NR==2 {gsub("%",""); print $5}'
}

# --- LOAD AVERAGE ---
coletar_load_1() {
    cat /proc/loadavg | awk '{print $1}'
}

coletar_load_5() {
    cat /proc/loadavg | awk '{print $2}'
}

coletar_load_15() {
    cat /proc/loadavg | awk '{print $3}'
}

# --- UPTIME ---
coletar_uptime_horas() {
    awk '{printf "%d", $1/3600}' /proc/uptime
}

# --- PROCESSOS ---
coletar_total_processos() {
    ps aux --no-heading | wc -l
}

# --- NÍVEL DE ALERTA ---
definir_alerta() {
    local cpu=$1
    local ram=$2
    local disco=$3

    # Converte para inteiro para comparação
    cpu_int=${cpu%%.*}
    ram_int=${ram%%.*}
    disco_int=${disco%%.*}

    if [ "$cpu_int" -ge 90 ] || [ "$ram_int" -ge 90 ] || [ "$disco_int" -ge 90 ]; then
        echo 'CRITICO'
    elif [ "$cpu_int" -ge 70 ] || [ "$ram_int" -ge 70 ] || [ "$disco_int" -ge 70 ]; then
        echo 'AVISO'
    else
        echo 'OK'
    fi
}
```

---

## 🚀 Parte 4 — Script Principal (coletor.sh)

```bash
#!/bin/bash
# ============================================
# INFRA MONITOR - Coletor Principal
# Arquivo: coletor.sh
# Descrição: Orquestra a coleta de métricas
#            e grava no banco MariaDB
# ============================================

# Carrega a biblioteca de funções
source $(dirname $0)/funcoes.sh

# --- Configurações do Banco ---
DB_USER="sysadmin"
DB_PASS="SenhaForte2026!"
DB_NAME="infra_monitor"

# --- Coleta de Métricas ---
HOSTNAME=$(hostname)
CPU=$(coletar_cpu)
RAM_TOTAL=$(coletar_ram_total)
RAM_USADA=$(coletar_ram_usada)
RAM_PCT=$(coletar_ram_percentual)
DISCO_TOTAL=$(coletar_disco_total)
DISCO_USADO=$(coletar_disco_usado)
DISCO_PCT=$(coletar_disco_percentual)
LOAD1=$(coletar_load_1)
LOAD5=$(coletar_load_5)
LOAD15=$(coletar_load_15)
UPTIME_H=$(coletar_uptime_horas)
PROCESSOS=$(coletar_total_processos)
ALERTA=$(definir_alerta $CPU $RAM_PCT $DISCO_PCT)

# --- Log da coleta ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Coleta: CPU=${CPU}% | RAM=${RAM_PCT}% | Disco=${DISCO_PCT}% | Alerta=${ALERTA}"

# --- INSERT no banco ---
mysql -u$DB_USER -p$DB_PASS $DB_NAME << EOF
INSERT INTO coletas (
  hostname, cpu_uso,
  ram_total_mb, ram_usada_mb, ram_uso_pct,
  disco_total_gb, disco_usado_gb, disco_uso_pct,
  load_1min, load_5min, load_15min,
  uptime_horas, total_processos, nivel_alerta
) VALUES (
  '$HOSTNAME', $CPU,
  $RAM_TOTAL, $RAM_USADA, $RAM_PCT,
  $DISCO_TOTAL, $DISCO_USADO, $DISCO_PCT,
  $LOAD1, $LOAD5, $LOAD15,
  $UPTIME_H, $PROCESSOS, '$ALERTA'
);
EOF

# --- Verifica se o INSERT foi bem-sucedido ---
if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Coleta gravada com sucesso no banco."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERRO ao gravar no banco!" >&2
fi
```

### Tornar os scripts executáveis

```bash
chmod +x ~/infra-monitor/scripts/coletor.sh
chmod +x ~/infra-monitor/scripts/funcoes.sh
```

---

## ⏰ Parte 5 — Agendamento com Cron

### 5.1 Testar manualmente antes de agendar

```bash
bash ~/infra-monitor/scripts/coletor.sh && echo 'Coletor OK - pronto pra agendar!'
```

### 5.2 Criar o agendamento

```bash
crontab -e
```

Adicionar a seguinte linha:

```cron
# =============================================
# INFRA MONITOR - Coleta automatica a cada 5 min
# Projeto Integrador - Administracao Linux
# =============================================
*/5 * * * * /bin/bash /root/infra-monitor/scripts/coletor.sh >> /root/infra-monitor/logs/cron.log 2>&1
```

> ⚠️ Ajustar o path conforme o usuário. Verificar com `echo $HOME`.

### 5.3 Confirmar o agendamento

```bash
crontab -l
```

### 5.4 Monitorar em tempo real

```bash
# Acompanhar o log do cron
tail -f ~/infra-monitor/logs/cron.log
```

### 5.5 Validar coletas automáticas no banco

```bash
mysql -u sysadmin -p'SenhaForte2026!' -e "
SELECT id, hostname, cpu_uso, ram_uso_pct, disco_uso_pct, nivel_alerta, data_coleta
FROM infra_monitor.coletas
ORDER BY id DESC LIMIT 5;"
```

---

## 📖 Anatomia do Cron — Referência Rápida

```
┌───────────── minuto (0-59)
│ ┌─────────── hora (0-23)
│ │ ┌───────── dia do mês (1-31)
│ │ │ ┌─────── mês (1-12)
│ │ │ │ ┌───── dia da semana (0-7, 0 e 7 = domingo)
│ │ │ │ │
* * * * *  comando
```

### Exemplos úteis

| Expressão | Significado |
|---|---|
| `*/5 * * * *` | A cada 5 minutos |
| `0 * * * *` | A cada hora cheia |
| `0 2 * * *` | Todo dia às 2h da manhã |
| `0 0 * * 0` | Todo domingo à meia-noite |
| `0 6 1 * *` | Dia 1 de cada mês às 6h |

### Comandos úteis do Cron

| Comando | O que faz |
|---|---|
| `crontab -e` | Editar agendamentos |
| `crontab -l` | Listar agendamentos |
| `crontab -r` | Remover todos os agendamentos |
| `systemctl status cron` | Verificar se o serviço cron está rodando |

---

## 🧩 Resumo do Projeto Completo

| Componente | Arquivo | Função |
|---|---|---|
| Biblioteca | `funcoes.sh` | Funções reutilizáveis de coleta (CPU, RAM, Disco, Load, Uptime, Processos) |
| Coletor | `coletor.sh` | Script principal que orquestra coleta e grava no banco |
| Banco de Dados | `schema.sql` | 3 tabelas: `coletas`, `servicos`, `eventos` |
| Agendamento | `crontab` | Execução automática a cada 5 minutos |
| Logs | `cron.log` | Registro de cada execução para auditoria |

---

## 🧠 Conceitos Praticados

- **Shell Script**: variáveis, funções, source, lógica condicional
- **Comandos Linux**: top, free, df, awk, grep, ps, hostname
- **Banco de Dados**: MariaDB, CREATE, INSERT, SELECT, FOREIGN KEY
- **Cron**: agendamento automático e redirecionamento de saída
- **Segurança**: usuário dedicado com permissões mínimas (princípio do menor privilégio)
- **Boas Práticas**: código modular, logs, separação de responsabilidades

---

## 🔮 Conexão com o Mundo Real

Em ambientes de produção (data centers, provedores de nuvem), o monitoramento
automatizado é o **coração da operação**. Ferramentas como Zabbix, Prometheus e
Grafana fazem exatamente o que construímos aqui — coletam métricas em intervalos
regulares e armazenam para análise.

A diferença é que neste projeto, entendemos **cada camada manualmente**:

- Como o dado nasce (comandos Linux)
- Como é processado (Shell Script)
- Como é armazenado (Banco de Dados)
- Como é automatizado (Cron)

Esse ciclo **coletar → processar → gravar → repetir** é exatamente o conceito
de um **pipeline de dados**. No futuro, **plataformas de automação de fluxos**
podem consumir esses mesmos dados via triggers, webhooks e APIs, criando
dashboards inteligentes e alertas em tempo real.

---

## ✅ Status da Aula

| Item | Status |
|---|---|
| Estrutura de pastas | ✅ Concluído |
| Banco de dados e tabelas | ✅ Concluído |
| Biblioteca de funções | ✅ Concluído |
| Script coletor principal | ✅ Concluído |
| Teste manual | ✅ Concluído |
| Agendamento com Cron | ✅ Concluído |
| Validação de coletas automáticas | ✅ Concluído |

---

> 📌 **Próximo passo**: Expandir o projeto com monitoramento de serviços
> (Apache, MariaDB, SSH) e geração de relatórios automáticos.
