# Configurações comerciais da Maison Parfum

Acesse **Admin → Configurações → Promoções e brinde**.

- **Desconto global:** informe o percentual e ative a promoção. O preço original do cadastro é preservado. Catálogo, busca, página do produto, quiz e carrinho passam a usar o preço com desconto. Novos pedidos guardam o percentual e os valores usados na compra; pedidos antigos não são recalculados.
- **Brinde:** o limite inicial é R$ 199,00. O destaque e o carrinho mostram quanto falta. A regra usa a soma dos produtos depois do desconto, sem frete. O pedido registra se ganhou e qual descrição do brinde estava vigente.
- **Borrifadas:** a estimativa inicial é de 10 borrifadas/ml e pode ser ajustada. Não é uma medição física exata. A página do produto mostra a estimativa do tamanho escolhido e permite converter uma quantidade de borrifadas em ml.
- **R$/ml:** calculado pelo preço de venda dividido pelo volume. Para lacrados, informe o volume em ml no cadastro da variante; sem ele, o sistema não inventa o cálculo.
- **Estoque:** informe unidades para cada tamanho (5, 8, 10 e 15 ml ou lacrado). O frasco mãe não participa mais do fluxo de compra. O estoque é baixado na transação do pedido e uma compra inválida reverte as alterações. Os antigos registros de frascos foram preservados, sem conversão automática de ml em unidades.
- **Editor:** descrições de produtos e da loja e mensagens usam Action Text. Textos antigos foram copiados para o editor, preservando as colunas de texto para consulta e busca.

O site anuncia envio para o Brasil e parcelamento em até seis vezes sem juros. A finalização registra o pedido pendente; não existe cobrança automática por cartão neste sistema. Combine frete e pagamento pelo atendimento da loja.

## Recuperação de senha

O fluxo usa o token original no link do e-mail e armazena seu digest no banco. Um novo pedido de recuperação invalida o link anterior; após a troca, o token é apagado e é necessário fazer login. O prazo de validade configurado é de seis horas.

Em produção, configure `APP_HOST` com o domínio público, sem protocolo (por exemplo, `loja.exemplo.com.br`) e configure o serviço SMTP no ambiente de produção. A validação automatizada dos tokens usa e-mails de teste; não verifica a entrega externa do provedor.

O WhatsApp permanece separado e desativado até configurar a Meta; consulte `docs/whatsapp.md`.
