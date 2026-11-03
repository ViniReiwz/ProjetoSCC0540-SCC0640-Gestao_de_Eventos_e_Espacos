# Cria os diretórios e copia os arquivos para a estrutura indicada na documentação para o protótipo (arquivo 03).

mkdir ProjetoBD &&
cd ProjetoBD && mkdir Prototipo SeuProjetoBD &&
cp ../src/* ./Prototipo/ && cp ../ArquivosTxt/Projeto.txt ./SeuProjetoBD/ && cd .. &&
zip -r Prototipo.zip ProjetoBD/;

# ----------------------------------------------------------------------------------------------


# Cria os diretórios e compacta tudo de acordo com a estrutura indicada para o envio final (arquivo 01)

mkdir Aux/ &&
cp ./Modelagem/MER_Projeto.drawio.pdf ./Aux/ER.pdf && 
cp ./Modelagem/Relacional_ProjetoBD.pdf ./Aux/Relacional.pdf &&
cp ./ArquivosTxt/Projeto.txt ./Aux/ && 
cp ./ArquivosTxt/Instrucoes.txt ./Aux/ && 
cp ./SQL/DML.sql ./Aux/ &&
cp ./Prototipo.zip ./Aux/ &&
cd Aux/ && zip -r Entrega.zip ./* &&
cd .. && mv ./Aux/Entrega.zip ./Entrega.zip;

# ----------------------------------------------------------------------------------------------


# Remove os arquivos e diretórios temporários --------------------------------------------------

rm -r ProjetoBD/ && rm -r Aux/ && rm Prototipo.zip;

# ----------------------------------------------------------------------------------------------