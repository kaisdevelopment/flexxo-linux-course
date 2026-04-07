# 📘 Aula 07 — Logs, Monitoramento Avançado e Introdução a Banco de Dados

## Módulo: Administração Linux | Flexxo - Polo Caxias do Sul
**Data:** 08/04/2026 (Terça-feira) | **Formato:** Aula ao vivo 1:1

---

## 🎯 Objetivo da Aula

Dominar o **sistema de logs do Linux** — onde tudo fica registrado, como investigar problemas e como automatizar a manutenção. Depois, dar o primeiro passo no mundo de **banco de dados**, conectando com tudo que já aprendemos.

---

## PARTE 1 — O SISTEMA DE LOGS DO LINUX

---

### 1. Por que Logs São Tão Importantes?

Imagina que o servidor caiu às 3h da madrugada. Tu não tava lá. Como descobre o que aconteceu? **Pelos logs.** O Linux registra praticamente tudo que acontece — logins, erros, serviços iniciando, pacotes instalados, tentativas de invasão...

Na Aula 06 a gente já usou o `journalctl` pra ver logs de serviços específicos. Hoje vamos aprofundar: entender o sistema completo de logs, onde cada coisa fica guardada, e como automatizar a limpeza.

**Analogia:** os logs são as **câmeras de segurança** do servidor. Quando algo dá errado, tu volta a fita e descobre exatamente o que aconteceu, quando e por quê.

---

### 2. Onde os Logs Ficam?

No Linux, quase todos os logs ficam dentro de um único diretório: `/var/log/`.

```bash
# Listar todos os arquivos de log
# O -lh a gente já conhece: -l formato detalhado, -h tamanhos legíveis
ls -lh /var/log/
```

**Os logs mais importantes:**

| Arquivo | O que registra | Quando usar |
|---|---|---|
| `/var/log/syslog` | Logs gerais do sistema (Debian/Ubuntu) | Primeiro lugar pra olhar quando algo dá errado |
| `/var/log/auth.log` | Autenticação: logins, sudo, SSH | Investigar tentativas de acesso e invasão |
| `/var/log/kern.log` | Mensagens do kernel | Problemas de hardware, drivers, disco |
| `/var/log/dpkg.log` | Instalação/remoção de pacotes | Saber o que foi instalado e quando |
| `/var/log/apt/` | Detalhes das operações do apt | Histórico completo de atualizações |
| `/var/log/cron.log` | Execuções do Cron | Verificar se os agendamentos da Aula 05 rodaram |
| `/var/log/boot.log` | Mensagens da inicialização | Problemas no boot |
| `/var/log/lastlog` | Último login de cada usuário | Auditoria de acessos |
| `/var/log/faillog` | Tentativas de login que falharam | Detectar ataques de força bruta |

Dependendo da distribuição (Debian, Ubuntu, CentOS), alguns nomes podem mudar. Em sistemas Red Hat, por exemplo, o log geral fica em `/var/log/messages` em vez de `syslog`. Mas a lógica é sempre a mesma.

---

### 3. Lendo Logs na Prática

#### 3.1 O log geral do sistema — `syslog`

```bash
# Ver as últimas 30 linhas do syslog
tail -30 /var/log/syslog
```

O `tail` mostra as últimas linhas de um arquivo. Usamos `-30` pra pegar as 30 mais recentes. Lembra que na Aula 06 a gente usou o `journalctl` pra ver logs de um serviço específico? O syslog é o 'jornalão' com tudo misturado.

```bash
# Acompanhar o syslog em tempo real (MUITO útil!)
tail -f /var/log/syslog
```

O `-f` é de 'follow'. O terminal fica aberto e cada nova linha de log aparece na hora. É como assistir as câmeras de segurança ao vivo. `Ctrl+C` pra sair.

**Prática:** abre dois terminais lado a lado:
- Terminal 1: `tail -f /var/log/syslog`
- Terminal 2: faz qualquer coisa (reinicia um serviço, por exemplo)

```bash
# No terminal 2:
sudo systemctl restart cron
```

Olha no terminal 1: apareceu o registro do Cron sendo parado e iniciado. Tudo fica registrado.

#### 3.2 O log de autenticação — `auth.log`

```bash
# Ver tentativas de login
tail -30 /var/log/auth.log
```

```bash
# Filtrar apenas tentativas que falharam (grep da Aula 03!)
grep "Failed" /var/log/auth.log
```

Se aparecer dezenas ou centenas de tentativas de IPs desconhecidos, é alguém tentando invadir via SSH — ataque de força bruta.

```bash
# Contar quantas tentativas falharam
# O -c do grep conta as ocorrências em vez de mostrar as linhas
grep -c "Failed" /var/log/auth.log
```

```bash
# Ver quem logou com sucesso
grep "Accepted" /var/log/auth.log
```

```bash
# Ver os últimos usos do sudo (quem virou root?)
grep "sudo" /var/log/auth.log | tail -20
```

Esse é um comando que equipes de segurança rodam constantemente. 'Quem usou sudo no servidor hoje?' Se alguém usou e não devia, tu sabe na hora.

