# 📘 Material de Apoio — Aula 02: Troubleshooting Corporativo

### Curso: Administração Linux | Mentoria Individual — Flexxo (Caxias do Sul)
### Instrutor: Wiliam | Data: Março/2026

---

> **Resumo:** Saímos da sobrevivência básica para a resolução de incidentes reais que derrubam servidores em produção: disco saturado por logs ocultos, portas travadas por processos fantasmas e a camada oculta de segurança com atributos de arquivo. Cada técnica aqui é usada diariamente por SREs e engenheiros de infraestrutura no mundo real.

---

## 📍 Pré-requisitos

- [ ] Ter concluído a Aula 01 (Fundação e Controle)
- [ ] Ambiente WSL funcional
- [ ] Estar confortável com `find`, `grep` e permissões básicas

---

## PARTE 1: Saturação de Disco e File Descriptors

### 1.1 — O Cenário Real

São 2h da manhã. O monitoramento dispara: **"Disco do servidor de aplicação em 98%"**. O sistema começa a rejeitar conexões, o banco de dados não consegue gravar, e o serviço cai.

Você faz o SSH, roda o `df -h` e confirma: o disco `/` está lotado. Mas **onde** está o problema?

### 1.2 — Encontrar o Culpado com du + sort

```bash
# Listar os maiores consumidores de disco, ordenados do maior ao menor
du -ah /var/log | sort -rh | head -20
```

**Decomposição do comando (encadeamento por pipe):**

| Parte | Função |
|-------|--------|
| `du -ah /var/log` | **D**isk **U**sage: mostra o tamanho de todos os arquivos em formato humano (GB, MB) |
| `\|` | **Pipe**: a saída do du vira a entrada do sort |
| `sort -rh` | Ordena em ordem reversa (maior primeiro), interpretando formato humano |
| `\| head -20` | Mostra apenas as 20 primeiras linhas (os maiores) |

> **🏢 Analogia Corporativa:** O **pipe** é como uma **esteira de fábrica**. O primeiro operário (du) coloca as peças na esteira. O segundo (sort) organiza. O terceiro (head) seleciona apenas as que importam. Cada um faz uma função, e a mágica está no **encadeamento**. Esse é o poder da filosofia Unix: ferramentas pequenas que fazem uma coisa bem feita, conectadas por pipes.

### 1.3 — O Resultado Típico

```
15G     /var/log/app/service-debug.log
2.1G    /var/log/syslog.1
800M    /var/log/nginx/access.log
```

Pronto. Encontramos o culpado: um **log de debug** de 15GB que nunca foi rotacionado.

### 1.4 — A Lição de Ouro: Truncar, NUNCA Deletar

Seu primeiro instinto é rodar `rm service-debug.log`. **NÃO FAÇA ISSO.**

#### Por que o rm é Perigoso em Logs Ativos?

Aqui entra o conceito de **File Descriptor (FD)**.

Quando uma aplicação (ex: Nginx, Java, Node) abre um arquivo de log, o sistema operacional cria um **File Descriptor** — um ponteiro, um canal de comunicação entre o processo e o arquivo.

Se você apaga o arquivo com `rm`:

- O **nome** do arquivo some do diretório (não aparece mais no `ls`).
- Mas o **File Descriptor continua aberto**. A aplicação continua gravando no espaço que o arquivo ocupava.
- O disco **não libera o espaço** até que o processo seja encerrado.
- Você acha que resolveu, mas o `df -h` continua mostrando disco cheio. **O log virou um fantasma.**

> **🏢 Analogia Corporativa:** Imagine que o File Descriptor é um **duto de água** conectado a uma caixa d'água. O rm é como **tirar a etiqueta da caixa** — o nome some, mas o duto continua bombeando água para dentro dela. A caixa vai transbordar do mesmo jeito. Só que agora, como a etiqueta sumiu, você nem consegue encontrá-la para resolver o problema.

#### A Solução Correta: Truncamento

```bash
# Truncar o arquivo: esvazia o conteúdo mas mantém o File Descriptor intacto
> /var/log/app/service-debug.log
```

