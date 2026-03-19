# Aula 03 — Shell Script: Fundamentos

## A linguagem nativa da infraestrutura

| Informação | Detalhe |
|------------|---------|
| **Módulo** | 2 — Automação com Shell Script |
| **Duração** | ~2h (teoria) + laboratório |
| **Pré-requisito** | Aulas 01 e 02 concluídas (terminal, permissões, troubleshooting) |
| **Objetivo** | Entender o mindset de automação e escrever scripts que validam, decidem e se protegem |

---

## 1. A Filosofia da Automação (Mindset SRE)

### De digitador de comandos a engenheiro de infraestrutura

Nas Aulas 01 e 02, você aprendeu a **falar** com o Linux — digitar comandos, interpretar saídas, resolver problemas em tempo real. Isso é essencial e nunca vai perder valor.

Mas existe uma diferença brutal entre dois perfis no mercado:

| Perfil | O que faz | Como o mercado enxerga |
|--------|-----------|----------------------|
| **Operador** | Digita comandos manualmente, um por um, servidor por servidor | Mão de obra substituível |
| **Engenheiro de Infraestrutura (SRE)** | Escreve rotinas que executam, validam e reportam sozinhas | Profissional estratégico |

A diferença entre um e outro não é talento — é **mentalidade**. O engenheiro pensa:

> *"Se eu fiz isso manualmente uma vez, na segunda vez já deveria ser um script."*

Esse é o princípio **Toil Elimination** (eliminação de trabalho repetitivo), um dos pilares da cultura SRE (Site Reliability Engineering) praticada em empresas como Google, Mercado Livre e Nubank.

**Shell Script é a ferramenta mais direta para essa transformação.** É um arquivo de texto puro contendo comandos que o Linux lê e executa de cima para baixo — como uma receita que o sistema segue sem precisar de você.

### O Shebang: a primeira linha de todo script

Todo script profissional começa com esta linha:

```bash
#!/bin/bash
```

Essa linha se chama **shebang** (ou hashbang). Ela **não é um comentário**. É uma instrução direta para o kernel Linux:

> *"Kernel, use o interpretador `/bin/bash` para executar este arquivo."*

Sem ela, o sistema não sabe **qual programa** deve interpretar o seu arquivo. Pode parecer que funciona sem o shebang em testes simples, mas em ambientes corporativos — onde scripts são disparados por cronjobs, por outros scripts ou por plataformas de automação de fluxos — a ausência do shebang causa falhas silenciosas e imprevisíveis.

```bash
#!/bin/bash
# ↑ Linha 1: OBRIGATÓRIA — instrução para o kernel
# ↑ Linha 2: Comentário normal (ignorado na execução)

echo "Script iniciado com sucesso."
```

> **🔒 Atenção (Zero Trust):** Um script sem shebang é um script ambíguo. Em segurança, ambiguidade é vulnerabilidade. O shebang é a sua **declaração explícita de intenção** — e no mundo Zero Trust, tudo deve ser explícito.

### Os três passos para executar qualquer script

Esses três passos vão se repetir centenas de vezes na sua carreira. Decore-os como decorou seu primeiro comando `ls`:

```bash
# 1. CRIAR o arquivo
nano meu-script.sh

# 2. DAR PERMISSÃO de execução
chmod +x meu-script.sh

# 3. EXECUTAR
./meu-script.sh
```

Perceba que o passo 2 é uma exigência do modelo de permissões Linux que você já conhece da Aula 01. Sem o `chmod +x`, o sistema **recusa** a execução:

```
bash: ./meu-script.sh: Permission denied
```

Isso não é um bug — é o Linux operando em modo Zero Trust: **nada executa sem permissão explícita**.

---

## 2. Variáveis de Ambiente Mágicas

### O Linux já entrega informações de bandeja

Antes de você criar suas próprias variáveis, precisa saber que o Linux já mantém dezenas de variáveis prontas, atualizadas automaticamente e disponíveis para qualquer script. São as **variáveis de ambiente**.

Pense nelas como **sensores de um painel de controle**: você não precisa instalar nada, eles já estão lá monitorando e expondo dados do sistema.

