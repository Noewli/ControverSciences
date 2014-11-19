class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :user, index: true
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
