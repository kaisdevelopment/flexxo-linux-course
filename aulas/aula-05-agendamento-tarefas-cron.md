# 📘 Aula 05 — Agendamento de Tarefas com Cron: O Servidor que Trabalha Sozinho

## Módulo: Administração Linux | Flexxo - Polo Caxias do Sul

---

## 🎯 Objetivo

Aprender a fazer o servidor Linux **executar tarefas automaticamente** usando o agendador nativo **Cron**, conectando com as funções construídas na Aula 04 e entendendo o conceito de **gatilho temporal** — base de toda automação moderna.

---

## 1. O que é o Cron?

O Cron é um serviço (daemon) que roda em **background** no Linux, 24 horas por dia, verificando a cada minuto se existe alguma tarefa programada para aquele momento.

### Analogia

Pense no Cron como um **despertador inteligente** do servidor:

- O **crond** (daemon) → é o motor do despertador, sempre ligado
- O **crontab** → é a lista de alarmes de cada usuário
- Cada **cron job** → é um alarme específico ("às 7h, rode o relatório")

```
┌──────────────────────────────────────────────┐
│              SISTEMA CRON                     │
│                                               │
│  1. crond (daemon) → O motor, sempre ligado   │
│  2. crontab        → A agenda de cada usuário │
│  3. cron job       → Cada tarefa agendada     │
│                                               │
│  🔄 A cada minuto, o crond olha o crontab     │
│     e executa o que estiver no horário.        │
└──────────────────────────────────────────────┘
```

### Conexão com o mundo real

Em data centers e provedores de nuvem, o Cron é usado para:

- Backups automáticos noturnos
- Limpeza de logs antigos
- Relatórios de saúde do servidor
- Renovação de certificados SSL
- Sincronização de dados entre ambientes

É exatamente o conceito de **trigger por tempo** presente em qualquer plataforma de automação de fluxos: *"a cada X tempo, execute este processo"*.

---

## 2. Verificando se o Cron Está Ativo

```bash
systemctl status cron
```

Se não estiver ativo:

```bash
sudo systemctl start cron
sudo systemctl enable cron
```

O `enable` garante que o Cron **sobe automaticamente** quando o servidor reiniciar.

---

## 3. A Sintaxe do Crontab — Os 5 Campos

O crontab usa uma expressão com **5 campos de tempo** seguidos do **comando** a ser executado:

```
┌───────────── minuto        (0 - 59)
│ ┌─────────── hora          (0 - 23)
│ │ ┌───────── dia do mês    (1 - 31)
│ │ │ ┌─────── mês           (1 - 12)
│ │ │ │ ┌───── dia da semana (0 - 7) [0 e 7 = domingo]
│ │ │ │ │
* * * * *  comando_a_executar
```

### Regra dos filtros

Cada campo funciona como um **filtro**:

- `*` = qualquer valor (filtro aberto)
- Um número = valor exato
- `*/N` = de N em N (intervalo)
- `N-M` = faixa de valores
- `N,M,O` = lista de valores específicos

### Exemplos comentados

```bash
# A cada minuto (todos os filtros abertos)
* * * * *

# A cada hora cheia (minuto 0 de toda hora)
0 * * * *

# Todo dia às 8h da manhã
0 8 * * *

# Toda segunda-feira às 8h
0 8 * * 1

# Segunda a sexta às 22:30 (backup noturno em dia útil)
30 22 * * 1-5

# A cada 2 horas
0 */2 * * *

# Dia 1 de cada mês às 8h (relatório mensal)
0 8 1 * *

# A cada 15 minutos
*/15 * * * *

# Todo domingo às 3h da madrugada
0 3 * * 0

# A cada 30 min, seg-sex, entre 8h e 18h (horário comercial)
*/30 8-18 * * 1-5
```

---

## 4. Comandos Essenciais do Crontab

```bash
# Ver minha agenda de tarefas
crontab -l

# Editar minha agenda de tarefas
crontab -e

# Ver agenda de outro usuário (precisa ser root)
sudo crontab -u nome_usuario -l

# ⚠️ CUIDADO: Remove TODA a agenda sem confirmação!
# crontab -r
```

