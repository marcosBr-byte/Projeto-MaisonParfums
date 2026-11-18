# Vídeos da home

Uploads MP4/WebM de até 100 MB são processados em segundo plano antes de aparecerem na loja. O FFmpeg verifica a duração (máximo 120 segundos) e converte para MP4 H.264/AAC, até 720 × 1280, sem ampliar a imagem, 30 fps, CRF 28, taxa de vídeo limitada a 1500 kbps e áudio a 96 kbps. O resultado tem limite de 25 MB e faststart para reprodução progressiva.

Instale `ffmpeg` (inclui `ffprobe`) no servidor; o Dockerfile já o instala. Mantenha `bin/jobs` em execução com os bancos do Solid Queue preparados (`RAILS_ENV=production bin/rails db:prepare`). A fila `videos` é atendida pela configuração padrão e permite uma conversão de cada vez por instalação. Cada conversão usa uma thread e tem prazo de 5 minutos. Após três falhas, o painel pede outro arquivo. Ao substituir um vídeo, ele fica oculto até concluir a nova conversão. O original substituído é removido pelo purge do Active Storage em segundo plano.

Os vídeos antigos em `app/assets/videos` não passam pela fila; devem ser otimizados antes do build ou reenviados pelo painel para entrar no processamento. Para uploads já existentes, execute `VideoHome.find_each { |v| OtimizarVideoJob.perform_later(v.id, v.arquivo.blob_id) if v.arquivo.attached? && !v.pronto_para_exibir? }` no console Rails. Esses uploads ficam ocultos até concluir.

A compressão reduz armazenamento e tráfego, mas a conversão usa CPU temporariamente. Dimensione a VPS para a aplicação e a fila. Os arquivos continuam no armazenamento configurado do Active Storage; isso não configura CDN nem armazenamento externo.
