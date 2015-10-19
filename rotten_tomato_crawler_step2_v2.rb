require 'wombat'
require 'fuzzy_match'
require 'net/http'
require 'uri'

movie_titles = Array.new #store all movie titles
movie_years = Array.new #store all movie years
results = Array.new #store all results (correct and incorrect)
new_lines = Array.new #store new movies' info
error_movies = Array.new #store info of error movies
iterator = 1
#path = "./movies_titles_error_in_step1.txt"
path = "./error_movies_step2_year_not_match.txt"
error_path = "./error_movies_id_year_title.txt"
#read movie titles from file
File.open(path, "r") do |f|
  f.each_line do |line|
    movie_titles << line.scrub.gsub(/\n/,'').gsub(/.*,/,'')
    movie_years << line[/[0-9]{4}/]
  end
end

movie_titles.each_with_index do |title, outer_index|
  #Search movie
  title_for_url = title.gsub(/\s/, '+')
  begin
    temp_result = Wombat.crawl do
      absolute_url = "http://www.rottentomatoes.com/search/?search=" + title_for_url
      base_url absolute_url
      path "/"

      success_info "xpath=//div[contains(@class, 'ui-tabs')]/h1//text()"
      error_info "xpath=//h1[contains(@class, 'center noresults')]//text()"
      candidate_movies do
        title "xpath=//div[contains(@class, 'results_content')]/ul/li/div/div/a//text()", :list
        year "xpath=//div[contains(@class, 'results_content')]/ul/li/div/div/span//text()", :list
        link "xpath=//div[contains(@class, 'results_content')]/ul/li/div/div/a/@href", :list
      end
    end
  rescue
    puts "==============Search error================"
  end
  search_success = !temp_result['success_info'].nil? and temp_result['error_info'].nil? and temp_result['success_info'].downcase.byteslice(0,18) == "search results for"
  search_error = !temp_result['error_info'].nil? and temp_result['success_info'].nil? and temp_result['error_info'].downcase.byteslice(0,27) == "sorry, no results found for"

  #case1: after search, only one movie match, redirect directly
  if !search_success and !search_error
    absolute_url = "http://www.rottentomatoes.com/search/?search=" + title_for_url
    real_uri = Net::HTTP.get_response(URI.parse(absolute_url))['location']
    absolute_url = "http://www.rottentomatoes.com" + real_uri if !real_uri.nil?
    begin
      result = Wombat.crawl do
        base_url absolute_url

        name 'xpath=//h1[@itemprop="name"]'

        year 'xpath=//h1[@itemprop="name"]/span//text()'

        genres "xpath=//span[@itemprop='genre']//text()", :list

        directors "xpath=//td[@itemprop='director']/a[@itemprop='url']/span[@itemprop='name']//text()", :list

        casts "xpath=//div[@itemprop='actors']/div/a[@itemprop='url']/span[@itemprop='name']//text()", :list
      end
      #puts result
      results << result
    rescue
      puts "Error movie" + iterator.to_s + ':' + title + ' (auto-redirect page not match)'
      iterator += 1 
      result = 'Error movie -' + title + ': auto-redirect page not match'
      results << result
      error_movies << title
    end
  #case2: after search, more than one movies match, choose the matching one
  elsif search_success
    #if search successfully, choose the matching one
    fz_title = FuzzyMatch.new(temp_result['candidate_movies']['title']).find(title)
    temp_result['candidate_movies']['title'].each_with_index do |candidate_movie_title, index|

      match_year = (temp_result['candidate_movies']['year'][index].gsub(/\(|\)/, '').to_i - movie_years[outer_index].to_i).abs < 4 if !temp_result['candidate_movies']['year'][index].nil?
      match_title = temp_result['candidate_movies']['title'][index] == fz_title if !temp_result['candidate_movies']['title'][index].nil?

      if match_year and match_title
        begin
          #crawling again (get name, year, link)
          absolute_url = "http://www.rottentomatoes.com" + temp_result['candidate_movies']['link'][index]
          result = Wombat.crawl do
            base_url absolute_url

            name 'xpath=//h1[@itemprop="name"]'

            year 'xpath=//h1[@itemprop="name"]/span//text()'

            genres "xpath=//span[@itemprop='genre']//text()", :list

            directors "xpath=//td[@itemprop='director']/a[@itemprop='url']/span[@itemprop='name']//text()", :list

            casts "xpath=//div[@itemprop='actors']/div/a[@itemprop='url']/span[@itemprop='name']//text()", :list
          end
          #puts result
          results << result
          break
        rescue
          puts "Error movie" + iterator.to_s + ':' + title + ' (redirect page not match)'
          iterator += 1 
          result = 'Error movie -' + title + ': redirect page not match'
          results << result
          error_movies << title
        end
      end
      if index == temp_result['candidate_movies']['title'].length - 1
        puts "Error movie" + iterator.to_s + ':' + title + ' (not match)'
        iterator += 1 
        result = 'Error movie: not match'
        results << result
        error_movies << title
      end
    end
  #case3: after search, no movie match, print and record error
  elsif search_error
    puts "Error movie" + iterator.to_s + ':' + title + ' (cannot find this title)'
    iterator += 1 
    result = 'Error movie -' + title + ': cannot find this title'
    results << result
    error_movies << title
  end
end


#puts results
puts '================================================================================='
#write movie genres, directors and casts in file
lines = IO.readlines(path)
lines.each_with_index do |line, index|
  next if results[index].class == String and results[index].byteslice(0,11) == 'Error movie'
  line = line.scrub.gsub(/\n/,'')
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
