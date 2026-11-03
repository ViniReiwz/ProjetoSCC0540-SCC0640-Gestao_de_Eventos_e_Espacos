import json
import re
from pathlib import Path
import psycopg
from psycopg import Error as PsycopgError
import ollama
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

# ------------------------------------------
# Tarefa 1: regras do prompt
# ------------------------------------------

# Dicas de JOIN para o modelo, conforme SQL/DDL.sql do repositório (commit c3d327f, 02/11).
# ATUALIZAR sempre que o DDL mudar.
DICAS_JOIN = """- Os nomes no DDL não têm aspas: escreva tabelas e colunas SEM aspas duplas (ex.: SELECT NomeEvento FROM EVENTOS).
- EVENTO é a iniciativa inteira (congresso, semana acadêmica, feira): nome em EVENTOS.NomeEvento
- ATIVIDADE é o que acontece dentro do evento (workshop, palestra, minicurso, live, mesa-redonda): nome em ATIVIDADES.NomeAtividade.
  Se a pergunta citar um workshop, palestra, minicurso etc., filtre por ATIVIDADES.NomeAtividade, NÃO por EVENTOS.NomeEvento
- para comparar nomes digitados pelo usuário, use ILIKE com % (ex.: NomeAtividade ILIKE '%workshop de postgresql%')
- atividade pertence a um evento: ATIVIDADES.EventoID = EVENTOS.EventoID
- sessão é uma realização de uma atividade: SESSOES.AtividadeID = ATIVIDADES.AtividadeID
- local, sala ou capacidade de uma SESSÃO: SESSOES.EspacoID = ESPACOS.EspacoID
- ferramentas de um espaço: ESPACO_FERRAMENTA.EspacoID = ESPACOS.EspacoID
- ferramentas que uma atividade precisa: ATIVIDADE_FERRAMENTA.AtividadeID = ATIVIDADES.AtividadeID
- quem está inscrito em um EVENTO: PARTICIPANTES (CPF, EventoID), junto com PESSOAS por CPF
- quem está inscrito em uma SESSÃO e com qual função: INSCRICOES (CPF, SessaoID, Funcao), junto com PESSOAS por CPF
- quem promove um evento: PROMOVE (PromotorID, EventoID); o promotor é uma pessoa (PESSOAS.PromotorID) ou uma organização (ORGANIZACOES.PromotorID)
- telefones: PESSOA_TELEFONE por CPF, ORGANIZACAO_TELEFONE por CNPJ"""

RESPOSTA_IMPOSSIVEL = "IMPOSSIVEL"


def compactar_ddl(texto):
    """Deixa só tipos e tabelas, sem comentários: prompt menor = resposta mais rápida"""
    # Funções e triggers não ajudam a gerar SELECT; corta a partir do primeiro deles
    corte = re.search(r"CREATE\s+(OR\s+REPLACE\s+)?(FUNCTION|TRIGGER|PROCEDURE)", texto, flags=re.IGNORECASE)
    if corte:
        texto = texto[:corte.start()]
    texto = re.sub(r"--[^\n]*", "", texto)   # comentários SQL
    texto = re.sub(r"^\s*=+\s*$", "", texto, flags=re.MULTILINE)  # linhas ===== do template
    linhas = [linha.strip() for linha in texto.splitlines() if linha.strip()]
    return "\n".join(linhas)


DDL_COMPACTO = compactar_ddl(ddl)


def montar_prompt(pergunta):
    """Monta o prompt: papel, esquema, regras, dicas de JOIN e a pergunta"""
    return f"""Você é um tradutor de perguntas em português para SQL do PostgreSQL.

ESQUEMA DO BANCO (DDL):
{DDL_COMPACTO}

REGRAS OBRIGATÓRIAS:
1. Gere UM único comando SELECT (pode começar com WITH). Nunca gere INSERT, UPDATE, DELETE, DROP, ALTER, CREATE ou TRUNCATE.
2. Use somente tabelas e colunas que existem no esquema acima. Não invente nomes.
3. Responda apenas com o SQL, sem explicações, sem comentários e sem markdown (nada de ```).
4. Mostre colunas legíveis para uma pessoa (NomeEspaco, NomePessoa, NomeEvento, NomeAtividade, RazaoSocial...) em vez de só IDs: faça JOIN com a tabela que tem o nome.
5. Se a pergunta não puder ser respondida com esse esquema, responda exatamente: {RESPOSTA_IMPOSSIVEL}

COMO AS TABELAS SE LIGAM:
{DICAS_JOIN}

PERGUNTA: {pergunta}
/no_think"""


