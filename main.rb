
require 'bundler/setup'

require 'pry'

require 'dotenv'
Dotenv.load if ENV['TOKEN'].nil?

require 'configatron'
require_relative 'config.rb'

require 'json'

require 'discordrb'

bot = Discordrb::Commands::CommandBot.new token: ENV['TOKEN'], application_id: ENV['APPID'], prefix: configatron.prefix, advanced_functionality: false, debug: true #, log_mode: :debug

bot.command(:invite, description: 'Add the bot to your server') do |event|
  "You can add this bot to your server. Just be aware that it logs ALL messages it can get hold off. Also who is able to view them is subject to change now and then. Right now this all is still BETA!!! #{bot.invite_url.to_s}"
end

bot.command(:stats, description: 'shows a few stats about the bot') do |event|
  members = 0
  event.bot.servers.each {|x,y| members = members + y.member_count}
  "Currently I'm on **#{event.bot.servers.size} servers** with a total user count of **#{members} users** in **#{event.bot.servers.collect { |x, y| y.channels.size }.inject(0, &:+)} channels**!"
end



# Method to create sth
def create(url, data)
  RestClient.post ENV['APIBASE']+url, data, :content_type => :json
end

# Method to update sth
def update(url, data)
  RestClient.put url, data, :content_type => :json
end

# Message Events
# Fired on message creation
bot.message do |event|
  puts "I saw that!"
  create("/messages", {"api_token" => "#{ENV['APITOKEN']}", "message" => { 'id' => "#{event.message.id}", 'content' => "#{event.message.content}", 'status' => 'active'}}.to_json)
end

# Fired when a message gets edited
bot.message_edit do |event|
  puts "edit"
end

# Fired when a message gets deleted
bot.message_delete do |event|
  puts "msg got deleted"
end

# Channel Events
# Fired when a channel gets created
bot.channel_create do |event|
  history = event.channel.history(50)
  puts "a channel got created"
end

#Fired when a channel gets updated
bot.channel_update do |event|
  puts "Channel got updated"
end

# Fired when a channel gets deleted
bot.channel_delete do |event|
  puts "Channel got deleted"
end

# Server events
# Fired when a Server gets created (Bot gets added to a server)
bot.server_create do |event|
  puts "Server got created"
  event.server.owner.pm "Someone added me to this server. All messages I can view I'm logging to INSERT HERE (TODO)"
  create("/servers", {"api_token" => "#{ENV['APITOKEN']}", "server" => { "server_id" => "#{event.server.id}", "name" => "#{event.server.name}", "owner_id" => "#{event.server.owner.id}", "membercount" => "#{event.server.members.size}", "icon_id" => "#{event.server.icon_id}", "status" => "active"}}.to_json)
end

# Fired when a Server gets updated
bot.server_update do |event|
  puts "Server got updated"
  update("/servers", {"api_token" => "#{ENV['APITOKEN']}", "server" => { "server_id" => "#{event.server.id}", "name" => "#{event.server.name}", "owner_id" => "#{event.server.owner.id}", "membercount" => "#{event.server.members.size}", "icon_id" => "#{event.server.icon_id}", "status" => "active"}}.to_json)
end

# Fired when a Server gets deleted (Bot gets removed)
bot.server_delete do |event|
  puts "Server got deleted"
  missingserver = bot.servers.clone.flatten.to_a - @cachedservers.to_a
  update("/servers", {"api_token" => "#{ENV['APITOKEN']}", "server" => { "server_id" => "#{missingserver.first}", "status" => "deleted"}}.to_json)
end

bot.server_create do |event|
  @cachedservers = bot.servers.clone
end

bot.ready do |event|
  @cachedservers = bot.servers.clone
end

# Member events
# Fired when a User joins a Server
bot.member_join do |event|
  event.user.pm "Messages on this server are getting logged to INSERT HERE (TODO)"
end

# Fired when a User leaves Server
bot.member_leave do |event|
  begin
    event.user.pm "Please be aware that your messages will stay saved."
  rescue
    puts "Can't dm #{event.user.id}, no permission error"
  end
end


bot.run :async
bot.game = 'NSA'
bot.sync
