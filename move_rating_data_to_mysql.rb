require 'mysql2'
require 'pry'


error_info = Hash.new
movie_id = ''
iterator = 1

for i in 1..17770
	ratings_info = Array.new
	#mv_0017738.txt
	file_name = 'mv_' + '0' * (7 - i.to_s.length) + i.to_s + '.txt'
	path = "../training_set/" + file_name
	#read rating info from file
	j = 1
	File.open(path, "r") do |f|
	  f.each_line do |line|
	  	movie_id = line.gsub(/:\n/,'') if j == 1
	    ratings_info << line.gsub(/\n/,'') if j != 1
	    j += 1
	  end
	end

	connect = Mysql2::Client.new(:host => "localhost", :username => "root")
	length = ratings_info.length
	multi_counter = 0
	insert_values = ""

	ratings_info.each_with_index do |info, index|
	  	info = info.gsub(/([0-9]{4}-[0-9]{2}-[0-9]{2})/, '\'\1\'')
		insert_values += '(' + iterator.to_s + ',' + info + ',' + movie_id + ')'
		if index == 10000*(multi_counter+1) - 1 or index == length - 1
			insert_values += ';'
		else
			insert_values += ','
		end

		iterator += 1
		short_ratings_info = (index == length - 1 and length-10000*multi_counter<=10000)
		long_ratings_info = (index == 10000*(multi_counter+1) - 1 and length-10000*multi_counter>10000)

		if short_ratings_info or long_ratings_info
			begin
	#binding.pry
				connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
				connect.query("INSERT INTO Netflix.ratings (id, user_id, rating, date, movie_id) values " + insert_values)
			rescue Exception => e
		    	#connect.close if connect
			    puts e.error
			    error_info[iterator] = e.error
			ensure
				puts iterator.to_s + '/' + ratings_info.length.to_s + '----- file ' + i.to_s
				insert_values = ""
				multi_counter += 1
			end
		end
	end
	puts '================================================================================================='
	puts i.to_s
	puts '================================================================================================='
end