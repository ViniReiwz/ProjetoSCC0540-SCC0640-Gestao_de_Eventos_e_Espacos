CREATE TABLE EVENTOS(
    EventoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NomeEvento VARCHAR(100) NOT NULL,
    DataInicio DATE NOT NULL,
    DataFim DATE NOT NULL
);

CREATE TYPE espaco_ferramentas AS ENUM(
    'Projetor',
    'Suporte à Transmissão',
    'Equipamento de Som',
    'Ar Condicionado'
);

CREATE TABLE ESPACOS(
    EspacoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NomeEspaco VARCHAR(50) NOT NULL,
    Capacidade INTEGER,
    Endereço TEXT NOT NULL
);

CREATE TYPE ativ_modalidade AS ENUM(
    'On-line',
    'Presencial'
);

CREATE TABLE ATIVIDADES(
    AtividadeID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    EventoID INTEGER NOT NULL,
    EspacoID INTEGER,
    Modalidade ativ_modalidade NOT NULL,

    ADD CONSTRAINT EventoID FOREIGN KEY REFERENCES EVENTOS(EventoID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    ADD CONSTRAINT EspacoID FOREIGN KEY REFERENCES ESPACOS(EspacoID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    
    ADD CONSTRAINT ativ_need_espaco CHECK(Modalidade = 'Presencial' AND EspacoID IS NOT NULL)
);

CREATE TABLE SESSOES(
    SessaoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    AtividadeID INTEGER NOT NULL,
    DataOcorre DATE NOT NULL,
    HorarioInicio TIME NOT NULL,
    HorarioFim TIME NOT NULL,
    Vagas INTEGER

    -- TODO: Criar o trigger pra relacionar Vagas e a capacidade do Espaco onde a atividade irá ocorrer.
);

CREATE TYPE pessoa_sexo AS ENUM(
    'Masculino', 'Feminino'
);

CREATE TABLE PESSOAS(
    CPF INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NomePessoa VARCHAR(50) NOT NULL,
    Idade INTEGER NOT NULL,
    Sexo pessoa_sexo
);