import json
from pathlib import Path
import psycopg
from psycopg import Error as PsycopgError
from ollama import Client

# ==========================================
# PARTE 1: INFRAESTRUTURA E CONEXÕES
# ==========================================

# Configuração de caminhos obrigatória
BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "config.json", encoding="utf-8") as f:
    config = json.load(f)

# Extração do DDL do arquivo Projeto.txt
projeto_path = BASE_DIR.parent / "Projeto.txt"
if not projeto_path.exists():
    print("Erro: Projeto.txt não encontrado na raiz do projeto.")
    raise SystemExit(1)

projeto_texto = projeto_path.read_text(encoding="utf-8")
try:
    # Recorte do DDL
    ddl = projeto_texto.split("3. DDL COMPLETO", 1)[1]
    ddl = ddl.split("4. CONSULTAS", 1)[0]
    ddl = ddl.strip()
    
    # Recorte das Consultas
    bloco_consultas = projeto_texto.split("4. CONSULTAS", 1)[1]
    bloco_consultas = bloco_consultas.split("FIM DO ARQUIVO", 1)[0]
    
except IndexError:
    print("Erro ao extrair dados. Verifique as marcações no Projeto.txt.")
    raise SystemExit(1)

# Conexão com o PostgreSQL
db = config["database"]
try:
    conn = psycopg.connect(
        host=db["host"],
        port=db["port"],
        dbname=db["dbname"],
        user=db["user"],
        password=db["password"]
    )
    # Habilitamos o autocommit para não travar em consultas com erro
    conn.autocommit = True 
except Exception as e:
    print(f"Erro ao conectar ao PostgreSQL: {e}")
    conn = None

# Configuração do cliente Ollama
ollama_config = config["ollama"]
client = Client(host=ollama_config["host"])


# ==========================================
# PARTE 2: FUNÇÕES DO MENU E IA
# ==========================================

def executar_consultas_fixas():
    """Extrai e executa as 5 consultas do Projeto.txt"""
    if not conn:
        print("\n[Erro] Sem conexão com o banco de dados.")
        return
        
    print("\n" + "="*40)
    print("EXECUÇÃO DAS 5 CONSULTAS DO PROJETO")
    print("="*40)
    
    consultas_split = bloco_consultas.split("CONSULTA ")
    cursor = conn.cursor()
    
    for c in consultas_split[1:]:
        num = "Desconhecido" # Resolve o aviso de unbound
        try:
            linhas = c.strip().split('\n')
            if not linhas:
                continue
                
            num = linhas[0].strip()
            
            objetivo = next((linha.split("OBJETIVO:", 1)[1].strip() for linha in linhas if "OBJETIVO:" in linha), "Não definido")
            sql_query = next((linha.split("SQL:", 1)[1].strip() for linha in linhas if "SQL:" in linha), None)
            
            if sql_query:
                print(f"\n--- CONSULTA {num} ---")
                print(f"Objetivo: {objetivo}")
                print(f"SQL: {sql_query}")
                
                # Executa o comando isoladamente 
                cursor.execute(sql_query)  # type: ignore
                
                # psycopg retorna list de tuplas ou None
                resultados = cursor.fetchall()
                
                print("\nResultados:")
                if resultados and cursor.description: 
                    # Captura o nome das colunas
                    colunas = [desc[0] for desc in cursor.description]
                    
                    # Cria um cabeçalho simples
                    header = " | ".join(colunas)
                    print(header)
                    print("-" * len(header))
                    
                    # Imprime cada linha formatada
                    for row in resultados:
                        # Converte tudo para string para evitar erros ao juntar
                        linha_formatada = " | ".join(str(item) for item in row)
                        print(linha_formatada)
                else:
                    print("(Nenhum registro encontrado ou consulta sem retorno)")
            else:
                print(f"\n[Aviso] SQL da Consulta {num} não encontrado.")
                
        except Exception as e:
            print(f"\n[Erro na Consulta {num}]: {e}")
            
    cursor.close()
    input("\nPressione Enter para voltar ao menu...")

