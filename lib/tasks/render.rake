namespace :render do
  desc "Prepara o PostgreSQL compartilhado do Render"
  task prepare: :environment do
    ActiveRecord::Base.with_connection do |connection|
      %w[queue cache cable].each do |schema|
        connection.execute("CREATE SCHEMA IF NOT EXISTS #{schema}")
      end
    end

    Rake::Task["db:prepare"].invoke
  end
end
