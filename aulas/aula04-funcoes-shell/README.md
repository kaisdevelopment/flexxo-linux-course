# 📘 Aula 04 — Funções no Shell Script

## Módulo: Administração Linux | Flexxo - Polo Caxias do Sul

---

## 🎯 Objetivo da Aula

Aprender a criar, organizar e executar **funções no Bash**, transformando comandos soltos em blocos reutilizáveis — o primeiro passo para pensar em **automação de processos**.

---

## 1. O que é uma Função?

Uma função é um **bloco de comandos com nome** que pode ser chamado várias vezes sem repetir código.

### 🏭 Analogia do Mundo Real

> Imagine uma **máquina em uma linha de produção**: você aperta um botão (chama a função), ela executa o processo interno e entrega o resultado. Você não precisa reconstruir a máquina toda vez — ela já está pronta para ser usada.

No mundo corporativo, funções são a base de:
- Scripts de monitoramento de servidores
- Rotinas de backup automatizado
- Pipelines de dados em sistemas de automação de fluxos

---

## 2. Sintaxe Básica

```bash
nome_da_funcao() {
    # comandos aqui dentro
}

# Chamada:
nome_da_funcao
```

**Regras:**
- A função deve ser **declarada antes** de ser chamada
- O nome **não pode ter espaços** nem começar com número
- Os `{ }` delimitam o bloco de execução

---

## 3. Prática — A Dinâmica do Comando `w`

### 3.1 Entendendo o comando `w`

O comando `w` mostra **quem está logado** no sistema, o que está fazendo e há quanto tempo:

```bash
w
```

Saída típica:
```
 09:41:06 up 2 days,  3:12,  2 users,  load average: 0.15, 0.10, 0.08
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
rmeneg   pts/0    192.168.1.50     08:30    0.00s  0.05s  0.00s w
aluno    pts/1    192.168.1.51     09:00    5:12   0.02s  0.01s bash
```

| Coluna | Significado |
|---|---|
| `USER` | Quem está logado |
| `TTY` | Terminal em uso |
| `FROM` | IP de origem |
| `LOGIN@` | Hora do login |
| `IDLE` | Tempo parado |
| `WHAT` | Comando que está executando |

> 💡 **No mundo real**, administradores de data centers usam esse comando para verificar sessões ativas, identificar acessos suspeitos e auditar conexões remotas — pilares do modelo **Zero Trust**.

---

### 3.2 Script v1 — Função Simples

```bash
#!/bin/bash
# =============================================
# Aula 04 - Funções no Shell Script
# =============================================

usuarios_logados() {
    echo "=============================="
    echo "  USUÁRIOS LOGADOS NO SISTEMA"
    echo "=============================="
    w
    echo ""
}

usuarios_logados
```

---

### 3.3 Script v2 — Função com Lógica e Alerta

```bash
#!/bin/bash
# =============================================
# Aula 04 - Funções no Shell Script (v2)
# Monitoramento com alertas
# =============================================

verificar_usuarios() {
    local total
    total=$(w -h | wc -l)

    echo "=============================="
    echo "  MONITOR DE SESSÕES ATIVAS"
    echo "=============================="
    echo "Data/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Total de usuários logados: $total"
    echo "------------------------------"
    w
    echo ""

    if [ "$total" -gt 1 ]; then
        echo "⚠️  ALERTA: Mais de 1 usuário logado!"
    else
        echo "✅ Apenas 1 sessão ativa. Tudo normal."
    fi
}

verificar_usuarios
```

> 🔐 **Conexão com Zero Trust:** Em ambientes corporativos, monitorar sessões ativas é prática essencial. Se um servidor tem 3 sessões e você esperava 1, pode ser uma **brecha de segurança**.

---

### 3.4 Script v3 — Múltiplas Funções + Log

```bash
#!/bin/bash
# =============================================
# Aula 04 - Funções no Shell Script (v3)
# Mini ferramenta de auditoria de sessões
# =============================================

LOG_FILE="/tmp/auditoria_sessoes.log"

cabecalho() {
    local titulo="$1"
    echo "=============================="
    echo "  $titulo"
    echo "  $(date '+%d/%m/%Y %H:%M:%S')"
    echo "=============================="
}

listar_sessoes() {
    echo ""
    echo "Sessões ativas:"
    echo "------------------------------"
    w -h
    echo ""
}

alertar_sessoes() {
    local total
    total=$(w -h | wc -l)
    if [ "$total" -gt 1 ]; then
        echo "⚠️  ALERTA: $total sessões ativas!"
    else
        echo "✅ Sistema com $total sessão ativa."
    fi
}

salvar_log() {
    echo "--- Auditoria $(date) ---" >> "$LOG_FILE"
    w >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "📄 Log salvo em: $LOG_FILE"
}

# EXECUÇÃO PRINCIPAL
cabecalho "AUDITORIA DE SESSÕES"
listar_sessoes
alertar_sessoes
salvar_log
```

---

## 4. Funções em Arquivo Separado (Padrão Profissional)

### Arquivo: `lib/funcoes_auditoria.sh`

```bash
#!/bin/bash
cabecalho() {
    echo "=============================="
    echo "  $1"
    echo "  $(date '+%d/%m/%Y %H:%M:%S')"
    echo "=============================="
}

listar_sessoes() { w -h; }
contar_sessoes() { w -h | wc -l; }
```

### Arquivo: `main.sh`

```bash
#!/bin/bash
source ./lib/funcoes_auditoria.sh

cabecalho "RELATÓRIO DE SESSÕES"
echo "Total: $(contar_sessoes) sessão(ões)"
listar_sessoes
```

---

## 5. Conceitos-Chave

| Conceito | O que faz | Uso no mercado |
|---|---|---|
| `funcao()` | Cria bloco reutilizável | Scripts de automação |
| `local var` | Variável só dentro da função | Evita conflitos |
| `$1, $2...` | Parâmetros da função | Flexibilidade |
| `source` | Importa outro arquivo .sh | Bibliotecas corporativas |
| `w` | Mostra sessões ativas | Auditoria e segurança |
| `wc -l` | Conta linhas | Monitoramento |
| `>> arquivo` | Append em log | Histórico de auditoria |

---

## 6. Desafio

> Criar uma função `relatorio_sistema()` que exiba:
> 1. Usuários logados (`w`)
> 2. Uso de disco (`df -h`)
> 3. Memória disponível (`free -h`)
> 4. Salve tudo em `/tmp/relatorio_DATA.log`

---

> 🔗 **Ponte com Automação:** A estrutura de `source` (importar funções) é o mesmo conceito de **módulos reutilizáveis** em plataformas de automação de fluxos. Cada arquivo de funções é um **componente** que você conecta em diferentes pipelines.
