class CreateObservations < ActiveRecord::Migration[5.0]
	def change
		create_table :observations do |t|
			t.integer :chirp_id
			t.index   :chirp_id
			t.integer :provider_id
			t.string  :concept
			t.index   :concept
			t.datetime :started_at
			t.index :started_at
			t.index [:chirp_id,:started_at]
			t.datetime :ended_at
			t.string :value
			t.index :value
			t.string :units, limit: 20
			t.string :raw
			t.datetime :downloaded_at
			t.string :source_schema, limit: 50
			t.string :source_table, limit: 50
			t.integer :source_id
			t.datetime :imported_at
		end
	end
end
