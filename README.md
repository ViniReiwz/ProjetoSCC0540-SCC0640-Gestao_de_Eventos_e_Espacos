# Sistema de Gestão de Eventos e Espaços

Sistema de banco de dados completo para gestão de eventos (congressos, simpósios, treinamentos, etc.) e sua infraestrutura física, desenvolvido para a disciplina de Bases de Dados (SCC0540/SCC0640).

## Como compilar e rodar

Requisitos: Python 3.11 ou superior, PostgreSQL e Ollama instalado localmente.

1. Instale as dependências do Python:
   ```bash
   python -m pip install -r Prototipo/requirements.txt
   ```
2. Configure as credenciais do banco e o modelo do Ollama no arquivo `Prototipo/config.json`.
3. Certifique-se de que o banco de dados foi criado e populado (executando o DDL presente em `Projeto.txt` e os inserts de `DML.sql` no seu SGBD).
4. Execute o protótipo:
   ```bash
   cd Prototipo
   python main.py
   ```

## Estrutura de pastas

```text
/
├── Prototipo/
│   ├── main.py             # Ponto de entrada da aplicação
│   ├── config.json         # Credenciais do BD e configuração do Ollama
│   └── requirements.txt    # Dependências do Python (psycopg e ollama)
├── Projeto.txt             # Documento contendo decisões, DDL e consultas
├── DML.sql                 # Script para popular o banco de dados
├── Instrucoes.txt          # Instruções de execução e requisitos
├── README.md               # Este arquivo
└── (Os arquivos de diagramas E/R e Relacional serão adicionados aqui posteriormente)
```

## Fluxo de trabalho com Git

Regras da equipe:

1. A branch `main` deve **sempre estar funcional** (sem erros de sintaxe no SQL ou travamentos no Python).
2. Toda mudança é feita em uma branch própria, criada a partir da `main` atualizada, nomeada no padrão `<tipo>/<descricao-curta>`. Exemplos: `feat/menu-python`, `docs/atualizar-readme`, `db/tabelas-iniciais`.
   Tipos mais usados:
   - `feat/` — nova funcionalidade no Python ou nova consulta SQL
   - `fix/` — correção de bug ou erro de sintaxe
   - `docs/` — documentação, MER ou Relacional
   - `db/` — alterações no DDL, DML ou Triggers
3. As mensagens de commit devem ser claras: `<tipo>: <descrição>` (ex.: `feat: adiciona loop do menu principal`).
4. Ao terminar, abra um Pull Request para a `main`. **Outro integrante deve revisar antes do merge.**
5. Antes de começar algo novo, sempre atualize sua `main` local com `git pull`.

### Comandos básicos

Atualizar a `main` local antes de começar algo novo:
```bash
git checkout main
git pull
```

Criar uma branch a partir da main atualizada:
```bash
git checkout -b feat/nome-da-feature
```

Ver o que foi alterado:
```bash
git status
git diff
```

Adicionar e commitar as mudanças:
```bash
git add .
git commit -m "feat: descrição clara da mudança"
```

Enviar a branch para o GitHub:
```bash
git push -u origin feat/nome-da-feature
```

## Divisão de tarefas

| Tarefa | Responsáveis |
|--------|-------------|
| Modelagem Entidade/Relacionamento (MER) e Relacional | João e Gustavo |
| Banco de Dados (SQL - DDL, DML, Triggers e Consultas) | Vini e Suellen |
| Código em Python e integração com BD / Ollama | Carlos e Miguel |