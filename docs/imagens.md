# Imagens da loja

Novos uploads de imagem principal, galeria, notas olfativas, banners, avaliações
e perfil são tratados com libvips antes de serem gravados no Active Storage:

- Aceita JPG, PNG e WebP de até 5 MB e 40 megapixels.
- Corrige a orientação do celular, preserva proporção e transparência, sem corte
  ou ampliação de arquivos pequenos.
- Converte para WebP, qualidade 82, retirando EXIF e outros metadados.
- Produtos e avaliações: maior lado até 1600 px. Notas e perfil: até 800 px.
  Banners: até 2400 px.
- Se o resultado exceder 700 KB, tenta até 1200 px com qualidade 76. Se ainda
  exceder o limite, recusa e pede um arquivo menor.
- Grava apenas a imagem otimizada para esses novos uploads, sem manter uma
  segunda cópia do original pesado. Imagens inválidas não substituem a anterior.

O serviço de fotos mantém a verificação de acesso e oferece apenas quatro
tamanhos fixos via parâmetro `tamanho`: `miniatura` (160 px), `catalogo` (480 px),
`detalhe` (1200 px) e `banner` (1920 px). Essas versões são WebP, preservam a
proporção e ficam armazenadas para reutilização. As páginas usam o tamanho
adequado; miniaturas da galeria não baixam a imagem grande. ETags evitam baixar
novamente imagens sem alterações, mantendo revalidação para respeitar a
moderação das avaliações e a privacidade das fotos de perfil.

Fotos que já existiam no armazenamento não são regravadas ou apagadas por essa
mudança. Sua exibição pelas páginas usa as versões menores. Reenviar a foto pelo
formulário aplica também a otimização ao arquivo armazenado. Blobs já existentes
e signed_ids não são recomprimidos a cada edição. Os formulários atuais usam
upload normal; se futuramente forem adotados uploads diretos para storage,
o processamento antes da gravação deverá ser adaptado a esse fluxo.

O Dockerfile já instala libvips. Em hospedagem sem Docker, instale a biblioteca
libvips antes de iniciar o Rails. A configuração usa `variant_processor = :vips`
e mantém o controle de versões do Active Storage. A geração inicial tem custo
de CPU; as próximas visualizações reutilizam o arquivo processado. Mantenha o
volume de armazenamento persistente e inclua imagens e versões nos backups.
