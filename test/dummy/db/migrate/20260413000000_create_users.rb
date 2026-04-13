class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string   :email,        null: false
      t.datetime :onboarded_at
      t.timestamps
    end
  end
end
