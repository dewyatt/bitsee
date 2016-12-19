class CreateSecrets < ActiveRecord::Migration[5.0]
  def change
    create_table :secrets do |t|
      t.string :tx
      t.string :file_mime
      t.string :file_path
      t.integer :file_size
      t.string :text
      t.datetime :time

      t.timestamps
    end
  end
end
