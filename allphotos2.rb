require 'rubygems'
require 'sinatra'
require 'fastimage'
require 'sqlite3'

LIBRARY="/Users/David/Pictures/iPhoto Library"
# DBPATH="/var/tmp/iPhotoMain.db"
# "live" DB :
DBPATH="#{LIBRARY}/iPhotoMain.db"
PAGESIZE=40

set :bind, '0.0.0.0'

class PhotoLibrary
	def initialize(dbpath)
		@db = SQLite3::Database.new(dbpath)
	end

	def get_flagged_album_paths(type)
		imagetype = case type
		when "photo"
			"6"
		when "thumb"
			"5"
		end
		@db.execute("SELECT sfinfo.relativePath
from sqalbum as sqa
left outer join AlbumsPhotosJoin as apj on apj.sqAlbum = sqa.primaryKey
left outer join SqFileImage      as sfim on sfim.photoKey = apj.sqPhotoInfo
left outer join SqFileInfo       as sfinfo on sfinfo.primaryKey = sfim.primaryKey
where sfim.imageType = #{imagetype}
and sqa.name = 'Flagged'
and sqa.className = 'Album'
and sfinfo.relativePath is not null")
	end

	def photo_list
		get_flagged_album_paths("photo").flatten.map! { |relpath| LIBRARY + "/" + relpath }
	end

	def thumb_list
		get_flagged_album_paths("thumb").flatten.map! { |relpath| LIBRARY + "/" + relpath }
	end
end

class PhotoPage
	attr_accessor :page, :last, :prev, :next, :photofiles, :thumbfiles, :maxwidth, :maxheight

	def initialize(pagenum, photoarray, thumbarray)
		@page = pagenum
		@pfirst = page_first(@page)
		@plast  = page_last(@page, photoarray.size)
		@photofiles = photoarray[@pfirst..@plast]

		@maxwidth  = 0
		@maxheight = 0
		@thumbfiles = {}
		(@pfirst..@plast).each do |i| 
			@thumbfiles[photoarray[i]] = thumbarray[i]
			puts "DEBUG: i = #{i}"
			p @thumbfiles[photoarray[i]]
			w, h = FastImage.size(@thumbfiles[photoarray[i]])
			p w
			p h
			puts "====="
			if (!w.nil? && w > @maxwidth)
				@maxwidth  = w
			end
			if (!h.nil? && h > @maxheight)
				@maxheight = h
			end
		end
		@maxwidth  = @maxwidth  / 2
		@maxheight = @maxheight / 2

		@last = last_page(photoarray.size)
		@prev = [(@page - 1), 1    ].max
		@next = [(@page + 1), @last].min
	end

	def page_first(pagenum)
		(pagenum - 1) * PAGESIZE
	end

	def page_last(pagenum, arrsize)
		[ (pagenum - 1) * PAGESIZE + (PAGESIZE - 1), arrsize - 1].min
	end
end

def last_page(total)
	(total / PAGESIZE) + 1
end

iphoto = PhotoLibrary.new(DBPATH)

Photos = iphoto.photo_list
Thumbs = iphoto.thumb_list

puts "Read #{Photos.size} photos from iPhoto DB #{DBPATH}"
puts "Read #{Thumbs.size} thumbs from iPhoto DB #{DBPATH}"

get '/' do
	erb :index
end

get '/sheet/:id' do
	@thispage = PhotoPage.new(params[:id].to_i, Photos, Thumbs)

	erb :sheet
end

get '/list/:id' do
	@thispage = PhotoPage.new(params[:id].to_i, Photos, Thumbs)

	erb :list
end

