# frozen_string_literal: true

require 'readline'

##
# Shell
class Shell
  BANNER = <<~ENDBANNER
    ___________________________

     OverTheWire wargame Natas
    ___________________________
  ENDBANNER

  CONFIG_FILE = "#{Dir.home}/.natas.yml"
  PROMPT = 'Natas> '

  attr_reader :console, :natas, :commands

  def initialize
    @console = Console.new
    @natas = Natas.new(self)
    @commands = []
    ObjectSpace.each_object(Class).select { |c| c < CmdBase }.each { |c| @commands << c.new(self) }
    @commands.sort! { |a, b| a.name <=> b.name }

    return unless File.exist?(CONFIG_FILE)

    config = YAML.safe_load(File.read(CONFIG_FILE))
    @natas.levels.each do |level|
      level.password = config.fetch(level.level, nil)
    end
  end

  def run
    Signal.trap('INT') { exit }

    puts @console.cyan.bold(BANNER)
    cmd_help = @commands.detect { |c| c.instance_of?(CmdHelp) }
    puts @console.yellow("Type #{cmd_help.name} or #{cmd_help.aliases.first} for list of commands")

    loop do
      line = Readline.readline(@console.green.bold(PROMPT))
      exit if line.nil?
      line.strip!
      next if line.empty?

      words = line.split(/\s+/)
      cmd = words.first.downcase
      command = @commands.detect { |c| c.name == cmd || c.aliases.include?(cmd) }
      if command.nil?
        puts @console.red('Unrecognized command ') + @console.magenta.bold(cmd)
        next
      end
      command.exec(words[1..-1])
    end
  end
end

##
# Base command
class CmdBase
  NAME = nil
  ALIASES = nil
  ARGUMENTS = nil
  DESCRIPTION = nil

  def initialize(shell)
    @shell = shell
  end

  def exec(args); end

  def name
    self.class::NAME
  end

  def aliases
    self.class::ALIASES
  end

  def arguments
    self.class::ARGUMENTS
  end

  def description
    self.class::DESCRIPTION
  end
end

##
# Command quit
class CmdQuit < CmdBase
  NAME = 'quit'
  ALIASES = ['q'].freeze
  ARGUMENTS = [].freeze
  DESCRIPTION = 'Quit'

  def exec(_)
    exit
  end
end

##
# Command help
class CmdHelp < CmdBase
  NAME = 'help'
  ALIASES = ['?'].freeze
  ARGUMENTS = [].freeze
  DESCRIPTION = 'Help'

  def exec(_)
    @shell.commands.each do |command|
      cmd = []
      cmd << command.name
      cmd += command.arguments.map { |a| "<#{a}>" }
      puts format(
        '%<alias>s %<cmd>-30s %<description>s',
        {
          alias: @shell.console.cyan.bold(command.aliases.first),
          cmd: @shell.console.magenta(cmd.join(' ')),
          description: @shell.console.yellow(command.description)
        }
      )
    end
  end
end

##
# Command list
class CmdList < CmdBase
  NAME = 'list'
  ALIASES = ['l'].freeze
  ARGUMENTS = [].freeze
  DESCRIPTION = 'List levels'

  def exec(_)
    @shell.natas.levels.each do |level|
      l = format(
        '%<login>s%<level>d: %<password>s',
        {
          login: NatasLevelBase::LOGIN,
          level: level.level,
          password: level.password
        }
      )
      if level.level == @shell.natas.level
        puts @shell.console.red.bold.on_white(l)
      else
        puts l
      end
    end
  end
end

##
# Command execute
class CmdExecute < CmdBase
  NAME = 'execute'
  ALIASES = ['e'].freeze
  ARGUMENTS = ['num'].freeze
  DESCRIPTION = 'Execute the level'

  def exec(args)
    unless args[0].nil?
      level = args[0].to_i
      if level >= 0 && level <= @shell.natas.class::MAXLEVEL
        @shell.natas.level = level
      else
        puts @shell.console.red("Level must be between 0-#{@shell.natas.class::MAXLEVEL}")
        return
      end
    end

    @shell.natas.level = 0 if @shell.natas.level.nil?

    begin
      @shell.natas.exec
    rescue StandardError => e
      puts @shell.console.red(e)
    end
  end
end

##
# Command next
class CmdNext < CmdBase
  NAME = 'next'
  ALIASES = ['n'].freeze
  ARGUMENTS = [].freeze
  DESCRIPTION = 'Next level'

  def exec(_)
    if @shell.natas.level == @shell.natas.class::MAXLEVEL
      puts @shell.console.red('Maximum level reached')
      return
    end
    @shell.natas.level = @shell.natas.level.nil? ? 0 : @shell.natas.level + 1

    begin
      @shell.natas.exec
    rescue StandardError => e
      puts @shell.console.red(e)
    end
  end
end

##
# Command save
class CmdSave < CmdBase
  NAME = 'save'
  ALIASES = ['s'].freeze
  ARGUMENTS = [].freeze
  DESCRIPTION = 'Save levels information'

  def exec(_)
    File.write(@shell.class::CONFIG_FILE, @shell.natas.to_yaml)
    puts @shell.console.yellow("Information has been saved to #{@shell.class::CONFIG_FILE}")
  end
end
