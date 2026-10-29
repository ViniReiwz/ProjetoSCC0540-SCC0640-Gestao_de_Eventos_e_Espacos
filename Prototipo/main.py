import json
from pathlib import Path
import psycopg
from ollama import Client

# 1. Configuração de caminhos obrigatória e leitura do config.json
BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "config.json", encoding="utf-8") as f:
    config = json.load(f)

# 2. Extração do DDL do arquivo Projeto.txt
projeto_path = BASE_DIR.parent / "Projeto.txt"
if not projeto_path.exists():
    print("Erro: Projeto.txt não encontrado na raiz do projeto.")
    raise SystemExit(1)

projeto = projeto_path.read_text(encoding="utf-8")
try:
    # Recorte exato exigido pelas regras do projeto
    ddl = projeto.split("3. DDL COMPLETO", 1)[1]
    ddl = ddl.split("4. CONSULTAS", 1)[0]
    ddl = ddl.strip()
    print("✓ DDL extraído com sucesso do Projeto.txt")
except IndexError:
    print("Erro ao extrair o DDL. Verifique as marcações '3. DDL COMPLETO' e '4. CONSULTAS' no Projeto.txt.")
    raise SystemExit(1)

# 3. Conexão com o PostgreSQL
db = config["database"]
try:
    conn = psycopg.connect(
        host=db["host"],
        port=db["port"],
        dbname=db["dbname"],
        user=db["user"],
        password=db["password"]
    )
    print("✓ Conexão com PostgreSQL estabelecida")
except Exception as e:
    print(f"Erro ao conectar ao PostgreSQL: {e}")
    conn = None # Mantemos None para tratar no menu caso o banco caia

# 4. Configuração do cliente Ollama
ollama_config = config["ollama"]
client = Client(host=ollama_config["host"])
print(f"✓ Ollama configurado para usar o modelo: {ollama_config['model']}")

if __name__ == "__main__":
    print("\nInicialização concluída. O menu será implementado na próxima etapa.")
    if conn:
        conn.close()