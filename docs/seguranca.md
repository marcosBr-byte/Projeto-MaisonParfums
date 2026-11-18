# Revisão de funcionamento e segurança — 17/11/2026

## Escopo

Revisão do código local, autenticação, permissões, arquivos, pagamentos, busca, avaliações, configuração de produção e dependências. Os testes usam banco separado; o banco de desenvolvimento foi preservado. Não foi executado ataque contra a Hostinger nem contra contas ou serviços externos.

## Correções

- Atualizadas dependências com 73 alertas conhecidos em 13 bibliotecas: Rails 8.1.4.1, Rack e servidor HTTP, sanitização HTML, parser XML e dependências transitivas. Auditoria final sem alertas; nenhuma vulnerabilidade foi ignorada. O aviso oficial do Rack sobre esgotamento de memória em multipart é um dos problemas corrigidos: https://github.com/rack/rack/security/advisories/GHSA-5v64-555j-wjxm.
- HTTPS obrigatório em produção, HSTS, cookies Secure/HttpOnly/SameSite=Lax e duração máxima de 12 horas. `APP_HOST` restringe os domínios aceitos. A inicialização de produção exige esse domínio; a compilação de assets usa localhost se ele ainda não estiver configurado.
- Content Security Policy com scripts locais e nonce aleatório por resposta, bloqueio de objetos incorporados, de execução de scripts inline sem nonce e de inclusão da loja em frames externos. Mantidos os domínios necessários para as fontes e ícones atuais. Estilos inline continuam permitidos para os componentes existentes.
- Login limitado a 20 requisições por IP a cada 10 minutos; recuperação de senha a 5; cadastro a 10; avaliações a 20 por cliente; mensagens a 10 por cliente. Os limites usam o cache compartilhado de produção (Solid Cache). Recuperação de senha não revela se o e-mail existe. Senhas novas exigem pelo menos 8 caracteres; acessos existentes não foram apagados.
- Upload direto do Active Storage exige administrador, aceita apenas JPG/PNG/WebP de até 5 MB e não aceita metadados de confiança enviados pelo navegador. O upload normal das fotos de avaliações continua funcionando pelo formulário. O envio direto de imagens pelo editor rico de mensagens de clientes não fica exposto.
- Limite geral de 110 MB por requisição, inclusive leituras sem Content-Length, compatível com o upload administrativo de vídeo de até 100 MB. Arquivos menores continuam sujeitos aos limites específicos do formulário.
- FFmpeg/FFprobe limitados a arquivos locais/pipe e aos contêineres de vídeo aceitos, evitando protocolos de rede e demuxers de playlists no tratamento dos uploads. Mantidos timeout, uma conversão por vez, duração e tamanho máximos.
- CPF, telefone e endereço removidos dos logs de parâmetros. Fotos de perfil públicas somente quando a pessoa possui avaliação publicada, além do próprio titular e admin; a permissão é conferida a cada acesso.
- Testes de segurança para CSRF, tentativa de criar admin por parâmetros, limitação de login, recuperação de senha, uploads, leitura de dados de outras contas e permissões de fotos. Corrigida a preparação do ambiente de testes para usar credenciais fictícias antes de carregar Devise. CI passa a preparar PostgreSQL e instalar FFmpeg, além de executar os testes JavaScript.

## Validação

Resultados finais: 166 testes Rails, 1.289 verificações, zero falhas/erros; 17 testes JavaScript aprovados; Brakeman sem alertas; auditoria de gems e Importmap sem vulnerabilidades conhecidas; autoload aprovado. Os 14 arquivos Ruby examinados pelo RuboCop nesta revisão não têm infrações. Também foi verificado em Chromium local que o carrossel automático e as sugestões de busca carregam com a CSP ativa, incluindo a busca mobile. A configuração de produção foi exercitada com requisições Rack para redirecionamento HTTPS, rejeição de domínio externo e healthcheck/HSTS, sem conexão com um banco de produção.

## Publicação

Antes de publicar, configure `APP_HOST` com o domínio sem protocolo, segredos Rails e de criptografia, banco e cache/fila de produção. Não defina `SECRET_KEY_BASE_DUMMY` na execução do site: ele serve somente para compilar assets. O proxy deve terminar HTTPS e informar corretamente o protocolo encaminhado. O processo da aplicação e o PostgreSQL não devem ficar acessíveis diretamente pela internet.

Na VPS, configure firewall, acesso SSH por chave, atualizações do sistema/FFmpeg/libvips, backups de banco e arquivos e teste de restauração. Limites no proxy também são necessários contra conexões lentas e tráfego volumoso; os limites da aplicação não substituem proteção de rede. As APIs reais de pagamento, SMTP e WhatsApp dependem de credenciais e homologação no servidor. Esta revisão não garante ausência de todas as vulnerabilidades nem valida um servidor ainda não publicado.

Referência de configuração: https://guides.rubyonrails.org/security.html.
