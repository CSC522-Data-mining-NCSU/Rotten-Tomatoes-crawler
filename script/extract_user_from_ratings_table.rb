require 'mysql2'
require 'pry'

user_ids = Array.new
error_info = Hash.new
iterator = 1
insert_values = ""
multi_counter = 0
connect = Mysql2::Client.new(:host => "localhost", :username => "root")

begin
	connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
	results = connect.query("SELECT distinct(user_id) FROM Netflix.ratings", :as => :array)
	results.each do |result|
		user_ids << result
	end
	user_ids.flatten!.sort!
binding.pry
rescue Exception => e
    connect.close if connect
	puts e.error
	error_info[iterator] = e.error
end

length = user_ids.length

user_ids.each_with_index do |user_id, index|
	insert_values += '(' + user_id.to_s + ', 1)'
	if index == 10000*(multi_counter+1) -1 or index == length - 1
		insert_values += ';'
	else
		insert_values += ','
	end

	iterator += 1
	short_ratings_info = (index == length - 1 and length-10000*multi_counter<=10000)
	long_ratings_info = (index == 10000*(multi_counter+1) - 1 and length-10000*multi_counter>10000)

	if short_ratings_info or long_ratings_info
		begin
			connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
			connect.query("INSERT INTO Netflix.users (id, reputation) values" + insert_values)
		rescue Exception => e
		    #connect.close if connect
			puts e.error
			error_info[iterator] = e.error
		ensure
			puts iterator.to_s + '/' + user_ids.length.to_s
			multi_counter += 1
			insert_values = ""
			puts '=========================================='
		end
	end

end