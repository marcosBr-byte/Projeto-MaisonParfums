require "tempfile"
require "timeout"
require "json"

class VideoOtimizado
  class Invalido < StandardError; end

  def self.processar(blob)
    blob.open do |entrada|
      Tempfile.create([ "video", ".mp4" ]) do |saida|
        Tempfile.create([ "video-log", ".txt" ]) do |log|
          executar([ "ffprobe", "-v", "error", "-protocol_whitelist", "file,pipe", "-format_whitelist", "mov,matroska,webm", "-show_entries", "format=duration", "-of", "json", entrada.path ], log, 20)
          log.rewind
          duracao = JSON.parse(log.read).dig("format", "duration").to_f
          raise Invalido, "O vídeo deve ter até 2 minutos." unless duracao.positive? && duracao <= 120
          log.truncate(0)
          log.rewind
          executar([ "ffmpeg", "-nostdin", "-y", "-v", "error", "-threads", "1", "-protocol_whitelist", "file,pipe", "-format_whitelist", "mov,matroska,webm", "-i", entrada.path,
            "-map", "0:v:0", "-map", "0:a:0?", "-map_metadata", "-1",
            "-vf", "scale=w='min(720,iw)':h='min(1280,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,setsar=1,fps=30",
            "-c:v", "libx264", "-threads", "1", "-preset", "fast", "-crf", "28",
            "-maxrate", "1500k", "-bufsize", "3000k", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "96k", "-ac", "2", "-movflags", "+faststart", saida.path ], log, 300)
          raise Invalido, "O vídeo otimizado excedeu 25 MB." if saida.size > 25.megabytes
          saida.rewind
          yield saida
        end
      end
    end
  end

  def self.executar(argumentos, log, limite)
    pid = Process.spawn(*argumentos, out: log, err: log)
    status = Timeout.timeout(limite) { Process.wait2(pid).last }
    raise Invalido, "Não foi possível processar o vídeo." unless status.success?
  rescue Timeout::Error
    Process.kill("KILL", pid) rescue Errno::ESRCH
    Process.wait(pid) rescue Errno::ECHILD
    raise Invalido, "O processamento do vídeo excedeu o tempo permitido."
  end
  private_class_method :executar
end
