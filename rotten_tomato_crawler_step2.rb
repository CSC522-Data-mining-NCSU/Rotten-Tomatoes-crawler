require 'wombat'
require 'pry'
error_movies = Array.new #store title of error movies
movies_total_info = Hash.new #store total info of movies (id, year, title)
error_movies_total_info = Array.new #store total info of error movies (id, year, title)

path = "../movie_titles.txt"
error_path = "./error_movies.txt"
error_path2 = "./error_movies_id_year_title.txt"

#read movie titles from movie_titles.txt
File.open(path, "r") do |f|
  f.each_line do |line|
    title = line.scrub.gsub(/\n/,'').gsub(/.*,/,'')
    movies_total_info[title] = line
  end
end
puts "====================read movie_titles.txt finished======================"

#read movie titles from error_movies.txt
File.open(error_path, "r") do |f|
  f.each_line do |line|
    error_movies << line.scrub.gsub(/\n/, '')
  end
end
puts "====================read error_movies.txt finished======================"

error_movies.each do |error_movie_title|
  error_movies_total_info << movies_total_info[error_movie_title]
end
binding.pry

File.open(error_path2, 'w') do |f|
  f.puts error_movies_total_info
end
