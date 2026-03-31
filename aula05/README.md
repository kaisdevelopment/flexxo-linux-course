# 🧰 Aula 05: Funções Avançadas e Automação de Rotinas

Bem-vindo à Aula 05! Hoje você vai construir sua própria biblioteca de ferramentas (seu 'canivete suíço' de Sysadmin). O objetivo é parar de digitar os mesmos comandos repetidamente e criar funções inteligentes que automatizam o seu dia a dia.

---

## 🟢 Nível 1: Aquecimento (Fácil)

### Exercício 1: A Fundação da sua Biblioteca
**Cenário:** Todo administrador de sistemas precisa de um local organizado para guardar seus scripts e atalhos.
**Missão:** Crie um diretório chamado `sysadmin-tools` na sua pasta *home*. Dentro dele, crie um arquivo chamado `funcoes.sh`. Neste arquivo, crie uma função chamada `ver_disco` que exiba o uso de espaço em disco de forma legível para humanos.
**Dica:** Lembre-se da sintaxe de função `nome_da_funcao() { ... }` e do comando `df -h`.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
mkdir -p ~/sysadmin-tools
nano ~/sysadmin-tools/funcoes.sh

# --- Conteúdo a ser digitado no funcoes.sh ---
ver_disco() {
    echo "=== Uso de Disco ==="
    df -h
    echo ""
}
```
</details>

### Exercício 2: Carregando a Munição
**Cenário:** A função está criada, mas se você digitar `ver_disco` no terminal agora, ele dirá 'comando não encontrado'. Precisamos carregar isso na memória.
**Missão:** Use o comando correto para ler o arquivo `funcoes.sh` e carregar as funções na sua sessão atual do terminal. Depois, teste a função `ver_disco`.
**Dica:** O comando significa 'fonte' ou 'origem' em inglês.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Carrega o arquivo na sessão atual
source ~/sysadmin-tools/funcoes.sh

# Testa a função como se fosse um comando nativo
ver_disco
```
</details>

### Exercício 9: O Arquiteto de Ambientes
**Cenário:** A equipe de Desenvolvimento sempre pede para você criar as pastas iniciais para novos projetos no servidor. Fazer isso manualmente demora e gera erros.
**Missão:** No seu `funcoes.sh`, crie uma função `criar_projeto` que receba um parâmetro (`$1` com o nome do projeto). A função deve criar um diretório com esse nome dentro de `/tmp/` e exibir uma mensagem de sucesso.
**Dica:** Lembre-se de salvar o `$1` em uma variável `local` para deixar o código elegante.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
criar_projeto() {
    local nome_projeto="$1"
    
    echo "🏗️ Criando estrutura para o projeto: $nome_projeto"
    mkdir -p "/tmp/$nome_projeto"
    echo "✅ Projeto $nome_projeto criado com sucesso em /tmp/"
}
```
</details>

---

## 🟡 Nível 2: Operações Táticas (Médio)

### Exercício 3: O Investigador de Serviços (Parâmetros)
**Cenário:** O chefe de infraestrutura quer que você verifique rapidamente se o `nginx` ou o `ssh` estão rodando, sem precisar digitar comandos longos.
**Missão:** Crie uma função chamada `checar_servico` que receba um parâmetro (`$1`). A função deve usar o `systemctl is-active` para verificar o status do serviço passado como parâmetro.
**Dica:** Salve o `$1` numa variável local. Depois do source, teste com `checar_servico ssh`.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no final do funcoes.sh
checar_servico() {
    local servico="$1"
    echo "Status do serviço: $servico"
    systemctl is-active "$servico"
}
```
</details>

### Exercício 4: Bloqueando Erros Humanos (Validação)
**Cenário:** Um analista júnior usou sua função `checar_servico` mas esqueceu de passar o nome do serviço. O script rodou em branco e assustou a equipe.
**Missão:** Melhore a função `checar_servico`. Adicione um bloco `if` no início dela para verificar se a variável do parâmetro está vazia. Se estiver, exiba uma mensagem de erro ensinando a usar e force a saída com `return 1`.
**Dica:** Use a flag `-z` no `if` para testar se uma string está vazia.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Atualize a função no funcoes.sh
checar_servico() {
    local servico="$1"
    
    if [ -z "$servico" ]; then
        echo "⛔ ERRO: O nome do serviço é obrigatório!"
        echo "Uso correto: checar_servico <nome_do_servico>"
        return 1
    fi

    echo "Status do serviço: $servico"
    systemctl is-active "$servico"
}
```
</details>

### Exercício 5: O Relatório Matinal (Composição de Funções)
**Cenário:** Todo dia às 8h da manhã você precisa checar o disco, a memória e quem está logado no servidor. Vamos juntar tudo em um comando só.
**Missão:** No `funcoes.sh`, crie duas funções rápidas: `ver_memoria` (usando `free -h`) e `ver_usuarios` (usando `w -h`). Depois, crie uma função `relatorio_completo` que apenas chama `ver_disco`, `ver_memoria` e `ver_usuarios` em sequência.
**Dica:** Uma função pode chamar outra função como se fosse um comando comum.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
ver_memoria() {
    echo "=== Uso de Memória ==="
    free -h
    echo ""
}

ver_usuarios() {
    echo "=== Usuários Logados ==="
    w -h
    echo ""
}

relatorio_completo() {
    echo "Iniciando Relatório Matinal..."
    echo "Data: $(date)"
    ver_disco
    ver_memoria
    ver_usuarios
    echo "✅ Relatório concluído!"
}
```
</details>

