require 'mysql2'
require 'pry'


error_info = Hash.new
movie_id = ''
iterator = 1

for i in 1..5000
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
	ratings_info.each do |info|
		begin
	  		info = info.gsub(/([0-9]{4}-[0-9]{2}-[0-9]{2})/, '\'\1\'')
			connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
			connect.query("INSERT INTO Netflix.ratings (id, user_id, rating, date, movie_id) values (" + iterator.to_s + ',' + info + ',' + movie_id + ");")
		rescue Exception => e
	    	#connect.close if connect
		    puts e.error
		    error_info[iterator] = e.error
		ensure
			puts iterator.to_s + '/' + ratings_info.length.to_s
			iterator += 1
		end
	end
	puts '================================================================================================='
	puts i.to_s
	puts '================================================================================================='
end