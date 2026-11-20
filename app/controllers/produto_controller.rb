class ProdutoController < ApplicationController
  include DetalhesProduto
  layout "admin", only: %i[index new create edit update]
  before_action :exigir_admin, only: %i[index new create edit update destroy]
  before_action :set_produto, only: %i[show edit update destroy]

  def index
    @produtos = Produto.all
  end

  def pag_todos_prod
    @masculinos = Produto.masculino.order(:nome)
    @femininos = Produto.feminino.order(:nome)
    @unissex = Produto.unissex.order(:nome)
    @nichos = Produto.nicho.order(:nome)
    @body_splashes = Produto.body_splash.order(:nome)
    @hidratantes = Produto.hidratante.order(:nome)

    render "produto/produtos_todos"
  end

  def decants_masculinos
    @produtos = filtrar_origem(Produto.masculino).order(:nome)
  end

  def decants_femininos
    @produtos = filtrar_origem(Produto.feminino).order(:nome)
  end

  def decants_unissex
    @produtos = filtrar_origem(Produto.unissex).order(:nome)
  end

  def decants_nicho
    @origem = params[:origem].presence_in(Produto::ORIGENS_NICHO.keys)
    @produtos = Produto.nicho.order(:nome)
    @produtos = @produtos.where(origem: @origem) if @origem
  end

  def body_splash
    @titulo = Produto.defined_enums.fetch("categoria").fetch("body_splash")
    @produtos = filtrar_publico(Produto.body_splash)
    render :categoria
  end

  def hidratantes
    @titulo = Produto.defined_enums.fetch("categoria").fetch("hidratante")
    @produtos = filtrar_publico(Produto.hidratante)
    render :categoria
  end

  def busca
    @termo = params[:q].to_s.strip.first(120)
    @produtos = produtos_da_busca(@termo)
  end

  def sugestoes
    termo = params[:q].to_s.strip.first(120)
    render partial: "produto/sugestoes", locals: { produtos: produtos_da_busca(termo).limit(4), termo: termo }
  end

  def show
    if params[:id] != @produto.to_param
      return redirect_to produto_path(@produto), status: :moved_permanently
    end
    carregar_avaliacoes
  end

  def new
    @produto = Produto.new
    @produto.montar_variantes
  end

  def create
    @produto = Produto.new(produto_params)
    if @produto.save
      redirect_to admin_path, notice: "Produto criado com sucesso."
    else
      @produto.montar_variantes
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return redirect_to edit_produto_path(@produto), status: :moved_permanently if params[:id] != @produto.to_param
    @produto.montar_variantes
  end

  def update
    if @produto.update(produto_params)
      redirect_to admin_path, notice: "Produto atualizado com sucesso."
    else
      @produto.montar_variantes
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @produto.destroy
    redirect_to admin_path, notice: "Produto excluído com sucesso."
  end

  private

  def filtrar_publico(produtos)
    @publico = params[:publico].presence_in(Produto::PUBLICOS.keys)
    produtos = produtos.where(publico: @publico) if @publico
    produtos.order(:nome)
  end

  def filtrar_origem(produtos)
    @origem = params[:origem].presence_in(Produto::ORIGENS.keys)
    @origem ? produtos.where(origem: @origem) : produtos
  end

  def produtos_da_busca(termo)
    return Produto.none if termo.blank?

    texto = "translate(lower(concat_ws(' ', nome, marca, descricao, fragancia, categoria, origem, publico)), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc')"
    palavras = I18n.transliterate(termo).downcase.split.first(8)
    equivalentes = { "arabes" => "arabe", "importados" => "importado", "unisex" => "unissex", "unisexy" => "unissex", "amadeirado" => "amadeirad", "amadeirada" => "amadeirad" }
    produtos = Produto.all
    palavras.each do |palavra|
      padrao = "%#{Produto.sanitize_sql_like(equivalentes.fetch(palavra, palavra))}%"
      produtos = produtos.where("#{texto} LIKE ?", padrao)
    end
    produtos.with_attached_imagem.includes(:variantes).order(:nome)
  end

  def set_produto
    @produto = Produto.por_link!(params[:id])
  end

  def produto_params
    permitidos = params.require(:produto).permit(
      :destaque,
      :nome, :marca, :descricao, :categoria, :publico, :origem, :fragancia, :intensidade,
      :momento, :piramide_olfativa, :concentracao, :imagem,
      :uso_inverno, :uso_primavera, :uso_verao, :uso_outono, :uso_dia, :uso_noite,
      fotos: [], notas_olfativas_attributes: [ :id, :nome, :nivel, :imagem, :_destroy ],
      novas_notas_olfativas: NotaOlfativa.defined_enums.fetch("nivel").keys,
      variantes_attributes: [ :id, :tamanho, :preco, :estoque, :volume_lacrado_ml ]
    )
    permitidos.delete(:fotos) if Array(permitidos[:fotos]).all?(&:blank?)
    permitidos
  end
end