# ------------------------------------------
# Tarefa 2: limpeza, validação e erros
# ------------------------------------------

class SQLRecusado(Exception):
    """SQL gerado pela IA que não passa na validação"""


def limpar_resposta(texto):
    """Remove o raciocínio do qwen3 e o markdown que o modelo insiste em mandar"""
    texto = re.sub(r"<think>.*?</think>", "", texto, flags=re.DOTALL)
    texto = re.sub(r"```(?:sql)?", "", texto, flags=re.IGNORECASE)
    return texto.strip()


def validar_sql(sql):
    """Aceita apenas um único comando de leitura; senão levanta SQLRecusado"""
    if not sql:
        raise SQLRecusado("o modelo não devolveu nenhum SQL.")
    if sql.upper().startswith(RESPOSTA_IMPOSSIVEL):
        raise SQLRecusado("a pergunta não pode ser respondida com o esquema do banco.")

    sql = sql.rstrip().rstrip(";").strip()
    if ";" in sql:
        raise SQLRecusado("a resposta tem mais de um comando SQL.")

    primeira_palavra = sql.split(None, 1)[0].upper()
    if primeira_palavra not in ("SELECT", "WITH"):
        raise SQLRecusado(f"só consultas SELECT são permitidas (recebido: {primeira_palavra}).")
    return sql


def consultar_com_ia():
    """Converte pergunta natural em SQL usando Ollama e executa"""
    if not conn:
        print("\n[Erro] Sem conexão com o banco de dados.")
        return

    pergunta = input("\nFaça sua pergunta sobre os eventos: ").strip()
    if not pergunta:
        print("\n[Aviso] Pergunta vazia.")
        return
    print("Processando (Ollama)...")

    # Etapa 1: pedir o SQL ao modelo
    try:
        response = client.chat(
            model=ollama_config["model"],
            messages=[{"role": "user", "content": montar_prompt(pergunta)}],
            think=False,                   # desliga o raciocínio longo do qwen3
            options={"num_predict": 400}   # limite de tokens na resposta: nunca gera para sempre
        )
        resposta = response["message"]["content"]
    except ollama.ResponseError as e:
        # Ollama respondeu com erro (ex.: modelo não baixado)
        print(f"\n[Erro no Ollama]: {e.error}")
        input("\nPressione Enter para voltar ao menu...")
        return
    except ConnectionError:
        print(f"\n[Erro] Não foi possível falar com o Ollama em {ollama_config['host']}. Ele está rodando?")
        input("\nPressione Enter para voltar ao menu...")
        return

    # Etapa 2: limpar e validar antes de tocar no banco
    try:
        sql_gerado = validar_sql(limpar_resposta(resposta))
    except SQLRecusado as e:
        print(f"\n[Consulta recusada]: {e}")
        input("\nPressione Enter para voltar ao menu...")
        return

    print("\n--- Consulta SQL Gerada ---")
    print(sql_gerado)
    print("---------------------------")

    # Etapa 3: executar numa transação somente leitura
    try:
        with conn.transaction():
            with conn.cursor() as cursor:
                # Garantia real: o próprio PostgreSQL recusa qualquer escrita
                cursor.execute("SET TRANSACTION READ ONLY")
                # Evita travar o menu com uma consulta pesada demais
                cursor.execute("SET LOCAL statement_timeout = '15s'")
                cursor.execute(sql_gerado)  # type: ignore
                resultados = cursor.fetchall()
                colunas = [desc[0] for desc in cursor.description] if cursor.description else []

        # Exibe os resultados de forma organizada
        print("\nResultados:")
        if resultados:
            # Mesmo formato de tabela das consultas fixas
            header = " | ".join(colunas)
            print(header)
            print("-" * len(header))
            for row in resultados:
                print(" | ".join(str(item) for item in row))
        else:
            print("(Nenhum registro encontrado)")
    except psycopg.Error as e:
        # Coluna/tabela inventada, erro de sintaxe, tentativa de escrita, timeout...
        # A saída do "with conn.transaction()" já desfez a transação.
        erro = e.diag.message_primary or str(e)
        print(f"\n[Erro no SQL gerado]: {erro}")
        print("Tente reformular a pergunta.")
    except Exception as e:
        # Último recurso: nada pode derrubar o menu
        print(f"\n[Erro inesperado]: {e}")

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