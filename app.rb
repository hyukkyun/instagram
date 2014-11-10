require "sinatra"
require "instagram"
require 'sinatra/reloader' if development?
require "uri"


enable :sessions

CALLBACK_URL = "http://localhost:9393/oauth/callback"

Instagram.configure do |config|
  config.client_id = "6b3eca301e364e7a8d5776e4893a0515"
  config.client_secret = "448f28e141b842969c8f9f4eccc6bab9"
  # For secured endpoints only
  #config.client_ips = '<Comma separated list of IPs>'
end

get "/" do
  '<a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :scope => 'comments relationships likes')
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/insta"
end


get "/insta" do

  client = Instagram.client(:access_token => session[:access_token])
  @user = client.user
  erb :index
end

get "/logout" do
  html =
  """
    <p>감사합니다</p>
    <a href='/'>처음으로</a><br>
    <a href='/oauth/connect'>Connect with Instagram</a>
    <iframe src='https://instagram.com/accounts/logout/' width='0' height='0' frameborder='no' scrolling='no'></iframe>
  """
  html
end


get "/user_recent_media" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  html = "<h1>#{user.username}'s recent media</h1>"
  for media_item in client.user_recent_media
    html << "<div style='float:left;'><img src='#{media_item.images.thumbnail.url}'><br/> <a href='/media_like/#{media_item.id}'>Like</a>  <a href='/media_unlike/#{media_item.id}'>Un-Like</a>  <br/>LikesCount=#{media_item.likes[:count]}</div>"
  end
  html
end

get '/media_like/:id' do
  client = Instagram.client(:access_token => session[:access_token])
  client.like_media("#{params[:id]}")
  redirect "/user_recent_media"
end

get '/media_unlike/:id' do
  client = Instagram.client(:access_token => session[:access_token])
  client.unlike_media("#{params[:id]}")
  redirect "/user_recent_media"
end

get "/user_media_feed" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  html = "<h1>#{user.username}'s media feed</h1>"

  page_1 = client.user_media_feed(777)
  page_2_max_id = page_1.pagination.next_max_id
  page_2 = client.user_recent_media(777, :max_id => page_2_max_id ) unless page_2_max_id.nil?
  html << "<h2>Page 1</h2><br/>"
  for media_item in page_1
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html << "<h2>Page 2</h2><br/>"
  for media_item in page_2
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
end

get "/location_recent_media" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Media from the Instagram Office</h1>"
  for media_item in client.location_recent_media(514276)
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
end

get "/media_search" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Get a list of media close to a given latitude and longitude</h1>"
  for media_item in client.media_search("37.7808851","-122.3948632")
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
end

get "/media_popular" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Get a list of the overall most popular media items</h1>"
  for media_item in client.media_popular
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
end
=begin
get "/user_search" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Search for users on instagram, by name or usernames</h1>"
  for user in client.user_search("coffeeworkers")
    html << "<li> <img src='#{user.profile_picture}'> #{user.username} #{user.full_name}</li>"
  end
  html
end
=end

get "/user_search" do
  erb :usersearch
end

get "/usersearch_process" do
  client = Instagram.client(:access_token => session[:access_token])
  @user = client.user_search(params[:username])

  erb :userlist
end


get "/location_search" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Search for a location by lat/lng with a radius of 5000m</h1>"
  for location in client.location_search("48.858844","2.294351","5000")
    html << "<li> #{location.name} <a href='https://www.google.com/maps/preview/@#{location.latitude},#{location.longitude},19z'>Map</a></li>"
  end
  html
end

get "/location_search_4square" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1>Search for a location by Fousquare ID (v2)</h1>"
  for location in client.location_search("3fd66200f964a520c5f11ee3")
    html << "<li> #{location.name} <a href='https://www.google.com/maps/preview/@#{location.latitude},#{location.longitude},19z'>Map</a></li>"
  end
  html
end
=begin
get "/tags" do
  @client = Instagram.client(:access_token => session[:access_token])
  @tags = @client.tag_search('루비')
  @page_1 = @client.tag_recent_media(@tags[0].name)


  @page_2_max_id = @page_1.pagination.next_max_id
  @page_2 = @client.tag_recent_media(@tags[0].name, :max_id => @page_2_max_id ) unless @page_2_max_id.nil?

  @page_3_max_id = @page_2.pagination.next_max_id
  @page_3 = @client.tag_recent_media(@tags[0].name, :max_id => @page_3_max_id ) unless @page_3_max_id.nil?

  erb :tags


end
=end



get "/tagsearch" do

  erb :tagsearch
end

post "/tags" do
  @client = Instagram.client(:access_token => session[:access_token])
  @tags = @client.tag_search(URI.escape(params[:tagname]))
  session[:tag] = URI.escape(params[:tagname])


  next_page_id = params[:next_page_id]
  @page = @client.tag_recent_media(@tags[0].name, :max_id => next_page_id )


  #@page_1 = @client.tag_recent_media(@tags[0].name)
  #@page_2_max_id = @page_1.pagination.next_max_id

  #@page_2 = @client.tag_recent_media(@tags[0].name :max_id => @page_2_max_id)
  #@page_3_max_id = @page_2.pagination.next_max_id

  erb :tags
end

post "/tag_process" do
  @client = Instagram.client(:access_token => session[:access_token])
  @tags = @client.tag_search("#{session[:tag]}")

  next_page_id = params[:next_page_id]
  if next_page_id.empty?
 
   else
  @page = @client.tag_recent_media(@tags[0].name, :max_id => next_page_id )
  @next_page_id = @page.pagination.next_max_id
  erb :tagsimg
  end
end


get "/allsearch" do

  erb :allsearch
end


get '/allsearch_process' do
  client = Instagram.client(:access_token => session[:access_token])
  @bio = client.user_search.bio

  allclient = Instagram.all
  @allbio = allclient.user.bio
  @dbbio = allclient.user(:bio.like => '%' + params[:search] + '%')

  @user = client.user
  @userbio = @user.bio
  @database_search_name = Search.all(:search_name.like => '%' + params[:myword] + '%')

  erb :searchdo

end





get "/limits" do
  client = Instagram.client(:access_token => session[:access_token])
  html = "<h1/>View API Rate Limit and calls remaining</h1>"
  response = client.utils_raw_response
  html << "Rate Limit = #{response.headers[:x_ratelimit_limit]}.  <br/>Calls Remaining = #{response.headers[:x_ratelimit_remaining]}"

  html
end