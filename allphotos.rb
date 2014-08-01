require 'rubygems'
require 'sinatra'
require 'fastimage'

LIBRARY='/Users/David/Pictures/iPhoto Library'
PHOTOBASE="#{LIBRARY}/Originals"
THUMBBASE="#{LIBRARY}/Data.noindex"
PAGESIZE=40

def photo_list(dir)
	Dir.glob("#{dir}/**/*").reject { |path| File.directory?(path) || (path =~ /.MOV$/) }
end

def page_first(pagenum)
	(pagenum - 1) * PAGESIZE
end

def page_last(pagenum)
	(pagenum - 1) * PAGESIZE + (PAGESIZE - 1)
end

def last_page(total)
	(total / PAGESIZE) + 1
end

Photos = photo_list(PHOTOBASE)
Thumbs = photo_list(THUMBBASE)

puts "Read #{Photos.size} photos from #{PHOTOBASE}"
puts "Read #{Thumbs.size} thumbs from #{THUMBBASE}"

p Photos[0..3]
p Thumbs[0..3]

p FastImage.size(Photos[0])
p FastImage.size(Thumbs[0])

puts "Test pf 1 / 2 / last : #{ page_first(1) }, #{ page_first(2) }, #{ page_first(last_page(Photos.size)) }"
puts "Test pl 1 / 2 / last : #{ page_last(1) },  #{ page_last(2) },  #{ page_last(last_page(Thumbs.size)) }"

get '/' do
	erb :index
end

get '/sheet/:id' do
	@page = params[:id].to_i
	@pfirst = page_first(@page)
	@plast = page_last(@page)
	@photofiles = Photos[@pfirst..@plast]

	@last = last_page(Photos.size)
	@prev = [(@page - 1), 1    ].max
	@next = [(@page + 1), @last].min

	erb :sheet
end

get '/list/:id' do
	@page = params[:id].to_i
	@pfirst = page_first(@page)
	@plast = page_last(@page)
	@photofiles = Photos[@pfirst..@plast]

	@last = last_page(Photos.size)
	@prev = [(@page - 1), 1    ].max
	@next = [(@page + 1), @last].min

	erb :list
end

