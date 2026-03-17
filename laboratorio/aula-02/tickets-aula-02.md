# ☠️ Laboratório 02: O Caos Controlado e Método USE

Aqui aplicamos a metodologia USE (Utilization, Saturation, Errors) para lidar com saturação de recursos e anomalias de Kernel.

---

## 🚨 Ticket 3: O Arquivo Fantasma (Saturação de Disco)

### 💥 Script de Preparação (Instrutor)
Rode o comando ofuscado (Atenção: criará um arquivo de 1GB na RAM/Disco):
```bash
echo "ZmFsbG9jYXRlIC1sIDFHKiAvdG1wLy5kZWJ1Z19vdmVybG9hZC5sb2cKdGFpbCAtZiAvdG1wLy5kZWJ1Z19vdmVybG9hZC5sb2cgPiAvZGV2L251bGwgMj4mMSA2CnJtIC90bXAvLmRlYnVnX292ZXJsb2FkLmxvZw==" | base64 -d | bash
```
*(Versão legível para você: Ele aloca 1GB em um log, abre um processo 'tail' prendendo o arquivo na memória, e depois deleta o arquivo com 'rm').*

### 🕵️ Enunciado (Aluno)
**O Cenário:** O Zabbix disparou um alerta vermelho: Disco em 100%. O sistema de faturamento vai cair em 2 minutos. O desenvolvedor jura que apagou os logs antigos, mas o disco não liberou espaço. Salve o servidor!

### 🛠️ Gabarito de Resolução
1. O aluno roda `df -h` e constata o disco cheio.
2. Roda `du -ah / | sort -rh | head -n 10` e não encontra o arquivo grande.
3. Usa o comando SRE para arquivos presos: `lsof +L1` ou `lsof | grep deleted`.
4. Identifica o processo (PID do `tail`) que está segurando 1GB.
5. Arranca o mal pela raiz: `kill -9 <PID>`. O disco é liberado imediatamente.

### 🧠 Explicação SRE
Quando um processo abre um arquivo, o Kernel cria um *File Descriptor*. Se você deletar o arquivo com `rm`, o ponteiro de nome some, mas os dados continuam no disco até que o processo feche. A forma correta de limpar logs em produção é o truncamento: `> arquivo.log`.

---

## 🚨 Ticket 4: O Processo Zumbi (Saturação de Rede/Porta)

### 💥 Script de Preparação (Instrutor)
Rode o comando ofuscado:
```bash
echo "bmMgLWwgLXAgODA4MCA+IC9kZXYvbnVsbCAyPiYxICY=" | base64 -d | bash
```
*(O que isso faz: Sobe o Netcat escutando na porta 8080 em background invisível).*

### 🕵️ Enunciado (Aluno)
**O Cenário:** Precisamos subir a nova API na porta 8080. O comando de start falha com o erro genérico: *Address already in use*. Descubra quem está usando a porta e libere-a.

### 🛠️ Gabarito de Resolução
1. O aluno investiga a rede: `ss -tulnp | grep 8080` ou `lsof -i :8080`.
2. Descobre que o processo `nc` (Netcat) está dono da porta.
3. Anota o PID.
4. Mata o processo: `kill -9 <PID>`.

### 🧠 Explicação SRE
Sistemas complexos deixam rastros. Um container Docker que morreu pela metade, um serviço do systemd mal configurado... Saber mapear qual processo (PID) responde por qual porta de rede (Socket) é vital para evitar colisões em microsserviços.

---

## 🚨 Ticket 5: A Blindagem Nível Kernel (Imutabilidade)

### 💥 Script de Preparação (Instrutor)
Rode o comando ofuscado:
```bash
echo "ZWNobyAiZGJfcG9ydD01NDNPIiA+IC90bXAvZGJfY29uZmlnLmNvbmYKc3VkbyBjaG1vZCA3NzcgL3RtcC9kYl9jb25maWcuY29uZgpzdWRvIGNoYXR0ciAraSAvdG1wL2RiX2NvbmZpZy5jb25m" | base64 -d | bash
```
*(O que isso faz: Cria um arquivo de config, dá permissão total 777, e crava o bit +i com chattr, travando o arquivo até para o root).* 

### 🕵️ Enunciado (Aluno)
**O Cenário:** Um script malicioso alterou a porta do banco de dados para `543O` (com a letra O no final). O arquivo está em `/tmp/db_config.conf`. Você tentou editar com `sudo`, tentou deletar, mas o sistema diz: *Operation not permitted*. Conserte o arquivo.

### 🛠️ Gabarito de Resolução
1. O aluno tenta editar o arquivo e falha.
2. Verifica permissões (`ls -l`) e vê que está 777 (o que gera muita confusão mental).
3. Analisa atributos estendidos do sistema de arquivos: `lsattr /tmp/db_config.conf`.
4. Enxerga o bit `i` (Imutável).
5. Remove a blindagem: `sudo chattr -i /tmp/db_config.conf`.
6. Edita e corrige o arquivo.

### 🧠 Explicação SRE
Segurança de infraestrutura vai além de usuários. O `chattr` atua direto no File System (Ext4/XFS). É usado por malwares para impedir que antivírus deletem seus arquivos, mas também é usado por SREs para proteger arquivos críticos (`resolv.conf`) de serem sobrescritos por automações defeituosas.

