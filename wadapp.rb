require 'sinatra'
require 'sinatra/activerecord'
set :bind, '0.0.0.0'

ActiveRecord::Base.establish_connection(
	:adapter => 'sqlite3',
	:database => 'wiki.db'
)

class User < ActiveRecord::Base
	validates :username, presence: true, uniqueness: true
	validates :password, presence: true
end

class Article < ActiveRecord::Base
	validates :name, presence: true
	validates :body, presence: true
	validates :date, presence: true
end

helpers do
	def protected!
		if authorized?
			return
		end
		redirect '/denied'
	end
	
	def authorized?
		if $credentials != nil
			@Userz = User.where(:username => $credentials[0]).to_a.first
			if @Userz
				if @Userz.edit == true
					return true
				else
					return false
				end
			else
				return false
			end
		end
	end
end

$myinfo = ""
@info = ""

def readFile(filename)
	info = ""
	file = File.open(filename)
	file.each do |line|
		info = info + line
	end
	file.close
	$myinfo = info
end

get '/' do
	info = "Hello there!"
	len = info.length
	len1 = len
	readFile("wiki.txt")
	@info = info + " " + $myinfo
	len = @info.length
	len2 = len - 1
	len3 = len2 - len1
	@words = len3.to_s
	erb :home
end

get '/about' do
	erb :about
end

get '/create' do
	erb :create
end

post '/create' do
	#do not create a new article if one with the same name already exists
	if Article.exists?(["lower(name) = ?", params[:name].downcase])
		erb :articleexists
	else
		n = Article.new
		n.name = params[:name]
		n.body = params[:body]
		n.date = Time.now
		n.save
		redirect "/article/" + params[:name]
	end
end

get '/edit' do
	info = ""
	file = File.open("wiki.txt")
	file.each do |line|
		info = info + line
	end
	file.close
	@info = info
	erb :edit
end

put '/edit' do
	info = "#{params[:message]}"
	@info = info
	file = File.open("wiki.txt", "w")
	file.puts @info
	file.close
	redirect '/'
end

get '/login' do
	erb :login
end

post '/login' do
	$credentials = [params[:username],params[:password]]
	@Users = User.where(:username => $credentials[0]).to_a.first
	if @Users
		if @Users.password == $credentials[1]
			redirect '/'
		else
			$credentials = ['', '']
			redirect '/wrongaccount'
		end
	else
		$credentials = ['','']
		redirect '/wrongaccount'
	end
end

get '/wrongaccount' do
	erb :wrongaccount
end

get '/createaccount' do
	erb :createaccount
end

post '/createaccount' do 
	n = User.new
	n.username = params[:username]
	n.password = params[:password]
	if n.username == "Admin"
		n.edit = true
	end
	n.save
	redirect "/"
end

get '/logout' do
	$credentials = ['','']
	redirect '/'
end

get '/notfound' do
	erb :notfound
end

get '/noaccount' do
	erb :noaccount
end

get '/denied' do
	erb :denied
end

get '/admincontrols' do
	protected!
	@list2 = User.all.sort_by { |u| [u.id] }
	erb :admincontrols
end

get '/user/:uzer' do
	protected!
	@Userz = User.where(:username => params[:uzer]).to_a.first
	if @Userz != nil
		erb :profile
	else
		redirect '/denied'
	end
end

put '/user/:uzer' do
	n = User.where(:username => params[:uzer]).to_a.first
	n.edit = params[:edit] ? 1 : 0
	n.save
	redirect '/'
end

get '/user/delete/:uzer' do
	protected!
	n = User.where(:username => params[:uzer]).to_a.first
	if n.username == "Admin"
		erb :denied
	else
		n.destroy
		@list2 = User.all.sort_by { |u| [u.id] }
		erb :admincontrols
	end
end

get '/nochange' do
	erb :articlenochange
end

# delete all articles and their old versions
delete '/article' do
	Article.delete_all
	redirect '/'
end

get '/article/:articlename' do
	@n = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.order("date DESC")
		.to_a.first
	if !@n
		status 404
		redirect '/notfound'
	else
		erb :article
	end
end

put '/article/:articlename' do
	oldBody = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.order("date DESC")
		.to_a.first.body
		
	# do not update if the article's body is the same as the latest one
	if params[:body] == oldBody
		redirect '/nochange'
	else
		n = Article.new
		n.name = params[:name]
		n.body = params[:body]
		n.date = Time.now
		n.save
		redirect '/article/' + params[:name]
	end
end

get '/article/:articlename/edit' do
	@n = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.order("date DESC")
		.to_a.first
		
	if !@n
		status 404
		redirect '/notfound'
	else
		erb :articleedit
	end
end

get '/history/:articlename' do
	@arr = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.order("date DESC")
		.to_a
		
	if @arr.length == 0
		status 404
		redirect '/notfound'
	else
		erb :history
	end
end

#delete specific article and all of its versions
delete '/history/:articlename' do
	Article.where("lower(name) = ?", params[:articlename].downcase).destroy_all
	redirect '/'
end

#delete all specified article versions from newest to selected, exclusive
delete '/history/:articlename/deleteto/:id' do
	date = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.where(:id => params[:id])
		.to_a.first.date
		
	Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.where("date > ?", date)
		.destroy_all
	redirect '/history/'+params[:articlename]
end

get '/history/:articlename/:id' do
	@n = Article
		.where("lower(name) = ?", params[:articlename].downcase)
		.where(:id => params[:id])
		.to_a.first
		
	if !@n
		status 404
		redirect '/notfound'
	else
		# track if user is viewing history of article instead of standard article page
		@viewingHistory = true
		erb :article
	end
end

not_found do
	status 404
	redirect '/notfound'
end