> **Dica de segurança:** nunca use `crontab -r` sem necessidade. Para remover uma tarefa específica, use `crontab -e` e apague apenas a linha desejada.

---

## 5. Prática — Primeiro Cron Job

### 5.1 Abrindo o crontab

```bash
crontab -e
```

Se perguntar qual editor, escolha `nano` (opção 1).

### 5.2 Primeiro agendamento — Teste simples

Adicione no final do arquivo:

```bash
# Meu primeiro cron job - teste a cada minuto
* * * * * echo "Cron funcionando! $(date)" >> /tmp/cron_teste.log
```

**Salvar:** `Ctrl+O` → `Enter` → `Ctrl+X`

Confirme que foi salvo:

```bash
crontab -l
```

Espere 1 a 2 minutos e verifique:

```bash
cat /tmp/cron_teste.log
```

Cada linha no arquivo representa **uma execução automática** feita pelo Cron, sem intervenção do usuário.

---

## 6. Conectando com a Aula 04 — Cron + Funções

### 6.1 Criando um script que usa a biblioteca de funções

```bash
nano ~/sysadmin-tools/relatorio_diario.sh
```

Conteúdo:

```bash
#!/bin/bash
# =============================================
# Script de Relatório Diário
# Executado automaticamente via Cron
# =============================================

# Carrega a biblioteca de funções
source ~/sysadmin-tools/funcoes.sh

# Define o arquivo de log com data
LOG="/tmp/relatorio_$(date '+%Y%m%d_%H%M').log"

# Executa o relatório completo (função da Aula 04)
relatorio_completo > "$LOG"

# Adiciona checagem de serviços ao log
checar_servicos_criticos >> "$LOG"

# Registra que o cron executou com sucesso
echo "[OK] Relatório gerado em: $(date)" >> /tmp/cron_execucoes.log
```

Tornar executável:

```bash
chmod +x ~/sysadmin-tools/relatorio_diario.sh
```

### 6.2 Testando manualmente primeiro

> **Regra de ouro do SysAdmin:** nunca coloque no Cron sem testar antes na mão.

```bash
bash ~/sysadmin-tools/relatorio_diario.sh
```

Verificar se gerou:

```bash
ls -la /tmp/relatorio_*.log
cat /tmp/relatorio_*.log
```

### 6.3 Agendando no Cron

```bash
crontab -e
```

Remova o teste anterior e adicione:

```bash
# Relatório diário do servidor - todo dia às 7h
0 7 * * * /bin/bash /home/USUARIO/sysadmin-tools/relatorio_diario.sh

# Relatório extra - segunda a sexta às 18h
0 18 * * 1-5 /bin/bash /home/USUARIO/sysadmin-tools/relatorio_diario.sh
```

> **Importante:** substitua `USUARIO` pelo nome real do usuário (use `whoami` para confirmar).

---

## 7. Boas Práticas do Cron

### 7.1 Sempre use caminhos completos

O Cron roda num ambiente mínimo — ele **não carrega** o `.bashrc` e pode não encontrar comandos sem caminho completo.

```bash
# ❌ Errado (pode não encontrar)
0 7 * * * bash relatorio_diario.sh

# ✅ Correto (caminho completo)
0 7 * * * /bin/bash /home/usuario/sysadmin-tools/relatorio_diario.sh
```

Para descobrir o caminho completo de qualquer comando:

```bash
which bash
which df
which systemctl
```

### 7.2 Redirecione a saída de erro

```bash
# Salva erros num log separado
0 7 * * * /bin/bash /home/usuario/sysadmin-tools/relatorio_diario.sh 2>> /tmp/cron_erros.log
```

O `2>>` captura **apenas os erros** (stderr) e adiciona no arquivo. Se algo falhar, você saberá exatamente o que aconteceu.

### 7.3 Comente cada linha

```bash
# Relatório de saúde do servidor - gerado automaticamente
0 7 * * * /bin/bash /home/usuario/sysadmin-tools/relatorio_diario.sh

# Limpeza de logs com mais de 30 dias - todo domingo às 4h
0 4 * * 0 /usr/bin/find /tmp -name "relatorio_*.log" -mtime +30 -delete
```

