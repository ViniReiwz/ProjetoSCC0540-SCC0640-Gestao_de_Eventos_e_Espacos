# Protótipo de modelagem da base de dados para a gestão de eventos e espaços

**Ideia inicial - 6 tabelas**

[Eventos](#tabela-eventos)  
[Espaços](#tabela-espaços)  
[Atividades](#tabela-atividades)  
[Sessões](#tabela-sessões)  
[Pessoas](#tabela-pessoas)
[Participações](#tabela-participações)

## Tabela Eventos

A tabela de eventos é responsável por armazenar as informações dos eventos que devem ocorrer.  

**Atributos:**  
- <u>EventoID</u> ->> PK e portanto é o identificador unívoco de uma tupla na tabela;
- NomeEvento (N.N) ->> Nome do Evento;
- DataInício (N.N) ->> Data de ínicio do evento;
- DataFim (N.N) ->> Data de fim do evento.

Pensei que podemos tratar novas edições de um evento como eventos separados dentro da tabela, acho que fica mais simples de manusear e o banco fica menos confuso.

## Tabela Espaços

Tabela responsável por armazenar as informações dos espaços disponíveis para a realização dos eventos.

**Atributos:**  
- <u>EspacoID</u> ->> PK e portanto é o identificador unívoco de uma tupla na tabela;
- NomeEspaco (N.N) ->> Nome do espaço;
- Capacidade ->> Capacidade de pessoas que o espaço pode suportar;
- Endereco (N.N) ->> Endereço do local
- Ferramentas ->> ENUM com algumas ferramentas disponíveis no local, por exemplo, [Projetor, Suporte à transmissão, Equipamento de som, Ar condicionado, ...], ou algo semelhante a isso.

Acredito que se Capacidade for *`NULL`* podemos entender que é um "ambiente aberto". Caso contrário, o número de poessoas que ele comporta é limitado e definido po `Capacidade`.

## Tabela Atividades

Tabela responsável por armazenar as informações das atividades dos eventos. Uma atividade **não existe sem um evento**.

**Atributos:**  
- <u>AtividadeID</u> ->> Id da atividade, PK;
- EventoID (N.N) ->> Id do evento à qual essa atividade se refere, sendo FK;
- Modalidade (N.N) ->> Tipo da atividade (online ou presencial);
- EspacoID ->> ID do espaço onde a atividade irá ocorrer;

Têm que fazer um `CHECK` pra verificar se a modalidade é presencial e portanto EspacoID deve ser diferente de `NULL`.  


## Tabela Sessões

Tabela responsável por armazenar as informações das sessões das atividades. Uma sessão não **não existe sem uma atividade**.  

**Atributos:**  
- <u>SessãoID</u> ->> ID da sessão, PK
- AtividadeID (N.N) ->> Id da atividade a qual a sessão se refere, sendo FK;
- Data (N.N) ->> Data em que a sessão ocorre;
- HorarioInicio (N.N) ->> Horario em que a sessão se inicia;
- HorarioFim (N.N) ->> Horario em que a sessão termina;
- Vagas ->> Vagas para a sessão.

O campo `Vagas`, caso não especificado, deve ter o mesmo valor de vagas do espaço em que ocorrerá (referenciado pela atividade). Se EspacoID for `NULL` ou Espaco(Capacidade) for `NULL`, para aquele EspacoID, temos uma atividade (e sessão) que não demanda inscrição prévia.

## Tabela Pessoas

Tabela responsável por armazenar as informações das pessoas que participaram dos eventos.

**Atributos:**  
- <u>CPF (ou CodPes, algo assim)</u> PK e identificador unívoco da tupla;
- NomePessoa (N.N) ->> Nome da Pessoa;
- Idade (N.N) ->> Idade da pessoa;
- Sexo ->> Sexo da pessoa;  
... qualquer campo que julgarmos relevante

## Tabela Participações

Tabela responsável por relacionar uma pessoa com uma sessão deuma atividade de um evento.

- <u>CPF</u> ->> Identificador da pessoa, sendo PK e FK;
- <u>SessaoID</u> ->> Identificador da sessão, sendo PK e FK;
- Participacao (N.N) ->> Tipo de participação na sessão, contido em [Organização, Apresentador, Participante].