#### 3.3 O log de pacotes — `dpkg.log`

```bash
# Ver o que foi instalado recentemente
tail -30 /var/log/dpkg.log
```

```bash
# Procurar quando um pacote específico foi instalado
# Lembra do htop da Aula 06? Olha lá no log:
grep "htop" /var/log/dpkg.log
```

---

### 4. O `journalctl` — Revisão e Aprofundamento

Na Aula 06, a gente já usou o `journalctl` pra ver logs de serviços. Agora vamos ver os recursos avançados.

#### 4.1 Revisão rápida (Aula 06)

```bash
# Logs de um serviço
journalctl -u ssh -n 20

# Logs em tempo real
journalctl -u cron -f

# Logs de erros
journalctl -p err --since today
```

#### 4.2 Recursos avançados

```bash
# Logs APENAS do boot atual
journalctl -b

# Logs do boot anterior (servidor reiniciou e quer saber por quê)
journalctl -b -1

# Listar todos os boots registrados
journalctl --list-boots
```

O `-b -1` é ouro quando o servidor reiniciou sozinho. Tu olha os logs do boot anterior e descobre se foi um crash, falta de memória ou alguém que reiniciou.

```bash
# Filtrar por intervalo de tempo
journalctl --since "2026-04-08 08:00" --until "2026-04-08 12:00"

# Filtrar pelo PID de um processo (conectando com Aula 06!)
journalctl _PID=482

# Ver quanto espaço os logs estão ocupando
journalctl --disk-usage
```

```bash
# Logs em formato JSON (pra automação e integração)
journalctl -u ssh -n 5 -o json-pretty
```

O `journalctl` consegue exportar logs em **JSON**. Isso é exatamente o formato que plataformas de automação de fluxos usam pra trocar dados. Quando tu integrar um sistema de monitoramento com alertas automáticos, é esse formato que vai trafegar.

---

### 5. Logrotate — A Faxina Automática dos Logs

Os logs crescem infinitamente. Se ninguém cuidar, eles enchem o disco e o servidor para. O **logrotate** é o faxineiro: ele compacta, rotaciona e apaga logs antigos automaticamente.

#### 5.1 Como funciona

```
  Semana 1     Semana 2     Semana 3     Semana 4     Semana 5
  ─────────    ─────────    ─────────    ─────────    ─────────
  syslog       syslog       syslog       syslog       syslog
               syslog.1     syslog.1     syslog.1     syslog.1
                            syslog.2.gz  syslog.2.gz  syslog.2.gz
                                         syslog.3.gz  syslog.3.gz
                                                      syslog.4.gz
                                                      (← antigos apagados)
```

Cada semana (ou dia, depende da config), o logrotate 'rotaciona': o syslog atual vira syslog.1, o syslog.1 vira syslog.2 e é compactado (.gz), e assim por diante. Logs muito antigos são apagados. Tudo automático.

#### 5.2 Configuração do logrotate

```bash
# Configuração global
cat /etc/logrotate.conf

# Configurações específicas por serviço
ls /etc/logrotate.d/

# Ver a config de um serviço específico
cat /etc/logrotate.d/rsyslog
```

Exemplo de configuração típica:

