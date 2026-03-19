# 🛠️ Laboratório 03: Fundamentos de Shell Script (A Lógica da Automação)

Bem-vindo ao laboratório prático! Aqui o foco é "mão na massa". Vamos construir ferramentas resilientes e consertar scripts quebrados usando variáveis de ambiente e condicionais lógicas.

---

## 🟢 Ticket 1: O Rastreador de Ambiente (Variáveis de Sistema)

**O Cenário:** A equipe de segurança quer um banner de boas-vindas inteligente no servidor corporativo. O script `boas_vindas.sh` deve saudar o usuário pelo nome, mostrar em qual servidor ele está logado e disparar um alerta vermelho caso o usuário logado seja o `root`. A política Zero Trust da empresa proíbe operar o servidor logado diretamente como administrador.

**Sua Missão:** Crie o script utilizando as variáveis de ambiente embutidas do Linux (`$USER`, `$HOSTNAME`, `$HOME`).

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

Crie o arquivo com `nano boas_vindas.sh`, adicione o código abaixo e dê permissão de execução (`chmod +x boas_vindas.sh`):

```bash
#!/bin/bash

echo "======================================="
echo "Bem-vindo ao servidor: $HOSTNAME"
echo "Seu diretório base é: $HOME"
echo "======================================="

# O script toma uma decisão baseada no usuário logado
if [ "$USER" == "root" ]; then
    echo "⚠️ ALERTA CRÍTICO: Você está logado como ROOT!"
    echo 'Por favor, deslogue e use um usuário comum com sudo.'
else
    echo "✅ Login seguro detectado. Bom trabalho, $USER!"
fi
```

**Explicação SRE:** O Linux carrega essas variáveis na memória. Ao usar `$USER`, o script se adapta magicamente a qualquer servidor. A condicional transforma um script comum num auditor de regras de segurança.
</details>

---

## 🟡 Ticket 2: O Guarda-Costas de Parâmetros (Entrada Dinâmica)

> ⚠️ **Atenção Instrutor (Setup do Caos):** Antes do aluno iniciar, rode o bloco abaixo escondido no terminal dele para criar o cenário quebrado.
> ```bash
> mkdir -p /tmp/logs_fake/sistema_{a,b}
> echo "log_sujo" > /tmp/logs_fake/sistema_a/erro.log
> echo "log_sujo" > /tmp/logs_fake/sistema_b/erro.log
> cat << 'SETUP_EOF' > /tmp/limpar_log.sh
> #!/bin/bash
> SISTEMA=$1
> echo "🧹 Iniciando limpeza dos logs do sistema: $SISTEMA..."
> rm -rf /tmp/logs_fake/$SISTEMA/*
> echo "Limpeza concluída com sucesso!"
> SETUP_EOF
> chmod +x /tmp/limpar_log.sh
> ```

**O Cenário:** Um analista júnior criou um script chamado `/tmp/limpar_log.sh`. A ideia era o script receber o nome de um sistema e apagar os logs dele.
**O Problema:** Execute o script **sem passar nenhum parâmetro** (`/tmp/limpar_log.sh`) e veja o que acontece com as pastas em `/tmp/logs_fake/`. Como a variável ficou vazia, o script apagou TUDO!

**Sua Missão:** Modifique o script original para que ele **exija** um parâmetro. Se o usuário rodar sem informar nada, o script deve bloquear a execução, ensinar como usar corretamente e encerrar (usando `exit 1`) **antes** de chegar no comando `rm`.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

O aluno deve editar o script e adicionar a validação `-z` (zero/vazio) no topo:

```bash
#!/bin/bash

# A flag -z verifica se a variável $1 (o primeiro parâmetro) está VAZIA
if [ -z "$1" ]; then
    echo "❌ ERRO: Faltou informar o nome do sistema!"
    echo "👉 Como usar: ./limpar_log.sh <nome_do_sistema>"
    echo "Exemplo: ./limpar_log.sh sistema_a"
    exit 1 # Interrompe a execução com código de erro
fi

SISTEMA=$1
echo "🧹 Iniciando limpeza dos logs do sistema: $SISTEMA..."
rm -rf /tmp/logs_fake/$SISTEMA/*
echo "Limpeza concluída com sucesso!"
```

**Explicação SRE:** Scripts nunca devem confiar cegamente na entrada humana. Se a variável `$SISTEMA` estiver vazia, o `rm -rf` vira uma arma de destruição em massa no seu servidor. Falhar rápido (*Fail Fast*) é a regra de ouro da automação.
</details>

---

## 🔵 Ticket 3: O Auditor de Arquivos (Testes de Sistema)

**O Cenário:** Precisamos criar uma ferramenta chamada `backup_seguro.sh`. Ela recebe dois parâmetros: o arquivo que deve ser copiado (`$1`) e a pasta para onde ele vai (`$2`). Para evitar mensagens de erro nativas, o script deve verificar por conta própria se o arquivo existe e se a pasta de destino é válida antes de tentar copiar.

**Sua Missão:** Crie o script `backup_seguro.sh` implementando testes de arquivo e diretório.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
#!/bin/bash

ARQUIVO=$1
DESTINO=$2

# 1. Verifica se os dois parâmetros foram passados
if [ -z "$ARQUIVO" ] || [ -z "$DESTINO" ]; then
    echo "Erro: Faltam parâmetros."
    echo "Uso: ./backup_seguro.sh <arquivo> <pasta_destino>"
    exit 1
fi

# 2. Verifica se o arquivo existe (flag -f de 'file')
if [ ! -f "$ARQUIVO" ]; then
    echo "⚠️ Ops! O arquivo '$ARQUIVO' não existe. Abortando."
    exit 1
fi

# 3. Verifica se o destino existe e é um diretório (flag -d de 'directory')
if [ ! -d "$DESTINO" ]; then
    echo "⚠️ Ops! A pasta de destino '$DESTINO' não existe. Abortando."
    exit 1
fi

# Se passou por todos os IFs acima, é seguro copiar!
echo "Copiando '$ARQUIVO' para '$DESTINO'..."
cp "$ARQUIVO" "$DESTINO"
echo "✅ Backup realizado com sucesso!"
```

**Explicação SRE:** O ponto de exclamação `!` dentro dos colchetes significa "NÃO". Logo, `[ ! -f "$ARQUIVO" ]` lê-se "Se NÃO for um arquivo". Validar caminhos no disco antes de manipular dados garante que seu script seja resiliente.
</details>
