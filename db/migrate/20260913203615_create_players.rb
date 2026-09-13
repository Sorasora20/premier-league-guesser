class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name
      t.date :date_of_birth
      t.integer :height
      t.string :nationality
      t.string :position
      t.string :preferred_foot
      t.string :club

      t.timestamps
    end
  end
end