Esse comando **zera o conteúdo** do arquivo, mas a "caixa d água" e o "duto" continuam no lugar. A aplicação continua gravando normalmente a partir do byte zero, e o disco libera os 15GB **instantaneamente**.

```bash
# Verificar que funcionou
df -h /
ls -lh /var/log/app/service-debug.log
```

#### E se o rm Já Foi Feito? Como Encontrar o Fantasma?

```bash
# Listar File Descriptors abertos apontando para arquivos deletados
lsof | grep "(deleted)"
```

A saída mostra qual processo ainda segura o arquivo. A partir daí, você pode reiniciar o serviço de forma controlada para liberar o espaço.

### 1.5 — Comandos Complementares de Diagnóstico de Disco

```bash
# Visão geral do uso de disco por partição
df -h

# Ver uso de disco apenas do diretório atual
du -sh *

# Ver inodes (número de arquivos) — disco pode lotar por inodes também!
df -i

# Encontrar os 10 maiores arquivos do sistema inteiro
find / -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10
```

> **💡 Dica:** Um disco pode mostrar espaço disponível no `df -h` mas estar com **inodes esgotados** (muitos arquivos pequenos). O `df -i` revela esse cenário oculto. É um diagnóstico que muitos administradores esquecem.

---

## PARTE 2: Conexões e Processos Fantasmas — A Porta 8080 Travada

### 2.1 — O Cenário Real

Você tenta subir uma aplicação web e recebe:

```
Error: EADDRINUSE - Port 8080 is already in use
```

Alguém ou algum processo já está "sentado" naquela porta. Mas quem?

### 2.2 — Auditar as Portas com ss

```bash
# Listar todas as conexões TCP e UDP com o processo responsável
ss -tulnp
```

**Decomposição dos parâmetros:**

| Flag | Significado |
|------|-------------|
| `-t` | Conexões **TCP** |
| `-u` | Conexões **UDP** |
| `-l` | Apenas portas em **listening** (escutando) |
| `-n` | Mostra **números** de porta (não resolve nomes) |
| `-p` | Mostra o **processo** (PID e nome) responsável |

**Saída típica:**

```
State    Recv-Q  Send-Q  Local Address:Port   Peer Address:Port   Process
LISTEN   0       128     0.0.0.0:8080          0.0.0.0:*          users:(("java",pid=4521,fd=12))
LISTEN   0       128     0.0.0.0:22            0.0.0.0:*          users:(("sshd",pid=890,fd=3))
LISTEN   0       128     0.0.0.0:443           0.0.0.0:*          users:(("nginx",pid=1205,fd=6))
```

Identificado: um processo **Java** com PID **4521** está ocupando a porta 8080.

### 2.3 — Investigar com lsof

```bash
# Confirmar qual processo está usando a porta 8080
sudo lsof -i :8080
```

```
COMMAND   PID    USER    FD   TYPE  DEVICE  SIZE/OFF  NODE  NAME
java      4521   deploy  12u  IPv4  45678   0t0       TCP   *:8080 (LISTEN)
```

Agora temos certeza: é o processo `java`, rodando pelo usuário `deploy`, PID `4521`.

### 2.4 — Encerrar o Processo

```bash
# Tentativa gentil (SIGTERM): pede para o processo encerrar
kill 4521

# Se o processo não obedeceu (zumbi/travado): encerramento forçado
kill -9 4521
```

**Diferença entre os sinais:**

| Sinal | Código | Comportamento |
|-------|--------|---------------|
| `SIGTERM` | `kill PID` | Pede educadamente para o processo parar. Ele pode fazer cleanup. |
| `SIGKILL` | `kill -9 PID` | Execução sumária. O kernel mata o processo imediatamente. Sem cleanup. |

> **🏢 Analogia Corporativa:** O `SIGTERM` é como bater na porta do escritório e dizer: "Pessoal, o expediente acabou, salvem seus trabalhos e saiam." O `SIGKILL` é o segurança do prédio cortando a luz. Use o -9 **somente quando o processo não respondeu ao sinal padrão** — ele pode causar corrupção de dados se a aplicação estava no meio de uma gravação.

