# 📘 Material de Apoio — Aula 01: A Fundação e o Controle

### Curso: Administração Linux | Mentoria Individual — Flexxo (Caxias do Sul)
### Instrutor: Wiliam | Data: Março/2026

---

> **Resumo:** Nesta aula construímos a base de tudo que virá a seguir: entendemos o ambiente WSL como laboratório profissional que replica servidores reais, dominamos as ferramentas de busca e filtragem de dados (find e grep) — a base do pensamento de pipeline — e aprendemos por que o modelo Zero Trust é o alicerce da segurança moderna em servidores Linux.

---

## 📍 Pré-requisitos

- [ ] Windows 10/11 com WSL2 instalado e funcional
- [ ] Distribuição Ubuntu instalada via Microsoft Store
- [ ] Terminal aberto e pronto para comandos

---

## PARTE 1: O Ambiente — WSL (Windows Subsystem for Linux)

### 1.1 — O que é e Por que Usamos

O **WSL** (Windows Subsystem for Linux) é uma camada de compatibilidade desenvolvida pela Microsoft que permite rodar distribuições Linux **nativamente** dentro do Windows, sem a necessidade de dual-boot ou de uma máquina virtual pesada como o VirtualBox.

Na prática, isso significa que você tem acesso ao **mesmo kernel e às mesmas ferramentas** que um servidor Ubuntu em produção na AWS, Azure ou em um data center físico — tudo isso a partir do seu terminal no Windows.

O WSL existe em duas versões:

| Versão | Característica Principal |
|--------|--------------------------|
| **WSL 1** | Camada de tradução de chamadas do sistema (mais leve, menos compatível) |
| **WSL 2** | Kernel Linux real rodando em uma micro VM gerenciada pelo Hyper-V (compatibilidade total) |

Neste curso utilizamos o **WSL 2**, que oferece compatibilidade total com ferramentas de administração Linux.

> **🏢 Analogia Corporativa:** Imagine que o WSL é como ter um **laboratório de testes dentro do prédio da empresa**, em vez de precisar viajar até o data center toda vez que quer testar algo. O ambiente é real, mas o risco é controlado. Você treina localmente, executa em produção com confiança.

### 1.2 — Relevância no Mundo Real

| Cenário | Sem WSL | Com WSL |
|---------|---------|---------|
| Testar um script de backup | Precisa de uma VM ou acesso SSH ao servidor | Roda direto no terminal local |
| Aprender comandos Linux | Precisa de uma máquina separada | Abre o terminal e pratica |
| Simular incidentes | Risco de danificar o ambiente | Ambiente isolado e descartável |
| Desenvolver automações | Necessário ambiente remoto | Desenvolvimento 100% local |

O WSL não é um brinquedo. É a **ferramenta oficial de milhares de engenheiros DevOps e SREs** que desenvolvem e testam localmente antes de fazer deploy em ambientes de nuvem.

### 1.3 — Comandos Iniciais de Verificação do Ambiente

```bash
# Verificar qual distribuição está rodando
cat /etc/os-release

# Verificar a versão do kernel Linux
uname -r

# Verificar o nome do host (máquina)
hostname

# Verificar qual usuário está logado
whoami

# Verificar o diretório atual
pwd

# Listar arquivos do diretório atual com detalhes
ls -la
```

> **💡 Dica:** O resultado de `uname -r` no WSL 2 vai mostrar algo como `5.15.x.x-microsoft-standard-WSL2`. Isso confirma que você está rodando um kernel Linux real, gerenciado pela Microsoft.

---

## PARTE 2: Busca e Filtros de Dados — find e grep

Se o Linux é um oceano de arquivos e informações, o `find` e o `grep` são seus **sonar e radar**. Um localiza **onde** a coisa está; o outro localiza **o que** está escrito dentro dela.

Juntos, eles formam a dupla mais usada no dia a dia de qualquer administrador de sistemas.

### 2.1 — find: O Localizador de Arquivos

O `find` varre a estrutura de diretórios buscando arquivos por **nome, tipo, tamanho, data de modificação** e muito mais.

**Sintaxe Básica:**

```
find [ONDE BUSCAR] [CRITÉRIOS] [AÇÃO]
```

**Exemplos Práticos:**

