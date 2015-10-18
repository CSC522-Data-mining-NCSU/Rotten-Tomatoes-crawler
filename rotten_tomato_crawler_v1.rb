require 'wombat'

movie_titles = Array.new #store all movie titles
results = Array.new #store all results (correct and incorrect)
new_lines = Array.new #store new movies' info
error_movies = Array.new #store info of error movies
iterator = 1
path = "./movie_titles.txt"
error_path = "./error_movies.txt"
#read movie titles from file
File.open(path, "r") do |f|
  f.each_line do |line|
    movie_titles << line.gsub(/\n/,'').gsub(/.*,/,'')
  end
end

movie_titles.each do |title|
  begin
    title_for_url = title.gsub(/\s/, '_')
    result = Wombat.crawl do
      absolute_url = "http://www.rottentomatoes.com/m/" + title_for_url
      base_url absolute_url
      path "/"

      name 'xpath=//h1[@itemprop="name"]'

      year 'xpath=//h1[@itemprop="name"]/span//text()'

      genres "xpath=//span[@itemprop='genre']//text()", :list

      directors "xpath=//td[@itemprop='director']/a[@itemprop='url']/span[@itemprop='name']//text()", :list

      casts "xpath=//div[@itemprop='actors']/div/a[@itemprop='url']/span[@itemprop='name']//text()", :list
    end
    #puts result
    results << result
  rescue
    puts "Error movie" + iterator.to_s + ':' + title
    iterator += 1 
    result = 'Error movie'
    results << result
    error_movies << title
  end
end


#puts results
puts '================================================================================='
#write movie genres, directors and casts in file
lines = IO.readlines(path)
lines.each_with_index do |line, index|
  next if results[index] == 'Error movie'
  line = line.gsub(/\n/,'') 
  line += ';' + results[index]["genres"].join(',')
  line += ';' + results[index]["directors"].join(',')
  line += ';' + results[index]["casts"].join(',') + "\n"
  new_lines << line
end
#puts new_lines
File.open(path, 'w') do |f|
  f.puts new_lines
end

File.open(error_path, 'w') do |f|
  f.puts error_movies
end
