require "readline"

class Shell
  BANNER = <<~EOF
    ___________________________

     OverTheWire wargame Natas
    ___________________________
  EOF

  CONFIG_FILE = Dir.home + "/.natas.yml"
  PROMPT = "Natas> "

  attr_reader :console, :natas, :commands

  def initialize
    @console = Console.new
    @natas = Natas.new(self)
    @commands = Array.new
    ObjectSpace.each_object(Class).select {|c| c < CmdBase}.each {|c| @commands << c.new(self)}
    @commands.sort! {|a, b| a.get_name <=> b.get_name}

    if File.exist?(CONFIG_FILE)
      config = YAML.load(File.read(CONFIG_FILE))
      @natas.levels.each do |level|
        level.password = config.fetch(level.level, nil)
      end
    end
  end

  def run
    Signal.trap("INT") {exit}

    puts @console.cyan.bold(BANNER)
    cmd_help = @commands.detect {|c| c.instance_of?(CmdHelp)}
    puts @console.yellow("Type #{cmd_help.get_name} or #{cmd_help.get_aliases.first} for list of commands")

    loop do
      line = Readline.readline(@console.green.bold(PROMPT))
      exit if line.nil?
      line.strip!
      next if line.empty?
      words = line.split(/\s+/)
      cmd = words.first.downcase
      command = @commands.detect {|c| c.get_name == cmd || c.get_aliases.include?(cmd)}
      if command.nil?
        puts @console.red("Unrecognized command ") + @console.magenta.bold(cmd)
        next
      end
      command.exec(words[1..-1])
    end
  end
end

class CmdBase
  NAME        = nil
  ALIASES     = nil
  ARGUMENTS   = nil
  DESCRIPTION = nil

  def initialize(shell)
    @shell = shell
  end

  def exec(args); end
  def get_name; self.class::NAME end
  def get_aliases; self.class::ALIASES end
  def get_arguments; self.class::ARGUMENTS end
  def get_description; self.class::DESCRIPTION end
end

class CmdQuit < CmdBase
  NAME        = "quit"
  ALIASES     = ["q"]
  ARGUMENTS   = []
  DESCRIPTION = "Quit"

  def exec(args)
    exit
  end
end

class CmdHelp < CmdBase
  NAME        = "help"
  ALIASES     = ["?"]
  ARGUMENTS   = []
  DESCRIPTION = "Help"

  def exec(args)
    @shell.commands.each do |command|
      cmd = Array.new
      cmd << command.get_name
      cmd += command.get_arguments.map {|a| "<#{a}>"}
      puts "%s %-30s %s" % [
        @shell.console.cyan.bold(command.get_aliases.first),
        @shell.console.magenta(cmd.join(" ")),
        @shell.console.yellow(command.get_description),
      ]
    end
  end
end

class CmdList < CmdBase

  NAME        = "list"
  ALIASES     = ["l"]
  ARGUMENTS   = []
  DESCRIPTION = "List levels"

  def exec(args)
    @shell.natas.levels.each do |level|
      l = "%s%d: %s" % [
        NatasLevelBase::LOGIN,
        level.level,
        level.password,
      ]
      if level.level == @shell.natas.level
        puts @shell.console.red.bold.on_white(l)
      else
        puts l
      end
    end
  end
end

class CmdExecute < CmdBase
  NAME        = "execute"
  ALIASES     = ["e"]
  ARGUMENTS   = ["num"]
  DESCRIPTION = "Execute the level"

  def exec(args)
    unless args[0].nil?
      level = args[0].to_i
      unless level >= 0 && level <= @shell.natas.class::MAXLEVEL
        puts @shell.console.red("Level must be between 0-#{@shell.natas.class::MAXLEVEL}")
        return
      else
        @shell.natas.level = level
      end
    end

    @shell.natas.level = 0 if @shell.natas.level.nil?

    begin
      @shell.natas.exec
    rescue => e
      puts @shell.console.red(e)
    end
  end
end

class CmdNext < CmdBase
  NAME        = "next"
  ALIASES     = ["n"]
  ARGUMENTS   = []
  DESCRIPTION = "Next level"

  def exec(args)
    if @shell.natas.level == @shell.natas.class::MAXLEVEL
      puts @shell.console.red("Maximum level reached")
      return
    end
    @shell.natas.level = @shell.natas.level.nil? ? 0 : @shell.natas.level + 1

    begin
      @shell.natas.exec
    rescue => e
      puts @shell.console.red(e)
    end
  end
end

class CmdSave < CmdBase
  NAME        = "save"
  ALIASES     = ["s"]
  ARGUMENTS   = []
  DESCRIPTION = "Save levels information"

  def exec(args)
    File.write(@shell.class::CONFIG_FILE, @shell.natas.to_yaml)
    puts @shell.console.yellow("Information has been saved to #{@shell.class::CONFIG_FILE}")
  end
end

