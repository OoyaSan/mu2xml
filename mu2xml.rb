# encoding: utf-8
require 'nokogiri'
require 'open-uri'
require 'sinatra'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

def returnError(message)
	logger.info(message)
	errorBuilder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
		xml.error('message' => message)
	end
	errorBuilder.to_xml
end

def parseSeries(inp)
	id = inp.to_i
	base_url = "https://www.mangaupdates.com/"

	if 0 == id
		logger.debug "Was given was #{inp}"
		return returnError("Invalid series ID")
	end

	begin
		series = Nokogiri::HTML(open("#{base_url}series.html?id=#{id}"))
	rescue => e
		logger.error(e)
		return returnError("Unable to connect to MangaUpdates #{id}")
	end

	if "You specified an invalid series id." == series.xpath("//*[@id='main_content']/table/tr/td/table/tr[2]/td/text()").to_s.strip
		logger.debug "ID was #{id}"
		return returnError("Series does not exist")
	end

	begin
	title = series.xpath("//span[@class='releasestitle tabletitle']").children[0].to_s

	status_string = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[14]").children[0].to_s.strip
	volumeCount =status_string.split(' ')[0]
	status = status_string.split(' ')[-1][1..-2]
	type = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[4]").children[0].to_s.strip
	related_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[6]/a")
	name_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[8]")
	group_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[10]/a")
	tlstatus = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[3]/div[1]/div[16]").children[0].to_s.strip

	author_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[12]/a")
	artist_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[14]/a")
	year = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[16]").children[0].to_s.strip
	publisher_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[18]/a")
	mag_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[20]/a")
	licensed = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[22]").children[0].to_s.strip
	engPublisher_list = series.xpath("//*[@id='main_content']/table[2]/tr/td/div[1]/div[4]/div[1]/div[24]/a")
	rescue => e
		logger.error(e)
		return returnError("Unable to parse content")
	end

	begin
	seriesBuilder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
	xml.series('id' => id, 'title' => title) do
		xml.type type
		xml.status status_string
		xml.volumesReleased volumeCount
		xml.completelyScanlated tlstatus
		xml.year year
		xml.licensed licensed


		xml.alternativeTitles do
			name_list.children[0..-2].each do |t|
			if t.text?					
				xml.altTitle('title' => t)
			end
			end
		end
		xml.relatedSeries do
			related_list.each do |t|				
				xml.series('id'=> t.values[0].split('=')[-1], 'title' => t.children[0].children.to_s)
			end
		end
		#disabled since it doesn't handle the more JS
		#xml.groupsScanlating do
		#	group_list.each do |t|				
		#		xml.group('id'=> t.values[0].split('=')[-1], 'name' => t.children[0].children.to_s)
		#	end
		#end
		xml.authors do
			author_list.each do |t|				
				xml.author('id'=> t.values[0].split('=')[-1], 'name' => t.children[0].children.to_s)
			end
		end
		xml.artists do
			artist_list.each do |t|					
				xml.artist('id'=> t.values[0].split('=')[-1], 'name' => t.children[0].children.to_s)
			end
		end
		xml.magazines do
			mag_list.each do |t|				
				xml.magazine('id'=> t.values[0].split('=')[-1], 'title' => t.children[0].children.to_s)
			end
		end
		xml.publishers do
			publisher_list.each do |t|					
				xml.publisher('id'=> t.values[0].split('=')[-1], 'title' => t.children[0].children.to_s)
			end
		end
		xml.englishPublishers do
			engPublisher_list.each do |t|					
				xml.publisher('id'=> t.values[0].split('=')[-1], 'title' => t.children[0].children.to_s)
			end
		end
		
	end
	end
	rescue => e
		logger.error(e)
		return returnError("Unable to write content")
	end

	seriesBuilder.to_xml
end

get "/" do
	content_type 'text/xml'
	returnError("No request type given")
end

error 400..510 do
  content_type 'text/xml'
	returnError("Invalid request type")
end

get "/series/:id" do
	content_type 'text/xml'
	parseSeries(params['id'])
end
