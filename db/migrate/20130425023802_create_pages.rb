class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :title
      t.text   :body
      t.references :store

      t.timestamps
    end
  end
end