### 2.5 — Verificação Final

```bash
# Confirmar que a porta foi liberada
ss -tulnp | grep 8080

# Se não retornar nada, a porta está livre. Suba sua aplicação.
```

### 2.6 — Comandos Extras de Investigação de Processos

```bash
# Listar todos os processos em execução (visão completa)
ps aux

# Filtrar processos por nome
ps aux | grep nginx

# Ver processos em árvore (quem é pai de quem)
pstree -p

# Monitor interativo de processos (equivalente ao Gerenciador de Tarefas)
top

# Versão melhorada do top (se instalado)
htop

# Ver todos os file descriptors abertos por um processo específico
ls -la /proc/4521/fd/
```

> **💡 Dica:** O diretório `/proc` é um sistema de arquivos virtual que expõe informações do kernel em tempo real. Cada processo tem uma pasta `/proc/[PID]/` com detalhes completos. É a "radiografia" do sistema operacional.

---

## PARTE 3: A Camada Oculta de Segurança — Atributos de Arquivo

### 3.1 — O Cenário Real

Você configurou o `/etc/resolv.conf` (resolução DNS do servidor) com os DNS corretos. No dia seguinte, o sistema sobrescreveu suas configurações. Ou pior: um atacante que ganhou acesso de root tenta apagar seus logs de auditoria.

As permissões tradicionais (`chmod`) não são suficientes para esse nível de proteção. Entra o **Immutable Bit**.

### 3.2 — O Atributo Immutable (+i)

```bash
# Tornar um arquivo IMUTÁVEL (nem o root consegue alterar ou deletar)
sudo chattr +i /etc/resolv.conf
```

**O que acontece após esse comando:**

```bash
# Tentativa de editar
sudo nano /etc/resolv.conf      # Erro: não consegue salvar

# Tentativa de deletar
sudo rm /etc/resolv.conf         # Erro: Operation not permitted

# Tentativa de sobrescrever
sudo echo "nameserver 8.8.8.8" > /etc/resolv.conf   # Erro
```

**Nem o root consegue.** Isso é uma camada de proteção **acima** das permissões tradicionais.

### 3.3 — Verificar Atributos com lsattr

```bash
# Ver os atributos especiais de um arquivo
lsattr /etc/resolv.conf
```

```
----i------------- /etc/resolv.conf
```

O `i` na saída confirma: o **Immutable Bit** está ativo.

### 3.4 — Remover a Proteção (Quando Necessário)

```bash
# Remover o atributo immutable para poder editar
sudo chattr -i /etc/resolv.conf

# Fazer a alteração necessária
sudo nano /etc/resolv.conf

# Reativar a proteção
sudo chattr +i /etc/resolv.conf
```

### 3.5 — Outros Atributos Úteis

| Atributo | Flag | Efeito |
|----------|------|--------|
| **Immutable** | `+i` | Bloqueia qualquer alteração, remoção ou renomeação |
| **Append Only** | `+a` | Permite apenas **adicionar** conteúdo (ideal para logs de auditoria) |

```bash
# Log de auditoria que só pode receber novas linhas, nunca ser editado ou apagado
sudo chattr +a /var/log/audit/audit.log
```

> **🏢 Analogia Corporativa:** O `chmod` é o **crachá de acesso** do funcionário — define quem entra em qual sala. O `chattr +i` é um **cofre-forte com cadeado de aço** dentro da sala. Mesmo quem tem o crachá master (root) precisa pegar a chave específica (`chattr -i`) para abrir. Em servidores de produção, configurações críticas como DNS, certificados SSL e regras de firewall são protegidas assim.

### 3.6 — Resumo Visual: Camadas de Segurança no Linux

