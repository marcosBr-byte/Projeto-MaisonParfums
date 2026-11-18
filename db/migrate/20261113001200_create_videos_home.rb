class CreateVideosHome < ActiveRecord::Migration[8.1]
  def up
    create_table :videos_home do |t|
      t.string :titulo, null: false
      t.string :arquivo_padrao
      t.integer :ordem, default: 0, null: false
      t.boolean :ativo, default: true, null: false
      t.timestamps
    end

    # Preserve the five videos already displayed on the home page.
    tabela = Class.new(ActiveRecord::Base) { self.table_name = "videos_home" }
    %w[video1.mp4 video2.mp4 video3.mp4 video4.mp4 video_parfum.mp4].each_with_index do |arquivo, indice|
      tabela.create!(titulo: "Vídeo Maison #{indice + 1}", arquivo_padrao: arquivo, ordem: indice)
    end
  end

  def down
    drop_table :videos_home
  end
end
