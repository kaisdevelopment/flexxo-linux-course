# 🚀 Aula 04: Automação em Escala (Loops e Funções)

Bem-vindo ao laboratório prático de automação! No mundo da Engenharia de Confiabilidade (SRE), nós temos horror a tarefas manuais e repetitivas. Se você precisa fazer a mesma coisa mais de duas vezes, é hora de automatizar.

Nesta aula, vamos dominar o poder da repetição e da organização de código.

> ⚠️ **Atenção:** Antes de iniciar cada Ticket, aguarde o instrutor rodar o comando de preparação do ambiente.

---

## 🟣 Ticket 1: O Backup em Massa (Laço FOR com Arquivos)

**O Cenário:** A empresa vai fazer um *deploy* gigante no sistema esta noite. O Gerente de TI mandou você fazer o backup de todos os 5 arquivos de log que estão na pasta `/tmp/logs_criticos/` antes da atualização começar. O backup consiste em criar uma cópia de cada arquivo adicionando a extensão `.bak` no final (ex: `web.log` vira `web.log.bak`).

**O Problema:** Um analista júnior faria isso digitando o comando `cp` 5 vezes. Mas e se fossem 500 servidores? Você precisa resolver isso em um único script usando o laço `for`.

**Sua Missão:** Crie um script chamado `rotina_backup.sh` que entre na pasta, leia todos os arquivos `.log` e faça a cópia de cada um deles automaticamente.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
#!/bin/bash

PASTA="/tmp/logs_criticos"
echo "🚀 Iniciando rotina de backup em lote..."

for ARQUIVO in $PASTA/*.log; do
    echo "Salvando backup de: $ARQUIVO"
    cp "$ARQUIVO" "$ARQUIVO.bak"
done

echo "✅ Todos os backups foram concluídos com sucesso!"
```

**Conceito SRE (DRY):** O asterisco (`*.log`) é um curinga. O Bash expande isso para uma lista real de arquivos. O `for` pega o primeiro, manipula, e repete. Isso elimina a margem de erro humano.
</details>

---

## 🟢 Ticket 2: O Arquiteto de Ambientes (Laço FOR com Listas)

**O Cenário:** A equipe de Dev está migrando o sistema para microsserviços. Eles abriram um ticket urgente: precisam que você crie as pastas para os 5 novos módulos do sistema (`auth`, `pagamento`, `catalogo`, `carrinho`, `database`) dentro do diretório `/tmp/sistema_core/`.

**O Problema:** Criar um por um com `mkdir` custa tempo e aumenta o risco de erro de digitação entre os ambientes de *Dev*, *QA* e *Produção*.

**Sua Missão:** Crie um script chamado `setup_modulos.sh`. Use o laço `for` para percorrer a lista de palavras (os nomes dos módulos). Para cada módulo, crie a pasta correspondente e imprima uma mensagem na tela.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
#!/bin/bash

BASE_DIR="/tmp/sistema_core"
echo "🏗️ Iniciando a construção da arquitetura de microsserviços..."

for MODULO in auth pagamento catalogo carrinho database; do
    echo "⚙️ Configurando o módulo: $MODULO..."
    mkdir -p "$BASE_DIR/$MODULO"
done

echo "✅ Todos os ambientes foram criados com sucesso!"
```

**Conceito SRE (Infra as Code):** O laço `for` não serve apenas para arquivos. Ele itera sobre qualquer lista de palavras. Ferramentas como Ansible e Terraform usam este exato conceito por baixo dos panos.
</details>

---

## 🟠 Ticket 3: O Guardião da Ordem (Laço WHILE e Healthchecks)

**O Cenário:** Nossa aplicação Web trava quando o servidor é reiniciado porque ela tenta iniciar *antes* do Banco de Dados estar 100% pronto. Quando o Banco finalmente carrega, ele cria um arquivo chamado `/tmp/db_ready.txt` para avisar que está no ar.

**O Problema:** Colocar um `sleep 30` no script é uma má prática. Se o banco subir em 5s, perdemos 25s. Se demorar 40s, a aplicação quebra. Você precisa **monitorar ativamente o estado**.

**Sua Missão:** Crie um script chamado `espera_banco.sh`. Use o laço `while` para verificar se o arquivo `/tmp/db_ready.txt` **NÃO** existe. Enquanto ele não existir, o script deve pausar por 2 segundos. Quando o arquivo aparecer, o loop deve encerrar e iniciar a aplicação.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
#!/bin/bash

ARQUIVO_SINAL="/tmp/db_ready.txt"
echo "🔍 Iniciando Healthcheck do Banco de Dados..."

# Enquanto o arquivo NÃO (!) existir (-f)...
while [ ! -f "$ARQUIVO_SINAL" ]; do
    echo "⏳ Banco de dados ainda não está pronto. Aguardando 2 segundos..."
    sleep 2 # Evita o uso de 100% de CPU (Busy Wait)
done

echo "✅ Arquivo $ARQUIVO_SINAL detectado!"
echo "🚀 Banco de dados ONLINE. Iniciando a aplicação Web agora!"
```

**Conceito SRE (Polling):** O laço `while` é o coração dos sistemas de orquestração. O Kubernetes e o Docker fazem isso nos bastidores (Liveness e Readiness Probes).
</details>

---

## 🔵 Ticket 4: O Padrão Ouro do SRE (Funções e Padronização)

**O Cenário:** A equipe de Segurança reprovou nossos scripts na auditoria. O motivo? Cada script escreve mensagens de log de um jeito diferente, o que quebra a integração com o Datadog e o ElasticSearch. O novo padrão obrigatório é: `[DATA HORA] [NÍVEL] Mensagem`.

**O Problema:** Digitar a captura de data e a formatação inteira a cada linha do script vai poluir o código e gerar erros.

**Sua Missão:** Crie um script chamado `deploy_padronizado.sh`. Nele, crie uma **função** chamada `registrar_log` que receba dois parâmetros: o Nível (INFO, WARN, ERRO) e a Mensagem. Use essa função três vezes para simular eventos de um deploy, salvando tudo no arquivo `/tmp/auditoria/sistema.log`.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
#!/bin/bash

ARQUIVO_LOG="/tmp/auditoria/sistema.log"

# 1. DEFINIÇÃO DA FUNÇÃO
registrar_log() {
    local NIVEL="$1"
    local MENSAGEM="$2"
    local DATA_HORA=$(date +'%Y-%m-%d %H:%M:%S')

    echo "[$DATA_HORA] [$NIVEL] $MENSAGEM" | tee -a "$ARQUIVO_LOG"
}

# 2. USO DA FUNÇÃO
echo "🚀 Iniciando rotina de Deploy..."

registrar_log "INFO" "Baixando a nova versão da aplicação..."
sleep 1
registrar_log "WARN" "Atenção: O servidor de cache está lento."
sleep 1
registrar_log "ERRO" "Falha crítica de conexão com o banco! Abortando."
```

**Conceito SRE (Manutenibilidade):** Se a Segurança pedir para mudar o formato da data amanhã, alteramos uma única linha dentro da função e o script inteiro obedece automaticamente. Nível Sênior!
</details>