def consultar_com_ia():
    """Converte pergunta natural em SQL usando Ollama e executa"""
    if not conn:
        print("\n[Erro] Sem conexão com o banco de dados.")
        return

    pergunta = input("\nFaça sua pergunta sobre os eventos: ")
    print("Processando (Ollama)...")
    
    # Prompt de sistema ensinando o modelo a retornar apenas SQL
    prompt_completo = f"""Você é um especialista em PostgreSQL.
O banco possui tabelas que foram criadas com o seguinte DDL:
{ddl}

A pergunta do usuário é: {pergunta}

Regras rigorosas:
1. Responda APENAS com o código SQL (SELECT). Não inclua explicações ou formatação markdown (como ```sql).
2. Utilize exclusivamente os nomes das tabelas e colunas fornecidos no DDL.
3. Se o usuário perguntar sobre vagas ou eventos físicos, utilize JOINs apropriados (ex: relacione SESSOES com ATIVIDADES, e ATIVIDADES com EVENTOS ou ESPACOS).
4. É ESTRITAMENTE PROIBIDO gerar comandos de modificação (INSERT, UPDATE, DELETE). Apenas SELECT.
"""

    try:
        response = client.chat(
            model=ollama_config["model"],
            messages=[{"role": "user", "content": prompt_completo}]
        )
        sql_gerado = response["message"]["content"].strip()
        
        # Limpa caso o modelo insista em mandar markdown
        if sql_gerado.startswith("```sql"): sql_gerado = sql_gerado[6:]
        if sql_gerado.startswith("```"): sql_gerado = sql_gerado[3:]
        if sql_gerado.endswith("```"): sql_gerado = sql_gerado[:-3]
        sql_gerado = sql_gerado.strip()
        
        print("\n--- Consulta SQL Gerada ---")
        print(sql_gerado)
        print("---------------------------")
        
        cursor = conn.cursor()
        cursor.execute(sql_gerado)
        resultados = cursor.fetchall()
        
        print("\nResultados:")
        if resultados and cursor.description: # Checa se tem resultado e colunas
            colunas = [desc[0] for desc in cursor.description]
            print(" | ".join(colunas))
            print("-" * (len(colunas) * 15))
            for row in resultados:
                print(row)
        else:
            print("(Nenhum registro encontrado)")
                
        cursor.close()
    except PsycopgError as e:
        # Captura erros do PostgreSQL (sintaxe, colunas inexistentes) e evita o crash
        print("\n[Erro] A IA gerou uma consulta SQL inválida para o banco atual.")
        print(f"Detalhes do erro no PostgreSQL: {e}")
        if 'cursor' in locals() and cursor: cursor.close()
    except Exception as e:
        # Captura erros gerais de Python
        print(f"\n[Erro inesperado na execução IA]: {e}")
        if 'cursor' in locals() and cursor: cursor.close()
        
    input("\nPressione Enter para voltar ao menu...")

def menu():
    while True:
        print("\n" + "="*40)
        print("SISTEMA DE GESTÃO DE EVENTOS E ESPAÇOS")
        print("="*40)
        print("1. Executar as 5 consultas do projeto")
        print("2. Fazer pergunta em linguagem natural (IA)")
        print("0. Sair")
        
        opcao = input("\nEscolha uma opção: ")
        
        if opcao == '0':
            print("Encerrando o sistema...")
            break
        elif opcao == '1':
            executar_consultas_fixas()
        elif opcao == '2':
            consultar_com_ia()
        else:
            print("Opção inválida.")

if __name__ == "__main__":
    if conn:
        print(f"✓ Conectado ao banco '{db['dbname']}' no host {db['host']}")
        print(f"✓ Ollama pronto (Modelo: {ollama_config['model']})")
        menu()
        conn.close()
    else:
        print("\n[Falha Crítica] Não é possível iniciar o menu sem conexão com o banco.")