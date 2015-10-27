require 'mysql2'
require 'pry'

#Define User class and related methods
class User
  attr_accessor :id
  attr_accessor :rating_records
  attr_accessor :reputation
  attr_accessor :leniency
  attr_accessor :weight

  def initialize(id)
    @id = id
    @rating_records = Array.new
    @reputation = nil
    @leniency = 0
    @weight = 0
  end

  def weight
    @weight
  end
end

#Define Rating class, a mapping class (between Movie and User)
class Rating
  attr_accessor :user_id
  attr_accessor :score
  attr_accessor :movie_id

  def initialize(user_id, score, movie_id)
    @user_id = user_id
    @score = score
    @movie_id = movie_id
  end
end

#Define Movie class and related method
class Movie
  attr_accessor :id
  attr_accessor :rating_records
  attr_accessor :temp_score

  def initialize(id)
    @id = id
    @rating_records = Array.new
    @temp_score = 0
  end
end

#Add data to @ratings
def ratings
  return @ratings if @ratings
  @rating_iterator = 0
  @ratings = Hash.new
  connect = Mysql2::Client.new(:host => "localhost", :username => "root")
  begin
    connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
    results = connect.query("SELECT * FROM Netflix.ratings limit 5000", :as => :hash)
    results.each do |result|
      rating = Rating.new(result['user_id'], result['rating'], result['movie_id'])
      @ratings[result['id']] = rating
    end
  rescue Exception => e
      connect.close if connect
      puts e.error
  ensure
    @rating_iterator += 1
    if @rating_iterator % 10000 == 0
      puts '==Reading ratings data========================================' 
      puts @user_iterator.to_s + '/ 100480507'
    end
  end
  return @ratings
end

#Add data to @users
def users
  return @users if @users
  @user_iterator = 0
  @users = Array.new
  @user_ids = Array.new
  connect = Mysql2::Client.new(:host => "localhost", :username => "root")
  begin
    connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
    results = connect.query("SELECT id FROM Netflix.users", :as => :array)
    results.each do |result|
      @user_ids << result[0]
    end
  rescue Exception => e
      connect.close if connect
      puts e.error
  end
  #Create new user and add corresponding rating_records.
  @user_ids.each do |user_id|
    begin
      user = User.new(user_id)
      connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
      results = connect.query("SELECT id FROM Netflix.ratings where user_id = #{user_id}", :as => :array)
      results.each do |result|
        user.rating_records << @ratings[result[0]]
      end
    rescue Exception => e
        #connect.close if connect
        puts e.error
    ensure
      @user_iterator += 1
      if @user_iterator % 10000 == 0
        puts '==Reading users data========================================' 
        puts @user_iterator.to_s + '/' + @user_ids.length.to_s
      end
    end
    @users << user
  end
  return @users
end

#Add data to @movies
def movies
  return @movies if @movies
  @movie_iterator = 0
  @movies = Array.new
  @movie_ids = Array.new
  connect = Mysql2::Client.new(:host => "localhost", :username => "root")
  begin
    connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
    results = connect.query("SELECT id FROM Netflix.movies", :as => :array)
    results.each do |result|
      @movie_ids << result[0]
    end
  rescue Exception => e
      connect.close if connect
      puts e.error
  end
  #Create new movie and add corresponding rating_records.
  @movie_ids.each do |movie_id|
    begin
      movie = Movie.new(movie_id)
      connect = Mysql2::Client.new(:host => "localhost", :username => "root") if !connect
      results = connect.query("SELECT id FROM Netflix.ratings where movie = #{movie_id}", :as => :array)
      results.each do |result|
        movie.rating_records << @ratings[result[0]]
      end
    rescue Exception => e
        #connect.close if connect
        puts e.error
    ensure
      @movie_iterator += 1
      if movie_iterator % 10000 == 0
        puts '==Reading movies data========================================' 
        puts @movie_iterator.to_s + '/' + @movie_ids.length.to_s
      end
    end
    @movies << movie
  end
  return @movies