```bash
echo $USER        # Quem está executando o script
echo $HOSTNAME    # Nome da máquina
echo $HOME        # Diretório home do usuário
echo $PWD         # Diretório atual
echo $SHELL       # Shell em uso
echo $PATH        # Onde o Linux procura executáveis
```

### Por que isso importa para automação?

Porque com variáveis de ambiente, você escreve **um único script** que funciona em qualquer servidor, sem alteração.

Exemplo — um script **frágil** (hardcoded):

```bash
#!/bin/bash
# ❌ ERRADO: valores fixos, só funciona nesta máquina
echo "Relatório do servidor srv-web-01"
echo "Usuário: kais"
echo "Home: /home/kais"
```

Exemplo — um script **resiliente** (usando variáveis de ambiente):

```bash
#!/bin/bash
# ✅ CORRETO: se adapta a qualquer servidor automaticamente
echo "Relatório do servidor $HOSTNAME"
echo "Usuário: $USER"
echo "Home: $HOME"
```

O segundo script funciona igual no seu WSL, em um servidor de produção na AWS ou em um container Docker — sem mudar uma vírgula.

> **💡 Dica de Mercado:** Em data centers corporativos, o mesmo script roda em dezenas ou centenas de servidores diferentes. Scripts com valores fixos ("hardcoded") são a primeira causa de falhas em deploy automatizado. **Use variáveis de ambiente. Sempre.**

### Criando suas próprias variáveis

A sintaxe é simples, mas tem uma regra de ouro — **sem espaços ao redor do `=`**:

```bash
#!/bin/bash

# ✅ CORRETO
SERVIDOR="srv-db-01"
PORTA=5432
LOG_DIR="/var/log/app"

# ❌ ERRADO — o bash interpreta como comando + argumentos
SERVIDOR = "srv-db-01"
# bash: SERVIDOR: command not found
```

Para **usar** uma variável, prefixe com `$`:

```bash
echo "Conectando em $SERVIDOR na porta $PORTA..."
echo "Logs em: $LOG_DIR"
```

> **💡 Dica de Mercado:** A convenção corporativa é usar **MAIÚSCULAS** para variáveis de ambiente e constantes, e **minúsculas** para variáveis locais de funções. Isso não é regra do bash — é disciplina de equipe.

---

## 3. Parâmetros de Entrada ($1, $2)

### Scripts que recebem dados de quem os chama

Um script verdadeiramente útil não pede dados interativamente — ele **recebe parâmetros** na hora da execução.

Quando você executa:

```bash
./checar-servico.sh nginx 80
```

O bash automaticamente cria variáveis especiais:

| Variável | Conteúdo | Descrição |
|----------|----------|-----------|
| `$0` | `./checar-servico.sh` | Nome do próprio script |
| `$1` | `nginx` | Primeiro parâmetro |
| `$2` | `80` | Segundo parâmetro |
| `$3` | *(vazio)* | Terceiro parâmetro (não informado) |
| `$#` | `2` | Quantidade total de parâmetros |
| `$@` | `nginx 80` | Todos os parâmetros juntos |

Exemplo prático:

```bash
#!/bin/bash
# checar-servico.sh — Verifica se um serviço está escutando em uma porta
# Uso: ./checar-servico.sh <servico> <porta>

SERVICO=$1
PORTA=$2

echo "Verificando se $SERVICO está na porta $PORTA..."
ss -tlnp | grep ":$PORTA " && echo "✅ Ativo" || echo "❌ Inativo"
```

> **💡 Dica de Mercado:** Em ambientes corporativos, scripts são chamados por outros scripts, por cronjobs agendados ou por plataformas de automação de fluxos. Nenhum desses vai "sentar no terminal e digitar uma resposta" quando o script perguntar algo com `read`. Por isso, **parâmetros posicionais ($1, $2) são o padrão do mercado**. O `read` interativo fica reservado para ferramentas de uso pessoal.

### O perigo mortal de variáveis vazias — Conceito "Fail Fast"

O que acontece se alguém executar seu script **sem passar os parâmetros**?