Daqui 6 meses você vai abrir o crontab e não vai lembrar pra que serve cada linha. **Comentários salvam sua vida.**

---

## 8. Diretórios Especiais do Cron

O Linux já vem com pastas prontas para agendamentos comuns:

```bash
ls /etc/cron.daily/       # Scripts que rodam todo dia
ls /etc/cron.weekly/      # Scripts que rodam toda semana
ls /etc/cron.monthly/     # Scripts que rodam todo mês
ls /etc/cron.d/           # Agendamentos avulsos do sistema
```

Se você colocar um script executável dentro de `/etc/cron.daily/`, ele roda todo dia automaticamente — sem precisar editar o crontab. Requer permissão de root.

Para verificar quando esses diretórios são processados:

```bash
cat /etc/crontab
```

---

## 9. Mapa de Conexão — Aula 04 + Aula 05

```
  AULA 04 (Funções)              AULA 05 (Cron)
  ═══════════════                ═══════════════
                    
  funcoes.sh ──────────┐
  ├── ver_disco()      │
  ├── ver_memoria()    │       relatorio_diario.sh
  ├── ver_processos()  ├──→    (source funcoes.sh)
  ├── relatorio_       │       (chama as funções)
  │   completo()       │              │
  └── checar_          │              │
      servicos_        ┘              ▼
      criticos()              
                               CRONTAB
                            ┌──────────────┐
                            │ 0 7 * * *    │──→ Roda todo dia 7h
                            │ 0 18 * * 1-5 │──→ Roda seg-sex 18h
                            └──────────────┘
                                    │
                                    ▼
                            /tmp/relatorio_*.log
                            (resultado automático)
```

---

## 10. Ponte com Automação de Fluxos

O agendamento por tempo (Cron) é o **primeiro tipo de gatilho (trigger)** que todo sistema de automação utiliza. Em plataformas de automação de fluxos, você encontra esse conceito como:

- **Schedule Trigger** — executa o fluxo a cada X minutos/horas/dias
- **Timer Node** — define intervalos entre etapas de um processo
- **Cron Expression** — a mesma sintaxe que aprendemos aqui, usada em diversas ferramentas

Mas gatilhos temporais são apenas o começo. Existem outros tipos:

- **Webhook** — executa quando uma API recebe um dado
- **File Trigger** — executa quando um arquivo novo aparece numa pasta
- **Event Trigger** — executa quando algo acontece em outro sistema

Todos seguem a mesma lógica: **"quando X acontecer, execute Y"**. Hoje você dominou o mais fundamental: **quando chegar a hora, execute.**

---

## 11. Referência Rápida

| Comando | O que faz |
|---|---|
| `crontab -l` | Lista todas as tarefas agendadas |
| `crontab -e` | Abre o editor para adicionar/editar tarefas |
| `crontab -r` | ⚠️ Remove TODAS as tarefas (sem confirmação) |
| `systemctl status cron` | Verifica se o serviço Cron está ativo |
| `which comando` | Mostra o caminho completo de um comando |
| `2>>` | Redireciona erros para um arquivo |

| Símbolo no Crontab | Significado | Exemplo |
|---|---|---|
| `*` | Qualquer valor | `* * * * *` = todo minuto |
| `*/N` | A cada N | `*/15 * * * *` = a cada 15 min |
| `N-M` | Faixa de valores | `8-18` = de 8h às 18h |
| `N,M,O` | Lista de valores | `1,3,5` = seg, qua, sex |

---

## 12. Desafio

Crie no crontab uma tarefa que:

1. Rode a cada **30 minutos**, de **segunda a sexta**, entre **8h e 18h**
2. Execute o script `relatorio_diario.sh`
3. Redirecione erros para `/tmp/cron_erros.log`

**Dica:** para restringir horário, use o formato de faixa no campo de hora: `8-18`

---

## w() — Registro de Aula

