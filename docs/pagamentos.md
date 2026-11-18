# Configuração de Pix e cartão

## Configurar pelo ambiente

O servidor também lê as variáveis abaixo do `.env` local (ou do ambiente de
produção). Valores não vazios têm prioridade sobre o painel. Reinicie o Rails
depois de alterá-los. Não versione credenciais.

```dotenv
MERCADO_PAGO_ACCESS_TOKEN=
MERCADO_PAGO_WEBHOOK_SECRET=
MERCADO_PAGO_SITE_URL=
MERCADO_PAGO_ATIVO=false
MERCADO_PAGO_TESTE=true
```

Preencha o token de teste, a chave de assinatura e o domínio HTTPS público.
O frete fixo continua nas configurações comerciais. Apenas `true` ativa
pagamentos; apenas `false` desliga o modo de teste. Mantenha pagamentos
desativados até configurar o webhook. Novos checkouts usam a API de Orders;
cobranças antigas via Preferences continuam reconhecidas pelo sistema.

A integração disponível é Mercado Pago Checkout Pro via API de Orders. O administrador configura tudo em **Configurações → Receber Pix e cartão — Mercado Pago**. Ela começa desativada e no ambiente de teste.

1. Na conta Mercado Pago da loja, crie a aplicação e obtenha o Access Token do ambiente que será usado.
2. No painel da loja, salve o endereço público HTTPS, sem caminhos (exemplo: `https://loja.com.br`).
3. No Mercado Pago, configure o evento **Order (Mercado Pago)** em Webhooks com a URL exibida no painel da loja (`/pagamentos/mercado-pago/notificacoes`). Copie a chave de assinatura gerada.
4. Preencha Access Token e chave de assinatura no painel. Esses valores são criptografados no banco e não aparecem novamente no formulário. Deixar os campos vazios ao salvar preserva as credenciais.
5. Informe o frete fixo cobrado nos pedidos fora da campanha regional. Zero significa isenção. O total do carrinho mostra esse valor antes de finalizar; não há cotação automática de transportadoras.
6. Ative o pagamento mantendo o ambiente de teste. Valide Pix/cartão com os recursos de teste da conta Mercado Pago, inclusive as notificações recebidas. As opções disponíveis dependem da conta e do ambiente do provedor.
7. Depois da homologação, substitua pelas credenciais de produção, confira o Webhook de produção e desmarque o ambiente de teste.

O cliente finaliza o pedido e acessa o botão **Pagar com Pix ou cartão**. A cobrança acontece na página do Mercado Pago. A loja não recebe números completos de cartão. Em **Perfil → Meus pedidos**, o cliente retoma a mesma cobrança se sair da página ou houver uma falha de comunicação.

O retorno do navegador não confirma pagamentos. O servidor valida a assinatura da notificação, consulta a API e confere moeda, valor, referência e ambiente antes de marcar como pago. Notificações repetidas não duplicam pedidos ou baixas de estoque. Pagamentos em ambiente de teste não entram no faturamento nem nos mais vendidos.

Os produtos são reservados ao finalizar o pedido, seguindo a baixa de estoque existente. Reembolsos e conciliação de contestações precisam de acompanhamento do administrador no Mercado Pago. A política de reservas está descrita abaixo. Parcelamento e juros seguem as condições configuradas na conta Mercado Pago. Não há desconto adicional automático de Pix.

As verificações automatizadas usam respostas simuladas do provedor e não fazem cobranças. A homologação com a conta da loja depende do administrador e de um endereço HTTPS acessível para as notificações.

Referências oficiais:

- [Checkout Pro via Orders API](https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-orders/create-order)
- [Notificações e assinatura de Webhooks](https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-orders/notifications)

## Aviso após pagamento

Quando uma notificação válida confirma o pagamento, a mudança para **Pago** agenda o aviso no WhatsApp da loja, se a integração estiver ativa. Pedidos pendentes, cancelados e pagamentos de teste não enviam avisos. Repetir a mesma confirmação não agenda um segundo aviso. O job verifica novamente a situação antes de enviar.

Configure também as etapas de [WhatsApp](whatsapp.md). O botão de envio no detalhe do pedido permite recuperar avisos de pedidos pagos que ainda não foram aceitos pela API, por exemplo após configurar as credenciais. O envio automático não é ativado sem credenciais e configuração do destino.