```bash
./checar-servico.sh
# Sem $1 e $2, o script roda com variáveis VAZIAS
# O grep busca ":" em tudo — resultado imprevisível
```

No melhor caso, o script dá resultado errado. No pior caso, em scripts de manutenção com `rm` ou `mv`, variáveis vazias podem causar **destruição de dados**.

Exemplo clássico de desastre:

```bash
#!/bin/bash
# Script para limpar diretório temporário
DIRETORIO=$1
rm -rf $DIRETORIO/*

# Se $1 estiver vazio, o comando vira:
# rm -rf /*
# ↑ APAGA O SISTEMA INTEIRO
```

A solução é o princípio **Fail Fast** (falhar rápido e seguro): **antes de fazer qualquer coisa, valide se recebeu o que precisa. Se não recebeu, pare imediatamente.**

```bash
#!/bin/bash

if [ -z "$1" ]; then
    echo "❌ ERRO: Informe o diretório como parâmetro."
    echo "Uso: $0 <diretorio>"
    exit 1
fi

DIRETORIO=$1
echo "Limpando $DIRETORIO..."
rm -rf "${DIRETORIO:?ERRO - variável vazia}"/*
```

Dois mecanismos de proteção nesse exemplo:

| Mecanismo | O que faz |
|-----------|-----------|
| `if [ -z "$1" ]` | Testa se o parâmetro está vazio **antes** de usá-lo |
| `${DIRETORIO:?ERRO}` | Se a variável estiver vazia na hora do uso, **aborta o script** com mensagem de erro |

> **🔒 Atenção (Zero Trust):** No modelo Zero Trust, **nenhuma entrada é confiável até ser validada**. Isso vale para dados de usuários em aplicações web e vale igualmente para parâmetros de um shell script. **Sempre valide. Sempre.**

---

## 4. O Cérebro do Script (Condicionais If/Else)

### A sintaxe que transforma uma lista de comandos em lógica

Até aqui, um script é apenas uma sequência linear — faz A, depois B, depois C. Mas a infraestrutura real exige **decisões**: se o disco estiver cheio, faça X; se estiver normal, faça Y.

A estrutura condicional `if/else` é o que dá inteligência ao script:

```bash
#!/bin/bash

DISCO_USO=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISCO_USO" -gt 80 ]; then
    echo "⚠️  ALERTA: Disco em ${DISCO_USO}% — acima do limite!"
elif [ "$DISCO_USO" -gt 60 ]; then
    echo "⚡ ATENÇÃO: Disco em ${DISCO_USO}% — monitorar"
else
    echo "✅ OK: Disco em ${DISCO_USO}%"
fi
```

### Anatomia da estrutura — peça por peça

```
if [ condição ]; then       ← SE a condição for verdadeira
    comandos                 ← execute estes comandos
elif [ outra_condição ]; then  ← SENÃO SE esta outra for verdadeira
    comandos                 ← execute estes outros
else                         ← SENÃO (nenhuma acima foi verdadeira)
    comandos                 ← execute estes como fallback
fi                           ← FIM do bloco (if escrito ao contrário)
```

Detalhes de sintaxe que causam 90% dos erros de iniciante:

| Regra | Correto | Errado |
|-------|---------|--------|
| Espaço depois do `[` | `[ "$VAR" -gt 10 ]` | `["$VAR" -gt 10]` |
| Espaço antes do `]` | `[ "$VAR" -gt 10 ]` | `[ "$VAR" -gt 10]` |
| Ponto-e-vírgula antes do `then` | `if [ ... ]; then` | `if [ ... ] then` |
| Variáveis entre aspas | `[ "$VAR" -gt 10 ]` | `[ $VAR -gt 10 ]` |

> **🔒 Atenção (Zero Trust):** Sempre coloque variáveis entre **aspas duplas** dentro dos testes: `"$VAR"`. Se a variável estiver vazia e sem aspas, o bash vê `[ -gt 10 ]` — que é um erro de sintaxe. Com aspas, ele vê `[ "" -gt 10 ]` — que é um teste válido que retorna falso. Aspas são sua proteção contra o inesperado.

### Operadores de comparação numérica