```
┌─────────────────────────────────────────────┐
│          CAMADA 3: Atributos (chattr)       │  ← Proteção máxima
│    Immutable (+i) / Append Only (+a)        │
├─────────────────────────────────────────────┤
│          CAMADA 2: Permissões (chmod)       │  ← Controle de acesso
│    Owner / Group / Others (rwx)             │
├─────────────────────────────────────────────┤
│          CAMADA 1: Propriedade (chown)      │  ← Identidade
│    Usuário dono / Grupo dono                │
└─────────────────────────────────────────────┘
```

Cada camada adiciona um nível de proteção. Um servidor bem configurado usa **todas as três**.

---

## 🔭 Visão de Futuro: Preparando o Terreno

Cada incidente que resolvemos nesta aula não foi apenas um exercício técnico. Foi a construção de uma **infraestrutura confiável** — e isso é o **pré-requisito absoluto** para o próximo nível.

Em um futuro próximo, você vai trabalhar com **sistemas de automação de fluxos** e **plataformas de integração** que rodam em servidores Linux. Esses sistemas executam **pipelines de dados em background** — fluxos que coletam informações de APIs, processam dados, movem arquivos e disparam ações automáticas 24 horas por dia, sem intervenção humana.

Agora veja como a base que você construiu é essencial:

**Problemas na base e suas consequências:**

| Problema na Base | Consequência na Automação |
|------------------|---------------------------|
| Disco saturado com logs | O pipeline de integração não consegue gravar dados temporários e falha silenciosamente |
| Porta ocupada por processo fantasma | O servidor de automação não sobe porque a porta que ele precisa está travada |
| Permissões mal configuradas | O serviço de automação não tem acesso aos arquivos que precisa processar |
| Configuração DNS sobrescrita | A automação não resolve os endpoints das APIs que precisa consumir |

**Base sólida e seus resultados:**

| Base Sólida | Resultado |
|-------------|-----------|
| Disco monitorado e logs rotacionados | Espaço garantido para processamento de dados |
| Portas auditadas e processos controlados | Serviços de automação sobem sem conflitos |
| Permissões Zero Trust com usuários de serviço | Cada processo roda com o mínimo de privilégio necessário |
| Arquivos críticos protegidos com atributos imutáveis | Configurações de infraestrutura blindadas contra erros e ataques |

A lógica que você praticou com `find | grep`, com `du | sort | head`, com pipes encadeados — isso é **pensamento de pipeline**. Você já está, sem perceber, raciocinando como quem projeta fluxos de automação: entrada, processamento, filtro, saída, ação.

Quando chegarmos ao módulo de automação, você não vai estar aprendendo algo novo do zero. Vai estar **aplicando em uma interface visual a mesma lógica que já domina no terminal**.

> **O terminal é a raiz. A automação é o fruto. E a árvore só dá frutos se a raiz for forte.**

---

## 📋 Checklist de Revisão — Aula 02

Antes de avançar para a Aula 03, confirme que você consegue:

- [ ] Diagnosticar saturação de disco com du -ah | sort -rh | head
- [ ] Verificar uso de disco por partição com df -h
- [ ] Verificar inodes com df -i
- [ ] Explicar o que é um File Descriptor e por que ele importa
- [ ] Explicar a diferença entre rm e truncamento (>) em logs ativos
- [ ] Encontrar arquivos fantasmas com lsof | grep "(deleted)"
- [ ] Identificar processos em portas com ss -tulnp e lsof -i :porta
- [ ] Encerrar processos com kill (SIGTERM) e kill -9 (SIGKILL), sabendo a diferença
- [ ] Investigar processos com ps aux, pstree e /proc
- [ ] Proteger arquivos críticos com chattr +i e verificar com lsattr
- [ ] Configurar logs append-only com chattr +a
- [ ] Explicar as três camadas de segurança: propriedade, permissões e atributos
- [ ] Entender que a lógica de pipes encadeados = pensamento de pipeline

---

> *"Qualquer pessoa consegue operar um servidor quando tudo está funcionando. O administrador Linux de verdade é aquele que resolve o caos às 2h da manhã — e deixa o servidor mais forte do que antes."*

---

**Próxima Aula:** Aula 03 — Shell Script: Fundamentos
