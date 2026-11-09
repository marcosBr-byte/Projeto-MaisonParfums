class MensagensController < ApplicationController
  before_action :authenticate_usuario!
  before_action :bloquear_admin

  def new
    @mensagem = Mensagem.new
    carregar_pedidos
  end

  def create
    @mensagem = current_usuario.mensagens.build(mensagem_params)

    @mensagem.nome = current_usuario.nome
    @mensagem.email = current_usuario.email

    if params[:mensagem][:pedido_id].present?
      @mensagem.pedido = current_usuario.pedidos.find_by(
        id: params[:mensagem][:pedido_id]
      )

      unless @mensagem.pedido
        @mensagem.errors.add(:pedido, "selecionado não é válido.")
        carregar_pedidos
        return render :new, status: :unprocessable_entity
      end
    end

    if @mensagem.save
      redirect_to root_path,
                  notice: "Mensagem enviada com sucesso! Em breve entraremos em contato."
    else
      carregar_pedidos
      flash.now[:alert] = "Não foi possível enviar sua mensagem. Verifique os campos."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def bloquear_admin
    if current_usuario&.admin?
      redirect_to admin_path, alert: "Essa área é exclusiva para clientes."
    end
  end

  def mensagem_params
    params.require(:mensagem).permit(:assunto, :conteudo, :pedido_id)
  end

  def carregar_pedidos
    @pedidos = current_usuario.pedidos.order(created_at: :desc)
  end
end
