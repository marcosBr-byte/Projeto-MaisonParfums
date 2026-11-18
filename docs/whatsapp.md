# Avisos de pedidos no WhatsApp

A integração está preparada para a API oficial WhatsApp Business Cloud da Meta. O número de destino é cadastrado em **Admin → Configurações → Avisos de pedidos no WhatsApp**. O número não substitui as credenciais da API.

## Configurar a Meta

1. Acesse [Meta for Developers](https://developers.facebook.com/), crie ou selecione um aplicativo para a empresa e configure o produto WhatsApp.
2. No painel de configuração da API, identifique o **Phone Number ID** do remetente e obtenha um token com permissão `whatsapp_business_messaging`. Para testes, cadastre e verifique seu número como destinatário de teste no painel.
3. Crie um modelo de mensagem em português do Brasil, com **duas variáveis no corpo**, nesta ordem: número do pedido e valor total. Sugestão de texto: `Pagamento confirmado para o pedido #{{1}} na Maison Parfum. Total: {{2}}. Consulte o painel da loja para mais detalhes.` Use o nome e o idioma exatos do modelo aprovado na configuração abaixo.
4. Configure os valores no ambiente do servidor (ou no `.env` local, que é ignorado pelo Git). Não compartilhe o token no chat, no código ou no navegador.

```dotenv
WHATSAPP_ACCESS_TOKEN=token_da_meta
WHATSAPP_PHONE_NUMBER_ID=id_do_numero_remetente
WHATSAPP_API_VERSION=versao_disponivel_no_seu_painel
WHATSAPP_TEMPLATE_NAME=nome_do_modelo_aprovado
WHATSAPP_TEMPLATE_LANGUAGE=pt_BR
```

A versão deve seguir o formato `vNN.N`; use uma versão suportada exibida pela Meta. O Phone Number ID não é o telefone do destinatário. Tokens temporários de teste precisam ser substituídos por uma credencial adequada à operação antes de manter o serviço em produção.

5. Reinicie o servidor. Em **Admin → Configurações**, confirme o destino e ative os avisos.
6. Em produção, mantenha o processador de filas em execução (`bin/jobs`, com Solid Queue e seu banco configurados). Em desenvolvimento, o adaptador padrão assíncrono depende do processo Rails estar em execução.

## Funcionamento

- Depois de confirmar o pagamento e alterar o pedido para **Pago**, o sistema agenda o aviso. Criar um pedido pendente não envia mensagens. Pagamentos de teste não enviam avisos reais. Uma falha de envio não desfaz o pedido.
- O aviso contém apenas número do pedido e total; endereços e documentos não são enviados.
- O job registra o identificador da mensagem e o horário da aceitação pela API. Execuções repetidas de um job já confirmado não reenviam o aviso.
- Falhas de comunicação e erros da API têm até quatro tentativas. Se houver um timeout depois de a Meta aceitar a mensagem, uma nova tentativa pode duplicar o aviso; não há garantia de envio exatamente uma vez.
- No detalhe do pedido, o administrador pode consultar a aceitação ou solicitar o envio de um pedido pago cujo aviso ainda não foi aceito pela API. Isso também permite avisar sobre um pedido feito antes da ativação.
- Aceitação pela API não significa entrega ou leitura; a integração atual não recebe webhooks de status.
- Os testes usam um transporte simulado. A validação com WhatsApp real depende da configuração da sua conta e do modelo na Meta.

Referência: [documentação da Meta no Postman](https://www.postman.com/meta/whatsapp-business-platform/documentation/wlk6lh4/whatsapp-cloud-api).

## Preparar a fila em produção

O PostgreSQL de produção tem bancos separados para dados da loja, fila, cache e conexões em tempo real, conforme `config/database.yml`. Prepare-os no servidor com `RAILS_ENV=production bin/rails db:prepare`, usando um usuário autorizado a criar esses bancos (ou peça ao administrador para criá-los antes). O Rails carrega `db/queue_schema.rb`, `db/cache_schema.rb` e `db/cable_schema.rb` nos bancos correspondentes.

Execute `RAILS_ENV=production bin/jobs` como serviço supervisionado ou configure `SOLID_QUEUE_IN_PUMA=true` para o Puma gerenciar a fila. Não use os dois modos simultaneamente no mesmo servidor. Reinicie o serviço após cadastrar as variáveis da Meta. Antes de liberar vendas, confirme uma compra de homologação com as credenciais da loja; os testes automatizados não enviam mensagens nem realizam cobranças.