```bash
# Encontrar todos os arquivos .log dentro de /var/log
find /var/log -name "*.log" -type f

# Encontrar arquivos maiores que 100MB
find / -type f -size +100M 2>/dev/null

# Encontrar arquivos modificados nas últimas 24 horas
find /etc -type f -mtime -1

# Encontrar diretórios vazios (candidatos a limpeza)
find /tmp -type d -empty

# Encontrar arquivos com permissão 777 (risco de segurança!)
find / -type f -perm 0777 2>/dev/null
```

**Detalhamento dos Parâmetros:**

| Parâmetro | Função | Exemplo |
|-----------|--------|---------|
| `-name "*.log"` | Filtra pelo padrão do nome | Todos os arquivos terminados em .log |
| `-iname "*.Log"` | Ignora maiúsculas/minúsculas | Encontra .log, .LOG, .Log |
| `-type f` | Busca apenas arquivos | Ignora diretórios e links |
| `-type d` | Busca apenas diretórios | Ignora arquivos |
| `-size +100M` | Filtra por tamanho (maior que 100MB) | Caçar arquivos grandes |
| `-size -1k` | Filtra por tamanho (menor que 1KB) | Encontrar arquivos quase vazios |
| `-mtime -1` | Modificado há menos de 1 dia | Arquivos recentes |
| `-mtime +30` | Modificado há mais de 30 dias | Arquivos antigos |
| `-perm 0777` | Filtra por permissão específica | Arquivos com acesso total (risco) |
| `-empty` | Arquivos ou diretórios vazios | Candidatos a limpeza |
| `-user root` | Pertence ao usuário root | Auditoria de propriedade |
| `2>/dev/null` | Descarta mensagens de erro | Saída limpa |

### 2.2 — grep: O Filtro de Conteúdo

Se o `find` localiza o **arquivo**, o `grep` localiza a **informação dentro do arquivo**. O nome vem de **G**lobal **R**egular **E**xpression **P**rint.

**Sintaxe Básica:**

```
grep [OPÇÕES] "PADRÃO" [ARQUIVO]
```

**Exemplos Práticos:**

```bash
# Buscar a palavra error dentro de um log do sistema
grep "error" /var/log/syslog

# Busca case-insensitive
grep -i "failed" /var/log/auth.log

# Buscar recursivamente em todos os arquivos de um diretório
grep -r "password" /etc/

# Mostrar o número da linha onde o padrão foi encontrado
grep -n "timeout" /var/log/syslog

# Contar quantas vezes o padrão aparece
grep -c "error" /var/log/syslog

# Mostrar linhas que NÃO contêm o padrão (inversão)
grep -v "INFO" /var/log/app.log

# Mostrar 3 linhas de contexto antes e depois do resultado
grep -B 3 -A 3 "CRITICAL" /var/log/syslog
```

**Parâmetros Essenciais:**

| Parâmetro | Função | Quando Usar |
|-----------|--------|-------------|
| `-i` | Ignora maiúsculas/minúsculas | Quando não sabe a capitalização exata |
| `-r` | Busca recursiva em subdiretórios | Vasculhar uma árvore inteira de configs |
| `-n` | Exibe o número da linha | Para localizar exatamente onde editar |
| `-c` | Conta o total de ocorrências | Para métricas rápidas |
| `-v` | Inversão (linhas que NÃO contêm) | Filtrar ruído |
| `-l` | Mostra apenas o nome do arquivo | Quando quer saber em qual arquivo está |
| `-B N` | Mostra N linhas antes (Before) | Contexto do que aconteceu antes do erro |
| `-A N` | Mostra N linhas depois (After) | Contexto do que aconteceu depois do erro |
| `-E` | Expressões regulares estendidas | Padrões complexos |

### 2.3 — A Combinação Poderosa: find + grep

Aqui é onde o poder se multiplica. Usar `find` para localizar os arquivos e `grep` para buscar dentro deles:

```bash
# Encontrar todos os .conf e procurar qual menciona a porta 8080
find /etc -name "*.conf" -exec grep -l "8080" {} \;

# Encontrar scripts shell e procurar qual usa rm -rf
find /opt/scripts -name "*.sh" -exec grep -n "rm -rf" {} \;

# Encontrar logs da última hora e buscar erros críticos
find /var/log -name "*.log" -mmin -60 -exec grep -l "CRITICAL" {} \;
```

**Decomposição do primeiro comando:**

