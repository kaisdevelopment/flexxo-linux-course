# ☠️ Laboratório 02: O Caos Controlado (Troubleshooting Raiz)

Bem-vindo às trincheiras. Aqui os servidores quebram e você aplica a **Metodologia USE (Utilization, Saturation, and Errors)** para identificar gargalos.

---

## 🛑 Cenário 1: Saturação Oculta de Disco (File Descriptors)
**A História Corporativa:** "O sistema de faturamento parou. O monitoramento aponta 100% de uso do disco, mas a equipe jura que apagou os logs antigos e o espaço não foi liberado."

### 💥 Script de Quebra (Para o Instrutor rodar escondido):
```bash
# 1. Cria um arquivo gigante mascarado
fallocate -l 1G /tmp/.faturamento_debug.log
# 2. Cria um processo em background mantendo o arquivo preso (File Descriptor aberto)
tail -f /tmp/.faturamento_debug.log > /dev/null &
PID=$!
# 3. Simula a equipe apagando o arquivo de forma errada (o arquivo some, o espaço não)
rm /tmp/.faturamento_debug.log
```

### 🛠️ Gabarito de Resolução (Para o Aluno):
1. O aluno vai rodar `df -h` e ver o disco cheio.
2. Vai rodar `du -ah / | sort -rh | head -n 10` e **não vai achar** o arquivo gigante (porque ele foi deletado com `rm`).
3. **A Magia SRE:** O aluno usa `lsof +L1` para listar arquivos deletados que ainda estão presos na memória RAM por processos ativos.
4. Ele encontra o PID do `tail` e o mata com `kill -9 <PID>`. Instantaneamente, o Kernel libera o 1GB de espaço.
**Lição de Ouro:** Nunca use `rm` em logs de aplicações ativas. Use o truncamento: `> /caminho/do/log.log`.

---

## 🛑 Cenário 2: O Processo Fantasma (Portas Travadas)
**A História Corporativa:** "Estamos tentando subir a nova API na porta 8080, mas o servidor recusa a inicialização dizendo: *Address already in use*. Ninguém sabe quem está usando a porta."

### 💥 Script de Quebra (Para o Instrutor rodar escondido):
```bash
# Inicia um processo mascarado escutando a porta 8080 em background
nc -l -p 8080 > /dev/null 2>&1 &
```

### 🛠️ Gabarito de Resolução (Para o Aluno):
1. O aluno tenta subir o serviço e toma erro de porta ocupada.
2. Ele usa ferramentas de rede para auditar: `ss -tulnp | grep 8080` ou `lsof -i :8080`.
3. Descobre o processo que está segurando a conexão.
4. Usa o envio letal de sinal: `kill -9 <PID>`.
5. Verifica novamente com `ss` e atesta que a porta está livre para a nova aplicação.

---

## 🛑 Cenário 3: A Blindagem Oculta (Atributos Ext4)
**A História Corporativa:** "O arquivo de configuração do Banco de Dados foi corrompido intencionalmente por um script malicioso (porta virou 543O). Vocês precisam corrigir, mas o arquivo diz *Permission Denied*, mesmo o usuário sendo ROOT e a permissão estando 777!"

### 💥 Script de Quebra (Para o Instrutor rodar escondido):
```bash
echo "db_port=543O" > /etc/db_config.conf
chmod 777 /etc/db_config.conf
# Aplica o bit de Imutabilidade (nem o root altera mais o arquivo)
chattr +i /etc/db_config.conf
```

### 🛠️ Gabarito de Resolução (Para o Aluno):
1. O aluno vai dar `cat /etc/db_config.conf` e ver o erro.
2. Vai tentar editar com `nano` e usar `sudo`, e vai falhar miseravelmente.
3. Vai usar `ls -l` e ver que está `777`. O desespero bate.
4. **A Magia SRE:** O aluno lembra das camadas profundas do sistema de arquivos e roda `lsattr /etc/db_config.conf`.
5. Ele enxerga o fatídico `----i---------` (Immutable bit).
6. O aluno remove a blindagem: `chattr -i /etc/db_config.conf`.
7. Agora ele consegue editar o arquivo, corrigir a porta e salvar.

---

## 🚀 A Ponte para Automação (Processos em Background)
Seja no terminal raiz ou em futuras **plataformas de integração visual**, a regra é a mesma:
Sistemas rodam baseados em I/O (Disco, Rede e Memória). Um pipeline não consegue processar dados se não puder ler o disco (`chattr`), não consegue enviar os dados se a porta de comunicação estiver travada (`ss`) e vai travar a infraestrutura inteira se lotar os descritores de arquivos e estourar o disco sem ninguém notar.

Dominar o Troubleshooting hoje é garantir que as integrações automatizadas do futuro rodem num ambiente limpo e blindado.
