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

CREATE TABLE ESPACO_FERRAMENTA(
    EspacoID INTEGER,
    Ferramenta espaco_ferramentas,

    CONSTRAINT esp_ferr_fk PRIMARY KEY (EspacoID, Ferramenta),

    CONSTRAINT esp_ferr_esp_fk FOREIGN KEY (EspacoID) REFERENCES ESPACOS(EspacoID)
        ON DELETE CASCADE ON UPDATE CASCADE
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

    CONSTRAINT atv_evnt_fk FOREIGN KEY (EventoID) REFERENCES EVENTOS(EventoID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT atv_esp_fk FOREIGN KEY (EspacoID) REFERENCES ESPACOS(EspacoID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    
    CONSTRAINT ativ_need_espaco CHECK(Modalidade = 'On-line' OR EspacoID IS NOT NULL)
);

CREATE TABLE SESSOES(
    SessaoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    AtividadeID INTEGER NOT NULL,
    DataOcorre DATE NOT NULL,
    HorarioInicio TIME NOT NULL,
    HorarioFim TIME NOT NULL,
    Vagas INTEGER,

    -- TODO: Criar o trigger pra relacionar Vagas e a capacidade do Espaco onde a atividade irá ocorrer.
    CONSTRAINT sess_atv_fk FOREIGN KEY (AtividadeID) REFERENCES ATIVIDADES(AtividadeID),

    CONSTRAINT sess_hoorario CHECK(HorarioFim > HorarioInicio)
);

CREATE TYPE pessoa_sexo AS ENUM(
    'Masculino',
    'Feminino'
);

CREATE TABLE PESSOAS(
    CPF VARCHAR(11) PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NomePessoa VARCHAR(50) NOT NULL,
    DataNasc DATE NOT NULL,
    Sexo pessoa_sexo
);

CREATE TYPE participacao_tipo AS ENUM(
    'Organização',
    'Participante',
    'Apresentador'
);

CREATE TABLE PARTICIPACOES(
    CPF VARCHAR(11),
    SessaoID INTEGER,
    Participacao participacao_tipo NOT NULL,

    CONSTRAINT part_cpf_sess_pk PRIMARY KEY (CPF, SessaoID),

    CONSTRAINT part_cpf_fk FOREIGN KEY (CPF) REFERENCES PESSOAS(CPF),
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    CONSTRAINT part_sess_fk FOREIGN KEY (SessaoID) REFERENCES SESSOES(SessaoID)
        ON DELETE CASCADE ON UPDATE CASCADE
);