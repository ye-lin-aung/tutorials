class CreateTutorialsUserTourProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :tutorials_user_tour_progresses do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string     :tour_id, null: false
      t.integer    :last_step, null: false, default: 0
      t.datetime   :started_at, null: false
      t.datetime   :completed_at
      t.datetime   :dismissed_at
      t.timestamps
    end

    add_index :tutorials_user_tour_progresses,
              [:user_id, :tour_id],
              unique: true,
              name: "idx_tutorials_progress_on_user_and_tour"
  end
end
