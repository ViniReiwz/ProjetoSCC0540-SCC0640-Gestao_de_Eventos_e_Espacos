# Cria os diretórios e copia os arquivos para a estrutura indicada na documentação para o protótipo (arquivo 03).

mkdir ProjetoBD &&
cd ProjetoBD && mkdir Prototipo SeuProjetoBD &&
cp ../src/* ./Prototipo/ && cp ../ArquivosTxt/Projeto.txt ./SeuProjetoBD/ && cd .. &&
zip -r Prototipo.zip ProjetoBD/

# ----------------------------------------------------------------------------------------------