end

#Define Lauw's algorithm
def self.calculate_weighted_scores_and_reputation(movies, users)
  alpha = 0.5  #???????????

  # Iterate until convergence
  iterations = 0
  begin
    previous_leniency = users.map(&:leniency)
    puts "=========================previous_leniencies=========================="
    previous_leniency.each_with_index do |leniency, index|
      puts users[index].to_s + ": " + leniency.to_s
    end

    # Pass 1: calculated weighted grades for each movie
    movies.each do |movie|
      weighted_score = 0.0
      movie.rating_records.each do |rr|
        weighted_score = weighted_score + rr.score * (1 - alpha * rr.reviewer.leniency)
      end
      movie.temp_score= weighted_score.to_f / movie.rating_records.size
      puts "temp_score=" + movie.temp_score.to_s
    end

    #Pass 2: calculate leniencies for each reviewer
    users.each do |reviewer|
      sum_leniency=0.0
      reviewer.rating_records.each do |rr|
        if rr.score!=0
          temp_leniency = (rr.score-rr.submission.temp_score)/(rr.score)
          if temp_leniency>1
            temp_leniency=1
          end
          if temp_leniency<-1
            temp_leniency=-1
          end
          sum_leniency=sum_leniency+temp_leniency
        else
          sum_leniency=sum_leniency+(rr.score-rr.submission.temp_score)/rr.submission.temp_score
        end
      end

      if reviewer.rating_records.size==0
        reviewer.leniency=0
      else
        reviewer.leniency=sum_leniency/reviewer.rating_records.size
        puts "sum_leniency/reviewer.rating_records.size:" + sum_leniency.to_s+"/"+reviewer.rating_records.size.to_s+"="+reviewer.leniency.to_s
      end
    end
    iterations += 1

    current_leniency = users.map(&:leniency)
  end while converged?(previous_leniency,current_leniency)
  #for each reviewer, use absolute value of leniency as reputation. At the same time make 1 the highest reputation and 0 the lowest
  users.each do |reviewer|
    reviewer.reputation=1-(reviewer.leniency).abs
  end

  #for each reviewer, if no peer-review has been done in current task,  reputation =N/A
  final_reputation = users.map(&:reputation)
  puts "=========================final_weights=========================="
  @users.each_with_index do |reviewer, index|
    if reviewer.rating_records.size>0
      puts @all_users_simple_array[index].to_s + ": " + final_reputation[index].to_s
    else
      puts @all_users_simple_array[index].to_s + ": N/A"
    end
  end

  return :iterations => iterations
end

# Ensure all numbers in lists a and b are equal
# Options: :precision => Number of digits to round to
def self.converged?(a, b, options={:precision => 1})
  raise "a and b must be the same size" unless a.size == b.size
  a.flatten!
  b.flatten!

  p = options[:precision]
  a.map! {|num| num.to_f.round(p)}
  b.map! {|num| num.to_f.round(p)}

  #judge initial situation
  if (a.uniq.length == 1) && (b.uniq.length == 1)
    return true
  else
    result = !(a == b)
    return result
  end
end

#==========================================================================================
#initialize
ratings
#users
#movies

=begin    temperary commit
calculate_weighted_scores_and_reputation(@movies, @users)

puts "=================calculate the diff between weighted final score and expert score============================="

puts "weighted_final_score | expert_grades"
@movies.each_with_index do |submission, index|
  @weighted_final_score = 0.0
  @weight_sum = 0.0
  @users.each do |reviewer|
      if reviewer.rating_records.size>0
        if reviewer.rating_records[index] != nil
          @weighted_final_score += reviewer.reputation * reviewer.rating_records[index].score 
          @weight_sum += reviewer.reputation
        end
      end
  end
  if @weighted_final_score == 0.0 || @weight_sum == 0.0
   puts 'N/A  | ' + (@expert_grades[index]).to_s
  else
   puts (@weighted_final_score / @weight_sum).round(1).to_s + ' | ' + (@expert_grades[index]).to_s
  end
end
=end