### Exercício 10: O Radar de Processos
**Cenário:** Ficar digitando `ps aux | grep nome | grep -v grep` toda hora é cansativo.
**Missão:** Crie uma função `procurar_processo` que receba o nome do processo como parâmetro. Use um `if` para validar se está vazio. Se estiver tudo certo, rode o comando `ps aux` filtrando pelo nome e removendo o próprio comando `grep` do resultado.
**Dica:** Concatene os filtros com o *pipe* `|`.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
procurar_processo() {
    local nome_processo="$1"
    
    if [ -z "$nome_processo" ]; then
        echo "ERRO: Informe o nome do processo!"
        echo "Uso: procurar_processo <nome>"
        return 1
    fi

    echo "🔍 Buscando processos com o nome: $nome_processo"
    ps aux | grep "$nome_processo" | grep -v "grep"
}
```
</details>

### Exercício 11: Extração Rápida de Logs
**Cenário:** O time de segurança pediu para extrair as 10 primeiras linhas de arquivos suspeitos e salvar num arquivo de evidências geral, sem apagar o histórico.
**Missão:** Crie a função `extrair_evidencia` que receba o caminho de um arquivo como parâmetro (`$1`). Valide o parâmetro. Use `head` para ler o arquivo e redirecione (anexando) a saída para `/tmp/evidencias.log`.
**Dica:** Lembre-se que `>` sobrescreve e `>>` anexa.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
extrair_evidencia() {
    local arquivo_alvo="$1"
    local arquivo_destino="/tmp/evidencias.log"
    
    if [ -z "$arquivo_alvo" ]; then
        echo "ERRO: Informe o caminho do arquivo suspeito!"
        return 1
    fi

    echo "Extraindo amostra de: $arquivo_alvo" >> "$arquivo_destino"
    head "$arquivo_alvo" >> "$arquivo_destino"
    echo "-----------------------------------" >> "$arquivo_destino"
    
    echo "✅ Evidência salva em $arquivo_destino"
}
```
</details>

---

## 🔴 Nível 3: Modo SRE Sênior (Desafiador)

