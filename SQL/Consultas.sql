-- Verifica a quantidade de pessoas inscritas nas atividadea de um evento específico, agrupadas por função, bem como o total de inscritos/participantes da atividade.
SELECT E.NomeEvento, A.NomeAtividade, I.Funcao, COUNT(*) AS nesta_funcao, SUM(COUNT(*)) OVER(PARTITION BY A.AtividadeID) AS total_atividade FROM INSCRICOES I
    JOIN SESSOES S ON S.SessaoID = I.SessaoID
    JOIN ATIVIDADES A ON A.AtividadeID = S.AtividadeID
    JOIN EVENTOS E ON E.EventoID = A.EventoID
    WHERE A.EventoID = 1
    GROUP BY E.EventoID, E.NomeEvento, A.AtividadeID, A.NomeAtividade, I.Funcao
    ORDER BY A.AtividadeID ASC, I.Funcao DESC;

-- Verifica a quantidade de pessoas inscritas em um evento específico, agrupadas por sexo, bem como o total de inscritos/participantes do evento.
SELECT E.NomeEvento, P.Sexo, COUNT(*) AS quantidade_sexo, SUM(COUNT(*)) OVER(PARTITION BY E.EventoID) AS total_participantes FROM PARTICIPANTES PA
    JOIN PESSOAS P ON P.CPF = PA.CPF
    JOIN EVENTOS E ON E.EventoID = PA.EventoID
    GROUP BY E.EventoID, E.NomeEvento, P.Sexo
    ORDER BY E.NomeEvento ASC, P.Sexo DESC;

-- Encontra, para todas as atividades, espaços que podem recebê-las de acordo com suas ferramentas
SELECT A.NomeAtividade, E.NomeEspaco, E.Capacidade, E.Endereco FROM ATIVIDADES A
    CROSS JOIN ESPACOS E
    WHERE NOT EXISTS(
        SELECT 1 FROM ATIVIDADE_FERRAMENTA AF
            WHERE AF.AtividadeID = A.AtividadeID AND NOT EXISTS(
                SELECT 1 FROM ESPACO_FERRAMENTA EF
                    WHERE EF.EspacoID = E.EspacoID AND EF.Ferramenta = AF.FerramentaNecessaria
            )
        )
    GROUP BY A.AtividadeID, E.EspacoID
    ORDER BY A.AtividadeID ASC, E.Capacidade DESC;

-- Lista todas as atividades, suas sessões e os espaços onde elas ocorrerão, caso haja algum espaço definido. Caso não haja, o resultado exibirá "-online-" no lugar do nome do espaço.
SELECT A.NomeAtividade, A.Modalidade, S.SessaoID, S.DataOcorre, S.HorarioInicio, S.HorarioFim, COALESCE(E.NomeEspaco, '-online-') AS NomeEspaco FROM ATIVIDADES A
    JOIN SESSOES S ON S.AtividadeID = A.AtividadeID
    LEFT JOIN ESPACOS E ON E.EspacoID = S.EspacoID
    GROUP BY A.AtividadeID, S.SessaoID, E.EspacoID
    ORDER BY A.AtividadeID, S.DataOcorre, S.HorarioInicio;

-- Retorna todos os promotores de um evento específico, sejam eles pessoas físicas ou organizações, juntamente com seus respectivos documentos (CPF ou CNPJ).
SELECT E.NomeEvento, PR.PromotorID,
    CASE
        WHEN P.CPF IS NOT NULL THEN 'Pessoa Física'
        WHEN O.CNPJ IS NOT NULL THEN 'Organização'
    END AS TipoPromotor,
    COALESCE(P.NomePessoa, O.RazaoSocial) AS NomePromotor,
    COALESCE(P.CPF, O.CNPJ) AS Documento
FROM EVENTOS E
    JOIN PROMOVE PM ON PM.EventoID = E.EventoID
    JOIN PROMOTORES PR ON PR.PromotorID = PM.PromotorID
    LEFT JOIN PESSOAS P ON P.PromotorID = PR.PromotorID
    LEFT JOIN ORGANIZACOES O ON O.PromotorID = PR.PromotorID
    WHERE E.EventoID = 2 AND (P.CPF IS NOT NULL OR O.CNPJ IS NOT NULL)
    ORDER BY NomePromotor ASC;