| Parte | O que faz |
|-------|-----------|
| `find /etc` | Varre o diretório /etc |
| `-name "*.conf"` | Filtra apenas arquivos .conf |
| `-exec` | Para cada arquivo encontrado, executa o comando seguinte |
| `grep -l "8080"` | Busca 8080 e mostra apenas o nome do arquivo |
| `{} \;` | {} é substituído pelo caminho do arquivo |

> **🔮 Ponte para o Futuro — Pipeline de Dados:** Essa lógica de buscar, filtrar e agir é exatamente o que você vai encontrar em plataformas de integração visual. Imagine um fluxo com três blocos: o primeiro coleta dados de uma fonte (como o find coleta arquivos), o segundo filtra e parseia o resultado (como o grep filtra conteúdo), o terceiro toma uma ação (envia alerta, grava num banco, move arquivo). Você está aprendendo o conceito raiz de pipeline de dados. A lógica é a mesma — só muda a interface.

---

## PARTE 3: Zero Trust na Prática — Usuários e Permissões

### 3.1 — O Princípio: Nunca Confie, Sempre Verifique

No modelo de segurança **Zero Trust**, nenhum usuário, processo ou sistema é confiável por padrão — mesmo que esteja dentro da rede. Cada ação precisa de **autorização explícita**.

O Linux já nasceu com essa filosofia embutida no seu sistema de permissões. Cada arquivo, cada processo, cada conexão tem um **dono**, um **grupo** e um **nível de acesso** definido.

### 3.2 — Por que NÃO Rodamos Tudo como root?

O usuário `root` é o **superusuário do sistema**. Ele tem poder absoluto: pode apagar o sistema operacional inteiro com um comando, expor portas de rede, desabilitar firewalls, ler qualquer arquivo.

Os riscos incluem:

- **Erro humano amplificado:** Um `rm -rf /` acidental destrói tudo sem pedir confirmação
- **Vetor de ataque:** Se um invasor compromete um processo rodando como root, ele tem controle total
- **Sem auditoria:** Ações como root não ficam associadas a uma pessoa específica
- **Não conformidade:** Auditorias de segurança (ISO 27001, SOC 2) exigem rastreabilidade

> **🏢 Analogia Corporativa:** Em um data center sério, nem o diretor de TI tem acesso root irrestrito aos servidores de produção. Ele usa um usuário nominal (com seu nome) e, quando precisa de privilégios elevados, solicita elevação temporária via sudo — que fica registrada em log para auditoria. Isso é Zero Trust em ação.

### 3.3 — Estrutura de Permissões do Linux

Cada arquivo e diretório no Linux possui três camadas de permissão:

```
-rwxr-xr-- 1 wiliam devops 4096 Mar 15 10:00 deploy.sh
```

- Primeiro bloco `rwx` = permissões do **dono** (User/Owner)
- Segundo bloco `r-x` = permissões do **grupo** (Group)
- Terceiro bloco `r--` = permissões de **outros** (Others)

**As Três Permissões Fundamentais:**

| Letra | Permissão | Valor Numérico | Em Arquivos | Em Diretórios |
|-------|-----------|----------------|-------------|---------------|
| `r` | Leitura (read) | 4 | Pode ler o conteúdo | Pode listar o conteúdo |
| `w` | Escrita (write) | 2 | Pode modificar | Pode criar/remover arquivos dentro |
| `x` | Execução (execute) | 1 | Pode executar como programa | Pode entrar (cd) no diretório |

**Calculando Permissões Numéricas:**

| Permissão | Cálculo | Resultado |
|-----------|---------|-----------|
| `rwx` | 4+2+1 | **7** |
| `r-x` | 4+0+1 | **5** |
| `r--` | 4+0+0 | **4** |
| `rw-` | 4+2+0 | **6** |
| `---` | 0+0+0 | **0** |

**Exemplos comuns:**

| Código | Permissão | Uso Típico |
|--------|-----------|------------|
| `755` | rwxr-xr-x | Scripts executáveis, diretórios de aplicação |
| `750` | rwxr-x--- | Scripts restritos ao dono e grupo |
| `644` | rw-r--r-- | Arquivos de configuração (leitura pública) |
| `600` | rw------- | Chaves SSH, arquivos sensíveis |
| `700` | rwx------ | Diretório pessoal, scripts privados |

### 3.4 — Comandos de Gestão de Permissões

