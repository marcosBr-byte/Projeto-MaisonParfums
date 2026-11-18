# Consulta o cache atual para compartilhar os limites entre processos em produção.
class SecurityRateLimitStore
  def self.increment(...)
    Rails.cache.increment(...)
  end
end
