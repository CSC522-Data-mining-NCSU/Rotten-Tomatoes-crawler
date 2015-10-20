require 'wombat'
require 'fuzzy_match'

movie_titles = Array.new
error_movies = Array.new #store title of error movies
movies_total_info = Hash.new #store total info of movies (id, year, title)
error_movies_total_info = Array.new #store total info of error movies (id, year, title)

path = "../movie_titles.txt"
#error_path = "./error_movies.txt"
error_path2 = "./error_movies_step1.txt"

#read movie titles from movie_titles.txt
File.open(path, "r") do |f|
  f.each_line do |line|
    title = line.scrub.gsub(/\n/,'').gsub(/.*,/,'')
    movies_total_info[title] = line
    movie_titles << title
  end
end
puts "====================read movie_titles.txt finished======================"

#read movie titles from error_movies.txt
File.open(error_path2, "r") do |f|
  f.each_line do |line|
    error_movies << line.scrub.gsub(/\n/, '')
  end
end
puts "====================read error_movies.txt finished======================"

iterator = 1
error_movies.each do |error_movie_title|
  if movies_total_info[error_movie_title].nil?
  	fz_title = FuzzyMatch.new(movie_titles).find(error_movie_title)
  else
  	fz_title = error_movie_title
  end
  error_movies_total_info << movies_total_info[fz_title]
  puts iterator.to_s + " / 7649"
  iterator += 1
end

File.open(error_path2, 'w') do |f|
  f.puts error_movies_total_info
end
