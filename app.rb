#NOTE: MUST CONNECT TO WEBSITE USING HTTP://LOCALHOST:4567 DUE TO REASONS WITH GOOGLE OATH CALLBACKS
require 'sequel'
require 'sinatra'
require 'omniauth'
require 'google/omniauth'
require 'google/api_client/client_secrets'

#DATABASE
DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/wps_rate_teachers.db')
require './models/entry.rb'
require './models/user.rb'

#GOOGLE AUTH

CLIENT_SECRETS = Google::APIClient::ClientSecrets.load

def client
  c = (Thread.current[:client] ||=
      Google::APIClient.new(:application_name => 'Ruby Google+ sample',
                            :application_version => '1.0.0'))
  # It's really important to clear these out,
  # since we reuse client objects across requests
  # for caching and performance reasons.
  c.authorization.clear_credentials!
  return c
end
client1 = Google::APIClient.new
oauth2 = client1.discovered_api('oauth2')


def api_client; settings.api_client; end

#LOGOUT CODE (CLEAR SESSIONS)
get '/logout' do
  session['credentials'] = nil
  session.clear
  redirect '/'
end
get '/' do
  redirect '/main'
end

get '/login' do
  if session['credentials']
    redirect '/main'
  else

    erb :login
  end

end
# Support both GET and POST for callbacks. (AGAIN, MORE GOOGLE AUTH STUFF...)
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do
    Thread.current[:client] = env['omniauth.auth']['extra']['client']

    # Keep track of the tokens. Use a real database in production.
    session['uid'] = env['omniauth.auth']['uid']
    session['credentials'] = env['omniauth.auth']['credentials']


    redirect '/main'
  end
end

get '/auth/failure' do
  redirect '/'
end

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider OmniAuth::Strategies::Google,
           CLIENT_SECRETS.client_id,
           CLIENT_SECRETS.client_secret,
           :scope => [
               'https://www.googleapis.com/auth/userinfo.profile',
               'https://www.googleapis.com/auth/userinfo.email',
               'https://www.googleapis.com/auth/plus.me'
           ],
           :skip_info => false
end

get '/main' do
  if session['credentials']
    # Build an authorization object from the client secrets.
    authorization = CLIENT_SECRETS.to_authorization
    authorization.update_token!(
        :access_token => session['credentials']['access_token'],
        :refresh_token => session['credentials']['refresh_token']
    )
    @token = session['credentials']['access_token']



    result = client1.execute(
        :api_method => oauth2.userinfo.get,
        :authorization => authorization
    )
    puts result.status
    if result.status == 401
      # The access token expired, fetch a new one and retry once.
      redirect '/logout'
    end

    puts session['credentials']
    session['email'] = result.data.email
    user = User.first(:email => session['email'])
    logged_in = true
    wepo_only = false

    if !user
      if result.data.hd.include? "westport.k12.ct.us"
        new_user = User.new
        new_user.name = result.data.name
        new_user.email = result.data.email
        new_user.save
        logged_in = true
        wepo_only = false
        first_time = true
      else
        session['credentials'] = nil
        session.clear
        logged_in = false
        wepo_only = true
      end
    end

  else
    logged_in = false
  end
  entries = Entry.all
  @teacher_entries = Entry.all
  f = File.new('./staff_directory.json', 'rb')
  data = JSON.parse(f.read)
  f.close
  puts data.inspect
  names = []
  data["Employees"].each do |person|
    names << person['Name'].to_s
  end
  puts names.inspect

  erb :index, :locals => {
      :result => result,
      :data => data["Employees"],
      :logged_in => logged_in,
      :entries => Entry.all,
      :wepo_only => wepo_only,
      :first_time => first_time,
      :names => names.to_json
  }
end

post '/post/create' do
  if session['credentials']
    user = User.first(:email => session['email'])
    entry = Entry.new
    entry.rating = params[:rating].to_i
    entry.body = params[:body]
    entry.teacher_id = params[:teacherID].to_i
    entry.user = user
    entry.created_at = Time.now
    entry.save
    stars = ""
    entry.rating.times do
      stars << '<div class="reviewRating"></div>'
    end
    d = DateTime.parse (entry.created_at.to_s)
    "<li class='list-group-item entryList'>
                    <span style='float: left; color: #d50000; display: inline-block' align='left'>#{entry.user.name}</span>

        <span style='float: right; display: inline-block; color: greenyellow'>
                          #{d.strftime('%A, %B %d, %Y')} -
                    #{d.strftime('%-I:%M:%S %p')}
    </span><br /><br />
                    <B>Rating:</B><br />
                    #{stars}
  <br />
                    <b>Review:</b><br /> #{entry.body}

                  </li>"
  else
    redirect '/'
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def confirmation_post(url)
    "<form method='post' action='' class='inline'>" +
        "<input type='submit' value='delete'>" +
        "</form>"
  end
end