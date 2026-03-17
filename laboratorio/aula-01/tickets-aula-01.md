# 🧪 Laboratório 01: A Fundação (Buscas, Filtros e Zero Trust)

Este laboratório simula problemas reais do dia a dia de operações, onde a informação está perdida ou o acesso foi revogado acidentalmente.

---

## 🚨 Ticket 1: Agulha no Palheiro (Vazamento de Dados)

### 💥 Script de Preparação (Instrutor)
Rode o comando ofuscado abaixo no terminal do aluno para gerar o caos:
```bash
echo "bWtkaXIgLXAgL3RtcC9sb2dzL2FwcC8kKGRhdGUgKyVzKQpmb3IgaSBpbiB7MS4uNTAwMH07IGRvIGVjaG8gIklORk86IHN5c3RlbSBydW5uaW5nIG9rIiA+IC90bXAvbG9ncy9hcHAvbG9nXyRpLmxvZzsgZG9uZQplY2hvICJDUklUSUNBTF9FUlJPUjogZGJfY29ubmVjdGlvbl9mYWlsZWRfYXV0aF90b2tlbj14cHRvMTIzIiA+IC90bXAvbG9ncy9hcHAvbG9nXzMzNDcubG9n" | base64 -d | bash
```
*(O que isso faz: Cria uma pasta oculta com 5.000 arquivos de log idênticos. Apenas um deles contém uma chave de erro crítica).*

### 🕵️ Enunciado (Aluno)
**O Cenário:** O time de segurança informou que houve um vazamento de um token de banco de dados nos logs da aplicação que ficam em `/tmp/logs/`. São milhares de arquivos. Você tem 5 minutos para encontrar o token exato que vazou para podermos revogá-lo.

### 🛠️ Gabarito de Resolução
1. O aluno deve navegar ou apontar direto para a pasta: `cd /tmp/logs/`
2. Executar uma busca recursiva pelo erro: `grep -iR "CRITICAL_ERROR" /tmp/logs/`
3. O terminal cuspirá o arquivo exato (`log_3347.log`) e o token (`xpto123`).

### 🧠 Explicação SRE
No mundo real, você não abre arquivo por arquivo. O `grep -R` atua como um scanner de varredura profunda no disco. Aprender a filtrar dados (I/O) rapidamente é a base para alimentar ferramentas de monitoramento como Prometheus ou ELK Stack.

---

## 🚨 Ticket 2: O Deploy Bloqueado (Zero Trust)

### 💥 Script de Preparação (Instrutor)
Rode o comando ofuscado:
```bash
echo "bWtkaXIgLXAgL29wdC9hcHAKZWNobyAiZWNobyAnRGVwbG95aW5nIHVwZGF0ZS4uLiciID4gL29wdC9hcHAvZGVwbG95LnNoCmNobXvZCAwMDAgL29wdC9hcHAvZGVwbG95LnNoCmNob3duIHJvb3Q6cm9vdCAvb3B0L2FwcC9kZXBsb3kuc2g=" | base64 -d | sudo bash
```
*(O que isso faz: Cria um script de deploy em /opt/app, mas zera todas as permissões (000) e coloca o root como dono).*

### 🕵️ Enunciado (Aluno)
**O Cenário:** O pipeline de CI/CD falhou. O script responsável por atualizar a aplicação está no servidor em `/opt/app/deploy.sh`, mas ninguém consegue executá-lo, nem mesmo lê-lo. Resolva o problema de permissão e execute o script com sucesso.

### 🛠️ Gabarito de Resolução
1. O aluno tenta `cat /opt/app/deploy.sh` e recebe *Permission Denied*.
2. Audita o arquivo: `ls -l /opt/app/deploy.sh`. Verá `---------- 1 root root`.
3. Restaura as permissões corretas (Leitura e Execução): `sudo chmod 755 /opt/app/deploy.sh`.
4. Executa o script: `./opt/app/deploy.sh`.

### 🧠 Explicação SRE
A quebra das permissões UGO (User, Group, Other) é a principal causa de falhas em automações. Um sistema em background (como o n8n ou GitHub Actions) roda sob um usuário específico (ex: `www-data` ou `runner`). Se esse usuário não tiver permissão mínima (+x), a automação morre silenciosamente.

