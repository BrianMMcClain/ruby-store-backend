require 'sinatra'
require 'mysql2'
require 'json'

configure do 
    mockData = [
        { "id": 1, "name": "Football", "price": 17.99, "quantity": 6},
        { "id": 2, "name": "Firewood", "price": 9.99, "quantity": 73},
        { "id": 3, "name": "Coffee Beans", "price": 11.99, "quantity": 35},
        { "id": 4, "name": "Running Shoes", "price": 74.99, "quantity": 24}
    ]
    set :mockData, mockData

    begin
        puts ENV["DATABASE_URL"]
        dbURI = URI.parse(ENV["DATABASE_URL"])

        host = dbURI.host
        port = dbURI.port
        username = dbURI.user
        password = dbURI.password
        database = dbURI.path[1..-1]

        puts host
        puts port
        puts username
        puts password
        puts database
        
        client = Mysql2::Client.new(:host => host, :port => port, :username => username, :password => password, :database => database)
        set :client, client
        set :connected, true

        # Init Database
        settings.client.query("DROP TABLE IF EXISTS inventory;")

        createTableSQL = <<-END_SQL
        create table inventory(
            id INT NOT NULL AUTO_INCREMENT,
            name VARCHAR(64) NOT NULL,
            price REAL NOT NULL,
            quantity INT,
            PRIMARY KEY ( id )
        );     
        END_SQL
        settings.client.query(createTableSQL)

        settings.client.query("INSERT INTO inventory(id, name, price, quantity) VALUES (1, 'Football', 17.99, 6)")
        settings.client.query("INSERT INTO inventory(id, name, price, quantity) VALUES (2, 'Firewood', 9.99, 73)")
        settings.client.query("INSERT INTO inventory(id, name, price, quantity) VALUES (3, 'Coffee Beans', 11.99, 35)")
        settings.client.query("INSERT INTO inventory(id, name, price, quantity) VALUES (4, 'Running Shoes', 74.99, 24)")
    rescue Exception => e
        puts e
        set :connected, false
    end
end

##### APP ENDPOINTS #####

get "/items" do
    ret = []

    if settings.connected 
        settings.client.query("SELECT * FROM inventory").each do |row|
            ret.append(row)
        end
    else
        ret = settings.mockData
    end

    return ret.to_json
end

get "/items/:id" do
    if settings.connected
        settings.client.query("SELECT * FROM inventory WHERE id=#{params['id']}").each do |row|
            if row["id"].to_s == params['id']
                return row.to_json
            end
        end
    else
        retItem = settings.mockData.select {|item| item[:id] == params['id'].to_i }
        return retItem.to_json
    end

    return "NO RESULTS"
end

##### DEBUG ENDPOINTS #####

get '/env' do
    ret = ""
    ENV.keys.each do |k|
        ret += "<b>#{k}</b>: #{ENV[k]}<br />"
    end

    return ret
end