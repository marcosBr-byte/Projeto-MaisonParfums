module OtimizaImagens
  extend ActiveSupport::Concern

  included do
    validate do
      (@erros_otimizacao || {}).each do |campo, mensagem|
        errors.add(campo, mensagem)
      end
    end
  end

  class_methods do
    def otimizar_anexos(*campos, limite: 1600)
      campos.each do |campo|
        multiplo = reflect_on_attachment(campo).macro == :has_many_attached
        define_method("#{campo}=") do |valor|
          @erros_otimizacao ||= {}
          @erros_otimizacao.delete(campo)
          begin
            preparado = if multiplo
              Array(valor).reject(&:blank?).map { |anexo| ImagemOtimizada.preparar(anexo, limite: limite) }
            else
              ImagemOtimizada.preparar(valor, limite: limite)
            end
            super(preparado)
          rescue ImagemOtimizada::Invalida => erro
            @erros_otimizacao[campo] = erro.message
            # Mantém a imagem anterior em edições recusadas, sem salvar o upload.
          end
        end
      end
    end
  end
end