```
/var/log/syslog {
    rotate 7          # Mantém 7 versões antigas
    daily             # Rotaciona todo dia
    missingok         # Não dá erro se o arquivo não existir
    notifempty        # Não rotaciona se estiver vazio
    compress          # Compacta com gzip
    delaycompress     # Compacta só a partir da 2ª rotação
    postrotate        # Comando executado DEPOIS de rotacionar
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

#### 5.3 Verificando a saúde dos logs

```bash
# Ver o tamanho dos logs (identificar logs gigantes)
# du -sh mostra tamanho, sort -rh ordena do maior pro menor, head -10 mostra os 10 maiores
# Pipe a gente já usa desde a Aula 03!
du -sh /var/log/* | sort -rh | head -10
```

```bash
# Verificar espaço em disco (da Aula 04 — função ver_disco!)
df -h
```

#### 5.4 Testar o logrotate manualmente

```bash
# Simular (dry-run) — mostra o que faria sem fazer
sudo logrotate -d /etc/logrotate.conf

# Forçar execução agora
sudo logrotate -f /etc/logrotate.conf
```

O `-d` (debug/dry-run) é boa prática: primeiro simula pra ver se tá certo, depois executa com `-f`.

---

### 6. Script de Análise de Logs — Juntando Tudo

Um script que analisa os logs e gera um relatório de segurança. Usa funções (Aula 04), pode ser agendado no Cron (Aula 05), e monitora serviços (Aula 06).

```bash
nano ~/sysadmin-tools/analise_logs.sh
```

```bash
#!/bin/bash
# =============================================
# Analisador de Logs - Aula 07
# Gera relatório de segurança e saúde do servidor
# =============================================

# Carrega a biblioteca de funções (Aula 04)
source ~/sysadmin-tools/funcoes.sh

LOG="/tmp/analise_logs_$(date '+%Y%m%d_%H%M').log"

# ---- Cabeçalho ----
echo "==========================================" > "$LOG"
echo " RELATÓRIO DE ANÁLISE DE LOGS" >> "$LOG"
echo " Servidor: $(hostname)" >> "$LOG"
echo " Data: $(date '+%d/%m/%Y %H:%M:%S')" >> "$LOG"
echo "==========================================" >> "$LOG"
echo "" >> "$LOG"

# ---- 1. Segurança: Tentativas de login ----
echo "--- 🔐 SEGURANÇA: AUTENTICAÇÃO ---" >> "$LOG"

if [ -f /var/log/auth.log ]; then
    FALHAS=$(grep -c "Failed" /var/log/auth.log 2>/dev/null || echo "0")
    SUCESSOS=$(grep -c "Accepted" /var/log/auth.log 2>/dev/null || echo "0")
    SUDO_USO=$(grep -c "sudo" /var/log/auth.log 2>/dev/null || echo "0")

    echo "Tentativas de login com falha: $FALHAS" >> "$LOG"
    echo "Logins bem-sucedidos: $SUCESSOS" >> "$LOG"
    echo "Usos do sudo: $SUDO_USO" >> "$LOG"

    echo "" >> "$LOG"
    echo "Top 5 IPs com mais tentativas falhas:" >> "$LOG"
    grep "Failed" /var/log/auth.log 2>/dev/null \
        | grep -oP '\d+\.\d+\.\d+\.\d+' \
        | sort | uniq -c | sort -rn | head -5 >> "$LOG"
else
    echo "Arquivo auth.log não encontrado." >> "$LOG"
fi

echo "" >> "$LOG"

# ---- 2. Saúde: Erros do sistema ----
echo "--- ⚠️  ERROS DO SISTEMA (últimas 24h) ---" >> "$LOG"
journalctl -p err --since "24 hours ago" --no-pager -q 2>/dev/null | tail -20 >> "$LOG"
echo "" >> "$LOG"

# ---- 3. Disco: Espaço ocupado pelos logs ----
echo "--- 💾 ESPAÇO DOS LOGS ---" >> "$LOG"
echo "Tamanho total de /var/log: $(du -sh /var/log 2>/dev/null | cut -f1)" >> "$LOG"
echo "" >> "$LOG"
echo "Top 5 maiores arquivos de log:" >> "$LOG"
du -sh /var/log/* 2>/dev/null | sort -rh | head -5 >> "$LOG"
echo "" >> "$LOG"

# ---- 4. Disco geral (função da Aula 04) ----
echo "--- 💿 ESPAÇO EM DISCO GERAL ---" >> "$LOG"
df -h | grep -E '^/dev/' >> "$LOG"

echo "" >> "$LOG"
ALERTA_DISCO=$(df -h | grep -E '^/dev/' | awk '{gsub("%","",$5); if ($5 > 80) print "⚠️  ALERTA: " $6 " está com " $5 "% de uso!"}')
if [ -n "$ALERTA_DISCO" ]; then
    echo "$ALERTA_DISCO" >> "$LOG"
else
    echo "✅ Nenhuma partição acima de 80%." >> "$LOG"
fi
echo "" >> "$LOG"

# ---- 5. Serviços críticos (Aula 06) ----
echo "--- 🔧 STATUS DOS SERVIÇOS CRÍTICOS ---" >> "$LOG"
for SERVICO in ssh cron mariadb; do
    STATUS=$(systemctl is-active "$SERVICO" 2>/dev/null)
    if [ "$STATUS" = "active" ]; then
        echo "[✅] $SERVICO: ativo" >> "$LOG"
    else
        echo "[❌] $SERVICO: $STATUS" >> "$LOG"
    fi
done
echo "" >> "$LOG"

# ---- 6. Processos (Aula 06) ----
echo "--- 🔍 TOP 5 PROCESSOS POR CPU ---" >> "$LOG"
ps aux --sort=-%cpu | head -6 >> "$LOG"
echo "" >> "$LOG"

echo "--- 🔍 TOP 5 PROCESSOS POR MEMÓRIA ---" >> "$LOG"
ps aux --sort=-%mem | head -6 >> "$LOG"
echo "" >> "$LOG"

# ---- 7. Load average ----
echo "--- 📊 CARGA DO SISTEMA ---" >> "$LOG"
echo "Load average: $(cat /proc/loadavg)" >> "$LOG"
echo "Uptime: $(uptime -p)" >> "$LOG"
echo "" >> "$LOG"

echo "==========================================" >> "$LOG"
echo " Relatório gerado com sucesso" >> "$LOG"
echo "==========================================" >> "$LOG"

cat "$LOG"
```

```bash
chmod +x ~/sysadmin-tools/analise_logs.sh
bash ~/sysadmin-tools/analise_logs.sh
```

**Agendar no Cron (Aula 05):**

```bash
crontab -e
```

```bash
# Análise de logs diária às 7h da manhã
0 7 * * * /bin/bash /home/USUARIO/sysadmin-tools/analise_logs.sh
```

---

## PARTE 2 — INTRODUÇÃO A BANCO DE DADOS

---

### 7. O que é um Banco de Dados?

Até agora, tudo que armazenamos foi em **arquivos de texto**: logs, relatórios, scripts. Funciona bem pra muita coisa, mas e quando precisa guardar milhares de registros de clientes? Ou consultar rapidamente uma informação entre milhões de linhas?

Aí entra o banco de dados: um software especializado em **armazenar, organizar e consultar dados** de forma eficiente e segura.

```
Arquivo de texto (.log, .csv)  →  Um caderno com anotações
Banco de dados                 →  Um arquivo de aço com gavetas
                                   organizadas, indexadas e com
                                   chave (segurança)
```

```
┌────────────────────────────────────────────────────┐
│         ARQUIVO DE TEXTO vs BANCO DE DADOS          │
│                                                     │
│  Arquivo de texto:                                  │
│  ├─ Simples de criar e ler                          │
│  ├─ Sem estrutura fixa                              │
│  ├─ Busca lenta em arquivos grandes                 │
│  └─ Sem controle de acesso granular                 │
│                                                     │
│  Banco de dados:                                    │
│  ├─ Estrutura organizada (tabelas, colunas)         │
│  ├─ Busca extremamente rápida (índices)             │
│  ├─ Controle de acesso por usuário                  │
│  ├─ Transações (tudo ou nada — sem corrompimento)   │
│  └─ Múltiplos acessos simultâneos                   │
└────────────────────────────────────────────────────┘
```

---

### 8. Tipos de Banco de Dados

| Tipo | Exemplos | Quando usar |
|---|---|---|
| **Relacional (SQL)** | MySQL/MariaDB, PostgreSQL, SQLite | Dados estruturados, tabelas com relações, a maioria dos sistemas corporativos |
| **Documento (NoSQL)** | MongoDB, CouchDB | Dados flexíveis, JSON, aplicações web modernas |
| **Chave-valor** | Redis, Memcached | Cache, sessões, dados temporários ultra-rápidos |
| **Colunar** | Cassandra, ClickHouse | Big Data, analytics, milhões de registros |

No nosso curso, vamos focar no **relacional (SQL)** porque é o que 80% das empresas usam, e a linguagem SQL é universal — funciona em qualquer banco relacional.

---

### 9. Instalando o MariaDB

O MariaDB é um fork do MySQL — mesma base, mesmos comandos, 100% compatível.

```bash
# Instalar o MariaDB
sudo apt update
sudo apt install mariadb-server mariadb-client -y
```

```bash
# Verificar se o serviço está rodando (Aula 06!)
systemctl status mariadb
```

O MariaDB é um **serviço**. Roda em background, escutando conexões — exatamente como o SSH e o Cron que vimos na Aula 06.

```bash
# Se não estiver rodando:
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

```bash
# Ver em qual porta está escutando (Aula 06!)
# MySQL/MariaDB escuta na porta 3306 por padrão
ss -tlnp | grep mysql
```

---

### 10. Segurança Inicial do Banco

```bash
# Rodar o assistente de segurança
sudo mysql_secure_installation
```

Respostas recomendadas:

```
Enter current password for root: (Enter, sem senha ainda)
Switch to unix_socket authentication? [Y/n]: Y
Change the root password? [Y/n]: Y
  → Define uma senha forte para o root do banco
Remove anonymous users? [Y/n]: Y
Disallow root login remotely? [Y/n]: Y
Remove test database? [Y/n]: Y
Reload privilege tables now? [Y/n]: Y
```

Isso é **hardening** — fortalecer a segurança. Mesma lógica de segurança Zero Trust: ninguém acessa sem credencial, sem necessidade não libera, e remove tudo que é desnecessário.

---

### 11. Primeiro Contato com o Banco

#### 11.1 Conectando

```bash
# Conectar como root do banco
sudo mysql -u root -p
```

O `-u root` diz 'conecta como usuário root'. O `-p` pede a senha. O prompt muda para:

```
MariaDB [(none)]>
```

A partir daqui, tudo que se digita são **comandos SQL**, não mais comandos Linux. É outro mundo dentro do terminal. Pra sair: `exit`.

**Regra importante:** todo comando SQL termina com **ponto e vírgula** (`;`). Se esqueceu, ele fica esperando na próxima linha. É só digitar `;` e Enter.

#### 11.2 Primeiros comandos SQL

```sql
-- Ver quais bancos de dados existem
SHOW DATABASES;
```

```sql
-- Criar um banco de dados para nossas práticas
CREATE DATABASE lab_linux;

-- Confirmar que foi criado
SHOW DATABASES;

-- Selecionar (entrar) no banco — é como o 'cd' no terminal
USE lab_linux;
```

O prompt muda para:

```
MariaDB [lab_linux]>
```

---

### 12. Criando uma Tabela

Uma tabela no banco é como uma **planilha**: tem colunas (campos) e linhas (registros). Vamos criar uma tabela de servidores — faz sentido pro nosso contexto de SysAdmin.

```sql
CREATE TABLE servidores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    ip VARCHAR(15),
    sistema_operacional VARCHAR(50),
    cpu_cores INT,
    ram_gb INT,
    status VARCHAR(20) DEFAULT 'ativo',
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Decifrando cada parte:**

| Elemento | O que significa |
|---|---|
| `id INT AUTO_INCREMENT PRIMARY KEY` | Número único, incrementa sozinho, é a identidade da linha |
| `nome VARCHAR(100) NOT NULL` | Texto de até 100 caracteres, obrigatório |
| `ip VARCHAR(15)` | Texto de até 15 caracteres (formato de IP) |
| `sistema_operacional VARCHAR(50)` | Texto de até 50 caracteres |
| `cpu_cores INT` | Número inteiro |
| `ram_gb INT` | Número inteiro |
| `status VARCHAR(20) DEFAULT 'ativo'` | Texto com valor padrão 'ativo' |
| `data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Data/hora, preenchida automaticamente |

O `AUTO_INCREMENT` é muito importante: não precisa informar o ID, o banco gera sozinho. E o `DEFAULT` define valores automáticos. Isso é **automação no nível de dados**.

```sql
-- Ver a estrutura da tabela criada
DESCRIBE servidores;
```

---

### 13. Inserindo Dados

```sql
INSERT INTO servidores (nome, ip, sistema_operacional, cpu_cores, ram_gb)
VALUES ('web-server-01', '192.168.1.100', 'Ubuntu 24.04', 4, 8);

INSERT INTO servidores (nome, ip, sistema_operacional, cpu_cores, ram_gb)
VALUES ('db-server-01', '192.168.1.101', 'Debian 12', 8, 32);

INSERT INTO servidores (nome, ip, sistema_operacional, cpu_cores, ram_gb)
VALUES ('backup-server-01', '192.168.1.102', 'Ubuntu 24.04', 2, 4);

INSERT INTO servidores (nome, ip, sistema_operacional, cpu_cores, ram_gb, status)
VALUES ('app-server-01', '192.168.1.103', 'Rocky Linux 9', 16, 64, 'manutencao');
```

Repara: não informamos `id` nem `data_cadastro` — o banco preenche sozinho. No quarto registro definimos status como 'manutencao' — nos outros, ficou 'ativo' pelo DEFAULT.

---

### 14. Consultando Dados — O Comando SELECT

O `SELECT` é o comando mais usado em banco de dados. É ele que **busca** informações.

```sql
-- Buscar TUDO da tabela (é o 'cat' do banco de dados)
SELECT * FROM servidores;
```

O `*` significa 'todas as colunas'. O `FROM` diz de qual tabela.

```sql
-- Buscar apenas nome e IP
SELECT nome, ip FROM servidores;

-- Filtrar com WHERE (é o 'grep' do SQL!)
SELECT * FROM servidores WHERE status = 'ativo';

-- Filtrar por sistema operacional
SELECT nome, ip FROM servidores WHERE sistema_operacional = 'Ubuntu 24.04';

-- Buscar servidores com mais de 4GB de RAM
SELECT nome, ram_gb FROM servidores WHERE ram_gb > 4;

-- Combinar filtros com AND
SELECT nome, ip, ram_gb FROM servidores WHERE status = 'ativo' AND ram_gb >= 8;

-- Ordenar por RAM (do maior pro menor) — é o 'sort' do SQL
SELECT nome, ram_gb FROM servidores ORDER BY ram_gb DESC;

-- Contar quantos servidores existem — é o 'wc -l' do SQL
SELECT COUNT(*) AS total_servidores FROM servidores;

-- Contar servidores por status — é o 'sort | uniq -c' do terminal
SELECT status, COUNT(*) AS quantidade FROM servidores GROUP BY status;

-- Limitar resultado — é o 'head' do SQL
SELECT * FROM servidores LIMIT 2;
```

**Conexão com Linux:**

| SQL | Equivalente Linux | Função |
|---|---|---|
| `SELECT *` | `cat arquivo` | Mostrar tudo |
| `WHERE` | `grep` | Filtrar |
| `ORDER BY` | `sort` | Ordenar |
| `COUNT(*)` | `wc -l` | Contar |
| `LIMIT 5` | `head -5` | Limitar resultado |

No Linux: `cat log | grep erro | sort | head -5`
No SQL: `SELECT * FROM logs WHERE tipo='erro' ORDER BY data LIMIT 5`
A lógica é a mesma: pega dados, filtra, ordena e limita.

---

### 15. Atualizando e Deletando Dados

```sql
-- Atualizar o status de um servidor
UPDATE servidores SET status = 'inativo' WHERE nome = 'backup-server-01';

-- Verificar a alteração
SELECT nome, status FROM servidores;
```

**REGRA DE OURO: nunca roda UPDATE sem WHERE.** Sem WHERE, ele atualiza TODAS as linhas da tabela. É como o `killall` da Aula 06 — mata tudo com aquele nome.

```sql
-- Atualizar múltiplos campos de uma vez
UPDATE servidores SET ram_gb = 16, status = 'ativo' WHERE nome = 'web-server-01';
```

```sql
-- Deletar um registro
DELETE FROM servidores WHERE nome = 'backup-server-01';

-- Verificar
SELECT * FROM servidores;
```

Mesma regra: **nunca roda DELETE sem WHERE.** Um `DELETE FROM servidores` sem WHERE apaga TODOS os registros. Sem Ctrl+Z.

---

### 16. Segunda Tabela — Logs de Monitoramento

Vamos criar uma tabela que registra eventos de monitoramento dos servidores. Aí conectamos as duas tabelas — isso é o poder do banco **relacional**.

```sql
CREATE TABLE monitoramento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    servidor_id INT,
    cpu_uso DECIMAL(5,2),
    ram_uso DECIMAL(5,2),
    disco_uso DECIMAL(5,2),
    status_check VARCHAR(20),
    observacao TEXT,
    data_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (servidor_id) REFERENCES servidores(id)
);
```

O `FOREIGN KEY` é a 'ponte' entre as tabelas. O campo `servidor_id` aponta pro `id` da tabela servidores. Garante que não dá pra registrar monitoramento de um servidor que não existe.

`DECIMAL(5,2)` guarda números com casas decimais — até 999.99. Perfeito pra percentual de uso.

```sql
-- Inserir dados de monitoramento
INSERT INTO monitoramento (servidor_id, cpu_uso, ram_uso, disco_uso, status_check, observacao)
VALUES (1, 23.5, 65.2, 45.0, 'ok', 'Operação normal');

INSERT INTO monitoramento (servidor_id, cpu_uso, ram_uso, disco_uso, status_check, observacao)
VALUES (2, 78.9, 88.1, 72.3, 'alerta', 'RAM acima de 85%');

INSERT INTO monitoramento (servidor_id, cpu_uso, ram_uso, disco_uso, status_check, observacao)
VALUES (1, 95.2, 91.0, 45.1, 'critico', 'CPU e RAM no limite');

INSERT INTO monitoramento (servidor_id, cpu_uso, ram_uso, disco_uso, status_check, observacao)
VALUES (3, 12.0, 30.5, 20.0, 'ok', 'Servidor leve, sem problemas');
```

```sql
SELECT * FROM monitoramento;
```

---

### 17. JOIN — Cruzando Tabelas

O poder de verdade do banco relacional: cruzar dados de duas tabelas numa consulta só.

```sql
-- Monitoramento com o NOME do servidor (em vez de só o ID)
SELECT
    s.nome,
    s.ip,
    m.cpu_uso,
    m.ram_uso,
    m.disco_uso,
    m.status_check,
    m.observacao,
    m.data_check
FROM monitoramento m
JOIN servidores s ON m.servidor_id = s.id;
```

O `JOIN` junta as duas tabelas pelo campo em comum: `servidor_id` = `id`. O `m.` e `s.` são apelidos (alias) pra não repetir o nome inteiro da tabela.

```sql
-- Só os alertas e críticos
SELECT
    s.nome,
    m.cpu_uso,
    m.ram_uso,
    m.status_check,
    m.observacao
FROM monitoramento m
JOIN servidores s ON m.servidor_id = s.id
WHERE m.status_check IN ('alerta', 'critico');
```

O `IN ('alerta', 'critico')` é um atalho pra `status_check = 'alerta' OR status_check = 'critico'`. Mais limpo.

```sql
-- Média de uso de CPU e RAM por servidor
SELECT
    s.nome,
    ROUND(AVG(m.cpu_uso), 1) AS media_cpu,
    ROUND(AVG(m.ram_uso), 1) AS media_ram
FROM monitoramento m
JOIN servidores s ON m.servidor_id = s.id
GROUP BY s.nome;
```

O `AVG()` calcula a média, o `ROUND(,1)` arredonda pra 1 casa decimal, e o `GROUP BY` agrupa por servidor.

---

### 18. Criando um Usuário Seguro pro Banco

Mesmo princípio das permissões da Aula 03: nunca usa root pra tudo.

```sql
-- Criar usuário
CREATE USER 'sysadmin'@'localhost' IDENTIFIED BY 'SenhaForte2026!';

-- Dar permissão só no nosso banco
GRANT ALL PRIVILEGES ON lab_linux.* TO 'sysadmin'@'localhost';

-- Aplicar
FLUSH PRIVILEGES;

-- Verificar
SELECT user, host FROM mysql.user;

exit
```

**Testar com o novo usuário:**

```bash
mysql -u sysadmin -p lab_linux
```

```sql
SELECT * FROM servidores;
SELECT * FROM monitoramento;
```

Esse usuário tem acesso total ao `lab_linux` mas não consegue tocar nos outros bancos. Princípio do **menor privilégio** — mesma filosofia de `chmod` da Aula 03.

---

### 19. SQL Direto do Terminal — Integração com Bash

Dá pra executar SQL direto do terminal Linux, sem entrar no prompt do MySQL. Essencial pra automação.

```bash
# Consulta direto do terminal
mysql -u sysadmin -p'SenhaForte2026!' -e "SELECT nome, ip, status FROM lab_linux.servidores;"
```

O `-e` executa o SQL e volta pro terminal. Perfeito pra usar dentro de scripts.

```bash
# Sem cabeçalho (pra usar em variáveis)
mysql -u sysadmin -p'SenhaForte2026!' -N -e "SELECT COUNT(*) FROM lab_linux.servidores WHERE status='ativo';"
```

O `-N` tira o nome da coluna. Só retorna o número.

```bash
# Guardando em variável do bash e tomando decisão
ATIVOS=$(mysql -u sysadmin -p'SenhaForte2026!' -N -e "SELECT COUNT(*) FROM lab_linux.servidores WHERE status='ativo';")
echo "Servidores ativos: $ATIVOS"

if [ "$ATIVOS" -lt 3 ]; then
    echo "⚠️  ALERTA: Menos de 3 servidores ativos!"
fi
```

Olha a conexão: bash (Aula 01 ao 05) + banco de dados (Aula 07) trabalhando juntos. Shell Script consultando banco e tomando decisão. Isso é o tipo de lógica que roda por trás de toda plataforma de automação de fluxos.

---

### 20. Backup do Banco de Dados

Banco sem backup é bomba-relógio. O MariaDB tem um comando nativo pra isso.

```bash
# Backup de um banco específico
mysqldump -u sysadmin -p'SenhaForte2026!' lab_linux > ~/sysadmin-tools/backup_lab_linux.sql
```

```bash
# Ver o que foi gerado
cat ~/sysadmin-tools/backup_lab_linux.sql
```

O arquivo `.sql` contém todos os comandos CREATE TABLE e INSERT pra recriar o banco do zero.

```bash
# Backup de TODOS os bancos
mysqldump -u root -p --all-databases > ~/sysadmin-tools/backup_todos_bancos.sql
```

```bash
# Restaurar um backup
mysql -u root -p lab_linux < ~/sysadmin-tools/backup_lab_linux.sql
```

**Automatizar backup com Cron (Aula 05):**

```bash
crontab -e
```

```bash
# Backup do banco todo dia às 2h da manhã
0 2 * * * mysqldump -u sysadmin -p'SenhaForte2026!' lab_linux > /home/USUARIO/sysadmin-tools/backup_lab_$(date +\%Y\%m\%d).sql
```

Tudo se conecta: banco de dados (hoje) + Cron (Aula 05) + arquivos (Aula 02).

---

### 21. O MariaDB como Serviço — Monitoramento Completo

Juntando Aula 06 + Aula 07:

```bash
# Status do serviço (Aula 06)
systemctl status mariadb

# Logs do banco (Aula 06 + 07)
journalctl -u mariadb -n 20

# Acompanhar em tempo real
journalctl -u mariadb -f

# Ver porta e conexões (Aula 06)
ss -tlnp | grep 3306

# Ver processos do MySQL (Aula 06)
ps aux | grep mysql
```

---

## Resumo Visual — Mapa Completo da Aula 07

```
┌──────────────────────────────────────────────────────────────┐
│                       AULA 07                                │
│          Logs, Monitoramento e Banco de Dados                │
├──────────────────────────┬───────────────────────────────────┤
│                          │                                    │
│  LOGS                    │  BANCO DE DADOS (MariaDB/SQL)     │
│  ────                    │  ──────────────────────────        │
│  /var/log/syslog         │  CREATE DATABASE / USE             │
│  /var/log/auth.log       │  CREATE TABLE                     │
│  /var/log/dpkg.log       │  INSERT INTO                      │
│  tail -f (tempo real)    │  SELECT * FROM ... WHERE          │
│  grep (filtrar)          │  UPDATE ... SET ... WHERE          │
│  journalctl avançado     │  DELETE FROM ... WHERE             │
│  logrotate (faxina)      │  JOIN (cruzar tabelas)            │
│                          │  mysqldump (backup)                │
│  SCRIPT:                 │  mysql -e (SQL via bash)          │
│  analise_logs.sh         │                                    │
│                          │                                    │
├──────────────────────────┴───────────────────────────────────┤
│                                                               │
│  🔗 CONEXÕES COM AULAS ANTERIORES:                           │
│  ├─ grep, tail, pipe, sort, wc (Aulas 01-03)                │
│  ├─ Funções e source (Aula 04)                               │
│  ├─ Cron para agendar análise e backup (Aula 05)             │
│  ├─ systemctl, journalctl, ss, ps (Aula 06)                 │
│  └─ Permissões e menor privilégio (Aula 03)                  │
│                                                               │
│  🔗 CONEXÃO COM AUTOMAÇÃO:                                   │
│  ├─ JSON nos logs → formato de troca de dados em APIs        │
│  ├─ SQL via bash → base pra integração script + banco        │
│  ├─ Backup automatizado → pipeline de dados                  │
│  └─ Tudo converge pra plataformas de automação de fluxos     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Registro de Aula

```
============================================================
 AULA 07 - LOGS, MONITORAMENTO AVANÇADO E BANCO DE DADOS
 Flexxo - Polo Caxias do Sul
 Módulo: Administração Linux
 Data: 08/04/2026
============================================================

OBJETIVOS ALCANÇADOS:
---------------------
[x] Entender o sistema de logs do Linux (/var/log/)
[x] Ler e filtrar logs com tail, grep, journalctl
[x] Acompanhar logs em tempo real (tail -f)
[x] Analisar auth.log para segurança (logins, sudo, ataques)
[x] Entender e configurar o logrotate
[x] Criar script de análise de logs automatizado
[x] Entender o conceito de banco de dados relacional
[x] Instalar e configurar o MariaDB
[x] Hardening do banco (mysql_secure_installation)
[x] Criar banco, tabelas e inserir dados (SQL)
[x] Consultar com SELECT, WHERE, ORDER BY, COUNT, GROUP BY
[x] Atualizar (UPDATE) e deletar (DELETE) com segurança
[x] Relacionar tabelas com FOREIGN KEY e JOIN
[x] Criar usuário do banco com permissões limitadas
[x] Executar SQL via bash (mysql -e)
[x] Fazer backup com mysqldump
[x] Automatizar backup no Cron

COMANDOS NOVOS - LOGS:
----------------------
tail -30 arquivo         -> Últimas 30 linhas
tail -f arquivo          -> Acompanhar em tempo real
grep -c "padrão" arq    -> Contar ocorrências
journalctl -b            -> Logs do boot atual
journalctl -b -1         -> Logs do boot anterior
journalctl --list-boots  -> Listar boots registrados
journalctl --disk-usage  -> Espaço usado pelos logs
journalctl -o json-pretty -> Saída em JSON
du -sh /var/log/*        -> Tamanho dos logs
logrotate -d config      -> Simular rotação (dry-run)
logrotate -f config      -> Forçar rotação

COMANDOS NOVOS - BANCO DE DADOS:
---------------------------------
sudo mysql -u root -p              -> Conectar ao banco
mysql_secure_installation          -> Hardening inicial
SHOW DATABASES;                    -> Listar bancos
CREATE DATABASE nome;              -> Criar banco
USE nome;                          -> Entrar no banco
SHOW TABLES;                       -> Listar tabelas
CREATE TABLE nome (...);           -> Criar tabela
DESCRIBE tabela;                   -> Ver estrutura
INSERT INTO tabela VALUES (...);   -> Inserir dados
SELECT * FROM tabela;              -> Consultar tudo
SELECT ... WHERE condição;         -> Filtrar
SELECT ... ORDER BY coluna;        -> Ordenar
SELECT COUNT(*) FROM tabela;       -> Contar
SELECT ... GROUP BY coluna;        -> Agrupar
SELECT ... LIMIT N;                -> Limitar resultado
UPDATE tabela SET ... WHERE ...;   -> Atualizar
DELETE FROM tabela WHERE ...;      -> Deletar
JOIN tabela ON campo = campo;      -> Cruzar tabelas
CREATE USER 'user'@'host' ...;    -> Criar usuário
GRANT ALL ON banco.* TO 'user';   -> Dar permissões
FLUSH PRIVILEGES;                  -> Aplicar permissões
mysqldump -u user -p banco > arq  -> Backup
mysql -u user -p banco < arq      -> Restaurar
mysql -u user -p -e "SQL"         -> SQL via terminal
mysql -u user -p -N -e "SQL"      -> SQL sem cabeçalho

ARQUIVOS CRIADOS/MODIFICADOS:
-----------------------------
~/sysadmin-tools/analise_logs.sh          -> Script de análise de logs
~/sysadmin-tools/backup_lab_linux.sql     -> Backup do banco de dados

PROGRESSO DO CURSO:
-------------------
Aula 01 [██████████] Terminal e navegação
Aula 02 [██████████] Arquivos e diretórios
Aula 03 [██████████] Permissões, usuários, grupos
Aula 04 [██████████] Funções no Shell (básicas + avançadas)
Aula 05 [██████████] Agendamento de tarefas (Cron)
Aula 06 [██████████] Processos, Serviços e Redes
Aula 07 [██████████] Logs, Monitoramento e Banco de Dados ← HOJE
Aula 08 [░░░░░░░░░░] Projeto Integrador Final

CONEXÃO COM AUTOMAÇÃO:
-----------------------
→ Logs em JSON (journalctl -o json) = formato de APIs
→ SQL via bash = integração entre script e banco
→ Backup automatizado = pipeline de dados
→ Plataformas de automação de fluxos consultam bancos via SQL
→ Webhooks disparam baseado em dados do banco
→ Todo monitoramento profissional passa por logs + banco

PRÓXIMA AULA (ÚLTIMA):
-----------------------
Aula 08 - Projeto Integrador Final
(Unir TUDO: Terminal + Permissões + Scripts + Cron + Serviços
 + Logs + Banco de Dados em um sistema completo de gestão)

============================================================
```
