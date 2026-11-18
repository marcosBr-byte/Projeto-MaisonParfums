# Links dos produtos e das fotos

Os produtos usam o nome no endereço (`/produtos/sabah-al-ward`), sem o número do cadastro. Nomes repetidos recebem um complemento aleatório. Renomear um produto preserva seu endereço para não quebrar links compartilhados. Links numéricos antigos de visualização e edição redirecionam para o endereço atual.

As imagens enviadas usam `/fotos/<chave-aleatoria>`, sem números de registros, nomes de relacionamentos ou rotas internas de armazenamento no link exibido. O servidor entrega a imagem diretamente; não redireciona para o endereço interno do arquivo.

As permissões são verificadas em cada solicitação. Fotos de produtos e de notas são públicas. Banners inativos são visíveis apenas ao administrador. Fotos de perfil são visíveis apenas ao dono ou ao administrador. Fotos de avaliações aguardando publicação são visíveis apenas ao autor ou ao administrador. Imagens da descrição pública do produto e da apresentação da loja continuam disponíveis aos visitantes.

Os números internos permanecem no banco para manter pedidos, variantes e associações. Os endereços amigáveis não substituem as verificações de autorização.
