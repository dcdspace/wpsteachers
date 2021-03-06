Sequel.migration do
  up do
    create_table(:entries) do
      primary_key :id

      String :body
      Integer :rating
      Integer :teacher_id
      Float :average_rating
      foreign_key :user_id, :users
      DateTime :created_at
    end
  end

  down do
    drop_table(:entries)
  end
end