### Exercício 6: A Varredura de Segurança (For Loop em Função)
**Cenário:** A gerência exigiu uma varredura rápida para garantir que os serviços críticos estão no ar.
**Missão:** Crie uma função chamada `checar_servicos_criticos`. Use um laço `for` para iterar sobre: `ssh`, `cron`, `nginx` e `mysql`. Para cada item do laço, chame a sua função `checar_servico` passando o item como parâmetro.
**Dica:** Princípio DRY (Don't Repeat Yourself)! Reutilize a função que já faz a checagem.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
checar_servicos_criticos() {
    echo "🔍 Iniciando Varredura de Serviços Críticos..."
    for srv in ssh cron nginx mysql; do
        echo "---------------------------"
        checar_servico "$srv"
    done
    echo "---------------------------"
    echo "✅ Varredura Finalizada!"
}
```
</details>

### Exercício 12: Blindagem em Lote
**Cenário:** Três pastas críticas (`/tmp/projetos`, `/tmp/bkp_db`, `/tmp/chaves`) precisam ter suas permissões restritas apenas ao dono.
**Missão:** Crie a função `blindar_pastas`. Use um laço `for` contendo os três caminhos. Para cada pasta no loop, execute um `mkdir -p` (para garantir que existem) e um `chmod 700`.
**Dica:** O laço `for` pode iterar sobre caminhos completos!

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
blindar_pastas() {
    echo "🛡️ Iniciando blindagem de diretórios críticos..."
    
    for pasta in /tmp/projetos /tmp/bkp_db /tmp/chaves; do
        echo "Ajustando segurança na pasta: $pasta"
        mkdir -p "$pasta"
        chmod 700 "$pasta"
    done
    
    echo "✅ Todas as pastas foram blindadas!"
}
```
</details>

### Exercício 7: Caçador de Gargalos (Redirecionamento)
**Cenário:** Um processo está consumindo muita memória de madrugada. Você precisa registrar os 'vilões da memória'.
**Missão:** Crie a função `registrar_viloes`. Registre a data e use `ps aux --sort=-%mem | head`. A saída NÃO deve ir para a tela, mas ser anexada ao arquivo `/tmp/viloes_ram.log`.
**Dica:** Use `>>` em todos os `echo` e comandos dentro dessa função para mandar tudo pro log.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
registrar_viloes() {
    local log_file="/tmp/viloes_ram.log"
    
    echo "======================================" >> "$log_file"
    echo "Registro gerado em: $(date)" >> "$log_file"
    echo "Top processos consumindo RAM:" >> "$log_file"
    
    ps aux --sort=-%mem | head >> "$log_file"
    
    echo "✅ Registro salvo com sucesso em $log_file"
}
```
</details>

### Exercício 13: O Snapshot do Sistema
**Cenário:** Você precisa de uma função que tire uma 'foto' do estado atual do servidor e salve num único arquivo de auditoria.
**Missão:** Crie a função `snapshot_sistema`. Defina o destino como `/tmp/snapshot_$(hostname).log`. Anexe (`>>`) a saída do `date`, depois `df -h` e depois `free -h` diretamente para este arquivo.
**Dica:** Não use as funções anteriores que imprimem na tela. Escreva os comandos puros apontando o `>>` para o log.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
snapshot_sistema() {
    local log_file="/tmp/snapshot_$(hostname).log"
    
    echo "📸 Gerando snapshot do sistema..."
    
    echo "===================================" >> "$log_file"
    echo "DATA: $(date)" >> "$log_file"
    echo "--- DISCO ---" >> "$log_file"
    df -h >> "$log_file"
    echo "--- MEMÓRIA ---" >> "$log_file"
    free -h >> "$log_file"
    echo "===================================" >> "$log_file"
    
    echo "✅ Snapshot salvo com sucesso em: $log_file"
}
```
</details>

### Exercício 8: A Ferramenta Eterna (Persistência no bashrc)
**Cenário:** Seu `funcoes.sh` está perfeito, mas se você abrir um novo terminal, o comando `source` é perdido.
**Missão:** Configure o seu usuário para que a sua biblioteca de funções seja carregada **automaticamente** toda vez que você abrir um terminal.
**Dica:** Injete o comando `source` na última linha do arquivo oculto `~/.bashrc`.

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# 1. Adicione a linha no final do seu .bashrc
echo "source ~/sysadmin-tools/funcoes.sh" >> ~/.bashrc

# 2. Recarregue o .bashrc para aplicar a alteração agora
source ~/.bashrc

# A partir de agora, suas funções são como comandos nativos do seu Linux!
```
</details>

---

## 💀 O Selo de Auditoria (Boss Final)

### Exercício 14
**Cenário:** A equipe de InfoSec exige que você gere logs de checagem 'assinando' com o seu nome.
**Missão:** Crie a função `assinar_auditoria` que receba o nome do Sysadmin (`$1`). Valide se está vazio (erro + return 1). Defina o log `/tmp/auditoria_compliance.log`. Anexe a frase 'Auditoria por: [NOME]' e a data. Faça um `for` iterando sobre `ssh` e `cron`, execute `systemctl is-active` e anexe a saída no log.
**Dica:** Este exercício une Tudo: Validação (if -z), Parâmetros, Variáveis, Loop for e Redirecionamento (>>).

<details>
<summary>🛠️ <b>Ver Gabarito</b></summary>

```bash
# Adicione no funcoes.sh
assinar_auditoria() {
    local sysadmin="$1"
    local log_file="/tmp/auditoria_compliance.log"
    
    if [ -z "$sysadmin" ]; then
        echo "⛔ ERRO: Você precisa assinar a auditoria!"
        echo "Uso: assinar_auditoria <seu_nome>"
        return 1
    fi

    echo "📝 Iniciando auditoria de compliance..."

    echo "=====================================" >> "$log_file"
    echo "Auditoria realizada por: $sysadmin" >> "$log_file"
    echo "Data: $(date)" >> "$log_file"
    echo "Status dos Serviços:" >> "$log_file"

    for srv in ssh cron; do
        echo -n "- $srv: " >> "$log_file"
        systemctl is-active "$srv" >> "$log_file"
    done
    
    echo "=====================================" >> "$log_file"
    
    echo "✅ Auditoria concluída e salva em $log_file!"
}
```
</details>
