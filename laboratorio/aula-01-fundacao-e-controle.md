# 🧪 Laboratório 01: A Fundação e o Controle (WSL, Buscas e Zero Trust)

## 1. O Ambiente: WSL (Windows Subsystem for Linux)
No mundo corporativo, nem sempre você terá um servidor físico ao seu lado. O WSL nos permite rodar um kernel Linux real diretamente do Windows. É aqui que nossa jornada de infraestrutura começa. Tudo o que roda aqui, roda em um servidor na nuvem da AWS, Azure ou Google Cloud.

## 2. Busca, Filtros e a Lógica de Pipelines
Servidores geram gigabytes de texto por dia. Achar a informação certa é o primeiro passo de qualquer Troubleshooting.

### Comando `find`: O Rastreador
O `find` não apenas busca arquivos, ele entende a estrutura do sistema.
* **Buscar por nome exato:** `find /var/log -name "syslog"`
* **Buscar por extensão:** `find /etc -name "*.conf"`
* **Buscar por arquivos gigantes (ex: maiores que 500MB):** `find / -type f -size +500M`

### Comando `grep`: O Extrator de Dados
Se o `find` acha o arquivo, o `grep` vasculha o conteúdo dele.
* **Buscando um erro específico:** `grep "ERROR" /var/log/syslog`
* **Busca recursiva em todos os arquivos de uma pasta (ignorando maiúsculas/minúsculas):** `grep -iR "fail" /var/log/`

> 🔗 **Conexão com o Futuro (Visão Low-Code):** Quando você for criar pipelines de automação, entenderá que o `find` funciona como o **gatilho de busca** (um nó que extrai dados) e o `grep` atua como o **nó condicional (Filter/If)**, limpando a sujeira e passando para a próxima etapa apenas os dados que importam.

## 3. Segurança SRE e Zero Trust (Usuários e Permissões)
O conceito de **Zero Trust** (Confiança Zero) significa: nunca confie, sempre verifique, e dê apenas a permissão estritamente necessária.

### Gestão de Permissões (`chmod`)
Permissões no Linux são lidas em blocos de três: **Dono (User)**, **Grupo (Group)** e **Outros (Others)**. Usamos a escala octal:
- **4** = Ler (Read)
- **2** = Escrever (Write)
- **1** = Executar (Execute)

**Exemplos Reais:**
* `chmod 777 arquivo`: O caos. Qualquer pessoa pode ler, editar e rodar o arquivo. Proibido em produção!
* `chmod 755 script.sh`: O Dono tem controle total (7). Grupo e Outros só podem ler e executar (5).
* `chmod 600 chave.pem`: Apenas o Dono pode ler e escrever. Essencial para chaves de segurança.

### Propriedade (`chown`)
* `chown root:www-data /var/www/html`: Define que o dono é o `root`, mas o grupo `www-data` (que o servidor web usa) tem acesso.

