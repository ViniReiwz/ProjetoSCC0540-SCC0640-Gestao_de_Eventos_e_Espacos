-- Remove as tabelas caso existam ==============================================================

DROP TABLE IF EXISTS INSCRICOES;
DROP TABLE IF EXISTS PARTICIPANTES;
DROP TABLE IF EXISTS PROMOVE;
DROP TABLE IF EXISTS SESSOES;
DROP TABLE IF EXISTS ATIVIDADES;
DROP TABLE IF EXISTS ESPACO_FERRAMENTA;
DROP TABLE IF EXISTS PESSOA_TELEFONE;
DROP TABLE IF EXISTS ORGANIZACAO_TELEFONE;
DROP TABLE IF EXISTS PESSOAS;
DROP TABLE IF EXISTS ORGANIZACOES;
DROP TABLE IF EXISTS PROMOTORES;
DROP TABLE IF EXISTS EVENTOS;
DROP TABLE IF EXISTS ESPACOS;

-- =============================================================================================

-- Remove os tipos criados, caso existam =======================================================

DROP TYPE IF EXISTS ferramentas;
DROP TYPE IF EXISTS ativ_modalidade;
DROP TYPE IF EXISTS pessoa_sexo;
DROP TYPE IF EXISTS participante_funcao;

-- =============================================================================================