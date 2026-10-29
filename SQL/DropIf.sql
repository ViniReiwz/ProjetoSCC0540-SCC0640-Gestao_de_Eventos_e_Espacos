-- Remove as tabelas caso existam ==============================================================

DROP TABLE IF EXISTS SESSOES;
DROP TABLE IF EXISTS ATIVIDADES CASCADE;
DROP TABLE IF EXISTS ESPACOS RESTRICT;
DROP TABLE IF EXISTS EVENTOS RESTRICT;

-- =============================================================================================

-- Remove os tipos criados, caso existam =======================================================

DROP TYPE IF EXISTS espaco_ferramentas;
DROP TYPE IF EXISTS ativ_modalidade;
DROP TYPE IF EXISTS pessoa_sexo;

-- =============================================================================================