| Operador | Significado | Leitura | Exemplo |
|----------|-------------|---------|---------|
| `-gt` | Greater Than | maior que | `[ "$A" -gt 80 ]` |
| `-lt` | Less Than | menor que | `[ "$A" -lt 20 ]` |
| `-ge` | Greater or Equal | maior ou igual | `[ "$A" -ge 80 ]` |
| `-le` | Less or Equal | menor ou igual | `[ "$A" -le 20 ]` |
| `-eq` | Equal | igual | `[ "$A" -eq 100 ]` |
| `-ne` | Not Equal | diferente | `[ "$A" -ne 0 ]` |

### O código de saída ($?) — Como o Linux diz "deu certo" ou "deu errado"

Todo comando Linux, ao terminar, deixa um **código de saída** na variável especial `$?`:

| Código | Significado |
|--------|-------------|
| `0` | Sucesso |
| `1-255` | Erro (cada número pode indicar um tipo diferente) |

```bash
ping -c 1 -W 2 192.168.1.1 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Host respondeu"
else
    echo "❌ Host não respondeu"
fi
```

E nos seus scripts, use `exit` para retornar códigos de saída adequados:

```bash
#!/bin/bash
if [ -z "$1" ]; then
    echo "❌ Parâmetro obrigatório não informado."
    exit 1    # Sai com código de ERRO
fi

echo "✅ Executando com: $1"
exit 0        # Sai com código de SUCESSO
```

> **💡 Dica de Mercado:** Plataformas de automação de fluxos e sistemas de CI/CD verificam o código de saída de cada script para decidir se o fluxo continua ou se dispara um alerta. Um script que falha mas retorna `exit 0` é uma **bomba-relógio** — o sistema inteiro acredita que deu certo quando na verdade deu errado. **Retorne códigos de saída honestos. Sempre.**

---

## 5. Operadores de Teste Essenciais

### O kit de sobrevivência para validação

Além dos operadores numéricos, o bash oferece operadores para testar **strings, arquivos e diretórios**. Estes são os que você vai usar diariamente como administrador Linux.

### Teste de string vazia: `-z`

O operador `-z` verifica se uma string tem **tamanho zero** (está vazia).

```bash
#!/bin/bash

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
    echo "❌ ERRO: Diretório de backup não informado."
    echo "Uso: $0 <diretorio>"
    exit 1
fi

echo "✅ Diretório de backup: $BACKUP_DIR"
```

Este é o operador mais importante para implementar **Fail Fast**. Ele deve aparecer no **topo de todo script** que recebe parâmetros.

### Teste de arquivo: `-f`

O operador `-f` verifica se o caminho informado **existe e é um arquivo regular** (não é diretório, não é link simbólico).

```bash
#!/bin/bash

CONFIG="/etc/nginx/nginx.conf"

if [ -f "$CONFIG" ]; then
    echo "✅ Arquivo de configuração encontrado."
    echo "Linhas: $(wc -l < "$CONFIG")"
else
    echo "❌ Arquivo $CONFIG não encontrado!"
    exit 1
fi
```

### Teste de diretório: `-d`

O operador `-d` verifica se o caminho informado **existe e é um diretório**.

```bash
#!/bin/bash

LOG_DIR="/var/log/aplicacao"

if [ -d "$LOG_DIR" ]; then
    echo "✅ Diretório de logs existe."
    echo "Tamanho: $(du -sh "$LOG_DIR" | awk '{print $1}')"
else
    echo "⚠️  Diretório não existe. Criando..."
    mkdir -p "$LOG_DIR"
    echo "✅ Diretório $LOG_DIR criado."
fi
```

### A negação lógica: `!`

O operador `!` **inverte** o resultado de qualquer teste. Ele transforma "se existe" em "se NÃO existe":

```bash
#!/bin/bash
# Criar arquivo de lock para evitar execução duplicada

LOCK_FILE="/tmp/backup.lock"

if [ ! -f "$LOCK_FILE" ]; then
    touch "$LOCK_FILE"
    echo "✅ Lock criado. Iniciando backup..."
    # ... comandos de backup ...
    rm -f "$LOCK_FILE"
    echo "✅ Backup concluído. Lock removido."
else
    echo "⚠️  Backup já em execução (lock ativo). Abortando."
    exit 1
fi
```

