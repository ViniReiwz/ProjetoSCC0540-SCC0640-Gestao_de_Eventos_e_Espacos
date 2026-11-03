# Cria os diretórios e copia os arquivos para a estrutura indicada na documentação para o protótipo (arquivo 03).

mkdir ProjetoBD &&
cd ProjetoBD && mkdir Prototipo &&
cp ../src/* ./Prototipo/ && cp ../ArquivosTxt/Projeto.txt ./ && cd .. &&
zip -r Prototipo.zip ProjetoBD/;

# ----------------------------------------------------------------------------------------------


# Cria os diretórios e compacta tudo de acordo com a estrutura indicada para o envio final (arquivo 01)

mkdir Aux/ &&
cp ./Modelagem/ER.pdf ./Aux/ && 
cp ./Modelagem/ER.xml ./Aux/ && 
cp ./Modelagem/Relacional.pdf ./Aux/ &&
cp ./Modelagem/Relacional.mmd ./Aux/ &&
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