```bash
# Ver permissões detalhadas de arquivos
ls -la /etc/passwd

# Ver permissões de um diretório específico
ls -ld /var/log/

# Alterar permissões — formato numérico
chmod 750 deploy.sh
chmod 600 ~/.ssh/id_rsa

# Alterar permissões — formato simbólico
chmod u+x script.sh
chmod g-w config.conf
chmod o-rwx secrets.txt

# Alterar permissões recursivamente em um diretório
chmod -R 750 /opt/app/
```

### 3.5 — Comandos de Gestão de Usuários e Grupos

```bash
# Criar um novo usuário com diretório home
sudo adduser analista

# Criar um usuário de serviço (sem shell interativo — SEGURANÇA!)
sudo useradd -r -s /usr/sbin/nologin app-monitor

# Verificar informações de um usuário
id analista

# Adicionar usuário a um grupo
sudo usermod -aG sudo analista

# Criar um grupo
sudo groupadd devops

# Alterar o dono e grupo de um arquivo
chown wiliam:devops deploy.sh

# Alterar dono recursivamente
chown -R www-data:www-data /var/www/html/

# Ver quem está logado no sistema
who

# Ver histórico de logins
last
```

**Tipos de Usuários no Linux:**

| Tipo | UID | Shell | Finalidade |
|------|-----|-------|------------|
| root | 0 | /bin/bash | Superusuário — NUNCA usar para tarefas rotineiras |
| Usuário comum | 1000+ | /bin/bash | Pessoas reais (analista, wiliam, etc.) |
| Usuário de serviço | 1-999 | /usr/sbin/nologin | Aplicações (nginx, mysql, app-monitor) |

### 3.6 — O Comando sudo: Elevação Controlada

```bash
# Executar um comando como root (fica registrado em /var/log/auth.log)
sudo systemctl restart nginx

# Ver o que o usuário atual pode fazer com sudo
sudo -l

# Executar um comando como outro usuário
sudo -u www-data whoami

# Editar o arquivo de configuração do sudo (CUIDADO!)
sudo visudo
```

**Regra de ouro para servidores de produção:**

- Aplicações rodam com usuários de serviço dedicados (sem shell, sem senha)
- Pessoas usam contas nominais e escalam via sudo
- Cada ação privilegiada fica registrada em /var/log/auth.log
- Ninguém faz login direto como root
- Ninguém usa chmod 777 em produção

---

## 🔭 Visão de Futuro: Preparando o Terreno

Tudo o que você aprendeu nesta aula forma o alicerce para o que vem a seguir:

| O que você aprendeu | Como se conecta com automação |
|---------------------|-------------------------------|
| find + grep (buscar, filtrar, agir) | É a lógica de pipeline de dados: um bloco coleta, outro filtra, outro age |
| Pipes encadeando comandos | É o conceito de fluxo de dados passando de uma etapa para outra |
| Permissões e Zero Trust | Garantem que cada processo de automação tenha apenas o acesso que precisa |
| Usuários de serviço (nologin) | Toda aplicação de automação roda como um usuário de serviço dedicado |
| WSL como laboratório | Ambiente seguro para testar tudo antes de colocar em produção |

Sem essa base, nenhuma automação é confiável. Com ela, qualquer automação é possível.

---

## 📋 Checklist de Revisão — Aula 01

- [ ] Explicar o que é o WSL e por que ele é relevante para administração Linux
- [ ] Verificar informações do sistema com uname, hostname, whoami
- [ ] Usar find para localizar arquivos por nome, tipo, tamanho e data
- [ ] Usar grep para filtrar conteúdo dentro de arquivos com diferentes flags
- [ ] Combinar find + grep com o parâmetro -exec
- [ ] Explicar o conceito de pipeline (buscar, filtrar, agir)
- [ ] Explicar por que não rodamos tudo como root (princípio Zero Trust)
- [ ] Ler e interpretar a saída de ls -la (tipo, permissões, dono, grupo)
- [ ] Calcular permissões numéricas (ex: rwxr-x--- = 750)
- [ ] Definir permissões com chmod (notação numérica e simbólica)
- [ ] Alterar proprietário e grupo com chown
- [ ] Criar usuários comuns com adduser
- [ ] Criar usuários de serviço sem shell interativo com useradd
- [ ] Usar sudo para elevação de privilégios com rastreabilidade

---

> *"Dominar o terminal não é decorar comandos. É entender a lógica por trás: buscar, filtrar, agir, proteger. Essa lógica é universal — do terminal ao pipeline mais complexo do mundo corporativo."*

---

**Próxima Aula:** Aula 02 — Troubleshooting Corporativo