## Operação de pedidos e reservas

Novos pedidos reservam estoque por 24 horas. O job `ExpirarReservasJob`, agendado a cada 10 minutos em produção, cancela reservas vencidas **sem checkout externo** e devolve o estoque uma única vez. Para executar manualmente em desenvolvimento: `bin/rails runner 'ExpirarReservasJob.perform_now'`. Pedidos antigos sem prazo permanecem para conferência manual.

Quando já existe checkout no Mercado Pago, o job sinaliza **Conferir pagamento**, sem liberar estoque: pagamentos em processamento podem ser aprovados depois. O administrador deve conferir e encerrar a cobrança no provedor antes de confirmar o cancelamento no painel. O sistema bloqueia novas aberturas de checkout após o prazo local; isso não encerra uma página de cobrança já aberta no provedor. A expiração automática dessas cobranças depende de homologação com a conta do cliente.

No detalhe do pedido, o administrador pode confirmar um recebimento manual apenas quando não existe cobrança online; depois pode marcar envio e entrega, informar transportadora/responsável local, código de rastreamento e previsão de entrega. Esses dados aparecem na página do pedido acessada pelo perfil do cliente. O endereço exibido no painel é o que foi salvo na compra.

Cancelar pedidos pagos ou enviados exige confirmação de que o reembolso foi realizado no provedor e os produtos podem voltar ao estoque. O botão não executa reembolsos na API. Pedidos entregues seguem atendimento de devolução. Aprovações recebidas após cancelamento, reembolsos e contestações sinalizam conferência manual e não liberam envio automático.

O frete fixo configurado é aplicado também quando o checkout online está desativado. Cotação por CEP, etiquetas e rastreamento automático de transportadoras não estão integrados; a previsão e o código são informados pelo administrador.

### Homologação pendente das credenciais do cliente

Com a URL HTTPS e os acessos do cliente, validar: compra aprovada, recusa, pagamento em processamento, notificações repetidas, pagamento após vencimento da reserva, cancelamento e reembolso. Confirmar também o aviso WhatsApp com modelo aprovado e fila ativa. Os testes locais usam simulações e não substituem essa homologação.


## Testar localmente sem domínio

1. Inicie o Rails com `bin/dev` (porta 3000).
2. Em outro terminal, execute `tmp/cloudflared tunnel --url http://127.0.0.1:3000 --protocol http2`.
   O executável oficial está no diretório temporário ignorado pelo Git; em outra
   máquina, instale `cloudflared` conforme a documentação da Cloudflare.
3. Copie a URL HTTPS `https://...trycloudflare.com` para `MERCADO_PAGO_SITE_URL` no `.env`.
4. Reinicie o Rails para autorizar esse host e carregar o ambiente atualizado.
5. No Mercado Pago, ambiente **Teste**, cadastre essa URL seguida de
   `/pagamentos/mercado-pago/notificacoes` e selecione **Order (Mercado Pago)**.
6. Salve e copie a assinatura secreta para `MERCADO_PAGO_WEBHOOK_SECRET` no `.env`.
7. Mantenha `MERCADO_PAGO_TESTE=true`, confira que usa o Access Token de teste,
   defina `MERCADO_PAGO_ATIVO=true` e reinicie o Rails.
8. Acesse a loja pelo endereço do túnel desde o login, crie um pedido de teste
   e conclua o checkout com os recursos de teste do Mercado Pago. Sessões de
   localhost não são compartilhadas com o domínio temporário. Confirme que o
   pedido fica pago apenas após a notificação autenticada e a consulta da order.
9. Ao terminar, desative `MERCADO_PAGO_ATIVO` e encerre o túnel com Ctrl+C.
   Ao abrir um novo túnel, atualize a URL no `.env` e no Mercado Pago e reinicie
   o Rails; o endereço temporário muda. Não use esse túnel para vendas reais.

O endpoint valida HMAC com o `data.id` da query string, preservando maiúsculas e
minúsculas conforme o validador oficial atual do SDK Ruby. Consulta a order pelo
ID salvo no pedido e confere referência, moeda, total, ambiente (IDs ORDTST para
testes) e valor efetivamente pago. Estados `processing`, `failed` e
`action_required` não aprovam pedidos. Estornos parciais/totais e contestações
exigem conferência manual. Não há reembolso automático.

Referência: [Quick Tunnels da Cloudflare](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/).
