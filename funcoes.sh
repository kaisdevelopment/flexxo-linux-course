#!/bin/bash
set -euo pipefail

# Definindo uma função
mostrar_uso_disco() {
    echo "=== Uso de Disco ==="
    df -h / | tail -1 | awk '{print "Usado: "$3" / Total: "$2" ("$5" em uso)"}'
}

mostrar_uso_memoria() {
    echo "=== Uso de Memória ==="
    free -h | grep Mem | awk '{print "Usado: "$3" / Total: "$2}'
}

# Chamando as funções
mostrar_uso_disco
mostrar_uso_memoria
#!/bin/bash
set -euo pipefail

# Definindo uma função
mostrar_uso_disco() {
    echo "=== Uso de Disco ==="
    df -h / | tail -1 | awk '{print "Usado: "$3" / Total: "$2" ("$5" em uso)"}'
}

mostrar_uso_memoria() {
    echo "=== Uso de Memória ==="
    free -h | grep Mem | awk '{print "Usado: "$3" / Total: "$2}'
}

# Chamando as funções
mostrar_uso_disco
mostrar_uso_memoria