> **🔒 Atenção (Zero Trust):** O padrão de lock file mostrado acima é usado em produção para garantir que um script agendado (cronjob) não execute em duplicidade. Imagine um script de backup que demora 2 horas, mas o cron dispara a cada 1 hora — sem lock, você teria dois backups simultâneos competindo por disco e rede. **Valide o ambiente antes de agir.**

### Tabela de referência rápida — Operadores de teste

| Operador | Tipo | Verdadeiro quando... | Exemplo |
|----------|------|----------------------|---------|
| `-z "$VAR"` | String | A variável está **vazia** | `[ -z "$1" ]` |
| `-n "$VAR"` | String | A variável **não** está vazia | `[ -n "$USER" ]` |
| `-f caminho` | Arquivo | O caminho é um **arquivo regular** | `[ -f /etc/passwd ]` |
| `-d caminho` | Diretório | O caminho é um **diretório** | `[ -d /var/log ]` |
| `-e caminho` | Existência | O caminho **existe** (arquivo ou diretório) | `[ -e /tmp/lock ]` |
| `-r caminho` | Permissão | Tem permissão de **leitura** | `[ -r /etc/shadow ]` |
| `-w caminho` | Permissão | Tem permissão de **escrita** | `[ -w /tmp ]` |
| `-x caminho` | Permissão | Tem permissão de **execução** | `[ -x ./script.sh ]` |
| `!` | Negação | **Inverte** qualquer teste | `[ ! -f /tmp/lock ]` |

> **💡 Dica de Mercado:** Em scripts de provisionamento e deploy, a sequência mais comum é: (1) validar parâmetros com `-z`, (2) verificar se arquivos de configuração existem com `-f`, (3) garantir que diretórios de trabalho existem com `-d`, e só então (4) executar a lógica principal. Esse padrão é chamado de **guard clauses** (cláusulas de guarda) — e separa scripts amadores de scripts profissionais.

---

## Mapa Mental — Aula 03

```
                      SHELL SCRIPT
                     FUNDAMENTOS
                          │
         ┌────────────────┼────────────────┐
         │                │                │
     ESTRUTURA        ENTRADA         INTELIGÊNCIA
         │                │                │
    ┌────┴────┐     ┌────┴────┐     ┌─────┴─────┐
    │         │     │         │     │           │
 Shebang  Variáveis  $1 $2   Fail   if/elif   Operadores
 #!/bin   de Ambiente Parâm.  Fast   /else/fi  de Teste
 /bash    $USER      $#      -z ""             -f -d !
          $HOSTNAME  $@      exit 1            $?
          $HOME
```

---

## Conexão com o Mundo da Automação

Tudo que você aprendeu nesta aula tem um paralelo direto com o que acontece dentro de plataformas de automação de fluxos modernas:

| Conceito Shell Script | Equivalente em Automação de Fluxos |
|----------------------|-------------------------------------|
| **Variáveis** | Dados que transitam entre etapas de um fluxo |
| **Parâmetros $1 $2** | Inputs que um fluxo recebe ao ser disparado (webhook, trigger) |
| **if/else** | Nós de decisão condicional ("Se status = 200, siga; senão, alerte") |
| **exit 0 / exit 1** | Status de sucesso ou erro que determina o caminho do fluxo |
| **Lock file** | Controle de concorrência entre execuções simultâneas |

Você não está apenas aprendendo a escrever scripts. Está construindo a **base lógica** que torna possível projetar, entender e depurar qualquer sistema de automação — visual ou não.

---

## Próximos Passos

A teoria está completa. Agora é hora de colocar a mão no terminal.

➡️ Abra o arquivo **[laboratorio/aula-03/tickets-aula-03.md](../laboratorio/aula-03/tickets-aula-03.md)** e inicie o treinamento tático.

Os tickets simulam demandas reais de um ambiente corporativo. Cada um exige que você aplique os conceitos desta aula para resolver um problema prático.

> *"Script sem validação é como servidor sem firewall — funciona até o dia que não funciona mais."*
