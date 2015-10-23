require 'mysql2'

movies_info = Array.new
error_info = Hash.new
path = "./movies_info_for_mysql.txt"
#path = "./movies_info_test.txt"
#read movie info from file
File.open(path, "r") do |f|
  f.each_line do |line|
    movies_info << line
  end
end

iterator = 1
connect = Mysql2::Client.new(:host => "localhost", :username => "root")
movies_info.each do |info|
	begin
  		info = info.gsub(/\([0-9]+,/, "(" + iterator.to_s + ",")
		connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
		connect.query("INSERT INTO Netflix.movies (id, year, title, genre, director, cast) values" + info + ";")
	rescue Exception => e
    	#connect.close if connect
	    puts e.error
	    error_info[iterator] = e.error
	ensure
		puts iterator.to_s + '/' + movies_info.length.to_s
		iterator += 1
	end
end
puts '================================================================================================='
puts error_info