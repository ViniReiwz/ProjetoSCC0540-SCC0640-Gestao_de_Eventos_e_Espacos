-- Criação dos tipos auxiliares ================================================================

CREATE TYPE ferramentas AS ENUM(
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
        Ferramenta ferramentas,

        CONSTRAINT esp_ferr_fk PRIMARY KEY (EspacoID, Ferramenta),

        CONSTRAINT esp_ferr_esp_fk FOREIGN KEY (EspacoID) REFERENCES ESPACOS(EspacoID)
            ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE TABLE ATIVIDADES(
        AtividadeID INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        EventoID INTEGER,
        Modalidade ativ_modalidade NOT NULL,

        CONSTRAINT atv_evnt_fk FOREIGN KEY (EventoID) REFERENCES EVENTOS(EventoID)
            ON DELETE CASCADE ON UPDATE CASCADE,
        
        CONSTRAINT ativ_need_espaco CHECK(Modalidade = 'On-line' OR EspacoID IS NOT NULL)
    );

        CREATE TABLE ATIVIDADE_FERRAMENTA(
            AtividadeID INTEGER,
            FerramentaNecessaria ferramentas,

            CONSTRAINT atv_ferr_pk PRIMARY KEY (AtividadeID, FerramentaNecessaria),

            CONSTRAINT atv_ferr_atv_fk FOREIGN KEY (AtividadeID) REFERENCES ATIVIDADES(AtividadeID)
                ON DELETE CASCADE ON UPDATE CASCADE
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

                CONSTRAINT inscricoes_cpf_fk FOREIGN KEY (CPF) REFERENCES PESSOAS(CPF)
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

    CREATE OR REPLACE FUNCTION set_limite_vagas()
        RETURNS TRIGGER AS $$
        DECLARE limite_vagas INTEGER;
        BEGIN

            IF NEW.Vagas IS NULL THEN
                SELECT Capacidade INTO limite_vagas FROM ESPACOS WHERE EspacoID = NEW.EspacoID;
                NEW.Vagas := limite_vagas;
            END IF;

            RETURN NEW;
        END;
        $$  LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION verifica_participante_evento()
        RETURNS TRIGGER AS $$
        DECLARE evento_id INTEGER;
        BEGIN

            SELECT A.EventoID INTO evento_id FROM SESSOES S
                JOIN ATIVIDADES A ON S.AtividadeID = A.AtividadeID
                WHERE S.SessaoID = NEW.SessaoID;

            IF NOT EXISTS(
                SELECT 1 FROM PARTICIPANTES WHERE CPF = NEW.CPF AND EventoID = evento_id
            ) THEN
                RAISE EXCEPTION 'A pessoa com CPF % não é participante do evento da sessão %', NEW.CPF, NEW.SessaoID;
            END IF;

            RETURN OLD;
        END;
        $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION verifica_limite_vagas()
        RETURNS TRIGGER AS $$
        DECLARE 
            vagas_ocupadas INTEGER;
            limite_vagas INTEGER;
        BEGIN

            SELECT COUNT(*) INTO vagas_ocupadas FROM INSCRICOES WHERE SessaoID = NEW.SessaoID;

            SELECT Vagas INTO limite_vagas FROM SESSOES WHERE SessaoID = NEW.SessaoID;
            
            IF vagas_ocupadas >= limite_vagas THEN
                RAISE EXCEPTION 'Não é possível realizar a inscrição. Limite de vagas atingido para a sessão %', NEW.SessaoID;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

-- =============================================================================================

-- Criação dos triggers =========================================================================

    CREATE TRIGGER set_limite_vagas_trigger BEFORE INSERT OR UPDATE ON SESSOES
        FOR EACH ROW EXECUTE FUNCTION set_limite_vagas();
    
    CREATE TRIGGER verifica_participante_evento_trigger BEFORE INSERT OR UPDATE ON INSCRICOES
        FOR EACH ROW EXECUTE FUNCTION verifica_participante_evento();

    CREATE TRIGGER verifica_limite_vagas_trigger BEFORE INSERT ON INSCRICOES
        FOR EACH ROW EXECUTE FUNCTION verifica_limite_vagas();

    -- TODO ->> Pensar e criar um 4° trigger que sejá útil pra algo

-- =============================================================================================