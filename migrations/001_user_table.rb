Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
#BASIC INFO
      String :email
      String :name

    end
  end

  down do
    drop_table(:users)
  end
end