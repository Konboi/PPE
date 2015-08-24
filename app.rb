require 'sinatra/base'
require 'json'
require 'mysql2-cs-bind'
require 'digest/sha2'
require 'erubis'
require 'securerandom'

class Ppe < Sinatra::Base
  set :bind, '0.0.0.0'
  helpers do
    set :erb, :escape_html => true
  end
  def connection
    config = JSON.parse(IO.read(File.dirname(__FILE__) + "/config/config.json"))['db']
    return $mysql if $mysql
    $mysql = Mysql2::Client.new(
      :host => config['host'],
      :port => config['port'],
      :username => config['username'],
      :password => config['password'],
      :database => config['dbname'],
      :reconnect => true,
    )
  end

  get '/' do
    erb :index, :layout => :base, :locals => {}
  end

  post '/post' do
    mysql = connection

    content  = params[:content]
    hash = SecureRandom.hex(4)

    if content && hash
      mysql.xquery(
        'INSERT INTO np (hash, content, created_at) VALUES (?, ?, ?)',
        hash,
        content,
        Time.now
      )
    end

    redirect "/np/#{hash}"
  end

  get '/np/:hash' do
    mysql = connection

    hash  = params[:hash]

    np = mysql.xquery('SELECT content FROM np WHERE hash=?', hash).first

    erb :np, :layout => :base, :locals => {
      :content => np["content"],
    }
  end

  run! if app_file == $0
end
