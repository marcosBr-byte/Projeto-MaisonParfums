require "test_helper"

class QuizPaginasTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  def respostas
    { categoria: "masculino", familias: [ "amadeirada" ], momento: "noite", intensidade: "alta" }
  end

  def perfume(nome: "Perfume recomendado", preco: 60, estoque: 2, fragancia: :amadeirada, categoria: :masculino, **outros)
    Produto.create!({ nome: nome, categoria: categoria, fragancia: fragancia, momento: :noite, intensidade: :alta,
      variantes_attributes: [ { tamanho: :lacrado, preco: preco, estoque: estoque } ] }.merge(outros))
  end

  test "paginas institucionais e nicho respondem com conteudo" do
    [ perguntas_frequentes_path, trocas_path, privacidade_path, sobre_path, atendimento_path, grupo_vip_path, decants_nicho_path ].each do |caminho|
      get caminho
      assert_response :success, caminho
      assert_select "h1", minimum: 1
      assert_select 'a[href="#"]', count: 0
      assert_select "a[href=?]", quiz_path, minimum: 1
    end
  end

  test "quem somos permite a incorporação direta do mapa da loja" do
    get sobre_path
    assert_response :success
    assert_select 'iframe[src^="https://www.google.com/maps/embed?"][src$="7738986536258988493"]', count: 1
    assert_includes response.headers["Content-Security-Policy"], "frame-src 'self' https://www.google.com/maps/embed"
  end

  test "quiz funciona sem login e resultado tem produto e motivos" do
    produto = perfume
    get quiz_path
    assert_response :success
    assert_select "fieldset", count: 4
    post quiz_path, params: { perfume_quiz: respostas }
    assert_redirected_to resultado_quiz_path
    follow_redirect!
    assert_response :success
    assert_select "h2", text: produto.nome
    assert_select "li", text: /Família amadeirada/
    assert_select "a[href=?]", produto_path(produto), minimum: 1
  end

  test "respostas incompletas e adulteradas nao geram resultado" do
    [ {}, { perfume_quiz: "invalido" }, { perfume_quiz: respostas.merge(categoria: "invalida") },
     { perfume_quiz: respostas.merge(familias: [ "floral", "citrica", "aquatica", "gourmand" ]) } ].each do |entrada|
      post quiz_path, params: entrada
      assert_response :unprocessable_entity
      assert_select '[role="alert"]', minimum: 1
    end
  end

  test "resultado exige quiz valido e pode ser revisado" do
    get resultado_quiz_path
    assert_redirected_to quiz_path
    post quiz_path, params: { perfume_quiz: respostas }
    get quiz_path(revisar: 1)
    assert_select 'input[type="radio"][value="masculino"][checked]'
    assert_select 'input[type="checkbox"][value="amadeirada"][checked]'
    get quiz_path
    assert_select "input[checked]", count: 0
  end

  test "nao recomenda esgotados nem fora do perfil" do
    perfume(nome: "Esgotado", estoque: 0)
    perfume(nome: "Outro perfil", categoria: :feminino)
    perfume(nome: "Outra familia", fragancia: :floral)
    post quiz_path, params: { perfume_quiz: respostas }
    follow_redirect!
    assert_select "h2", text: "Ainda não encontramos essa combinação"
    assert_select "article", count: 0
  end

  test "nicho filtra marcas e pagina inicial exibe link do quiz" do
    produto = perfume(marca: "Xerjoff", categoria: "nicho", origem: "xerjoff")
    get decants_nicho_path
    assert_select "a[href=?]", produto_path(produto)
    get root_path
    assert_response :success
    assert_select "#descubra a[href=?]", quiz_path
  end
end
