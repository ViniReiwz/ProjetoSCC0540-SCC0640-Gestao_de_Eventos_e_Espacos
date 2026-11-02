-- Criação dos tipos auxiliares ================================================================

CREATE TYPE espaco_ferramentas AS ENUM(
    'Projetor',
    'Suporte à Transmissão',
    'Equipamento de Som',
    'Ar Condicionado'
);

CREATE TYPE ativ_modalidade AS ENUM(
    'On-line',
    'Presencial'
);

CREATE TYPE pessoa_sexo AS ENUM(
    'Masculino',
    'Feminino'
);

CREATE TYPE participante_funcao AS ENUM(
    'Organização',
    'Participante',
    'Apresentador'
);

-- =============================================================================================

--  Criação das tabelas ========================================================================

CREATE TABLE EVENTOS(
    EventoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NomeEvento VARCHAR(100) NOT NULL,
    DataInicio DATE NOT NULL,
    DataFim DATE NOT NULL
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

    CREATE TABLE ATIVIDADES(
        AtividadeID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        EspacoID INTEGER,
        Modalidade ativ_modalidade NOT NULL,

        CONSTRAINT atv_evnt_fk FOREIGN KEY (EventoID) REFERENCES EVENTOS(EventoID)
            ON DELETE CASCADE ON UPDATE CASCADE,
        
        CONSTRAINT ativ_need_espaco CHECK(Modalidade = 'On-line' OR EspacoID IS NOT NULL)
    );

        CREATE TABLE SESSOES(
            SessaoID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            EspacoID INTEGER,
            AtividadeID INTEGER NOT NULL,
            DataOcorre DATE NOT NULL,
            HorarioInicio TIME NOT NULL,
            HorarioFim TIME NOT NULL,
            Vagas INTEGER,

            CONSTRAINT sess_atv_fk FOREIGN KEY (AtividadeID) REFERENCES ATIVIDADES(AtividadeID),

            CONSTRAINT sess_esp_fk FOREIGN KEY (EspacoID) REFERENCES ESPACOS(EspacoID)
                ON DELETE RESTRICT ON UPDATE CASCADE,

            CONSTRAINT sess_hoorario CHECK(HorarioFim > HorarioInicio)
        );

CREATE TABLE PROMOTORES(
    PromotorID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY
);
    CREATE TABLE PROMOVE(
        PromotorID INTEGER,
        EventoID INTEGER,

        CONSTRAINT promove_pk PRIMARY KEY (PromotorID, EventoID),
    
        CONSTRAINT promove_prom_fk FOREIGN KEY (PromotorID) REFERENCES PROMOTORES(PromotorID)
            ON DELETE RESTRICT ON UPDATE CASCADE,

        CONSTRAINT promove_evnt_fk FOREIGN KEY (EventoID) REFERENCES EVENTOS(EventoID)
            ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE TABLE PESSOAS(
        CPF VARCHAR(11) PRIMARY KEY,
        NomePessoa VARCHAR(50) NOT NULL,
        DataNasc DATE NOT NULL,
        Sexo pessoa_sexo,
        PromotorID INTEGER UNIQUE,

        CONSTRAINT pess_prom_fk FOREIGN KEY (PromotorID) REFERENCES PROMOTORES(PromotorID)
            ON DELETE SET NULL ON UPDATE CASCADE
    );

        CREATE TABLE PESSOA_TELEFONE(
            CPF VARCHAR(11),
            Telefone VARCHAR(11),

            CONSTRAINT pessoa_tel_pk PRIMARY KEY (CPF, Telefone),

            CONSTRAINT pessoa_tel_cpf_fk FOREIGN KEY (CPF) REFERENCES PESSOAS(CPF)
                ON DELETE CASCADE ON UPDATE CASCADE,
        );

        CREATE TABLE PARTICIPANTES(
            CPF VARCHAR(11),
            EventoID INTEGER,

            CONSTRAINT part_cpf_evnt_pk PRIMARY KEY (CPF, EventoID),

            CONSTRAINT part_cpf_fk FOREIGN KEY (CPF) REFERENCES PESSOAS(CPF),
                ON DELETE CASCADE ON UPDATE CASCADE,
            
            CONSTRAINT part_evnt_fk FOREIGN KEY (EventoID) REFERENCES EVENTOS(EventoID)
                ON DELETE CASCADE ON UPDATE CASCADE
        );

            CREATE TABLE INSCRICOES(
                CPF VARCHAR(11),
                SessaoID INTEGER,
                Funcao participante_funcao NOT NULL,
                DataInscricao DATE NOT NULL,

                CONSTRAINT inscricoes_pk PRIMARY KEY (CPF, SessaoID),

                CONSTRAINT inscricoes_cpf_fk FOREIGN KEY (CPF) REFERENCES PARTICIPANTES(CPF)
                    ON DELETE CASCADE ON UPDATE CASCADE,
                
                CONSTRAINT inscricoes_sess_fk FOREIGN KEY (SessaoID) REFERENCES SESSOES(SessaoID)
                    ON DELETE CASCADE ON UPDATE CASCADE
            );

    CREATE TABLE ORGANIZACOES(
        CNPJ VARCHAR(14) PRIMARY KEY,
        RazaoSocial VARCHAR(50) NOT NULL,
        Endereco TEXT NOT NULL,
        PromotorID INTEGER UNIQUE,

        CONSTRAINT org_prom_fk FOREIGN KEY (PromotorID) REFERENCES PROMOTORES(PromotorID)
            ON DELETE SET NULL ON UPDATE CASCADE
    );

        CREATE TABLE ORGANIZACAO_TELEFONE(
            CNPJ VARCHAR(11),
            Telefone VARCHAR(11),

            CONSTRAINT org_tel_pk PRIMARY KEY (CNPJ, Telefone),

            CONSTRAINT org_tel_cnpj_fk FOREIGN KEY (CNPJ) REFERENCES ORGANIZACOES(CNPJ)
                ON DELETE CASCADE ON UPDATE CASCADE,
        );

-- =============================================================================================

-- Criação das funções =========================================================================

    -- TODO ->> Criar as funções necessárias para os triggers

-- =============================================================================================

-- Criação dos triggers =========================================================================

    -- TODO ->> Criar trigger para setar o limite de vagas para cada sessão
        -- Se não for especificado na inserção da sessão, pega a capacidade do espaço em que ocorrerá (se não for especificado [atividade on-line] é NULL)
    
    -- TODO ->> Criar trigger que verifica, numa inserção/atualização em inscrição se a pessa referenciada é participante do evento

    -- TODO ->> Criar trigger que verifica se é possível haver inscrições novas pra uma sessão (N° de vagas > n de inscritos)

    -- TODO ->> Pensar e criar um 4° trigger que sejá útil pra algo

-- =============================================================================================