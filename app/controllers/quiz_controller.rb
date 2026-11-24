class QuizController < ApplicationController
  def new
    respostas = params[:revisar] == "1" ? session[:perfume_quiz] : {}
    @quiz = PerfumeQuiz.new((respostas || {}).except("orcamento", :orcamento))
  end

  def create
    entrada = params[:perfume_quiz]
    entrada = ActionController::Parameters.new unless entrada.is_a?(ActionController::Parameters)
    respostas = entrada.permit(:categoria, :momento, :intensidade, familias: [])
    @quiz = PerfumeQuiz.new(respostas)
    if @quiz.valid?
      session[:perfume_quiz] = @quiz.respostas
      redirect_to resultado_quiz_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def resultado
    @quiz = PerfumeQuiz.new((session[:perfume_quiz] || {}).except("orcamento", :orcamento))
    unless @quiz.valid?
      redirect_to quiz_path, alert: "Responda ao quiz para descobrir suas sugestões."
      return
    end
    @resultados = RecomendadorPerfumes.new(@quiz).resultados
  end
end
