# 🧰 Aula 07: Logs, Monitoramento Avançado e Banco de Dados

Bem-vindo à penúltima aula! Hoje você deixará de ser apenas um administrador para se tornar um investigador de sistemas. Vamos aprender a ler o passado (logs), monitorar o presente (uso de disco/processos) e garantir a segurança do coração da empresa: o Banco de Dados.

---

## 📚 Comandos Essenciais do Dia

### 1. Logs (O Diário do Servidor)
- `/var/log/`: O diretório sagrado onde tudo é registrado.
- `tail -f /var/log/syslog` (ou `messages`): Acompanha o log rolando em tempo real.
- `grep "erro" /var/log/auth.log`: Filtra arquivos gigantes buscando apenas o que importa (ex: tentativas de invasão).

### 2. Monitoramento Avançado
- `df -h`: Verifica o espaço livre e ocupado das partições do disco.
- `du -sh *`: Mostra o tamanho exato de cada pasta e arquivo no diretório atual.
- `lsof | grep <arquivo>`: (List Open Files) Descobre qual processo (PID) está usando ou gravando em um arquivo.

### 3. Banco de Dados (MariaDB/MySQL)
- No Linux, o banco é um serviço (gerenciado via `systemctl`) e guarda seus dados no disco, geralmente em `/var/lib/mysql`.
- `mysql -u root -p`: Acessa a linha de comando do banco de dados (o 'cofre').
- `CREATE DATABASE nome;`: Cria um banco de dados novo.

---

## 🧪 Laboratórios Práticos (Caos Controlado)

### 🔴 Laboratório 1: A Inundação Silenciosa
**O Cenário:** Alerta vermelho! O disco do servidor está enchendo assustadoramente rápido e a aplicação vai parar a qualquer momento. Um desenvolvedor deixou o 'Modo Debug' ativado em um script fantasma.
**A Missão:** Descubra onde está o arquivo gigante em `/var/log`, qual processo está escrevendo nele e neutralize a ameaça antes que o disco chegue a 100%.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
# 1. Verifique a saturação do disco
df -h

# 2. Encontre o arquivo que está pesando (dentro de /var/log)
cd /var/log
du -sh * | sort -hr | head

# 3. Veja o log crescendo ao vivo (opcional, para entender o erro)
tail -f app_debug_fantasma.log

# 4. Descubra QUEM (qual PID) está escrevendo no arquivo
lsof | grep app_debug_fantasma.log

# 5. Mate o processo culpado (substitua <PID> pelo número encontrado)
kill -9 <PID>

# 6. Limpe o disco esvaziando o log sem apagá-lo
> /var/log/app_debug_fantasma.log
```
</details>

### 🔴 Laboratório 2: O Cofre Trancado por Dentro
**O Cenário:** A loja virtual caiu! Um analista júnior tentou 'aumentar a segurança' da pasta do banco de dados na madrugada e agora o serviço MariaDB recusa-se a iniciar.
**A Missão:** Use os logs do sistema (`journalctl`) para entender o erro exato e devolva o acesso ao banco corrigindo as permissões da pasta.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
# 1. Verifique o status do serviço (estará failed)
systemctl status mariadb

# 2. Leia a "caixa preta" para ver o motivo da falha
journalctl -xeu mariadb
# (Você verá erros de permissão negada na pasta /var/lib/mysql)

# 3. Cheque as permissões atuais da pasta
ls -ld /var/lib/mysql
# (Você notará que pertence ao usuário root)

# 4. Corrija o problema devolvendo a pasta ao usuário mysql
chown -R mysql:mysql /var/lib/mysql

# 5. Inicie o serviço novamente e confira o status
systemctl start mariadb
systemctl status mariadb
```
</details>

### 🔴 Laboratório 3: O Backup Que Chora
**O Cenário:** O cliente está desesperado pedindo o backup do banco de dados `loja_db`. Você notou que o script de backup diário roda via Cron, mas o arquivo gerado está vazio (0 bytes).
**A Missão:** Leia o script de backup para entender para onde os erros estão indo. Leia o log de erros, descubra por que o dump está falhando e corrija o problema criando o que falta.

<details>
<summary>🛠️ <b>Ver Gabarito de Resolução</b></summary>

```bash
# 1. Analise o script para entender como ele funciona
cat /opt/backup_diario.sh
# (Observe que os erros "2>>" vão para /var/log/backup_erro.log)

# 2. Leia o log de erros
cat /var/log/backup_erro.log
# (A mensagem dirá: Unknown database "loja_db")

# 3. O banco não existe! Acesse o MySQL para criá-lo
mysql -u root

# 4. Dentro do MySQL, crie o banco e saia
MariaDB [(none)]> CREATE DATABASE loja_db;
MariaDB [(none)]> exit

# 5. Rode o script de backup manualmente para testar
/opt/backup_diario.sh

# 6. Verifique se o arquivo de backup agora tem tamanho (> 0 bytes)
ls -lh /tmp/backup_loja.sql
```
</details>
