# TODO: Write documentation for `Karcal::Cr`

require "uri"
require "http/client"
require "lexbor"
require "colorize"
require "json"
require "option_parser"

module ScrapyKarcal
  class GetItem
    def initialize(@auction : Int32, @numPag : Int32 = 1, @total_page : Int32 = 0)
      @cars = Array(Hash(String, String)).new
      @url = URI.new(
        scheme: "https",
        host: "www.karcal.cl",
        path: "/Listado/Index/" + @auction.to_s,
        query: URI::Params.encode({"NumPag" => @numPag.to_s})
      )
    end

    def getCars(body : String) : Array(Hash(String, String))
      parse = Lexbor.new body
      parse.css(".caluga-card").each do |node|
        car = Hash(String, String).new
        car["brand"] = node.css(".descripcion-bien > .nombre-bien:nth-child(1)").first.inner_text.downcase
        car["model"] = node.css(".descripcion-bien > .nombre-bien:nth-child(2)").first.inner_text.downcase
        car["year"] = node.css(".descripcion-bien > .nombre-bien:nth-child(3)").first.inner_text.downcase
        car["link"] = node.css("div:nth-child(1) >a:nth-child(1)").map(&.attribute_by("href")).first.to_s.downcase.gsub("/detalle/ficha", "")
        @cars.push(car)
      end
      @cars
    end

    # Obtenemos el total de las paginas
    def getTotalPage(body : String) : Int32
      parse = Lexbor.new body
      parse.css("ul.pagination:last-child > li:not(.PagedList-skipToNext,.PagedList-skipToPrevious) > a").map(&.inner_text).to_a.size
    end

    def get : Array(Hash(String, String))
      client = HTTP::Client.new @url
      # maximo 5 segundosesperando
      client.connect_timeout = 5.seconds
      body = begin
        response = client.get @url.request_target
        response.body
      rescue ex
        nil
      end
      # revisamos si el total del las paginas se a definido en un numero real
      # en caso de ser menos uno se procede al analicis del total de paginas
      if @total_page == -1
        @total_page = getTotalPage(body.to_s)
      end
      getCars body.to_s
    end

    def getTotalPage
      puts "Run getTotal Page ===> "
    end
  end
end

module Karkal::Cr
  VERSION = "0.1.0"

  auction = 0
  verbose = false
  cache = false
  cache_dir = "/tmp/karcal-cr/"

  if !Dir.exists?(cache_dir)
    Dir.mkdir(cache_dir)
  end

  parser = OptionParser.new do |parser|
    parser.banner = " Welcome karcal Web Scrapy"
    # 30188 example

    parser.on("-c", "--cache", "Enabled cache") { cache = true }
    parser.on("-a AUCTION", "--auction=AUCTION", "bllldldldldl") { |_auction| auction = _auction.to_i? }
    parser.on "-v", "--version", "Show version" do
      puts "version 1.0"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.missing_option do |option_flag|
      STDERR.puts "ERROR: #{option_flag} is missing something."
      STDERR.puts ""
      STDERR.puts parser
      exit(1)
    end
    parser.invalid_option do |option_flag|
      STDERR.puts "ERROR: #{option_flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  parser.parse

  if auction != 0 && !auction.nil?
    k = ScrapyKarcal::GetItem.new auction.not_nil!.to_i32
    puts k.get.to_pretty_json
  else
    puts "Hubo un Error con auction .("
  end

  # puts a.size
  # TODO: Put your code here
end