```
============================================================
 AULA 05 - AGENDAMENTO DE TAREFAS COM CRON
 Flexxo - Polo Caxias do Sul
 Módulo: Administração Linux
 Data: 30/03/2026
============================================================

OBJETIVOS ALCANÇADOS:
---------------------
[x] Compreender o sistema Cron (daemon, crontab, cron job)
[x] Dominar a sintaxe dos 5 campos do crontab
[x] Usar crontab -e, crontab -l e crontab -r
[x] Criar cron jobs com diferentes agendamentos
[x] Conectar scripts da Aula 04 (funções) com o Cron
[x] Usar caminhos completos e redirecionamento de erros
[x] Conhecer os diretórios /etc/cron.daily, weekly, monthly
[x] Entender gatilho temporal como base de automação de fluxos

CONTEÚDO ABORDADO:
------------------
1. O que é o Cron e como funciona (analogia do despertador)
2. Verificação do serviço: systemctl status cron
3. Sintaxe do crontab: 5 campos (min, hora, dia, mês, dia_semana)
4. Símbolos: * (qualquer), */N (intervalo), N-M (faixa), N,M (lista)
5. Comandos: crontab -l (listar), -e (editar), -r (remover tudo)
6. Primeiro cron job: echo com data para log de teste
7. Script relatorio_diario.sh usando source + funcoes.sh da Aula 04
8. Regra de ouro: testar manualmente antes de agendar
9. Boas práticas: caminhos completos, 2>> para erros, comentários
10. Diretórios especiais: /etc/cron.daily, weekly, monthly
11. Ponte: trigger temporal = base de plataformas de automação

ARQUIVOS CRIADOS/MODIFICADOS:
-----------------------------
~/sysadmin-tools/relatorio_diario.sh  -> Script de relatório automático
crontab do usuário                     -> Agendamentos configurados
/tmp/cron_teste.log                    -> Log do primeiro teste
/tmp/relatorio_YYYYMMDD_HHMM.log      -> Logs de relatório gerados
/tmp/cron_execucoes.log                -> Registro de execuções do cron
/tmp/cron_erros.log                    -> Captura de erros do cron

COMANDOS NOVOS APRENDIDOS:
--------------------------
crontab -e          -> Editar agenda de tarefas do usuário
crontab -l          -> Listar tarefas agendadas
crontab -r          -> Remover todas as tarefas (CUIDADO)
systemctl status    -> Verificar status de um serviço
systemctl start     -> Iniciar um serviço
systemctl enable    -> Habilitar serviço na inicialização
which               -> Mostrar caminho completo de um comando
2>>                 -> Redirecionar stderr (erros) para arquivo

EXPRESSÕES CRON PRATICADAS:
----------------------------
* * * * *           -> A cada minuto
0 7 * * *           -> Todo dia às 7h
0 18 * * 1-5        -> Seg-sex às 18h
*/15 * * * *        -> A cada 15 minutos
0 3 * * 0           -> Todo domingo às 3h
*/30 8-18 * * 1-5   -> A cada 30min, seg-sex, 8h-18h

PROGRESSO DO CURSO:
-------------------
Aula 01 [██████████] Terminal e navegação
Aula 02 [██████████] Arquivos e diretórios
Aula 03 [██████████] Permissões, usuários, grupos
Aula 04 [██████████] Funções no Shell (básicas + avançadas)
Aula 05 [██████████] Agendamento de tarefas (Cron) ← HOJE
Aula 06 [░░░░░░░░░░] Gerenciamento de processos e serviços
Aula 07 [░░░░░░░░░░] Redes e conectividade
Aula 08 [░░░░░░░░░░] Logs e monitoramento
Aula 09 [░░░░░░░░░░] Shell Script completo (projeto integrador)

CONEXÃO COM AUTOMAÇÃO:
-----------------------
→ Cron = trigger temporal (Schedule Trigger)
→ Mesma lógica usada em plataformas de automação de fluxos
→ Outros triggers futuros: webhook, file, event
→ Conceito central: "quando X acontecer, execute Y"

PRÓXIMA AULA:
-------------
Aula 06 - Gerenciamento de Processos e Serviços
(systemctl, journalctl, ps, kill, nice, foreground/background)

============================================================
```
