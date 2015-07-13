require 'mechanize'
require 'csv'
require 'pry'

class POEScraper
  @@class_pages = {
    'http://www.pathofexile.com/forum/view-forum/40'  => "./results/duelist.csv",
    'http://www.pathofexile.com/forum/view-forum/marauder' => "./results/marauder.csv",
    'http://www.pathofexile.com/forum/view-forum/24' => "./results/ranger.csv",
    'http://www.pathofexile.com/forum/view-forum/436' => "./results/scion.csv",
    'http://www.pathofexile.com/forum/view-forum/303' => "./results/shadow.csv",
    'http://www.pathofexile.com/forum/view-forum/41' => "./results/templar.csv",
    'http://www.pathofexile.com/forum/view-forum/22' => "./results/witch.csv"
    }

  # If the thread contains one of these words we assume it is not a guide.
  @@banned_words = ["help", "question", "input", "someone", "?", "theorycraft", "1.3", "discussion"]

  def initialize
    @agent = Mechanize.new

    # Important, please don't remove this and spam GGG with requests!
    @agent.history_added = Proc.new { sleep 5 }
  end

  def parse_forums
    @@class_pages.each do |class_url, class_name|
      parse_class(class_url)
    end
  end

  # Takes the class_url and appends all guides found to the proper csv.
  def parse_class(class_url)
    page = @agent.get(class_url)
    classname = @@class_pages[class_url]
    threads = get_threads(page)

    csv_contents = CSV.read(classname) if File.exist? (classname)
    csv_contents ||= []

    csv_file = CSV.open(classname, "a+")
    threads.each do |thread|
      info = generate_info(thread)
      unless already_scraped?(csv_contents, info[:title])
        csv_file << [info[:title], info[:link], info[:author]]
      end
    end
    csv_file.close
  end

  # We input the page, get the thread elements.
  def get_threads(page)
    threads = page.search("#view_forum_table").search("tr")[1..-1]
    threads = get_relevant_threads(threads)
    threads = remove_irrelevant_threads(threads)
    threads
  end

  # already_scraped? just sees if our result is already written to our file.
  # We only want to append guides that we haven't already scraped.
  def already_scraped?(csv, title)
    return false if csv.empty?
    csv.any? {|entry| entry[0].include?(title)}
  end

  # We take the thread element and scrape the information we want from it.
  def generate_info(thread)
    info = {}
    info[:title] = thread.search(".title").text
    info[:link] = ("http://www.pathofexile.com" + thread.search("a")[0]["href"])[0..-6]
    info[:author] = thread.search(".postBy").search("a")[0].text
    info
  end

  def get_relevant_threads(threads)
    threads.select {|thread| thread.search(".title").text.include? ("2.0")}
  end

  def remove_irrelevant_threads(threads)
    threads.reject{|thread| @@banned_words.any?{|word| thread.search(".title").text.downcase.include? (word)}}
  end
end

# Comment these lines out if you don't want to actually parse
s = POEScraper.new
s.parse_forums