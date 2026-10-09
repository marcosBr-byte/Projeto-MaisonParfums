class PerfumeController < ApplicationController
  before_action :authenticate_usuario!, only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  def index
    exigir_admin
  end
end
